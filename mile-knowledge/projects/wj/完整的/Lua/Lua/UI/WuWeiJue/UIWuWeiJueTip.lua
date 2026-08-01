local UIWuWeiJueTip = class("UIWuWeiJueTip")

function UIWuWeiJueTip:OnEnter(tbRecommend)
    self.tbRecommend = tbRecommend
    self:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.EditBox, false)
    UIHelper.RemoveAllChildren(self.ScrollViewType)
end

function UIWuWeiJueTip:OnExit()
end

function UIWuWeiJueTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        if self.fnConfirm then
            self.fnConfirm(self.nIndex)
        end
        Event.Dispatch(EventType.HideAllHoverTips)
    end)

    UIHelper.RegisterEditBox(self.EditBox, function()
        self.szKey = UIHelper.GetString(self.EditBox)
        self:UpdateInfo()
    end)

    -- UIHelper.BindUIEvent(self.BtnNone, EventType.OnClick, function(btn)
    --     TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    -- end)

    -- UIHelper.BindUIEvent(self.ScrollViewType, EventType.OnClick, function(btn)
    --     TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    -- end)
end

local function GetItemAmount(dwTab, dwIndex)
    local nCount = ItemData.GetItemAmountInPackage(dwTab, dwIndex)

    return nCount
end

function UIWuWeiJueTip:AddItemWidget(nIndex, dwTabType, dwIndex, bRecommend)
    local nStackNum = ItemData.GetItemAmountInPackage(dwTabType, dwIndex)
    -- local nStackNum = ItemData.GetItemAllStackNum(item, true)

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewType)
    script:SetTouchDownHideTips(false)
    
    script:SetClickCallback(function(dwTabType, dwIndex)
        if dwTabType and dwIndex then
            self.nIndex = nIndex
            self:UpdateButtonState()
            TipsHelper.ShowItemTips(self._rootNode, dwTabType, dwIndex, false)
        end
        Event.Dispatch("WuWeiJueItem_Click", script)
    end)
    
    script:OnInitWithTabID(dwTabType, dwIndex)
    script:SetLabelCount(nStackNum)
    script:SetIconGray(nStackNum and nStackNum <= 0)
    script:SetIconOpacity(nStackNum == 0 and 120 or 255)
    script:ShowRecommend(bRecommend ~= nil)

    Event.Reg(script, "WuWeiJueItem_Click", function(obj)
        script:RawSetSelected(obj == script)
    end)
end

function UIWuWeiJueTip:UpdateInfo(tbList)
    UIHelper.RemoveAllChildren(self.ScrollViewType)

    self.tbList = tbList or self.tbList
    for i, tab in ipairs(self.tbList) do
        local szName = GBKToUTF8(ItemData.GetItemNameByItemInfoIndex(tab.dwTabType, tab.dwIndex))
        if not self.szKey or self.szKey == "" or string.find(szName, self.szKey) then
            self:AddItemWidget(i, tab.dwTabType, tab.dwIndex, self.tbRecommend[tab.dwIndex])
        end
    end
    
    self:UpdateButtonState()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewType)

end

function UIWuWeiJueTip:UpdateButtonState()
    UIHelper.SetButtonState(self.BtnConfirm, self.nIndex and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UIWuWeiJueTip:SetBtnConfirmFunc(fnConfirm)
    self.fnConfirm = fnConfirm
end

return UIWuWeiJueTip