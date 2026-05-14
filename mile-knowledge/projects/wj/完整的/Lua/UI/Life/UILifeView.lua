-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILifeView
-- Date: 2022-11-21 17:38:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILifeView = class("UILifeView")

function UILifeView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UILifeView:OnExit()
    self.bInit = false
end

function UILifeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelLifeMain)
    end)
end

function UILifeView:RegEvent()
    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelLifePage then
            self:UpdateDomesticateInfo()
        end
    end)

    Event.Reg(self, "UPDATE_VIGOR", function()
        UIHelper.SetString(self.LabelGetTips, string.format("（本周还可以获得精力：%s）", g_pClientPlayer.GetVigorRemainSpace()))
        self.VigorScript = self.VigorScript or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetJingLi)
        self.VigorScript:SetCurrencyType(CurrencyType.Vigor)
        local nCurrentVigor = g_pClientPlayer.nVigor + g_pClientPlayer.nCurrentStamina
        local nMaxVigor = g_pClientPlayer.GetMaxVigor() + g_pClientPlayer.nMaxStamina
        self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
        UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.WidgetJingLi), true)
    end)

    Event.Reg(self, "SYS_MSG", function()
        if arg0 == "UI_OME_ADD_PROFESSION_PROFICIENCY" then
            self:RefreshCraftButtons()
        end
    end)
end

function UILifeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UILifeView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutCollect)
    UIHelper.RemoveAllChildren(self.LayoutManufacture)
    UIHelper.RemoveAllChildren(self.LayoutOther)

    self.tScriptButtons = {}
    local scriptButton = nil
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutCollect)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutCollect)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutCollect)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutManufacture)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutManufacture)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutManufacture)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutManufacture)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutManufacture)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end
    scriptButton = UIHelper.AddPrefab(PREFAB_ID.WidgetLiftType, self.LayoutOther)
    if scriptButton then table.insert(self.tScriptButtons, scriptButton) end

    UIHelper.LayoutDoLayout(self.LayoutCollect)
    UIHelper.LayoutDoLayout(self.LayoutManufacture)
    UIHelper.LayoutDoLayout(self.LayoutOther)

    self:RefreshCraftButtons()
    -- 驯养
    self:UpdateDomesticateInfo()
    
    -- 精力
    UIHelper.SetString(self.LabelGetTips, string.format("（本周还可以获得精力：%s）", g_pClientPlayer.GetVigorRemainSpace()))
    self.VigorScript = self.VigorScript or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetJingLi)
    self.VigorScript:SetCurrencyType(CurrencyType.Vigor)
    local nCurrentVigor = g_pClientPlayer.nVigor + g_pClientPlayer.nCurrentStamina
	local nMaxVigor = g_pClientPlayer.GetMaxVigor() + g_pClientPlayer.nMaxStamina
    self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
    UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.WidgetJingLi), true)
end

function UILifeView:RefreshCraftButtons()
    for nIndex, scriptCell in ipairs(self.tScriptButtons) do
        local tBtnConfig = UICraftMainButtonTab[nIndex]
        if tBtnConfig then
            UIHelper.BindUIEvent(scriptCell.BtnLifeType, EventType.OnClick, function ()
                tBtnConfig.fCallCack()
            end)
            UIHelper.SetString(scriptCell.LabelName, tBtnConfig.szName)
            UIHelper.SetSpriteFrame(scriptCell.ImgIcon, tBtnConfig.szIconPath)
            if tBtnConfig.nProfessionID then
                local tProInfo = self:GetProfessionInfo(tBtnConfig.nProfessionID)
                if tProInfo then
                    local nExp = tProInfo.Proficiency or 0
                    local Profession = GetProfession(tBtnConfig.nProfessionID)
                    local nMaxExp = Profession.GetLevelProficiency(tProInfo.Level)
                    local nPercent = nExp/nMaxExp * 100
                    local bHasExpertised = g_pClientPlayer.IsProfessionExpertised(tBtnConfig.nProfessionID) or false
                    UIHelper.SetString(scriptCell.LabelLevel, tostring(tProInfo.Level))
                    UIHelper.SetString(scriptCell.LabelExp, string.format("%d/%d", nExp, nMaxExp))                    
                    UIHelper.SetVisible(scriptCell.ImgSpecialization, bHasExpertised)
                    UIHelper.SetProgressBarPercent(scriptCell.ProgressBarLevel, nPercent)
                    UIHelper.LayoutDoLayout(UIHelper.GetParent(scriptCell.LabelLevel))
                end
            end
        end
    end
end

function UILifeView:UpdateDomesticateState()    
    local bDomesticating, bComplete = false, false
    local tDomesticate = g_pClientPlayer.GetDomesticate()
    if not tDomesticate then
        return bDomesticating, bComplete
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return bDomesticating, bComplete
    end
    local tAdultItemInfo = tDomesticate.GetAdultItemInfo()
    if not tAdultItemInfo then
        return bDomesticating, bComplete
    end
    bDomesticating = true
    bComplete = tDomesticate.nGrowthLevel == tDomesticate.nMaxGrowthLevel

    local tShowWord = Table_GetShowWord(tCubItemInfo.nSub)
    local tCubInfo = Table_GetCubInfo(tAdultItemInfo.dwID)
    local szName = UIHelper.GBKToUTF8(tCubInfo.szName)
    local szCubLevel = string.format("%d/%d", tDomesticate.nGrowthLevel, tDomesticate.nMaxGrowthLevel)
    local nPercent = tDomesticate.nGrowthExp/tDomesticate.nMaxGrowthExp*100
    local scriptCell = self.tScriptButtons[CRAFT_TYPE.Demosticate]
    local nItemIconID = Table_GetItemIconID(tAdultItemInfo.nUiId)
    local szIconPath = UIHelper.GetIconPathByIconID(nItemIconID)
    UIHelper.SetString(scriptCell.LabelLevel, szCubLevel)
    UIHelper.SetProgressBarPercent(scriptCell.ProgressBarLevel, nPercent)

    local nEventID = tDomesticate.dwEventID
    local bHasEvent = nEventID and nEventID > 0

    local nSatietyPercent = tDomesticate.nFullMeasure/tDomesticate.nMaxFullMeasure*100
    local bHungry = nSatietyPercent < tShowWord.nFullMeasureDegree1
    local szMsg = "饱食度低"
    if bHasEvent then szMsg = "新事件" end
    UIHelper.SetVisible(scriptCell.ImgRedDot, bHasEvent or bHungry)
    UIHelper.SetString(scriptCell.LabelNews, szMsg)
    UIHelper.SetTextColor(scriptCell.LabelNews, cc.c3b(0xff, 0xe9, 0xe8))

    return bDomesticating, bComplete
end

function UILifeView:UpdateDomesticateInfo()
    local scriptDomesticate = self.tScriptButtons[CRAFT_TYPE.Demosticate]
    local tBtnConfig = UICraftMainButtonTab[CRAFT_TYPE.Demosticate]
    UIHelper.SetString(scriptDomesticate.LabelName, tBtnConfig.szName)

    UIHelper.SetVisible(scriptDomesticate.ImgRedDot, false)

    local bDomesticating, bComplete = self:UpdateDomesticateState()
    local LabelState = scriptDomesticate.LabelExp
    UIHelper.SetVisible(scriptDomesticate.LabelLevel,  false)
    UIHelper.SetVisible(scriptDomesticate.LaberLevelTitle, false)
    UIHelper.SetVisible(scriptDomesticate.ProgressBarLevel, false)

    if bComplete then UIHelper.SetString(LabelState, "可收获")
    elseif not bDomesticating then UIHelper.SetString(LabelState, "无驯养")
    else UIHelper.SetString(LabelState, "驯养中") end
    UIHelper.LayoutDoLayout(UIHelper.GetParent(LabelState))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(scriptDomesticate.LabelLevel))
end

function UILifeView:GetProfessionInfo(nProfessionID)
    local player = GetClientPlayer()
    local ProTab = player.GetProfession()
    local tProInfo = nil
    for _, val in pairs(ProTab) do
        local nProID = val.ProfessionID
        if nProID == nProfessionID then
            tProInfo = val
        end
    end
    return tProInfo
end


return UILifeView