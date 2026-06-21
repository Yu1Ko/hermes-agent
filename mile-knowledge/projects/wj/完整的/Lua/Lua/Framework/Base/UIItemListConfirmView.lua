-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemListConfirmView
-- Date: 2023-02-15 14:21:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemListConfirmView = class("UIItemListConfirmView")

function UIItemListConfirmView:OnEnter(szContent, tbItemList, funcConfirm, funcCancel, funcChooseItem)
    self.szContent = szContent
    self.tbItemList = tbItemList
    self.funcConfirm = funcConfirm
    self.funcCancel = funcCancel
    self.funcChooseItem = funcChooseItem

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemListConfirmView:OnExit()
    self.bInit = false
end

function UIItemListConfirmView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalloff,EventType.OnClick,function()
        if self.funcCancel then
            self.funcCancel()
        end

        UIMgr.Close(self._nViewID)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        if self.funcConfirm then
            self.funcConfirm()
        end

        UIMgr.Close(self._nViewID)
    end)
    UIHelper.SetTouchDownHideTips(self.ScrollViewItemShell, false)
    UIHelper.SetTouchDownHideTips(self.LayoutItemShell, false)
end

function UIItemListConfirmView:RegEvent()

end

function UIItemListConfirmView:UpdateInfo()
    UIHelper.SetLabel(self.LabelHintNormal, self.szContent)
    self:UpdateItemInfo()
end

function UIItemListConfirmView:UpdateItemInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewItemShell)
    UIHelper.RemoveAllChildren(self.LayoutItemShell)

    self.tbItemIcon      = {}

    local bUseScrollView = #self.tbItemList > 8

    UIHelper.SetVisible(self.ScrollViewItemShell, bUseScrollView)
    UIHelper.SetVisible(self.LayoutItemShell, not bUseScrollView)

    local container = self.LayoutItemShell
    if bUseScrollView then
        container = self.ScrollViewItemShell
    end

    for index, item in ipairs(self.tbItemList) do
        ---@type UIItemIcon
        local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, container)
        if bUseScrollView then
            UIHelper.SetAnchorPoint(itemIcon._rootNode, 0, 0)
        end

        if item.dwTabType ~= "COIN" then
            itemIcon:OnInitWithTabID(item.dwTabType, item.dwIndex)
            itemIcon:SetLabelCount(item.nStackNum)
        else
            itemIcon:OnInitCurrency(item.dwIndex, item.nStackNum)
        end

        itemIcon:SetToggleGroupIndex(ToggleGroupIndex.AchievementAward)
        itemIcon:SetClickCallback(function()
            local scriptItemTip
            if item.dwTabType ~= "COIN" then
                _, scriptItemTip = TipsHelper.ShowItemTips(itemIcon._rootNode, item.dwTabType, item.dwIndex, false)
            else
                _, scriptItemTip = TipsHelper.ShowCurrencyTips(itemIcon._rootNode, item.dwIndex, item.nStackNum)
            end
            scriptItemTip:SetBtnState({})

            if self.funcChooseItem then
                self.funcChooseItem(item)
            end
        end)
        UIHelper.SetTouchDownHideTips(itemIcon.ToggleSelect, false)
        table.insert(self.tbItemIcon, itemIcon)
    end

    if bUseScrollView then
        UIHelper.ScrollViewDoLayout(container)
        UIHelper.ScrollToLeft(container, 0)
    else
        UIHelper.LayoutDoLayout(self.LayoutItemShell)
    end

    UIHelper.LayoutDoLayout(self.LayoutReward)
end

function UIItemListConfirmView:ShowButton(szButtonName)
    if szButtonName=="Cancel" then
        UIHelper.SetVisible(self.BtnCalloff, true)
    elseif szButtonName=="Confirm" then
        UIHelper.SetVisible(self.BtnOk, true)
    end
end

function UIItemListConfirmView:HideButton(szButtonName)
    if szButtonName=="Cancel" then
        UIHelper.SetVisible(self.BtnCalloff, false)
    elseif szButtonName=="Confirm" then
        UIHelper.SetVisible(self.BtnOk, false)
    end
end

function UIItemListConfirmView:SetButtonContent(szButtonName,szContent)
    if szButtonName=="Cancel" then
        UIHelper.SetLabel(self.LabelCalloff, szContent)
    elseif szButtonName=="Confirm" then
        UIHelper.SetLabel(self.LabelOk, szContent)
    end
end


return UIItemListConfirmView