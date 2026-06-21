-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILifePage
-- Date: 2022-11-21 17:38:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILifePage = class("UILifePage")

local UILifePageTab = {
    [CRAFT_PANEL.Collect] = {
        nProfessionID = 1,
    },
    [CRAFT_PANEL.Foundry] = {
        nProfessionID = 6,
    },
    [CRAFT_PANEL.Medical] = {
        nProfessionID = 7,
    },
    [CRAFT_PANEL.Cooking] = {
        nProfessionID = 4,
    },
    [CRAFT_PANEL.Sewing] = {
        nProfessionID = 5,
    },
    [CRAFT_PANEL.Carpentry] = {
        nProfessionID = 15,
    },
    [CRAFT_PANEL.Demosticate] = {
        nProfessionID = 0,
    },
}

function UILifePage:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        -- 初始化最近手动选择项
        CraftData.tCraftID2LastRecipeID = {}
    end
    self.tParam = tParam or {}
    self:InitLifePage()
    self:UpdateInfo()
    self:RefreshToggles()
end

function UILifePage:OnExit()
    self.bInit = false
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetNPCGuideTips)
end

function UILifePage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelLifePage)
    end)

    UIHelper.BindUIEvent(self.BtnSpecialization, EventType.OnClick, function ()
        local tbTravelList = {}
        local nCraftPanelID = self.nCurCraftPanel or 1
        local tbConfig = UILifePageTab[nCraftPanelID]
        local nProfessionID = tbConfig.nProfessionID
        if nCraftPanelID == 1 then nProfessionID = self.scriptCollect.nProfessionID end
        
        local tNavigation = CraftData.CraftDoodadNavigation[nProfessionID]
        for _, nLinkID in ipairs(tNavigation.nLinkIDList) do
            local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
            for _, tInfo in pairs(tAllLinkInfo) do
                table.insert(tbTravelList, tInfo)
            end
        end
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetNPCGuideTips, self.BtnTrade, TipsLayoutDir.BOTTOM_CENTER, tbTravelList)
    end)

    for nCraftPanelID, toggle in ipairs(self.tToggleList) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then self:OnSelectPanelChanged(nCraftPanelID) end
        end)

        local imgSpecialization = self.tImgSpecializationList[nCraftPanelID]
        local bHasExpertised = false
        if nCraftPanelID == 1 then
            bHasExpertised = bHasExpertised or g_pClientPlayer.IsProfessionExpertised(1)
            bHasExpertised = bHasExpertised or g_pClientPlayer.IsProfessionExpertised(2)
            bHasExpertised = bHasExpertised or g_pClientPlayer.IsProfessionExpertised(3)
        elseif nCraftPanelID ~= 7 then
            local tbConfig = UILifePageTab[nCraftPanelID]
            bHasExpertised = g_pClientPlayer.IsProfessionExpertised(tbConfig.nProfessionID)
        end
        UIHelper.SetVisible(imgSpecialization, bHasExpertised)
    end
end

function UILifePage:RegEvent()
    Event.Reg(self, "UPDATE_VIGOR", function()
        self:UpdateVigor()
    end)

    Event.Reg(self, "SYS_MSG", function()
        if arg0 == "UI_OME_ADD_PROFESSION_PROFICIENCY" then
            self:UpdateVigor()
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
		if nViewID ~= VIEW_ID.PanelChatSocial then return end

		UIHelper.SetVisible(self.WidgetAnchorBotton, false)
		UIHelper.PlayAni(self, self.AniAll, "AniBottomHide")
    end)

	Event.Reg(self, EventType.OnViewClose, function (nViewID)
		if nViewID ~= VIEW_ID.PanelChatSocial then return end
		
		UIHelper.PlayAni(self, self.AniAll, "AniBottomShow")
		UIHelper.SetVisible(self.WidgetAnchorBotton, true)
    end)

    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetNPCGuideTips)
        if self.nCurCraftPanel ~= 1 then return end
        if HomelandData.CheckIsHomelandMapTeleportGo(tbInfo.nLinkID, tbInfo.dwMapID) then
            return
        end

        local bCD, _ = MapMgr.GetTransferSkillInfo()
        if bCD then
            UIHelper.ShowSwitchMapConfirm(g_tStrings.USE_RESET_ITEM, function()
                MapMgr.UseResetItem()
                Timer.Add(MapMgr, 0.2, function()
                    RemoteCallToServer("On_Teleport_Go", tbInfo.nLinkID, tbInfo.dwMapID)
                end)
            end)
        else
            RemoteCallToServer("On_Teleport_Go", tbInfo.nLinkID, tbInfo.dwMapID)
        end
    end)
end

function UILifePage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UILifePage:InitLifePage()
    -- 初始化三个分页实体
    local tParam = self.tParam
    self.nCurCraftPanel = tParam.nDefaultCraftPanel or 1
    
    self.scriptDomesticate = self.scriptDomesticate or UIHelper.AddPrefab(PREFAB_ID.WidgetDomesticate, self.WidgetAnchorMiddle)
    self.scriptManufacture = self.scriptManufacture or UIHelper.AddPrefab(PREFAB_ID.WidgetManufactureMain, self.WidgetAnchorMiddle)
    self.scriptCollect = self.scriptCollect or UIHelper.AddPrefab(PREFAB_ID.WidgetCollectMain, self.WidgetAnchorMiddle)

    self.scriptCollect:SetSwitchCallBack(function ()
        self:UpdateVigor()
    end)
    
    if self.nCurCraftPanel == CRAFT_PANEL.Demosticate then
        self.scriptDomesticate:OnEnter(tParam.dwDemesticateBox, tParam.dwDemesticateIndex)
    end

    self.scriptDomesticate:SetOnOpenBag(function (bOpenBag)
        if bOpenBag then
            UIHelper.SetVisible(self.WidgetAnchorBotton, false)
            UIHelper.PlayAni(self, self.AniAll, "AniBottomHide")
        else
            UIHelper.PlayAni(self, self.AniAll, "AniBottomShow")
            UIHelper.SetVisible(self.WidgetAnchorBotton, true)
        end
    end)
    if self.nCurCraftPanel > 1 and self.nCurCraftPanel <= 6 then
        self.scriptManufacture:OnEnter(tParam)
    end
    if self.nCurCraftPanel == 1 then self.scriptCollect:OnEnter(tParam.nDefaultProfessionID) end

    self.VigorScript = self.VigorScript or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
    self.VigorScript:SetCurrencyType(CurrencyType.Vigor)

    self:RefreshPanels()
end

function UILifePage:UpdateInfo()
    self:UpdateVigor()
end

function UILifePage:RefreshPanels()
    UIHelper.SetVisible(UIHelper.GetParent(self.BtnSpecialization), self.nCurCraftPanel ~= 7)
    UIHelper.SetVisible(self.scriptDomesticate._rootNode, self.nCurCraftPanel == 7)
    UIHelper.SetVisible(self.scriptManufacture._rootNode, self.nCurCraftPanel > 1 and self.nCurCraftPanel <= 6)
    UIHelper.SetVisible(self.scriptCollect._rootNode, self.nCurCraftPanel == 1)
    local nodeTop = UIHelper.GetParent(self.LayoutAnchorRightTop)
    UIHelper.CascadeDoLayoutDoWidget(nodeTop, true, true)
    self:UpdateVigor()
end

function UILifePage:RefreshToggles()
    for nIndex, toggle in ipairs(self.tToggleList) do
        UIHelper.SetSelected(toggle, self.nCurCraftPanel == nIndex, false)
    end
end

function UILifePage:UpdateVigor()
    local tbConfig = UILifePageTab[self.nCurCraftPanel]
    if self.nCurCraftPanel ~= 7 then
        local nProID = tbConfig.nProfessionID
        if self.nCurCraftPanel == CRAFT_PANEL.Collect then
            nProID = self.scriptCollect.nProfessionID
        end
        local player = GetClientPlayer()
        local nLevel	= player.GetProfessionLevel(nProID)
        local nAdjustLevel = player.GetProfessionAdjustLevel(nProID)
        local nMaxLevel = player.GetProfessionMaxLevel(nProID)
        local nExp		= player.GetProfessionProficiency(nProID)
        local Profession  = GetProfession(nProID)
        local nMaxExp	= Profession.GetLevelProficiency(nLevel)
        if nAdjustLevel and nAdjustLevel ~= 0 then
            nLevel = math.min((nLevel + nAdjustLevel), nMaxLevel)
        end
        if nLevel == 0 then
            UIHelper.SetVisible(self.WidgetMiningProgress, false)
            UIHelper.SetVisible(self.WidgetCurrency, false)
            return
        else
            UIHelper.SetVisible(self.WidgetMiningProgress, true)
            UIHelper.SetVisible(self.WidgetCurrency, true)
        end
        local tCraftNav = CraftData.CraftDoodadNavigation[nProID]
        UIHelper.SetString(self.LabslLevelNum, string.format("%s%d/%d级", tCraftNav.szName, nLevel, nMaxLevel))
        if nExp and nMaxExp then
            UIHelper.SetString(self.LabelNum, nExp .. '/' .. nMaxExp)
            UIHelper.SetProgressBarPercent(self.ProgressBarMining, 100 * nExp / nMaxExp)
        else
            local node = UIHelper.GetParent(self.ProgressBarMining)
            UIHelper.SetVisible(node, false)
        end
    
        local nodeParent = UIHelper.GetParent(self.LayoutAnchorRightTop)
        UIHelper.CascadeDoLayoutDoWidget(nodeParent, true, true)
    
        local player = GetClientPlayer()
        local nCurrentVigor = player.nVigor + player.nCurrentStamina
        local nMaxVigor = player.GetMaxVigor() + player.nMaxStamina
        self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
        UIHelper.CascadeDoLayoutDoWidget(nodeParent, true, true)
    end
    UIHelper.SetVisible(self.WidgetMiningProgress, self.nCurCraftPanel ~= 7)
    UIHelper.SetVisible(self.WidgetCurrency, self.nCurCraftPanel ~= 7)
end

function UILifePage:OnSelectPanelChanged(nCraftPanelID)
    self.nCurCraftPanel = nCraftPanelID

    local tbConfig = UILifePageTab[self.nCurCraftPanel]
    if self.nCurCraftPanel > CRAFT_PANEL.Collect and self.nCurCraftPanel < CRAFT_PANEL.Demosticate then
        self.scriptManufacture:OnEnter({nDefaultProfessionID = tbConfig.nProfessionID})
    end
    if self.nCurCraftPanel == CRAFT_PANEL.Collect then
        if self.nCurCraftPanel == CRAFT_PANEL.Collect and not self.scriptCollect.nProfessionID then self.scriptCollect:OnEnter(tbConfig.nProfessionID) end
    end
    if self.nCurCraftPanel == CRAFT_PANEL.Demosticate then
        self.scriptDomesticate:OnEnter()
    end

    self:RefreshPanels()
end

return UILifePage