local UIWidgetRenowReputationRule = class("UIWidgetRenowReputationRule")


function UIWidgetRenowReputationRule:OnEnter(dwForceID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not dwForceID then
        return
    end
    self.dwForceID = dwForceID
    self.scriptTopTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetRenowReputationRuleTitle, self.WidgetTopContainer)
    UIHelper.ScrollViewDoLayout(self.WidgetTopContainer)
    UIHelper.ScrollToTop(self.WidgetTopContainer, 0) 
    self:UpdateInfo(dwForceID)
end

function UIWidgetRenowReputationRule:OnExit()
    self.bInit = false
end

function UIWidgetRenowReputationRule:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelRenowReputationRule)
    end)
    UIHelper.BindUIEvent(self.WidgetItemTipCloseBtn, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelRenowReputationRule)
    end)
end

function UIWidgetRenowReputationRule:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        local nTopViewID = UIMgr.GetLayerTopViewID(UILayer.Page)
        if nTopViewID ~= VIEW_ID.PanelRenownList then
            UIMgr.Close(self)
        end
    end)
end

function UIWidgetRenowReputationRule:UpdateInfo(dwForceID)
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    UIHelper.SetVisible(self.WidgetTopContainer, false)
    self:UpdateLevelInfo(dwForceID)
    self:UpdateStoreInfo(dwForceID)

    UIHelper.SetVisible(self.WidgetContentMask, true)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContent, true, true)
    Timer.AddFrame(self, 3, function ()        
        UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContent, true, true)
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        UIHelper.ScrollToTop(self.ScrollViewContent, 0)
        UIHelper.SetVisible(self.WidgetContentMask, false)
    end)
end

function UIWidgetRenowReputationRule:UpdateLevelInfo(dwForceID)
    local tGainDescs = Table_GetReputationGainDescByForceID(dwForceID)
    if not tGainDescs then
        return
    end

    self.scriptLevelTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetRenowReputationRuleTitle, self.ScrollViewContent)
    self.scriptLevelTitle:OnEnter(g_tStrings.STR_REPUTATION_GAIN_TITLE, PREFAB_ID.WidgetRenowReputationRuleBar, function (bSelected)
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        UIHelper.ScrollToTop(self.ScrollViewContent, 0)
    end)
    
    local nDescCount = #tGainDescs
    if nDescCount > 0 then
        for i = 1, nDescCount do
            local tDesc = tGainDescs[i]
            local tFromLevelInfo = Table_GetReputationLevelInfo(tDesc.dwFromLevel)
            local tToLevelInfo = Table_GetReputationLevelInfo(tDesc.dwToLevel)
            local szFromName = UIHelper.GBKToUTF8(tFromLevelInfo.szName)
            local szToName = UIHelper.GBKToUTF8(tToLevelInfo.szName)
            local szLevel = g_tStrings.STR_BRACKET_LEFT .. szFromName .. "-" .. szToName .. g_tStrings.STR_BRACKET_RIGHT
            local szDesc = UIHelper.GBKToUTF8(tDesc.szDesc)
            local tData = {szLevel = szLevel, szDesc = szDesc}
            self.scriptLevelTitle:PushData(tData)
        end
    end
end

function UIWidgetRenowReputationRule:UpdateStoreInfo(dwForceID)
    local tForceUIInfo = Table_GetReputationForceInfo(dwForceID)
	if not tForceUIInfo then
		Log("ERROR!找不到ID == " .. tostring(dwForceID) .. "的声望势力信息！")
		return
	end

    self.scriptStoreTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetRenowReputationRuleTitle, self.ScrollViewContent)
    self.scriptStoreTitle:OnEnter(g_tStrings.STR_REPUTATION_REWARD_TITLE, PREFAB_ID.WidgetRenownRewardList, function (bSelected)
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        UIHelper.ScrollToTop(self.ScrollViewContent, 0)
    end)

    local dwNpcLinkID = tForceUIInfo.dwNpcLinkID
    self.scriptStoreTitle.scriptStoreDescribe = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownStoreDescribe, self.scriptStoreTitle.LayoutReward)
    self.scriptStoreTitle.scriptStoreDescribe:OnEnter(dwNpcLinkID)
    
    local tItems = Table_GetReputationRewardItemInfoByForceID(dwForceID)
    if not tItems then
        return
    end
    local tSortedItems = {}
    for k, _ in pairs(tItems) do
        table.insert(tSortedItems, k)
    end
    table.sort(tSortedItems, function(a, b) return a < b end)

    local nLevelCount = #tSortedItems
    if nLevelCount > 0 then
        for nIndex = 1, nLevelCount do
            local tData = {}
            tData.nRepuLevel = tSortedItems[nIndex]
            tData.aItemInfoList = tItems[tData.nRepuLevel] or {}
            local aFiltedItemList = RepuData.TryFliterItems(tData.aItemInfoList)
            if #aFiltedItemList > 0 then
                tData.aItemInfoList = aFiltedItemList
            end
            self.scriptStoreTitle:PushData(tData)
        end
    end
end

return UIWidgetRenowReputationRule