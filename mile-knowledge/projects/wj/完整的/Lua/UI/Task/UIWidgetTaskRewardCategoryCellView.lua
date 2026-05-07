-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTaskRewardCategoryCellView
-- Date: 2024-11-13 09:56:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTaskRewardCategoryCellView = class("UIWidgetTaskRewardCategoryCellView")

function UIWidgetTaskRewardCategoryCellView:OnEnter(tbItemList, funcChooseItem, funcCancelChooseItem)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.cellAwardPrefab = PrefabPool.New(PREFAB_ID.WidgetAwardItem1)
    self.tbItemList = tbItemList
    self.funcChooseItem = funcChooseItem
    self.funcCancelChooseItem = funcCancelChooseItem
    self:UpdateInfo()
end

function UIWidgetTaskRewardCategoryCellView:OnExit()
    if self.cellAwardPrefab then
        self.cellAwardPrefab:Dispose()
        self.cellAwardPrefab = nil
    end
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTaskRewardCategoryCellView:BindUIEvent()
    
end

function UIWidgetTaskRewardCategoryCellView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTaskRewardCategoryCellView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTaskRewardCategoryCellView:UpdateInfo()
    for nIndex, tbAwardInfo in ipairs(self.tbItemList) do
        local szName = tbAwardInfo.szItemName
        local nCount = tbAwardInfo.nStackNum
        local nItemTabType = tbAwardInfo.dwTabType
        local nItemIndex = tbAwardInfo.dwIndex
        local bMail = tbAwardInfo.bMail
        local bReputation = tbAwardInfo.bReputation
        local bBook = tbAwardInfo.bBook
        local nIconID = tbAwardInfo.nIconID
        local node, scriptView = self.cellAwardPrefab:Allocate(self.LayoutRewardList, szName, nCount, nItemTabType, nItemIndex, bMail, bReputation, nIconID, false)
        self:SetClickCallback(scriptView, tbAwardInfo)
        scriptView:AddToggleGroup(self.Togglegroup)
    end
    UIHelper.LayoutDoLayout(self.LayoutRewardList)
end

function UIWidgetTaskRewardCategoryCellView:SetClickCallback(scriptView, tbAwardInfo)
    scriptView:SetClickCallback(function(nTabType, nTabID , nCount)
        if self.funcChooseItem then
            self.funcChooseItem(tbAwardInfo, scriptView)
        end
    end)

    scriptView:SetClickNotSelectCallback(function(nTabType, nTabID , nCount)
        if self.funcCancelChooseItem then
            self.funcCancelChooseItem(tbAwardInfo)
        end
    end)
end

return UIWidgetTaskRewardCategoryCellView