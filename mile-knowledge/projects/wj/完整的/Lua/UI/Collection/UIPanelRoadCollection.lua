-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelRoadCollection
-- Date: 2026-03-09 14:50:21
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nSystemOpenTabID = {
    [COLLECTION_PAGE_TYPE.DAY] = 52,--日课
    [COLLECTION_PAGE_TYPE.SECRET] = 2,--秘境
    [COLLECTION_PAGE_TYPE.CAMP] = 16,--阵营
    [COLLECTION_PAGE_TYPE.ATHLETICS] = 44,--竞技
    [COLLECTION_PAGE_TYPE.REST] = 79,--休闲
}

local TYPE_TO_PREFABNAME = {
    [COLLECTION_PAGE_TYPE.DAY] = {szPrefabName = "WidgetDay"},
    [COLLECTION_PAGE_TYPE.SECRET] = {szPrefabName = "WidgetSecretArea"},
    [COLLECTION_PAGE_TYPE.CAMP] = {szPrefabName = "WidgetCamp"},
    [COLLECTION_PAGE_TYPE.ATHLETICS] = {szPrefabName = "WidgetAthletics"},
    [COLLECTION_PAGE_TYPE.REST] = {szPrefabName = "WidgetRest"},
}

local TYPE_TO_COINTYPE = {
    [COLLECTION_PAGE_TYPE.SECRET] = 4,--秘境
    [COLLECTION_PAGE_TYPE.CAMP] = 3,--阵营
    [COLLECTION_PAGE_TYPE.ATHLETICS] = 3,--竞技
    [COLLECTION_PAGE_TYPE.REST] = 9,--休闲
    [COLLECTION_PAGE_TYPE.DAY] = 11,--周课点
}

local UIPanelRoadCollection = class("UIPanelRoadCollection")

function UIPanelRoadCollection:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    CollectionDailyData.InitData()
    self:UpdateInfo(nType)
    self:PlayEnterAniByType(nType)
    
end

function UIPanelRoadCollection:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelRoadCollection:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:PlayExitAniByCurrentType()
    end)

    for nType, toggle in ipairs(self.tbTogList) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(btn, bSelected)
            if bSelected then
                local nOldType = self.nCurrentType
                local script = self:_getScriptByType(nType)
                if not self.bUpdatingToggle then
                    self:PlaySwitchAni(nOldType, nType)
                end
                CollectionData.SetLastPageType(script:GetPageType())
                Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelRoadCollection, UIHelper.GetName(btn))
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function()
        if self.nCurrentType == COLLECTION_PAGE_TYPE.SECRET then
            ShopData.OpenSystemShopGroup(1, 922)
        elseif self.nCurrentType == COLLECTION_PAGE_TYPE.CAMP then
            local player = g_pClientPlayer
            if not player then return end
            local nCamp = player.nCamp
            if nCamp == CAMP.GOOD then
                ShopData.OpenSystemShopGroup(1, 1002)
            elseif nCamp == CAMP.EVIL then
                ShopData.OpenSystemShopGroup(1, 1370)
            else
                TipsHelper.ShowNormalTip("侠士还未加入阵营")
            end
        elseif self.nCurrentType == COLLECTION_PAGE_TYPE.ATHLETICS then
            ShopData.OpenSystemShopGroup(1, 918)
        elseif self.nCurrentType == COLLECTION_PAGE_TYPE.REST then
            ShopData.OpenSystemShopGroup(1, 1478)
        elseif self.nCurrentType == COLLECTION_PAGE_TYPE.DAY then
            ShopData.OpenSystemShopGroup(1, 1564)
        end
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelChatSocial)
    end)
end

function UIPanelRoadCollection:RegEvent()
    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "UPDATE_JUSTICE", function()    --秘境
        if self.nCurrentType == COLLECTION_PAGE_TYPE.SECRET then
            self:UpdatePageInfo(self.nCurrentType)
        end
    end)

    Event.Reg(self, "UPDATE_PRESTIGE", function()   --阵营与竞技
        if self.nCurrentType == COLLECTION_PAGE_TYPE.CAMP or self.nCurrentType == COLLECTION_PAGE_TYPE.ATHLETICS then
            self:UpdatePageInfo(self.nCurrentType)
        end
    end)

    Event.Reg(self, "UPDATE_CONTRIBUTION", function()   --休闲
        if self.nCurrentType == COLLECTION_PAGE_TYPE.REST then
            self:UpdatePageInfo(self.nCurrentType)
        end
    end)

    Event.Reg(self, EventType.On_GameGuide_UpdateWeeklyInfo, function(nPoint, nGetRewardLv)
        if self.nCurrentType == COLLECTION_PAGE_TYPE.DAY then
            self:UpdatePageInfo(self.nCurrentType)
        end
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
end

function UIPanelRoadCollection:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelRoadCollection:UpdateInfo(nType)
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

    self:UpdateToggleSelect(nType)
    self:_getScriptByType(nType)
end

function UIPanelRoadCollection:UpdateToggleSelect(nType)
    self.bUpdatingToggle = true
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.tbTogList[nType])
    self.bUpdatingToggle = false
end

function UIPanelRoadCollection:PlayEnterAniByType(nType)
    local szAni = (nType == COLLECTION_PAGE_TYPE.DAY) and "AniRoadCollectionShow" or "AniRoadCollectionShow2"
    UIHelper.PlayAni(self, self.AniAll, szAni)
end

function UIPanelRoadCollection:PlaySwitchAni(nOldType, nNewType)
    if not nOldType or nOldType == nNewType then
        return
    end

    if nOldType == COLLECTION_PAGE_TYPE.DAY and nNewType ~= COLLECTION_PAGE_TYPE.DAY then
        UIHelper.PlayAni(self, self.AniAll, "AniToPlayingShow")
    elseif nOldType ~= COLLECTION_PAGE_TYPE.DAY and nNewType == COLLECTION_PAGE_TYPE.DAY then
        UIHelper.PlayAni(self, self.AniAll, "AniToPlayingHide")
    end
end

function UIPanelRoadCollection:PlayExitAniByCurrentType()
    local szAni = (self.nCurrentType == COLLECTION_PAGE_TYPE.DAY) and "AniRoadCollectionHide" or "AniRoadCollectionHide2"
    UIHelper.PlayAni(self, self.AniAll, szAni, function ()
        UIMgr.Close(self)
    end)
end

function UIPanelRoadCollection:_getScriptByType(nType)
    if not self.tbScriptMap then
        self.tbScriptMap = {}
    end

    if not nType then
        nType = COLLECTION_PAGE_TYPE.DAY
    end

    local script = self.tbScriptMap[nType]
    if script == nil then
        local szPrefabName = TYPE_TO_PREFABNAME[nType].szPrefabName
        script = UIHelper.GetBindScript(self[szPrefabName])
        self.tbScriptMap[nType] = script
    else
        if IsFunction(script.OnShow) then script:OnShow() end
    end
    script:Open()   

    self:UpdatePageInfo(nType)
    return script
end

function UIPanelRoadCollection:UpdatePageInfo(nType)
    self.nCurrentType = nType
    CollectionData.SetLastOpenType(nType)
    UIHelper.SetVisible(self.LayoutRightTop, true)

    local nJustice, nJusticeRemain = CollectionData.GetJustice()
    local nPrestige, nPrestigeRemain = CollectionData.GetPrestige()
    local nRestRemain = g_pClientPlayer and g_pClientPlayer.GetContributionRemainSpace() or 0
    local szTips = nType == COLLECTION_PAGE_TYPE.SECRET and string.format(g_tStrings.STR_VALUE_JUSTICE_MAX_EXTSPACE, nJusticeRemain)
                    or (nType == COLLECTION_PAGE_TYPE.CAMP or nType == COLLECTION_PAGE_TYPE.ATHLETICS) and string.format(g_tStrings.STR_VALUE_PRESTIGE_MAX_EXTSPACE, nPrestigeRemain)
                    or nType == COLLECTION_PAGE_TYPE.REST and string.format(g_tStrings.STR_VALUE_CONTRIBUTION_MAX_EXTSPACE, nRestRemain)

    UIHelper.SetString(self.LabelGetTips, szTips)
    local nCurrencyCode = TYPE_TO_COINTYPE[nType]
    UIHelper.RemoveAllChildren(self.LayoutCurrency)
    UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency, nCurrencyCode)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIPanelRoadCollection:LinkToCard(nType, nPageType, nID)
    self:UpdateToggleSelect(nType)
    local script = self:_getScriptByType(nType)
    script:LinkToCard(nPageType, nID)
end

return UIPanelRoadCollection