-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationLayOutRewardList
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationLayOutRewardList = class("UIOperationLayOutRewardList")

function UIOperationLayOutRewardList:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self:UpdateInfo()
end

function UIOperationLayOutRewardList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationLayOutRewardList:BindUIEvent()

end

function UIOperationLayOutRewardList:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UIOperationLayOutRewardList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  鈫撯啌鈫?-- ----------------------------------------------------------

function UIOperationLayOutRewardList:UpdateInfo()
    UIHelper.SetVisible(self.LabelMiniTitleCountOrHint, false)
    self.itemScript = {}

    local tRewardInfo = OperationSimpleTmplData.GetRewardInfo(self.nOperationID)
    UIHelper.SetString(self.LabelMiniTitle, UIHelper.GBKToUTF8(tRewardInfo.szTitle))
    local tReward = tRewardInfo.tRewardList
    UIHelper.RemoveAllChildren(self.ScrollViewRewardList)
    if tReward and not table_is_empty(tReward) then
        for k, _ in ipairs(tReward) do
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewRewardList)
            if itemScript then
                self:UpdataItemScript(itemScript, tReward, k)
            end
            table.insert(self.itemScript, itemScript)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardList)
end

function UIOperationLayOutRewardList:UpdataItemScript(itemScript, tReward, k)
    if itemScript then
        local tInfo = tReward[k]
        itemScript:OnInitWithTabID(tInfo.dwTabType, tInfo.dwIndex, tInfo.nCount)
        itemScript:SetClickCallback(function(nTabType, nTabID)
            self.SelectToggle = itemScript.ToggleSelect
            local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip,  self.SelectToggle)
            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
        end)
        UIHelper.SetAnchorPoint(itemScript._rootNode, 0, 0)
    end
end

function UIOperationLayOutRewardList:UpdataItemState(tRewardState)
    for k, itemScript in ipairs(self.itemScript) do
        if tRewardState[k] then
            itemScript:SetItemGray(tRewardState[k] == OPERACT_REWARD_STATE.ALREADY_GOT)
            itemScript:SetItemReceived(tRewardState[k] == OPERACT_REWARD_STATE.ALREADY_GOT)
        end
    end
end

return UIOperationLayOutRewardList
