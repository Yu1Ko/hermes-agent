-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIPanelMijiSelectPop
local UIPanelMijiSelectPop = class("UIPanelMijiSelectPop")

function UIPanelMijiSelectPop:OnEnter(nSkillID, nSelectedKungFu)
    if not self.bInit then
        self.bInit = true
        self:RegEvent()
        self:BindUIEvent()

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutTrain)
        script:SetCurrencyType(CurrencyType.Train)
        script:HandleEvent()
    end

    if nSkillID and nSelectedKungFu then
        self.nSkillID = nSkillID
        self.nSelectedIndex = 1
        self.bIsCurrentKungFu = g_pClientPlayer.GetActualKungfuMount().dwSkillID == nSelectedKungFu
        self.nSelectedKungFu = nSelectedKungFu
        self.fnExitCallback = nil
        self.mijiScripts = {}

        self.dwLevel = g_pClientPlayer.GetSkillLevel(self.nSkillID) or 1
        if self.dwLevel == 0 then
            self.nSkillID = GetSkillRecipeMirror(self.nSkillID)
            self.dwLevel = g_pClientPlayer.GetSkillLevel(self.nSkillID)
        end

        local tSkill = SkillData.GetSkill(g_pClientPlayer, self.nSkillID, self.dwLevel)
        self.bIsHD = tSkill and tSkill.nPlatformType ~= SkillPlatformType.Mobile

        self:UpdateMiji()
        self:UpdateEquipButton()
    end
end

function UIPanelMijiSelectPop:InitDisplay(nSkillID)
    self.nSkillID = nSkillID
    self.nSelectedIndex = 1
    self.bIsCurrentKungFu = false
    self.mijiScripts = {}

    for i = 1, 2 do
        local compLuaBind = self.mijiPrefabs[i]:getComponent("LuaBind")
        local script = compLuaBind and compLuaBind:getScriptObject()
        table.insert(self.mijiScripts, script)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupConfiguration, self.mijiScripts[i]:GetToggle())
    end

    self:UpdateMiji(true, true)

    UIHelper.SetVisible(self.BtnEquip, false)

    if not self.bInit then
        self.bInit = true
        self:RegEvent()
        self:BindUIEvent()
    end
end

function UIPanelMijiSelectPop:InitDxRecommend(nSkillID)
    self.nSkillID = nSkillID
    self.bIsCurrentKungFu = false
    self.mijiScripts = {}
    
    self:UpdateMijiDX(true, true, GetSkillTeachRecipe(nSkillID, 1, true))

    UIHelper.SetVisible(self.BtnEquip, false)

    if not self.bInit then
        self.bInit = true
        self:RegEvent()
        self:BindUIEvent()
    end
end

function UIPanelMijiSelectPop:OnExit()
    local view = UIMgr.GetView(VIEW_ID.PanelSkillInfo)
    local script = view and view.scriptView ---@type  UIPanelSkillInfo
    if script then
        script:UpdateInfo()
    end
    --
    --if self.fnExitCallback then
    --    self.fnExitCallback()
    --end

    self.bInit = false
    self:UnRegEvent()
end

function UIPanelMijiSelectPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
        self:ActiveMiJiVK(self.tRecipes, self.nSelectedIndex)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose1, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelMijiSelectPop:RegEvent()
    Event.Reg(self, "SKILL_RECIPE_LIST_UPDATE", function(arg0, arg1, arg2)
        Timer.AddFrame(self, 2, function()
            OutputMessage("MSG_ANNOUNCE_NORMAL", "秘籍操作成功")
            if not self.bIsHD then
                UIMgr.Close(self)
            else
                self:UpdateMijiDX(false)
            end
        end)
    end)
end

function UIPanelMijiSelectPop:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelMijiSelectPop:UpdateMiji(bUpdateChild, bDisplayOnly)
    if not self.bIsHD then
        self:UpdateMijiVK(bUpdateChild, bDisplayOnly)
    else
        self:UpdateMijiDX(bUpdateChild, bDisplayOnly)
    end

    UIHelper.SetVisible(self.LabelCount, self.bIsHD)
    UIHelper.SetVisible(self.WidgetVkParent, not self.bIsHD)
    UIHelper.SetVisible(self.WidgetDXParent, self.bIsHD)
end

function UIPanelMijiSelectPop:UpdateMijiVK(bUpdateChild, bDisplayOnly)
    self.tRecipes = SkillData.GetFinalRecipeList(self.nSkillID)

    if bDisplayOnly then
        self.tRecipes[1].active = false
        self.tRecipes[2].active = false
    end

    if bUpdateChild ~= false then
        for i = 1, 2 do
            local script = UIHelper.GetBindScript(self.mijiPrefabs[i])
            local toggle = script:GetToggle()
            table.insert(self.mijiScripts, script)

            UIHelper.ToggleGroupAddToggle(self.ToggleGroupConfiguration, toggle)
            UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(toggle, bSelected)
                if bSelected then
                    self.nSelectedIndex = i
                    self:UpdateEquipButton()
                end
            end)
        end

        SkillData.ClearSpecialNoun(self)
        self.mijiScripts[1]:UpdateInfo(self.tRecipes[1])
        self.mijiScripts[2]:UpdateInfo(self.tRecipes[2])

        for i = 1, 2 do
            if self.tRecipes[i].active then
                UIHelper.SetToggleGroupSelected(self.ToggleGroupConfiguration, i - 1)
                self.nSelectedIndex = i
                break
            end
        end
    end

    for i = 1, 2 do
        local tFrame = self.mijiScripts[i].ImgSelectFrame
        UIHelper.SetVisible(tFrame, self.tRecipes[i].active)
    end
end

function UIPanelMijiSelectPop:UpdateMijiDX(bUpdateChild, bDisplayOnly, tRecipes)
    self.tRecipes = tRecipes or SkillData.GetFinalRecipeList(self.nSkillID)

    if bUpdateChild ~= false then
        SkillData.ClearSpecialNoun(self)

        for nIndex, tRecipe in ipairs(self.tRecipes) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetDXMijiCell, self.ScrollViewDXMijiCellList)
            script:UpdateInfo(tRecipe)
            if not bDisplayOnly and self.bIsCurrentKungFu then
                script:BindClickCallback(function()
                    self:SwitchMiJi(tRecipe)
                end)
            end
            table.insert(self.mijiScripts, script)
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDXMijiCellList)
        UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewDXMijiCellList, false)
    end

    local nCount = 0
    for nIndex, tRecipe in ipairs(self.tRecipes) do
        local script = self.mijiScripts[nIndex]
        if not bDisplayOnly and self.bIsCurrentKungFu then
            script:BindClickCallback(function()
                if tRecipe.bHave then
                    self:SwitchMiJi(tRecipe)
                else
                    self:LearnMiji(tRecipe)
                end
            end)
        end

        UIHelper.SetNodeGray(script._rootNode, not tRecipe.bHave, true)

        local tFrame = script.ImgSelectFrame
        if bDisplayOnly then
            UIHelper.SetVisible(tFrame, false)
        else
            local bSelected = tRecipe.active or false
            UIHelper.SetVisible(tFrame, bSelected)
        end

        if tRecipe.active then
            nCount = nCount + 1
        end
    end

    UIHelper.SetLabel(self.LabelCount, string.format("( %d/4 )", nCount))
end

function UIPanelMijiSelectPop:UpdateEquipButton()
    local szLabel = "装备秘籍"
    if self.tRecipes[self.nSelectedIndex].active then
        szLabel = "卸下秘籍"
    end
    UIHelper.SetString(self.LabelEquip, szLabel)

    local bDead = g_pClientPlayer and
            (g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH or g_pClientPlayer.nMoveState == MOVE_STATE.ON_AUTO_FLY)
    local szDeath = g_tStrings.STR_DEAD_OR_AUTO_FLY
    UIHelper.SetButtonState(self.BtnEquip,
            (not bDead and self.bIsCurrentKungFu) and BTN_STATE.Normal or BTN_STATE.Disable, function()
                OutputMessage("MSG_ANNOUNCE_NORMAL", bDead and szDeath or "应用本心法后可配置")
            end)
end

function UIPanelMijiSelectPop:ActiveMiJiVK(tRecipes, nSelectedIndex)
    if not tRecipes or not nSelectedIndex or not tRecipes[nSelectedIndex] then
        LOG.ERROR("UIPanelSkillLeftPop:ActiveMiJi tRecipe invalid")
        return
    end

    if not ArenaData.IsCanChangeSkillRecipe() then
        TipsHelper.ShowImportantRedTip("比赛即将开始或正在进行中，无法切换招式奇穴")
        return
    end

    local tRecipe = tRecipes[nSelectedIndex]
    -----遗忘秘籍
    if tRecipe.active then
        local nRetCode = g_pClientPlayer.DeactiveSKillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
        if nRetCode ~= SKILL_RECIPE_RESULT_CODE.SUCCESS then
            if nRetCode == SKILL_RECIPE_RESULT_CODE.ERROR_IN_FIGHT then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_INFIGHT_OFF)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_UNKNOWN_OFF)
            end
        else
            Event.Dispatch("MYSTIQUE_ACTIVE_UPDATE", self.nSkillID)
        end
    end

    if not tRecipe.active then
        local nRetCode = g_pClientPlayer.ActiveSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
        if nRetCode ~= SKILL_RECIPE_RESULT_CODE.SUCCESS then
            if nRetCode == SKILL_RECIPE_RESULT_CODE.ERROR_IN_FIGHT then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_INFIGHT_ON)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_UNKNOWN_ON)
            end
        else
            Event.Dispatch("MYSTIQUE_ACTIVE_UPDATE", self.nSkillID)
        end
    end
end

function UIPanelMijiSelectPop:SwitchMiJi(tRecipe)
    if not tRecipe then
        LOG.ERROR("UIPanelSkillLeftPop:ActiveMiJi tRecipe invalid")
        return
    end

    if not ArenaData.IsCanChangeSkillRecipe() then
        TipsHelper.ShowImportantRedTip("比赛即将开始或正在进行中，无法切换招式奇穴")
        return
    end

    local fnAction
    if not tRecipe.active then
        fnAction = g_pClientPlayer.ActiveSkillRecipe
    else
        fnAction = g_pClientPlayer.DeactiveSKillRecipe
    end

    local nRetCode = fnAction(tRecipe.recipe_id, tRecipe.recipe_level)
    if nRetCode ~= SKILL_RECIPE_RESULT_CODE.SUCCESS then
        if nRetCode == SKILL_RECIPE_RESULT_CODE.ERROR_IN_FIGHT then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_INFIGHT_ON)
        else
            print(nRetCode)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_UNKNOWN_ON)
        end
    else
        Event.Dispatch("MYSTIQUE_ACTIVE_UPDATE", self.nSkillID)
    end
end

function UIPanelMijiSelectPop:LearnMiji(tRecipe)
    if not tRecipe then
        LOG.ERROR("UIPanelSkillLeftPop:ActiveMiJi tRecipe invalid")
        return
    end

    if not ArenaData.IsCanChangeSkillRecipe() then
        TipsHelper.ShowImportantRedTip("比赛即将开始或正在进行中，无法切换招式奇穴")
        return
    end

    local tSkillRecipe = Table_GetSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
    local szName = FormatString(g_tStrings.STR_BRACKETS, UIHelper.GBKToUTF8(tSkillRecipe.szName))
    local szText = string.format("确定消耗%s修为领悟秘籍：%s", UIHelper.AttachTextColor(tSkillRecipe.nTrainCost, FontColorID.ImportantYellow), szName)
    local nCurrentTrain = g_pClientPlayer.nCurrentTrainValue
    local myTrain = string.format("当前拥有的修为：%d", nCurrentTrain)
    szText = szText .. "\n" .. myTrain

    local fnConfirm = function()
        if tSkillRecipe.nTrainCost > nCurrentTrain then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.NEW_SKILL_RECIPE_OPEN_LESS_TRAIN_VALUE)
            OutputMessage("MSG_SYS", g_tStrings.NEW_SKILL_RECIPE_OPEN_LESS_TRAIN_VALUE)
            return
        end
        RemoteCallToServer("On_Skill_LearnRecipe", self.nSkillID, tRecipe.recipe_id, tRecipe.recipe_level)
    end

    UIHelper.ShowConfirm(szText, fnConfirm, nil, true)

end

return UIPanelMijiSelectPop
