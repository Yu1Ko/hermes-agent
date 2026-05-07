local UIWidgetRenownRewardList = class("UIWidgetRenownRewardList")


function UIWidgetRenownRewardList:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not tData then
        return
    end
    self.tData = tData
    self:UpdateInfo(tData)
end

function UIWidgetRenownRewardList:OnExit()
    self.bInit = false
end

function UIWidgetRenownRewardList:BindUIEvent()

end

function UIWidgetRenownRewardList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenownRewardList:UpdateInfo(tData)
    local tLevelInfo = Table_GetReputationLevelInfo(tData.nRepuLevel)
    local szLevel = g_tStrings.STR_BRACKET_LEFT .. UIHelper.GBKToUTF8(tLevelInfo.szName) .. g_tStrings.STR_BRACKET_RIGHT .. g_tStrings.STR_REPUTATION_REWARD_ITEMS_TITLE 
    UIHelper.SetString(self.LabelRenowanRewardTitle, szLevel)

    UIHelper.RemoveAllChildren(self.LayoutRenowanRewaedIcon)
    for _, tItemInfo in ipairs(tData.aItemInfoList) do
        local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutRenowanRewaedIcon)
        if itemIcon then
            itemIcon:OnInitWithTabID(tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
            itemIcon:SetClearSeletedOnCloseAllHoverTips(true)
            itemIcon:SetToggleGroupIndex(ToggleGroupIndex.ReputationUnlockedItem)
            itemIcon:SetClickCallback(function (dwItemTabType, dwItemTabIndex)
                TipsHelper.ShowItemTips(itemIcon._rootNode, dwItemTabType, dwItemTabIndex)
            end)
            UIHelper.SetSwallowTouches(itemIcon.ToggleSelect, false)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutRenowanRewaedIcon)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIWidgetRenownRewardList