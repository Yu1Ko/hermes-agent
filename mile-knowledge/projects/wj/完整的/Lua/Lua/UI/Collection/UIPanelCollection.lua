-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelCollection
-- Date: 2023-12-15 14:23:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nSystemOpenTabID = {
    [COLLECTION_PAGE_TYPE.DAY] = 52,--日课
    [COLLECTION_PAGE_TYPE.SECRET] = 2,--秘境
    [COLLECTION_PAGE_TYPE.CAMP] = 16,--阵营
    [COLLECTION_PAGE_TYPE.ATHLETICS] = 44,--竞技
    [COLLECTION_PAGE_TYPE.REST] = 79,--休闲
}

local TYPE_TO_PREFAB = {
    [COLLECTION_PAGE_TYPE.DAY] = {nPrefabID = PREFAB_ID.WidgetDay, szParentName = "WidgetAnchorDay"},
    [COLLECTION_PAGE_TYPE.SECRET] = {nPrefabID = PREFAB_ID.WidgetSecretArea, szParentName = "WidgetAnchorSecretArea"},
    [COLLECTION_PAGE_TYPE.CAMP] = {nPrefabID = PREFAB_ID.WidgetCamp, szParentName = "WidgetAnchorCamp"},
    [COLLECTION_PAGE_TYPE.ATHLETICS] = {nPrefabID = PREFAB_ID.WidgetAthletics, szParentName = "WidgetAnchorAthletics"},
    [COLLECTION_PAGE_TYPE.REST] = {nPrefabID = PREFAB_ID.WidgetRest, szParentName = "WidgetAnchorRest"},
}

local UIPanelCollection = class("UIPanelCollection")

function UIPanelCollection:OnEnter(nType, nPageType, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    CollectionData.RemoteCallDailyAllInfo()--端游策划说每次打开页面需要重新拉一下数据
    self:UpdateInfo(nType)
    if nPageType then
        self:LinkToCard(nType, nPageType, nID)
    end
end

function UIPanelCollection:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Event.Dispatch("OnUpdateArenaRedPoint")
end

function UIPanelCollection:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for nType, toggle in ipairs(self.tbTogList) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(btn, bSelected)
            if bSelected then
                local script = self:_getScriptByType(nType)
                CollectionData.SetLastPageType(script:GetPageType())
                Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelCollection, UIHelper.GetName(btn))
            end
        end)
    end
end

function UIPanelCollection:RegEvent()
    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptIcon then
            self.scriptIcon:SetSelected(false)
        end
    end)

    Event.Reg(self, EventType.OnSelectCollectionAwardChanged, function(script, bSelected, szType, dwTabType, dwID, nCount)
        if bSelected then
            if self.scriptIcon then
                self.scriptIcon:SetSelected(false)
            end
            local tips, scriptTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, script._rootNode)
            if szType == "COIN" then
                local tbLine = Table_GetCalenderActivityAwardIconByID(dwID) or {}
                local szName = CurrencyNameToType[tbLine.szName]
                scriptTip:OnInitCurrency(szName, nCount)
            else
                scriptTip:OnInitWithTabID(dwTabType, dwID)
            end
            self.scriptIcon = script
        else
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
            self.scriptIcon = nil
        end
    end)

    Event.Reg(self, EventType.OnShowCollectionMoreReward, function(tbReward, bShow)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        if self.scriptIcon then
            self.scriptIcon:SetSelected(false)
        end
        self.scriptIcon = nil
    end)
end

function UIPanelCollection:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCollection:UpdateInfo(nType)
    for nType, toggle in ipairs(self.tbTogList) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, toggle)

        local nID = nSystemOpenTabID[nType]
        if nID then
            local bOpen = SystemOpen.IsSystemOpen(nID)
            local szDesc = SystemOpen.GetSystemOpenDesc(nID)
            local szTitle = SystemOpen.GetSystemOpenTitle(nID)

            UIHelper.SetVisible(self.tbWidgetlock[nType], not bOpen)
            if not bOpen then
                UIHelper.SetCanSelect(toggle, false, szDesc, false)
                UIHelper.SetVisible(self.tbImgBG[nType], false)
            elseif nType == COLLECTION_PAGE_TYPE.CAMP and g_pClientPlayer.nCamp == CAMP.NEUTRAL then
                UIHelper.SetCanSelect(toggle, false, function()
                    UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
                end, false)
                UIHelper.SetVisible(self.WidgetNoCamp, true)
                UIHelper.SetVisible(self.tbImgBG[nType], false)
            end
            
            local szLock = szTitle
            UIHelper.SetString(self.tbLabelLock[nType], szLock)
        end
    end


    local nCamp = g_pClientPlayer.nCamp
    UIHelper.SetVisible(self.ImgBgZYRed, nCamp == CAMP.EVIL)
    UIHelper.SetVisible(self.ImgBgZYBlue, nCamp == CAMP.GOOD)

    self:UpdateToggleSelect(nType)
    self:_getScriptByType(nType)
end

function UIPanelCollection:UpdateToggleSelect(nType)
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.tbTogList[nType])
end


function UIPanelCollection:LinkToCard(nType, nPageType, nID)
    self:UpdateToggleSelect(nType)
    local script = self:_getScriptByType(nType)
    script:LinkToCard(nPageType, nID)
end

function UIPanelCollection:UpdatePageInfo(nType)
    CollectionData.SetLastOpenType(nType)
    UIHelper.SetVisible(self.ImgBtnLine, nType ~= COLLECTION_PAGE_TYPE.DAY)
end

function UIPanelCollection:_getScriptByType(nType)
    if not self.tbScriptMap then
        self.tbScriptMap = {}
    end

    local script = self.tbScriptMap[nType]
    if script == nil then
        local nPrefabID = TYPE_TO_PREFAB[nType].nPrefabID
        local parent = self[TYPE_TO_PREFAB[nType].szParentName]
        script = UIHelper.AddPrefab(nPrefabID, parent)
        self.tbScriptMap[nType] = script
    else
        if IsFunction(script.OnShow) then script:OnShow() end
    end

    self:UpdatePageInfo(nType)
    return script
end

return UIPanelCollection