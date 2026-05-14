-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIPanelDXSkillRecommend
-- Date: 2025-10-21 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------
local OPEN_TEACHQIXUE_RECOMMEND_LEVEL = 95

local function IsShowQiXueReCommend()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if hPlayer.nLevel < OPEN_TEACHQIXUE_RECOMMEND_LEVEL then
        return false
    end

    return true
end

function GetTeachRecommendList()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return {}
    end
    local tKungfu = hPlayer.GetKungfuMount()
    if not tKungfu then
        return {}
    end
    local tTeachRecommendList = Table_GetSkillTeachQixueRecommend(hPlayer.dwForceID, tKungfu.dwSkillID)
    return tTeachRecommendList
end

function CheckConfirmQixue(tQixueList)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nCostTrain = 0
    local tConfirmList = {}
    local tMixConfirmList = {}
    for _, tQixue in ipairs(tQixueList) do
        local dwPointID = tQixue[1]
        local nIndex = tQixue[2]

        local tInfo = hPlayer.GetTalentInfoByPointID(dwPointID)
        local tSkill = tInfo.SkillGroup[nIndex]
        if tInfo.nType == TALENT_SELECTION_TYPE.MIXED then
            table.insert(tMixConfirmList, nIndex)
            if not tSkill.bSelected then
                nCostTrain = tInfo.nCostTrain + nCostTrain
            end
        else
            if not tSkill.bSelected then
                nCostTrain = tInfo.nCostTrain + nCostTrain
                table.insert(tConfirmList, tQixue)
            end
        end
    end

    --判断混选奇穴方案
    local tMixPointSelected = {}
    local tNowQixueList = SkillData.GetQixueList()
    for _, tQixue in ipairs(tNowQixueList) do
        if tQixue.nType == TALENT_SELECTION_TYPE.MIXED then
            tMixPointSelected[tQixue.dwPointID] = tQixue.nSelectIndex
        end
    end

    for _, nSetIndex in ipairs(tMixConfirmList) do
        if not CheckIsInTable(tMixPointSelected, nSetIndex) then
            for dwPointID, nSelectedIndex in pairs(tMixPointSelected) do
                if not CheckIsInTable(tMixConfirmList, nSelectedIndex) then
                    table.insert(tConfirmList, { dwPointID, nSetIndex })
                    tMixPointSelected[dwPointID] = nSetIndex
                    break
                end
            end
        end
    end

    return true, nCostTrain, tConfirmList
end

function OnConfirmQixue(tQixueList, nWay, tSkillRecipeList)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if g_pClientPlayer and g_pClientPlayer.bFightState then
        TipsHelper.ShowImportantYellowTip("战斗状态中不能切换")
        return
    end

    local bResult, UserData, tConfirmList = CheckConfirmQixue(tQixueList)
    if not bResult then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tSelectTalentResult[UserData])
        return
    end

    local nCostTrain = UserData
    if nCostTrain > hPlayer.nCurrentTrainValue then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tSelectTalentResult[SELECT_TALENT_RESULT.NOT_ENOUGH_TRAIN])
        return
    end

    if nWay == 1 then
        RemoteCallToServer("On_Skill_SetNewTalent", tConfirmList)
        return
    elseif nWay == 2 then
        local fnSureAction = function()
            if #tConfirmList > 0 then
                RemoteCallToServer("On_Skill_SetNewTalent", tConfirmList)
            end
            ConfirmCheckRecipe(tSkillRecipeList, true)
        end
        UIHelper.ShowConfirm(FormatString(g_tStrings.SKILL_RECIPE_TEACH_CONFIRM_QIXUE, nCostTrain), fnSureAction)
    else
        if #tConfirmList <= 0 then
            return
        end

        local fnSureAction = function()
            RemoteCallToServer("On_Skill_SetNewTalent", tConfirmList)
        end
        local szMsg = FormatString(g_tStrings.SKILL_TEACH_CONFIRM_QIXUE, nCostTrain)
        UIHelper.ShowConfirm(szMsg, fnSureAction)
    end
end

function ConfirmCheckRecipe(tSkillRecipeList, bNoMessage)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if g_pClientPlayer and g_pClientPlayer.bFightState then
        TipsHelper.ShowImportantYellowTip("战斗状态中不能切换")
        return
    end
    
    local function fnSureAction()
        for dwSkillID, tRecipeList in pairs(tSkillRecipeList) do
            --先卸所有秘籍
            for i, tRecipe in ipairs(tRecipeList) do
                if tRecipe.active then
                    player.DeactiveSKillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
                end
            end

            --按照优先级装四本
            local nActiveCount = 0
            for i, tRecipe in ipairs(tRecipeList) do
                if nActiveCount < 4 then
                    local nRetCode = player.ActiveSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
                    if nRetCode == SKILL_RECIPE_RESULT_CODE.SUCCESS then
                        nActiveCount = nActiveCount + 1
                    end
                end
            end
            FireUIEvent("MYSTIQUE_ACTIVE_UPDATE", dwSkillID)
        end
        FireEvent("ON_ACTIVE_SKILL_RECIPE")
    end

    if bNoMessage then
        fnSureAction()
        return
    end

    UIHelper.ShowConfirm(g_tStrings.SKILL_RECIPE_TEACH_CONFIRM_MIJI, fnSureAction)
end


---@class UIPanelDXSkillRecommend
local UIPanelSkillRecommendDX = class("UIPanelSkillRecommendDX")

function UIPanelSkillRecommendDX:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationMiJing)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationJingJi)
end

function UIPanelSkillRecommendDX:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIPanelSkillRecommendDX:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogNavigationMiJing, EventType.OnSelectChanged, function(_, bSel)
        if bSel then
            self:UpdatePVEInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigationJingJi, EventType.OnSelectChanged, function(_, bSel)
        if bSel then
            self:UpdatePVPInfo()
        end
    end)
end

function UIPanelSkillRecommendDX:RegEvent()
    Event.Reg(self, "ON_ACTIVE_SKILL_RECIPE", function()
        TipsHelper.ShowImportantBlueTip("秘籍应用成功")
    end)

    Event.Reg(self, "ON_UPDATE_TALENT", function()
        TipsHelper.ShowImportantBlueTip("奇穴应用成功")
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.SetOpacity(self.ScrollView, 0)
        Timer.DelAllTimer(self)
        Timer.AddFrame(self, 5, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
            UIHelper.SetOpacity(self.ScrollView, 255)
        end)
    end)
end

function UIPanelSkillRecommendDX:UpdatePVEInfo()
    UIHelper.RemoveAllChildren(self.ScrollView)

    local tTeachList = GetTeachList()
    local tInfo = tTeachList[1]

    local tQixueList = tInfo.tQixueList
    local tRecipeSkillList = tInfo.tRecipeSkillList

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillRecommendDXCell, self.ScrollView)

    local szTitle = UIHelper.GBKToUTF8(tInfo.szQixue)
    script:InitQixue(szTitle, tQixueList, true)

    script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillRecommendDXCell, self.ScrollView)
    local szDesc = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tInfo.szQixueDesc), false)
    script:InitMiji("秘籍推荐", tRecipeSkillList, szDesc)

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollView, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end

function UIPanelSkillRecommendDX:UpdatePVPInfo()
    UIHelper.RemoveAllChildren(self.ScrollView)

    local tTeachQixueRecommendList = GetTeachRecommendList()
    local tTeachTrueInfo = tTeachQixueRecommendList[1]
    for nQixueRecommendIndex = 1, tTeachTrueInfo.nGroup, 1 do
        local tQixueList = tTeachTrueInfo["tQixueList" .. nQixueRecommendIndex]
        local szTitle = UIHelper.GBKToUTF8(tTeachTrueInfo["szQixue" .. nQixueRecommendIndex])
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillRecommendDXCell, self.ScrollView)
        script:InitQixue(szTitle, tQixueList)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollView, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end

return UIPanelSkillRecommendDX
