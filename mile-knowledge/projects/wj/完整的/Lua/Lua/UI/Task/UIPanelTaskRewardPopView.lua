-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelTaskRewardPopView
-- Date: 2024-11-13 09:47:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelTaskRewardPopView = class("UIPanelTaskRewardPopView")

function UIPanelTaskRewardPopView:OnEnter(nQuestID, dwTargetType, dwTargetID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nQuestID = nQuestID
    self.dwTargetType, self.dwTargetID = dwTargetType, dwTargetID
    self.tbItemGroup, self.nGroupCount = QuestData.GetQuestFinishAwardList(nQuestID)
    self:UpdateInfo()
end

function UIPanelTaskRewardPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTaskRewardPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function()
        local nChooseNum = table.get_len(self.tbAwardInfoList)
        if (not self.tbAwardInfoList) or (nChooseNum < self.nGroupCount) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_MSG_SELECT_HOR)
        else
            QuestData.FinishQuest(self.nQuestID, self.dwTargetType, self.dwTargetID, self.tbAwardInfoList[1], self.tbAwardInfoList[2])
            UIMgr.Close(self)
        end
    end)
end

function UIPanelTaskRewardPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:HideItemTip()
    end)


end

function UIPanelTaskRewardPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelTaskRewardPopView:OnChooseAward(tbAwardInfo, scriptView)
    local nSelectIndex, nGroup = tbAwardInfo.nSelectIndex, tbAwardInfo.nGroup
    if not self.tbAwardInfoList then self.tbAwardInfoList = {} end
    self.tbAwardInfoList[nGroup] = nSelectIndex
    self:OpenTip(tbAwardInfo.dwTabType, tbAwardInfo.dwIndex, tbAwardInfo.nStackNum, tbAwardInfo.bBook, scriptView)
    self:UpdateChooseNum()
end

function UIPanelTaskRewardPopView:OnCanCelChooseAward(tbAwardInfo)
    local nSelectIndex, nGroup = tbAwardInfo.nSelectIndex, tbAwardInfo.nGroup
    if self.tbAwardInfoList and self.tbAwardInfoList[nGroup] and self.tbAwardInfoList[nGroup] == nSelectIndex then
        self.tbAwardInfoList[nGroup] = nil
        self:HideItemTip()
    end
    self:UpdateChooseNum()
end


function UIPanelTaskRewardPopView:UpdateChooseNum()
    local nNum = self.tbAwardInfoList and table.get_len(self.tbAwardInfoList) or 0
    local szContent = string.format("<color=#AED9E0>已选择的奖励：</c><color=#D7F6FF>%s/%s</color>", tostring(nNum), tostring(self.nGroupCount))
    UIHelper.SetRichText(self.LabelNum, szContent)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTaskRewardPopView:UpdateInfo()
    for nIndex, tbAwardList in pairs(self.tbItemGroup) do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskRewardCategoryCell, self.ScrollViewContent, tbAwardList, function(tbAwardInfo, scriptView)
            self:OnChooseAward(tbAwardInfo, scriptView)
        end, function(tbAwardInfo)
            self:OnCanCelChooseAward(tbAwardInfo)
        end)
    end
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
    self.nTimer = Timer.AddFrame(self, 2, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    end)
    self:UpdateChooseNum()
end

function UIPanelTaskRewardPopView:OpenTip(nTabType, nTabID , nCount, bBook, scriptView)
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    self.tips, self.scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptView._rootNode)

    if bBook then
        self.scriptItemTip:SetBookID(nCount)
    end

    local scriptIcon = scriptView:GetScriptItemIcon()
    if scriptIcon.bItem then
        self.scriptItemTip:OnInit(nTabType, nTabID)
    elseif scriptIcon.bIsCurrencyType then
        self.scriptItemTip:OnInitCurrency(nTabID , nCount, scriptIcon.bIsReputation)
    else
        self.scriptItemTip:OnInitWithTabID(nTabType, nTabID, nCount)
        self.scriptItemTip:SetBtnState({})
    end

    if nTabType and nTabID then
        self.CurSelectedItemView = scriptView
    end
end

function UIPanelTaskRewardPopView:HideItemTip()
    if self.scriptItemTip then
        self.scriptItemTip = nil
        -- if self.CurSelectedItemView then
        --     self.CurSelectedItemView:SetSelected(false)
        --     self.CurSelectedItemView = nil
        -- end
    end
end

return UIPanelTaskRewardPopView