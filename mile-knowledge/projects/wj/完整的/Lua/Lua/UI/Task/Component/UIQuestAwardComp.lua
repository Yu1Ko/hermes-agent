-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestAwardComp
-- Date: 2022-11-24 11:20:17
-- Desc: ?
-- ---------------------------------------------------------------------------------
local CHOOSEAWARD_PREFAB = {
    [PREFAB_ID.WidgetAwardItem1] = PREFAB_ID.WidgetRewardChooseOneShell,
    [PREFAB_ID.WidgetAward] = PREFAB_ID.WidgetRewardChooseOneShellVertical,
}

local UIQuestAwardComp = class("UIQuestAwardComp")

function UIQuestAwardComp:OnEnter(tbAwardList, WidgetAwardPreFab, bShowCanSelect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if WidgetAwardPreFab then
        self:Init(tbAwardList, WidgetAwardPreFab, bShowCanSelect)
        self:UpdateInfo()
    end
end

function UIQuestAwardComp:OnExit()
    if self.cellAwardPrefab then
        self.cellAwardPrefab:Dispose()
        self.cellAwardPrefab = nil
    end
    if self.cellChooseAward then
        self.cellChooseAward:Dispose()
        self.cellChooseAward = nil
    end
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestAwardComp:BindUIEvent()

end

function UIQuestAwardComp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:HideItemTip()
    end)
    Event.Reg(self, EventType.OnSelectAward, function(nTabType, nTabID , nCount, scriptView, tbAward)
        self:OpenTip(nTabType, nTabID, nCount, tbAward.bBook, scriptView)
    end)
end

function UIQuestAwardComp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIQuestAwardComp:Init(tbAwardList, WidgetAwardPreFab, bShowCanSelect)
    self.tbAwardList = tbAwardList
    self.WidgetAwardPreFab = WidgetAwardPreFab
    self.cellAwardPrefab = PrefabPool.New(self.WidgetAwardPreFab)
    self.cellChooseAward = PrefabPool.New(CHOOSEAWARD_PREFAB[self.WidgetAwardPreFab])
    self.bShowCanSelect = true
    if  bShowCanSelect ~= nil then self.bShowCanSelect = bShowCanSelect end
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestAwardComp:UpdateInfo()

    UIHelper.SetVisible(self._rootNode, self.tbAwardList and #self.tbAwardList ~= 0)
    UIHelper.RemoveAllChildren(self.ScrollViewAward)
    if not self.tbAwardList then return end

    local tbCanSelectList = {}
    local nAwardIndex = 1
    for nIndex, tbQuestAward in ipairs(self.tbAwardList) do
        if not self.bShowCanSelect or not tbQuestAward.bCanSelect then
            local nItemTabType = tbQuestAward[3] or nil
            local nItemIndex = tbQuestAward[4] or nil
            local bReputation = tbQuestAward[5] or nil
            local nIconID = tbQuestAward[6] or nil
            local bBook = tbQuestAward.bBook or false
            local node, scriptView = self.cellAwardPrefab:Allocate(self.ScrollViewAward, tbQuestAward[1], tbQuestAward[2], nItemTabType, nItemIndex, nil, bReputation, nIconID)
            self:SetClickCallback(scriptView, bBook)
        else
            local nGroup = tbQuestAward.selectgroup
            if not tbCanSelectList[nGroup] then
                tbCanSelectList[nGroup] = {}
            end
            table.insert(tbCanSelectList[nGroup], tbQuestAward)
        end
    end


    if table.get_len(tbCanSelectList) > 0 then
        for nIndex, tbAwardList in pairs(tbCanSelectList) do
            self.cellChooseAward:Allocate(self.ScrollViewAward, tbAwardList, self.WidgetAwardPreFab, self.ScrollViewAward)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewAward)
    if self.WidgetAwardPreFab == PREFAB_ID.WidgetAward then
        UIHelper.ScrollToTop(self.ScrollViewAward, 0, true)
    else
        UIHelper.ScrollToLeft(self.ScrollViewAward, 0, true)
    end
    UIHelper.SetTouchDownHideTips(self.ScrollViewAward, false)
    UIHelper.SetSwallowTouches(self.ScrollViewAward, true)
    UIHelper.SetVisible(self.WidgetNoReward, #self.tbAwardList == 0)
end


function UIQuestAwardComp:SetClickCallback(scriptView, bBook)
    scriptView:SetClickCallback(function(nTabType, nTabID , nCount)
        self:OpenTip(nTabType, nTabID , nCount, bBook, scriptView)
    end)
end

function UIQuestAwardComp:OpenTip(nTabType, nTabID , nCount, bBook, scriptView)
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

function UIQuestAwardComp:HideItemTip()
    if self.scriptItemTip then
        self.scriptItemTip = nil
        if self.CurSelectedItemView then
            self.CurSelectedItemView:SetSelected(false)
            self.CurSelectedItemView = nil
        end
    end
end


return UIQuestAwardComp