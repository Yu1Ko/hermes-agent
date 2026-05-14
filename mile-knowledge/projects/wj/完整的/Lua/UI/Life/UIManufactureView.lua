-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIManufactureView
-- Date: 2022-11-28 19:35:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIManufactureView = class("UIManufactureView")

local TogLeftToID = {
    {["nMaseterID"] = 22, ["nProfessionID"] = 6, ["szName"] = "铸造", ["szDesc"] = "30级后\n在主城寻找铸造训练师学习【铸造专精】后可铸造", ["szTypePath"] = "UIAtlas2_Life_Manufacture_ZhuZao" },
    {["nMaseterID"] = 16, ["nProfessionID"] = 7, ["szName"] = "医术", ["szDesc"] = "30级后\n在主城寻找医术训练师学习【医术专精】后可医术", ["szTypePath"] = "UIAtlas2_Life_Manufacture_YiShu" },
    {["nMaseterID"] = 1, ["nProfessionID"] = 4, ["szName"] = "烹饪", ["szDesc"] = "30级后\n在主城寻找烹饪训练师学习【烹饪专精】后可烹饪", ["szTypePath"] = "UIAtlas2_Life_Manufacture_PengRen" },
    {["nMaseterID"] = 10, ["nProfessionID"] = 5, ["szName"] = "缝纫", ["szDesc"] = "30级后\n在主城寻找缝纫训练师学习【缝纫专精】后可缝纫", ["szTypePath"] = "UIAtlas2_Life_Manufacture_FengRen" },
    {["nMaseterID"] = 31, ["nProfessionID"] = 15, ["szName"] = "梓匠", ["szDesc"] = "30级后\n在主城寻找梓匠训练师学习【梓匠专精】后可梓匠", ["szTypePath"] = "UIAtlas2_Life_Manufacture_ZiJiang" },
}

FliterLearnType = {
    All = 1,
    Learned = 2,
    Unlearned = 3,
}
FliterExpertiseType = {
    All = 1,
    Normal = 2,
    Expertise = 3
}

FliterMakeType = {
    All = 1,
    MaterialEnough = 2,
    CanMake = 3,
    Collected = 4,
    Uncollected = 5,
}

local colorRed = cc.c3b(255, 133, 125)
local colorWhite = cc.c3b(0xDF, 0XF6, 0XFF)

local g_LearnInfo = {
	--配方道具使用表 2022,10删除
	--[2210] = {["dwCraftID"] = 4, ["dwRecipeID"] = 1},
	[6201] = {["dwCraftID"] = 6, ["dwRecipeID"] = 259},
	[6202] = {["dwCraftID"] = 6, ["dwRecipeID"] = 260},
	[6203] = {["dwCraftID"] = 6, ["dwRecipeID"] = 261},
	[6204] = {["dwCraftID"] = 6, ["dwRecipeID"] = 262},
	[6205] = {["dwCraftID"] = 6, ["dwRecipeID"] = 263},
	[6206] = {["dwCraftID"] = 6, ["dwRecipeID"] = 264},
	[6207] = {["dwCraftID"] = 6, ["dwRecipeID"] = 265},
	[6208] = {["dwCraftID"] = 6, ["dwRecipeID"] = 266},
	[24222] = {["dwCraftID"] = 4, ["dwRecipeID"] = 302, ["dwAdventureID"] = 10},--炼狱水煮鱼
	[52783] = {["dwCraftID"] = 4, ["dwRecipeID"] = 417, ["dwAdventureID"] = 10},--百炼水煮鱼
}

local function MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false;
	end

	return true
end

local function TableSortCmp(a, b)
	if a.nBelongID == b.nBelongID then
		if a.bNeedExpertise == b.bNeedExpertise then
			return a.nLevel > b.nLevel
		else
			return a.bNeedExpertise or (not b.bNeedExpertise)
		end
	else
		return a.nBelongID < b.nBelongID
	end
end

local function GetRequireItems(recipe)
	local player = GetClientPlayer()
	local tItems = {}
	for nIndex = 1, 6, 1 do
		local nType  = recipe["dwRequireItemType"..nIndex]
		local nID	 = recipe["dwRequireItemIndex"..nIndex]
		local nNeed  = recipe["dwRequireItemCount"..nIndex]

		local nSatisfy = 1
		if nNeed > 0 then
			local nCount = player.GetItemAmount(nType, nID)
			if nNeed > nCount then
				nSatisfy = 0
			end
			table.insert(tItems, {["nType"]=nType, ["nID"]=nID, ["nNeed"]=nNeed, ["nCount"]=nCount, ["nSatisfy"]=nSatisfy})
		end
	end
	table.sort(tItems, function(a, b) return a.nSatisfy < b.nSatisfy end)

	return tItems
end


function UIManufactureView:OnEnter(tParam)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    tParam = tParam or {}
    self:InitManufacture(tParam)
    self:InitItemToRecipeMap()
    self:UpdateInfo()
    Timer.AddFrameCycle(self, 5, function ()
        self:OnFrameBreathe()
    end)
end

function UIManufactureView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIManufactureView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelLifePage)
    end)

    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function()
        
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_RIGHT, self:GetFilterDef())
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        if self.nMakeCount > 0 then
           self:MakeRecipe(self.nCurCraftID, self.nCurRecipeID)
        end
    end)
    UIHelper.BindUIEvent(self.BtnJia, EventType.OnClick, function ()
        self.nMakeCount = math.min(self.nMakeCount + 1 , self.nCurTotalCount)
        self.nMakeCount = math.max(self.nMakeCount, 1)
        UIHelper.SetText(self.EditPaginate, self.nMakeCount)
        self:RefreshCostVigor()
        self:RefreshProgressBarPercent()
    end)
    UIHelper.BindUIEvent(self.BtnJian, EventType.OnClick, function ()
        self.nMakeCount = math.max(self.nMakeCount - 1, 1)
        UIHelper.SetText(self.EditPaginate, self.nMakeCount)
        self:RefreshCostVigor()
        self:RefreshProgressBarPercent()
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        GetClientPlayer().StopCurrentAction()
    end)

    for index, tog in ipairs(self.tbTogLeft) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            local  player = GetClientPlayer()
            if index == 5 and player and player.nLevel < 108 then  --特判梓匠开启需要达到108级
                TipsHelper.ShowNormalTip("侠士达到108级后方可开启梓匠")
                UIHelper.SetSelected(self.tbTogLeft[self.nLeftSelectIndex], true)
            else
                self:SelectedClass(index)
            end
        end)
    end

    UIHelper.BindUIEvent(self.SliderNum, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            self:RefreshProgressBarPercent()
        end

        local percent = UIHelper.GetProgressBarPercent(self.SliderNum)/100
        if self.bSliding then
            self.nMakeCount = percent * self.nCurTotalCount
            if math.floor(self.nMakeCount) + 0.5 < self.nMakeCount then
                self.nMakeCount = math.ceil(self.nMakeCount)
            else
                self.nMakeCount = math.floor(self.nMakeCount)
            end
            self.nMakeCount = math.min(self.nMakeCount, self.nCurTotalCount)
            self.nMakeCount = math.max(self.nMakeCount, 1)
            self:RefreshCostVigor()
            UIHelper.SetText(self.EditPaginate, self.nMakeCount)
        end
        UIHelper.SetWidth(self.ImgSliderNum, self.SliderImgWidth*percent)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
        local szNewSearchTxt = UIHelper.GetString(self.EditKindSearch)
        if szNewSearchTxt == self.szSearchTxt then return end

        self.szSearchTxt = szNewSearchTxt
        self:UpdateInfo()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
        local szText = UIHelper.GetText(self.EditPaginate)
        self.nMakeCount = tonumber(szText) or 1
        self.nMakeCount = math.min(self.nMakeCount, self.nCurTotalCount)
        self.nMakeCount = math.max(self.nMakeCount, 1)
        self:RefreshCostVigor()
        UIHelper.SetText(self.EditPaginate, self.nMakeCount)
        self:RefreshProgressBarPercent()
    end)

    UIHelper.BindUIEvent(self.BtnAdd1, EventType.OnClick, function ()
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
        end
        local recipe  = GetRecipe(self.nCurCraftID, self.nCurRecipeID)
        local nType = recipe.dwCreateItemType1
        local nID	= recipe.dwCreateItemIndex1

        self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
        self.scriptItemTip:OnInitWithTabID(nType, nID)
        self.scriptItemTip:SetBtnState({})
    end)

    UIHelper.BindUIEvent(self.BtnSpecialization, EventType.OnClick, function ()
        local dwAdventureID = nil
        for _, tRecipeInfo in pairs(g_LearnInfo) do
            if self.nCurCraftID == tRecipeInfo["dwCraftID"] and self.nCurRecipeID == tRecipeInfo["dwRecipeID"] then
                dwAdventureID = tRecipeInfo.dwAdventureID
            end
        end
        if not dwAdventureID then
            local bVisable = UIHelper.GetVisible(self.WidgetAnchorLeaveFor)
            UIHelper.SetVisible(self.WidgetAnchorLeaveFor, not bVisable)
        else
            ItemData.RedirectForceToAdventure(dwAdventureID)
        end
    end)
end

function UIManufactureView:RegEvent()
    Event.Reg(self, "SYS_MSG", function()
        if arg0 == "UI_OME_CRAFT_RESPOND" then
            if arg1 == CRAFT_RESULT_CODE.SUCCESS then
                self:OnMakeRecipeRespond(arg2, arg3)
            else
                GetClientPlayer().StopCurrentAction()
                UIMgr.Close(VIEW_ID.PanelCycleProgressBar)
                self.tProgressBarParamList = {}
            end
        elseif arg0 == "UI_OME_ADD_PROFESSION_PROFICIENCY" then
            self:UpdateVigorNode()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
        end
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, "DO_RECIPE_PREPARE_PROGRESS", function()
        local nCraftID = arg1
        local nRecipeID = arg2
        local recipe  = GetRecipe(nCraftID, nRecipeID)
        local nType = recipe.dwCreateItemType1
        local nID	= recipe.dwCreateItemIndex1
        local itemInfo = ItemData.GetItemInfo(nType, nID)
        local tParam = {
            szType = "Normal",
            szTitle = "制作中",
            szFormat = Table_GetRecipeName(nCraftID, nRecipeID),
            nStartTime = Timer.RealtimeSinceStartup(),
            nDuration = arg0 / GLOBAL.GAME_FPS,
            dwTabType = nType,
            dwIndex = nID,
            bTouchClose = true,
            fnCancel = function ()
                GetClientPlayer().StopCurrentAction()
            end
        }

        table.insert(self.tProgressBarParamList, tParam)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == self:GetFilterDef().Key then
            self:UpdateCustomData(tbSelected)
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 1, self.nMakeCount)
    end)

    Event.Reg(self, EventType.OnSelectLeaveForBtn,function(tbInfo)
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
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

    Event.Reg(self, "BAG_ITEM_UPDATE", function ()
        self:RecallSelectRecipeFunc()
    end)

    Event.Reg(self, "UPDATE_VIGOR", function()
        self:UpdateVigorNode()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.ScrollViewDoLayout(self.ScrollViewEquipment)

        local nPosX, nPosY = UIHelper.GetWorldPosition(self.WidgetContentRecipe)
        local layoutMask = UIHelper.GetParent(self.ScrollViewEquipment)
        UIHelper.SetWorldPosition(layoutMask, nPosX, nPosY)
        UIHelper.SetWorldPosition(self.ScrollViewEquipment, nPosX, nPosY)
    end)
end

function UIManufactureView:UnRegEvent()

end

function UIManufactureView:InitManufacture(tParam)
    self.dwDefaultCraftID = tParam.dwCraftID
    self.dwDefaultRecipeID = tParam.dwRecipeID
    local nDefaultProfessionID = tParam.nDefaultProfessionID
    local nIndex = 1
    if nDefaultProfessionID then
        for index, tInfo in ipairs(TogLeftToID) do
            if tInfo.nProfessionID == nDefaultProfessionID then
                nIndex = index
                break
            end
        end
    end

    self.nMasterID = TogLeftToID[nIndex].nMaseterID
    self.nProfessionID = TogLeftToID[nIndex].nProfessionID
    self.szTogLeftName = TogLeftToID[nIndex].szName
    self.nLeftSelectIndex = nIndex
    for nTogIndex, tog in ipairs(self.tbTogLeft) do
        UIHelper.SetSelected(tog, nTogIndex == nIndex)
    end

    local tFilterDef = self:GetFilterDef()
    tFilterDef.Reset()
    self.tCustomData = {
        nLearnFliter = tFilterDef[1].tbDefault[1],
        nExpertiseFliter = tFilterDef[2].tbDefault[1],
        nMakeFliter = tFilterDef[3].tbDefault[1],
    }
    self.tProgressBarParamList = {}
    self.szSearchTxt = nil
    UIHelper.SetText(self.EditPaginate, "")

    self.scriptContentRecipe = UIHelper.GetBindScript(self.WidgetContentRecipe)
    self:RefreshTravelList()
    UIHelper.SetTouchDownHideTips(self.BtnSpecialization, false)

    local tbSelected = tFilterDef.GetRunTime()
    self:UpdateCustomData(tbSelected)

    for index, tog in ipairs(self.tbTogLeft) do
        local nodes = UIHelper.GetChildren(tog)
        local bExpertised = GetClientPlayer().IsProfessionExpertised(TogLeftToID[index].nProfessionID)
        if not bExpertised then
            for i, node in ipairs(nodes) do
                local name = tostring(node:getName())
                if string.match(name, "ImgSpecialization") then
                    UIHelper.SetVisible(node, false)
                end
            end
        end
    end
    self.nMakeCount = 1
    UIHelper.SetText(self.EditPaginate, self.nMakeCount)

    self.SliderImgWidth = UIHelper.GetWidth(self.ImgSliderNumBg)

    if not CraftData.tCustomData.bAutoSelectLearned then
        CraftData.tCustomData.bAutoSelectLearned = true
        tFilterDef[1].tbDefault = {2}
        self.tCustomData.nLearnFliter = FliterLearnType.Learned
    end
end

function UIManufactureView:OnFrameBreathe()
    if #self.tProgressBarParamList > 0 then
        local uiView = UIMgr.GetView(VIEW_ID.PanelCycleProgressBar)
        local scriptView = uiView and uiView.scriptView
        local tParam = table.remove(self.tProgressBarParamList, 1)
        if not scriptView then
            scriptView = UIMgr.Open(VIEW_ID.PanelCycleProgressBar, tParam, self.nMakeCount)
        else
            scriptView:OnEnter(tParam)
        end
    end
    if self.bCoolDown then
        local _,_, szCoolDown, bCoolDown = self:GetRecipeTip(self.nCurCraftID, self.nCurRecipeID)
        self.bCoolDown = bCoolDown
        UIHelper.SetVisible(self.LabelCD, szCoolDown ~= "")
        UIHelper.SetString(self.LabelCD, szCoolDown or "")
        if not bCoolDown then
            UIHelper.SetTextColor(self.LabelCD, colorWhite)
            UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
        end
    end
end

function UIManufactureView:UpdateInfo()
    -- 任何刷新都会尝试去自动选中最近一次手动选中的配方
    local dwLastRecipeID = CraftData.tCraftID2LastRecipeID[self.nProfessionID]
    if not self.dwDefaultCraftID and dwLastRecipeID then
        self.dwDefaultCraftID = self.nProfessionID
        self.dwDefaultRecipeID = dwLastRecipeID
    end
    self:UpdateRecipeTable()
    self:UpdateRecipePrefab()
    local bAllSame = self:CheckDefaultFilter()
    if bAllSame then
        UIHelper.SetSpriteFrame(self.ImgSift, ShopData.szScreenImgDefault)
    else
        UIHelper.SetSpriteFrame(self.ImgSift, ShopData.szScreenImgActiving)
    end
    self:UpdateVigorNode()
end

function UIManufactureView:UpdateRecipeTable()
    Table_InitRecipe()
    local tbProfession = self:GetProfession()
    local tRes = {}
    self.tOrderBelongIDList = {}
    self.tRecipeClassMap = {}
    for i=1, #tbProfession, 1 do
        local v = tbProfession[i]
        local Recipe = GetRecipe(v.dwCraftID, v.dwRecipeID)
        local tRecipeInfo = Table_GetRecipeInfo(v.dwCraftID, v.dwRecipeID)
        if Recipe and tRecipeInfo and not tRecipeInfo.bHide then
            local nBelongID = tonumber(Recipe.szBelong) or 0
            tRes[v.dwCraftID] = tRes[v.dwCraftID] or Table_GetRecipeNameVer2(v.dwCraftID)
            local tbRow = tRes[v.dwCraftID][v.dwRecipeID]
            if not tbRow then
                LOG.INFO("[UIManufactureView] UpdateRecipeTable Receipe not found : %d.", v.dwRecipeID)
            else
                local bCheckFliter = self.tCustomData.nExpertiseFliter == FliterExpertiseType.All or
                self.tCustomData.nExpertiseFliter == FliterExpertiseType.Expertise and Recipe.bNeedExpertise or
                self.tCustomData.nExpertiseFliter == FliterExpertiseType.Normal and not Recipe.bNeedExpertise

                local nTotalCount, nCountNoChild = self:GetRecipeTotalCount(Recipe)
                local bCanMake = self.tCustomData.nMakeFliter == FliterMakeType.CanMake
                bCheckFliter = bCheckFliter and (not bCanMake or ( bCanMake and nTotalCount > 0))

                local bMaterialFliter = self.tCustomData.nMakeFliter ~= FliterMakeType.MaterialEnough or nCountNoChild > 0
                bCheckFliter = bCheckFliter and bMaterialFliter

                local bCollected = ItemData.IsItemCollected(Recipe.dwCreateItemType1, Recipe.dwCreateItemIndex1)
                local bCollectedFilter = (self.tCustomData.nMakeFliter == FliterMakeType.Collected and bCollected) or (self.tCustomData.nMakeFliter == FliterMakeType.Uncollected and not bCollected)
                bCollectedFilter = bCollectedFilter or (self.tCustomData.nMakeFliter ~= FliterMakeType.Collected and self.tCustomData.nMakeFliter ~= FliterMakeType.Uncollected)
                bCheckFliter = bCheckFliter and bCollectedFilter

                local bShow = self:DoSearch(v.dwCraftID, v.dwRecipeID, self.szSearchTxt)
                bCheckFliter = bCheckFliter and bShow
                if bCheckFliter then
                    if not self.tRecipeClassMap[nBelongID] then
                        self.tRecipeClassMap[nBelongID] = {
                            szName = UIHelper.GBKToUTF8(Table_GetCraftBelongName(self.nProfessionID, nBelongID)),
                            bTitle = true,
                            nCanMakeCount = 0,
                            bHasLearned = tbProfession[i].bHas,
                            bNeedExpertise = Recipe.bNeedExpertise,
                            tRecipeList = {}
                        }
                        table.insert(self.tOrderBelongIDList, nBelongID)
                    end
                    table.insert(self.tRecipeClassMap[nBelongID].tRecipeList, {
                        nCraftID	= tbProfession[i].dwCraftID,
                        nRecipeID   = tbProfession[i].dwRecipeID,
                        szName = UIHelper.GBKToUTF8(tbRow.szName),
                        nLevel = tbRow.nLevel,
                        nBelongID = nBelongID,
                        bNeedExpertise = Recipe.bNeedExpertise,
                        nTotalCount = nTotalCount,
                        nCountNoChild = nCountNoChild,
                        bHasLearned	= tbProfession[i].bHas,
                    })
                end
            end
        end
    end

    table.sort(self.tOrderBelongIDList, function (a, b)
        return a < b
    end)
    for i = 1, #self.tOrderBelongIDList, 1 do
        local nBelongID = self.tOrderBelongIDList[i]
        table.sort(self.tRecipeClassMap[nBelongID].tRecipeList, TableSortCmp)
    end
end

function UIManufactureView:UpdateRecipePrefab()
    self.scriptContentRecipe:ClearContainer()
    self.scriptContentRecipe:OnInit(PREFAB_ID.WidgetManufactureFilter, function (scriptContainer, tClass) -- 初始化标题
        UIHelper.SetString(scriptContainer.LabelTitleDown, tClass.szName)
        UIHelper.SetString(scriptContainer.LabelTitleUp, tClass.szName)
    end)

    local nDefaultBIndex = 1
    local nDefaultRIndex = 1
    for nBIndex, nBelongID in ipairs(self.tOrderBelongIDList) do
        local tRecipeInfoList = {}
        local tClass = self.tRecipeClassMap[nBelongID]
        for nRIndex, tRecipe in ipairs(tClass.tRecipeList) do
            if (self.dwDefaultCraftID and self.dwDefaultRecipeID) and (self.dwDefaultCraftID == tRecipe.nCraftID and self.dwDefaultRecipeID == tRecipe.nRecipeID) then
                self.dwDefaultCraftID = nil
                self.dwDefaultRecipeID = nil
                nDefaultBIndex = nBIndex
                nDefaultRIndex = nRIndex
            end
            local tRecipeInfo = {
                nPrefabID = PREFAB_ID.WidgetManufactureFilterCell,
                tArgs = {
                    tRecipe = tRecipe,
                    fCallBack = function (tRecipe)
                        if self.nCurCraftID ~= tRecipe.nCraftID or self.nCurRecipeID ~= tRecipe.nRecipeID then self.nMakeCount = 1 end

                        local recipe = GetRecipe(tRecipe.nCraftID, tRecipe.nRecipeID)
                        local nTotalCount, nCountNoChild = self:GetRecipeTotalCount(recipe)
                        tRecipe.nTotalCount = nTotalCount

                        self.nCurCraftID = tRecipe.nCraftID
                        self.nCurRecipeID = tRecipe.nRecipeID
                        self.nCurTotalCount = nCountNoChild

                        CraftData.tCraftID2LastRecipeID[self.nCurCraftID] = self.nCurRecipeID

                        self:RefreshProgressBarPercent()
                        self:UpdateRecipeDetail()
                    end,
                }
            }
            table.insert(tRecipeInfoList, tRecipeInfo)
        end

        self.scriptContentRecipe:AddContainer(tClass, tRecipeInfoList, function (scriptContainer, bSelected) -- 标题选中事件
            if bSelected then self.tRecipeInfoList = tRecipeInfoList end
        end,function () -- 标题点击事件

        end)
    end
    self.scriptContentRecipe:UpdateInfo()

    if #self.scriptContentRecipe.tContainerList > 0 then
        for _, tContainter in ipairs(self.scriptContentRecipe.tContainerList) do
            UIHelper.CascadeDoLayoutDoWidget(tContainter.scriptContainer._rootNode, false, true)
        end
        Timer.AddFrame(self, 2, function ()
            local scriptContainer = self.scriptContentRecipe.tContainerList[nDefaultBIndex].scriptContainer
            scriptContainer:SetSelected(true)
            if #scriptContainer.tItemScripts > 0 then
                local tItemScript = scriptContainer.tItemScripts[nDefaultRIndex]
                self.nCurCraftID = tItemScript.tRecipe.nCraftID
                self.nCurRecipeID = tItemScript.tRecipe.nRecipeID
                UIHelper.SetSelected(tItemScript.ToggleSelect, true)
                self:UpdateRecipeDetail()
                local nTotalLength = #self.scriptContentRecipe.tContainerList*80 + #scriptContainer.tItemScripts*70
                local nCurlength = (nDefaultBIndex-1)*80 + (nDefaultRIndex-1)*70
                local nPercent = nCurlength/nTotalLength*100
                UIHelper.ScrollToPercent(self.scriptContentRecipe.ScrollViewContent, nPercent)
            end
        end)
    end

    local bHasResult = #self.tOrderBelongIDList > 0
    UIHelper.SetVisible(self.WidgetRecipeDetail, bHasResult)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasResult)
end

function UIManufactureView:UpdateRecipeDetail()
    local player = GetClientPlayer()
    local recipe  = GetRecipe(self.nCurCraftID, self.nCurRecipeID)
    local nType = recipe.dwCreateItemType1
    local nID	= recipe.dwCreateItemIndex1
    local ItemInfo = GetItemInfo(nType, nID)
    local bHasLearned = player.IsRecipeLearned(self.nCurCraftID, self.nCurRecipeID)
    local nProID = self.nProfessionID
    local szRecipeName = Table_GetRecipeName(self.nCurCraftID, self.nCurRecipeID)
    local nMin  = recipe.dwCreateItemMinCount1
    local nMax  = recipe.dwCreateItemMaxCount1
    local szItemCount = ""
    if nMax == nMin then
        if nMin ~= 1 then
            szItemCount = tostring(nMin)
        end
    else
        szItemCount = nMin.."-"..nMax
    end
    UIHelper.SetItemIconByItemInfo(self.ImgAdd1, ItemInfo)
    UIHelper.SetString(self.LabelTitle, szRecipeName)
    UIHelper.SetString(self.LabelProductionItemCount, szItemCount)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[ItemInfo.nQuality + 1])

    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetBottom)
    UIHelper.RemoveAllChildren(self.LayoutConsume)
    UIHelper.RemoveAllChildren(self.ScrollViewConsume)
    UIHelper.ToggleGroupAddToggle(self.WidgetBottom, self.ToggleDefaultConsume)
    local tItems = GetRequireItems(recipe)
    local bSatisfy = true
    local nodeParent = self.LayoutConsume
    if #tItems > 7 then
        nodeParent = self.ScrollViewConsume
    end
    for i, v in ipairs(tItems) do
        nType  = v.nType
	    nID	 = v.nID
		local nNeed  = v.nNeed
        if nNeed > 0 then
            ItemInfo = GetItemInfo(nType, nID)
            local szItemName = UIHelper.GBKToUTF8(Table_GetItemName(ItemInfo.nUiId))
            local nCount = player.GetItemAmount(nType, nID)

            local Script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, nodeParent)
            Script:SetLabelItemName(szItemName)
            Script:SetItemQualityBg(ItemInfo.nQuality)
            Script:SetImgIcon(UIHelper.GetIconPathByItemInfo(ItemInfo))
            Script:RegisterSelectEvent(function (bSelected)
                if self.scriptItemTip then
                    self.scriptItemTip:OnInit()
                end
                if not bSelected then
                    return
                end
                self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
                if nNeed > nCount then
                    self.scriptItemTip:SetShopNeedCount(nNeed - nCount)
                else
                    self.scriptItemTip:SetShopNeedCount(nil)
                end
                self.scriptItemTip:OnInitWithTabID(tItems[i].nType, tItems[i].nID)
                self.scriptItemTip:SetBtnState({})
            end)
            UIHelper.SetAnchorPoint(Script._rootNode, 0.5, 0.5)
            UIHelper.ToggleGroupAddToggle(self.WidgetBottom, Script.ToggleSelect)
            if nNeed > nCount then
                Script:SetLableCount(nCount.."/"..nNeed)
                Script:SetLabelCountColor(cc.c3b(255,133,125))
                bSatisfy = false
            else
                Script:SetLableCount(nCount.."/"..nNeed)
            end
            UIHelper.RemoveAllChildren(Script.ToggleSelect) -- 交互要求，手动移除光圈
        end
    end
    UIHelper.SetVisible(self.WidgetConsume, true)
    UIHelper.SetVisible(self.WidgetQuantity, true)
    UIHelper.SetVisible(self.WidgetPlaceTrack, false)
    UIHelper.SetVisible(self.WidgetCanntDo, false)

	local bNeedExpertised = recipe.bNeedExpertise and (not player.IsProfessionExpertised(nProID)) --是否需要学习专精
    local szCannotDesz
    if bNeedExpertised then
        szCannotDesz = "需要专精"
    end
    local tbConfig = TogLeftToID[self.nLeftSelectIndex]
    local szRecipeTip, szSuitInfo, szCoolDown, bCoolDown = self:GetRecipeTip(self.nCurCraftID, self.nCurRecipeID)
    if not bHasLearned then
        szCannotDesz = szRecipeTip
    end
    UIHelper.SetVisible(self.LabelCD, szCoolDown ~= "")
    UIHelper.SetString(self.LabelCD, szCoolDown or "")
    UIHelper.SetVisible(self.LabelSuit, szSuitInfo ~= "")
    UIHelper.SetString(self.LabelSuit, szSuitInfo or "")
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetConsume, true, true)

    if bCoolDown then
        UIHelper.SetTextColor(self.LabelCD, colorRed)
    else
        UIHelper.SetTextColor(self.LabelCD, colorWhite)
    end
    self.bCoolDown = bCoolDown
    local szForbidTip = ""
    if self.bCoolDown then
        szForbidTip = "技艺调息时间未到"
    end
    UIHelper.SetSpriteFrame(self.ImgType, tbConfig["szTypePath"])
    self.nMakeCount = math.max(self.nMakeCount, 1)
    if not szCannotDesz then
        UIHelper.SetText(self.EditPaginate, self.nMakeCount)
    else
        UIHelper.SetVisible(self.WidgetConsume, false)
        UIHelper.SetVisible(self.WidgetQuantity, false)
        UIHelper.SetVisible(self.WidgetCanntDo, true)
        local nodes = UIHelper.GetChildren(self.WidgetCanntDo)
        UIHelper.SetString(nodes[1], szCannotDesz)
    end

    local bHasDoodad, szDoodadName = self:CheckDoodad(recipe)
    if not bHasDoodad and bHasLearned and not bNeedExpertised then
        UIHelper.SetVisible(self.WidgetConsume, false)
        UIHelper.SetVisible(self.WidgetQuantity, false)
        UIHelper.SetVisible(self.WidgetPlaceTrack, true)
        UIHelper.SetVisible(self.BtnSpecialization, true)
        UIHelper.SetString(self.LabelAnnotate, "请到"..UIHelper.GBKToUTF8(szDoodadName).."附近")
    end

    if bSatisfy and bHasDoodad and bHasLearned and not bNeedExpertised and not bCoolDown then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable, szForbidTip)
    end

    self:RefreshCostVigor()

    UIHelper.CascadeDoLayoutDoWidget(self.WidgetBottom, true, true)
end

function UIManufactureView:RefreshCostVigor()
    local recipe  = GetRecipe(self.nCurCraftID, self.nCurRecipeID)
    local nCostVigor = recipe.nVigor * self.nMakeCount
    if not GetClientPlayer().IsVigorAndStaminaEnough(nCostVigor) then
        UIHelper.SetTextColor(self.LabelConsumeNum, colorRed)
    else
        UIHelper.SetTextColor(self.LabelConsumeNum, colorWhite)
    end
    UIHelper.SetString(self.LabelConsumeNum, nCostVigor)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelConsumeNum))
end

function UIManufactureView:UpdateVigorNode()
    local nProID = self.nProfessionID
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
        UIHelper.SetVisible(self.ImgMiningProgress, false)
        UIHelper.SetVisible(self.WidgetCurrency, false)
        return
    else
        UIHelper.SetVisible(self.ImgMiningProgress, true)
        UIHelper.SetVisible(self.WidgetCurrency, true)
    end
    --UIHelper.SetString(self.LabelCast, self.szTogLeftName)
    UIHelper.SetString(self.LabslLevelNum, self.szTogLeftName..nLevel.."级")
    if nExp and nMaxExp then
        UIHelper.SetString(self.LabelNum, nExp .. '/' .. nMaxExp)
        UIHelper.SetProgressBarPercent(self.ProgressBarMining, 100 * nExp / nMaxExp)
    else
        local node = UIHelper.GetParent(self.ProgressBarMining)
        UIHelper.SetVisible(node, false)
    end
    self:RefreshProgressBarPercent()

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutRT, true, true)
end

function UIManufactureView:UpdateCustomData(tbSelected)
    if not tbSelected then return end
    if tbSelected[1][1] then self.tCustomData.nLearnFliter = tbSelected[1][1] end
    if tbSelected[2][1] then self.tCustomData.nExpertiseFliter = tbSelected[2][1] end
    if tbSelected[3][1] then self.tCustomData.nMakeFliter = tbSelected[3][1] end
end

function UIManufactureView:RefreshTravelList()
    self.tbTravelList = {}

    local tNavigation = CraftData.CraftDoodadNavigation[self.nProfessionID]
    for _,nLinkID in ipairs(tNavigation.nLinkIDList) do
        local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
        for _, tInfo in pairs(tAllLinkInfo) do
            table.insert(self.tbTravelList, tInfo)
        end
    end
    local scriptTravelView = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)
    if scriptTravelView then
        scriptTravelView:OnEnter(self.tbTravelList, 8)
    end
end

function UIManufactureView:OnMakeRecipeRespond(dwCraftID, dwRecipeID)
    if self.nCurCraftID == dwCraftID and self.nCurRecipeID == dwRecipeID then
        self.nMakeCount = self.nMakeCount - 1
        if self.nMakeCount > 0 then
            self:MakeRecipe(dwCraftID, dwRecipeID)
        else
            self.nMakeCount = 1
        end
        self:RefreshCostVigor()
        self:UpdateRecipeDetail()
    end
end

function UIManufactureView:GetProfession()
    local bCan = self.tCustomData.nLearnFliter ~= 2
    local bHas = self.tCustomData.nLearnFliter ~= 3
    local bCannot = self.tCustomData.nLearnFliter ~= 2
    local tbProfession = GetMasterRecipeList(self.nMasterID, bCan, bHas, bCannot)--根据条件返回配方

    local dwCraftID = Table_GetCraftID(self.nProfessionID)
	local bPlayerHas, bPlayerCanLearn
	for k, v in pairs(g_LearnInfo) do
		if dwCraftID == v.dwCraftID then
			bPlayerHas		= g_pClientPlayer.IsRecipeLearned(dwCraftID, v.dwRecipeID)
			bPlayerCanLearn	= g_pClientPlayer.CanLearnRecipe(dwCraftID, v.dwRecipeID, self.nMasterID)
			if (((bCan and bPlayerCanLearn) or (bHas and bPlayerHas) or (bCannot and not bPlayerCanLearn and not bPlayerHas))) then
				v.bHas = bPlayerHas
				table.insert(tbProfession, v)
			end
		end
	end
    return tbProfession
end

function UIManufactureView:GetRecipeTip(nCurCraftID, nCurRecipeID)
    local szRecipeTip = Table_GetRecipeTip(nCurCraftID, nCurRecipeID)
    szRecipeTip = UIHelper.GBKToUTF8(szRecipeTip)
    szRecipeTip = string.pure_text(szRecipeTip)

    local splitList = string.split(szRecipeTip, '。')
    local szCoolDown = splitList[2] or ""

    splitList = string.split(szRecipeTip, '\n')
    szRecipeTip = splitList[1]
    local szSuitInfo = splitList[2] or ""
    if not MatchString(szCoolDown, "冷却") then
        szCoolDown = ""
    end
    if not MatchString(szSuitInfo, "套装") then
        szSuitInfo = ""
    end
    local recipe  = GetRecipe(nCurCraftID, nCurRecipeID)
    local bCoolDown = false
    if recipe and recipe.dwCoolDownID and recipe.dwCoolDownID > 0 then
        local CDRemainTime = GetClientPlayer().GetCDLeft(recipe.dwCoolDownID)
        --CDRemainTime = CDRemainTime - (3600*3+ 60*5)*GLOBAL.GAME_FPS
        if CDRemainTime > 0 then
            bCoolDown = true
            szCoolDown = UIHelper.GetTimeText(CDRemainTime/GLOBAL.GAME_FPS)
            szCoolDown = "冷却时间："..szCoolDown
        end
    end
    return szRecipeTip, szSuitInfo, szCoolDown, bCoolDown
end

local function GetAttStr(szAttrID)
	return GetAttributeString(szAttrID, 0)
end

local function SearchAttr(szAttrID, szKey)
	if szAttrID == "" then
		return false
	end

	local szAttrStr = GetAttStr(szAttrID)
	szAttrStr = UIHelper.GBKToUTF8(szAttrStr)
	local bSearch = MatchString(szAttrStr, szKey)

	return bSearch
end

function UIManufactureView:DoSearch(nCraftID, nRecipeID, szKey)
    local szName = Table_GetRecipeName(nCraftID, nRecipeID)
	if MatchString(szName, szKey) then
		return true
	end

	local szTip = Table_GetRecipeTip(nCraftID, nRecipeID)
    szTip = UIHelper.GBKToUTF8(szTip)
	if MatchString(szTip, szKey) then
		return true
	end

	-- local recipe = GetRecipe(nCraftID, nRecipeID)
	-- local nType = recipe.dwCreateItemType1
	-- local nID	= recipe.dwCreateItemIndex1
    -- local tAttribute = g_tTable.tCraftSearch:Search(nType, nID)
	-- if tAttribute then
	-- 	for i = 1, 12 do
	-- 		if SearchAttr(tAttribute["szAttr" .. i], szKey) then
	-- 			return true
	-- 		end
	-- 	end
	-- end
	return false
end

function UIManufactureView:InitItemToRecipeMap()
    self.tItem2RecipeMap = {}
    local tbProfession = GetMasterRecipeList(self.nMasterID, false, true, false) -- 根据条件返回配方
    for i=1, #tbProfession, 1 do
        local v = tbProfession[i]
        local recipe = GetRecipe(v.dwCraftID, v.dwRecipeID)
        if recipe then
            local nType = recipe.dwCreateItemType1
            local nID	= recipe.dwCreateItemIndex1
            if not self.tItem2RecipeMap[nType] then
                self.tItem2RecipeMap[nType] = {}
            end
            self.tItem2RecipeMap[nType][nID] = {
                dwCraftID = v.dwCraftID,
                dwRecipeID = v.dwRecipeID
            }
        end
    end
end

function UIManufactureView:CheckDoodad(recipe)
	if recipe.dwRequireDoodadID ~= 0 then
		local doodadTamplate = GetDoodadTemplate(recipe.dwRequireDoodadID)
		if doodadTamplate then
			local szName = Table_GetDoodadTemplateName(doodadTamplate.dwTemplateID)
			local bRet = self:SearchDoodad(doodadTamplate.dwTemplateID)
			if not bRet then
				return false, szName
			end
		end
	end
    return true
end

function UIManufactureView:SearchDoodad(dwRequireDoodadID)
	local player = GetClientPlayer()
	local tDoodads	 = player.SearchForDoodad(12 * 32)
	if not tDoodads then
		return false
	end

	for k, dwID in pairs(tDoodads) do
		local doodad = GetDoodad(dwID)
		local dwTemplateID = doodad.dwTemplateID
		if dwTemplateID == dwRequireDoodadID then
			return true
		end
	end
	return false
end

function UIManufactureView:GetRecipeTotalCount(recipe)
	local nTotalCount = 9999999
	local nCountNoChild = 9999999
	for nIndex = 1, 6, 1 do
		local nType = recipe["dwRequireItemType"..nIndex] or 0
		local nID = recipe["dwRequireItemIndex"..nIndex] or 0
		local nNeed = recipe["dwRequireItemCount"..nIndex] or 0

		if nNeed > 0 then
			local nCurrentCount = GetClientPlayer().GetItemAmount(nType, nID)
			local nMakeCount = self:GetChildCanMakeCount(nType, nID)
			local nCount = math.floor((nCurrentCount) / nNeed)
			local nChildCount = math.floor((nMakeCount) / nNeed)
			nTotalCount = math.min(nTotalCount, nCount + nChildCount)
			nCountNoChild = math.min(nCountNoChild, nCount)
		end
	end
	if nTotalCount == 9999999 then
		nTotalCount = 0
	end
	return nTotalCount , nCountNoChild
end

function UIManufactureView:GetChildCanMakeCount(dwType, dwIndex)
    if not self.tItem2RecipeMap[dwType] or not self.tItem2RecipeMap[dwType][dwIndex] then
        return 0
	end
    local tRequireRecipe = self.tItem2RecipeMap[dwType][dwIndex]
	local recipe = GetRecipe(tRequireRecipe.dwCraftID, tRequireRecipe.dwRecipeID)
	local nMin = recipe.dwCreateItemMinCount1
	local nCount,_ = self:GetRecipeTotalCount(recipe)

	return nCount * nMin
end

function UIManufactureView:RecallSelectRecipeFunc()
    for _, tRecipeInfo in pairs(self.tRecipeInfoList) do
        if self.nCurCraftID == tRecipeInfo.tArgs.tRecipe.nCraftID and self.nCurRecipeID == tRecipeInfo.tArgs.tRecipe.nRecipeID then
            tRecipeInfo.tArgs.fCallBack(tRecipeInfo.tArgs.tRecipe)
            break
        end
    end
end

function UIManufactureView:RefreshProgressBarPercent()
    local totalSize = self.nCurTotalCount
    if totalSize == 0 or totalSize == nil then
        totalSize = 99999
    end
    local percent = self.nMakeCount/totalSize*100
    UIHelper.SetProgressBarPercent(self.SliderNum, percent)
end

function UIManufactureView:SetSliderVisiable(bEnable)
    UIHelper.SetVisible(self.SliderNum, bEnable)
    UIHelper.SetVisible(self.BtnJia, bEnable)
    UIHelper.SetVisible(self.BtnJian, bEnable)
end

function UIManufactureView:MakeRecipe(nCraftID, nRecipeID)
    GetClientPlayer().CastProfessionSkill(nCraftID, nRecipeID)
end

function UIManufactureView:SelectedClass(nIndex)
    UIHelper.SetToggleGroupSelected(self.WidgetAnchorLeft, nIndex - 1)
    self.nMasterID = TogLeftToID[nIndex].nMaseterID
    self.nProfessionID = TogLeftToID[nIndex].nProfessionID
    self.szTogLeftName = TogLeftToID[nIndex].szName
    self.nLeftSelectIndex = nIndex
    self:UpdateInfo()
    self:RefreshTravelList()
end

function UIManufactureView:CheckDefaultFilter()
    local bAllSame = true
    bAllSame = bAllSame and self.tCustomData.nLearnFliter == FliterLearnType.All
    bAllSame = bAllSame and self.tCustomData.nExpertiseFliter == FliterExpertiseType.All
    bAllSame = bAllSame and self.tCustomData.nMakeFliter == FliterMakeType.All

    return bAllSame
end

function UIManufactureView:GetFilterDef()
    local tNavigation = CraftData.CraftDoodadNavigation[self.nProfessionID]
    if tNavigation.szName == "医术" or tNavigation.szName == "烹饪" then
        return FilterDef.ManufactureWithoutCollect
    else
        return FilterDef.Manufacture
    end
end

return UIManufactureView