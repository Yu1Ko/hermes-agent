-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetRewardChooseOneShell
-- Date: 2024-04-28 15:39:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetRewardChooseOneShell = class("UIWidgetRewardChooseOneShell")

function UIWidgetRewardChooseOneShell:OnEnter(tbAwardList, WidgetAwardPreFab, scrollView)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbWidgetAwardList = self.tbWidgetAwardList or {}
    self.tbAwardList = tbAwardList
    self.WidgetAwardPreFab = WidgetAwardPreFab
    self.scrollView = scrollView
    self:UpdateInfo()
end

function UIWidgetRewardChooseOneShell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRewardChooseOneShell:BindUIEvent()
    
end

function UIWidgetRewardChooseOneShell:RegEvent()
    Event.Reg(self, EventType.SelectAwardSuccess, function(tbAward)
        self:UpdateSelectAward(tbAward)
    end)
end

function UIWidgetRewardChooseOneShell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetRewardChooseOneShell:UpdateInfo()
    if not self.tbAwardList then return end
    local nCount = #self.tbAwardList
    for nIndex, tbAward in ipairs(self.tbAwardList) do
        local WidgetAward = self.tbWidgetAwardList[nIndex]
        local nItemTabType = tbAward[3] or nil
        local nItemIndex = tbAward[4] or nil
        local bReputation = tbAward[5] or nil
        local nIconID = tbAward[6] or nil
        if WidgetAward then
            local scriptView = WidgetAward.scriptView
            scriptView:OnEnter(tbAward[1], tbAward[2], nItemTabType, nItemIndex, nil, bReputation, nIconID)
            scriptView:SetImgAwardBgVis(false)
            scriptView:SetLineVis(nIndex ~= nCount)
            self:SetClickCallback(scriptView, tbAward)
        else
            local scriptView = UIHelper.AddPrefab(self.WidgetAwardPreFab, self.LayoutRewardList, tbAward[1], tbAward[2], nItemTabType, nItemIndex, nil, bReputation, nIconID)
            scriptView:SetImgAwardBgVis(false)
            scriptView:SetLineVis(nIndex ~= nCount)
            self:SetClickCallback(scriptView, tbAward)
            
            local node = scriptView._rootNode
            local value = {["node"] = node,["scriptView"] = scriptView}
            table.insert(self.tbWidgetAwardList, value)
        end
    end

    for nIndex = #self.tbAwardList + 1,#self.tbWidgetAwardList do
        local QuestAward = self.tbWidgetAwardList[nIndex].node
        UIHelper.SetVisible(QuestAward, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutRewardList)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self.WidgetRewardChooseOneShell)

    UIHelper.ScrollViewDoLayout(self.scrollView)
end

function UIWidgetRewardChooseOneShell:SetClickCallback(scriptView, tbAward)
    scriptView:SetClickCallback(function(nTabType, nTabID , nCount)
        Event.Dispatch(EventType.OnSelectAward, nTabType, nTabID , nCount, scriptView, tbAward)
    end)
end

function UIWidgetRewardChooseOneShell:UpdateSelectAward(tbAward)
    if not self.tbWidgetAwardList or not self.tbAwardList then return end
    for nIndex, tbInfo in ipairs(self.tbAwardList) do
        local bSelected = self:IsSelectedAward(tbInfo, tbAward)
        local scriptView = self.tbWidgetAwardList[nIndex].scriptView
        scriptView:SetImgCHooseVis(bSelected)
    end
end

function UIWidgetRewardChooseOneShell:IsSelectedAward(tbAwardInfo, tbAward)
    for nGroup, nSelectIndex in pairs(tbAward) do
        if tbAwardInfo.selectindex == nSelectIndex and tbAwardInfo.selectgroup == nGroup then
            return true
        end
    end
    return false
end

return UIWidgetRewardChooseOneShell