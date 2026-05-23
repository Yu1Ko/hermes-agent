-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAcupointTip
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class WidgetSkillInfoTips
local WidgetSkillInfoTips = class("WidgetSkillInfoTips")

local SPECIAL_ORDER = 11
local SHOW_SCROLL_GUILD_CRITICAL_VALUE = -30
local tIndexToName = {
    [1] = "壹式",
    [2] = "贰式",
    [3] = "叁式",
    [4] = "肆式",
    [5] = "伍式",
    [6] = "陆式",
}

local tLevelToName = {
    [1] = "一",
    [2] = "二",
    [3] = "三",
    [4] = "四",
    [5] = "五",
    [6] = "六",
    [7] = "七",
    [8] = "八",
    [9] = "九",
    [10] = "十",
}

local nShortHeight = 385
local nLongHeight = 530

function WidgetSkillInfoTips:OnEnter(nSkillID, nCurrentKungFuID, nCurrentSetID, nSkillLevel, nFakeMijiIndex)
    if not self.bInit then
        self:RegEvent()
        self.bInit = true
        
        print(nSkillID)

        local tHideTouchDownList = {
            self.BtnEquip, self.BtnEquipMiji, self.ScrollViewSkillDetailsList, self.BtnTraceQuest }
        for _, node in ipairs(tHideTouchDownList) do
            UIHelper.SetTouchDownHideTips(node, false)
        end
    end

    if not nSkillID then
        return
    end

    self:BindUIEvent()

    self.nIndex = 1
    self.nSkillID = nSkillID
    self.nMainSkillID = nSkillID
    self.nSkillLevel = nSkillLevel or math.max(1, g_pClientPlayer.GetSkillLevel(self.nSkillID))
    self.nCurrentKungFuID = nCurrentKungFuID or g_pClientPlayer.GetActualKungfuMount().dwSkillID
    self.nCurrentSetID = nCurrentSetID or
            g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
    self.bApplyExitFunc = true
    self.nFakeMijiIndex = nFakeMijiIndex or -1 -- 用于展示特定的秘籍信息
    self.bBaiZhan = #Table_GetMonsterSkillInfo(self.nSkillID) ~= 0
    self.bTreasureBFDynamic = TreasureBattleFieldSkillData.IsInDynamic() or
            UIMgr.IsViewOpened(VIEW_ID.PanelImpasseSkills)
    self.bDisplayOnly = false
    self.bShowQiXueModification = true

    self:InitMijiScript()
    self:PlayAnim()
    self:UpdateSkillList()
    self:UpdateInfo()
    self:UpdateToggles()
end

function WidgetSkillInfoTips:InitDisplayOnly(nSkillID, nCurrentKungFuID, nFakeMijiIndex, targetPlayer)
    if not nSkillID then
        return
    end

    self:BindUIEvent()

    self.nIndex = 1
    self.nSkillID = nSkillID
    self.nMainSkillID = nSkillID
    self.nSkillLevel = 1
    self.nCurrentKungFuID = nCurrentKungFuID
    self.nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
    self.bApplyExitFunc = true
    self.nFakeMijiIndex = nFakeMijiIndex or -1
    self.bBaiZhan = false
    self.bDisplayOnly = true
    self.bShowQiXueModification = targetPlayer ~= nil
    self.player = targetPlayer

    self:InitMijiScript()
    self:PlayAnim()
    self:UpdateSkillList()
    self:UpdateInfo()
    self:UpdateToggles()
end

function WidgetSkillInfoTips:InitMijiScript()
    self.tMijiScripts = {}
    local bIsHD = TabHelper.IsHDKungfuID(self.nCurrentKungFuID)
    if bIsHD then
        for i = 1, 4 do
            table.insert(self.tMijiScripts, UIHelper.GetBindScript(self.tDXMijiWidgets[i]))
        end
    else
        table.insert(self.tMijiScripts, UIHelper.GetBindScript(self.WidgetMiji))
    end

    UIHelper.SetVisible(self.LayoutMiJiDX, bIsHD)
    UIHelper.SetVisible(UIHelper.GetParent(self.WidgetMiji), not bIsHD)
end

function WidgetSkillInfoTips:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
    if self.bApplyExitFunc and self.fnExit then
        self.fnExit()
        self.fnExit = nil
    end
end

function WidgetSkillInfoTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        self:ShowMiJiTip()
    end)

    UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
        self.fnEquip()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)

    UIHelper.BindUIEvent(self.BtnEquipMiji, EventType.OnClick, function()
        --    UIMgr.Open(VIEW_ID.PanelMijiSelectPop, self.nSkillID)
        self.fnEquipMiji()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)
end

function WidgetSkillInfoTips:RegEvent()
    Event.Reg(self, "ON_SKILL_REPLACE", function(arg0, arg1, arg2)
        LOG.WARN("ON_SKILL_REPLACE UIPanelSkillLeftPop %d %d", arg0, arg1)
        if arg0 == self.nSkillID then
            self.nSkillID = arg1
            self:UpdateInfo()
        end
    end)
end

function WidgetSkillInfoTips:UpdateInfo()
    if self.nSkillID then
        self:UpdateBasicInfo()
        self:UpdateMiJiInfo()
        self:UpdateQuestInfo()
        self:UpdateDetailInfo()

        local bHasButton = self.fnEquip ~= nil
        local bShowMijiWidget = self.nFakeMijiIndex == -1 and (#self.tRecipes > 0 and self.nIndex <= 1)
        local bLearned = self.bDisplayOnly or g_pClientPlayer.GetSkillLevel(self.nSkillID) > 0
        local bForbidShowMiji = self.bForbidShowMiji or false
        UIHelper.SetVisible(self.WidgetMijiParent, not bHasButton and bShowMijiWidget and bLearned and not bForbidShowMiji)

        UIHelper.SetHeight(self.ScrollViewSkillDetailsList,
                (bHasButton or bShowMijiWidget) and nShortHeight or nLongHeight)

        UIHelper.ScrollViewDoLayout(self.ScrollViewSkillDetailsList)
        UIHelper.ScrollToTop(self.ScrollViewSkillDetailsList, 0)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
        UIHelper.LayoutDoLayout(self.LayoutAll)

        Timer.AddFrame(self, 1, function()
            self:UpdateScrollGuild()
        end)
    end
end

function WidgetSkillInfoTips:UpdateMiJiInfo()
    if not self.nSkillID or self.nIndex > 1 then
        return
    end

    local tList = SkillData.GetFinalRecipeList(self.nSkillID, self.player)

    self.nActivated = 0
    self.nRecipeCount = 0
    self.tRecipes = {}

    for _, tRecipe in ipairs(tList) do
        self.nRecipeCount = self.nRecipeCount + 1
        if self.bDisplayOnly then
            tRecipe.active = false
        end

        if tRecipe.active then
            local script = self.tMijiScripts[self.nActivated + 1]
            local tSkillRecipe = Table_GetSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
            UIHelper.SetItemIconByIconID(script.ImgIcon, tSkillRecipe.nIconID)
            UIHelper.SetVisible(script.ImgIcon, true)
            UIHelper.SetVisible(script.ImgRedPoint, false)
            self.nActivated = self.nActivated + 1
        end
        table.insert(self.tRecipes, tRecipe)
    end
    UIHelper.LayoutDoLayout(self.LayoutMiJi)

    for i = 1, #self.tMijiScripts do
        local script = self.tMijiScripts[i]
        UIHelper.BindUIEvent(script.BtnMiji, EventType.OnClick, function()
            self:ShowMiJiTip()
        end)
        UIHelper.SetVisible(script._rootNode, #self.tRecipes > 0)
    end
end

function WidgetSkillInfoTips:UpdateQuestInfo()
    if not self.nSkillID then
        return
    end

    if OBDungeonData.IsPlayerInOBDungeon() then
        -- 观战模式不展示任务引导
        return
    end

    local bLearned = g_pClientPlayer.GetSkillLevel(self.nSkillID) > 0
    local szQuestList = not bLearned and Table_GetSkillQuestList(self.nSkillID)
    if szQuestList and szQuestList ~= "" then
        local dwQuestID = GetLastTrackID(szQuestList)
        if dwQuestID then
            local tQuestString = Table_GetQuestStringInfo(dwQuestID)
            local szQuestName = UIHelper.GBKToUTF8(tQuestString and tQuestString.szName or "")
            local szTip = FormatString(g_tStrings.NEW_SKILL_MKUNGFU_QUEST_TIP, szQuestName)
            UIHelper.SetLabel(self.LabelQuestInfo, szTip)
        end
    end
    
    UIHelper.SetVisible(self.WidgetSkillLock, not self.bDisplayOnly and not bLearned and (szQuestList and szQuestList ~= ""))
    UIHelper.BindUIEvent(self.BtnTraceQuest, EventType.OnClick, function()
        if szQuestList and szQuestList ~= "" then
            local dwQuestID = GetQuestTrackID(szQuestList)
            if dwQuestID then
                MapMgr.TransferToNearestCity(dwQuestID)
            end
        end
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)
end

function WidgetSkillInfoTips:ShowMiJiTip()
    if not self.bDisplayOnly then
        UIMgr.Open(VIEW_ID.PanelMijiSelectPop, self.nSkillID, self.nCurrentKungFuID)
    else
        local script = UIMgr.Open(VIEW_ID.PanelMijiSelectPop)
        script:InitDisplay(self.nSkillID)
    end

    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
end

function WidgetSkillInfoTips:UpdateBasicInfo()
    UIHelper.RemoveAllChildren(self.WIdgetSkillCell)
    UIHelper.SetVisible(self.ImgType, false)

    local nSkillLevel = self.nSkillLevel
    local tSkillInfo = TabHelper.GetUISkill(self.nSkillID)

    if tSkillInfo then
        local nOrder = tSkillInfo.nAppendSkillOrder
        local szName = tSkillInfo.szName
        if nOrder < SPECIAL_ORDER then
            if tSkillInfo.tbParentSkillID and #tSkillInfo.tbParentSkillID >= 1 then
                local nIndex = table.get_key(self.tMainSkillChildGroupList, self.nSkillID)
                szName = tIndexToName[nIndex]
            end
        end
        UIHelper.SetString(self.LabelSkillName, szName)
        UIHelper.SetString(self.LabelSkillType, tSkillInfo.szSkillDefinition)
        UIHelper.SetVisible(self.ImgType, not string.is_nil(tSkillInfo.szSkillDefinition)) -- 获取到配置的类型后才显示
    else
        local szName = Table_GetSkillName(self.nSkillID, nSkillLevel)
        UIHelper.SetString(self.LabelSkillName, UIHelper.GBKToUTF8(szName))
    end

    local iconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.WIdgetSkillCell, self.nSkillID, nSkillLevel)
    iconScript:SetSelectEnable(false)
    iconScript:HideLabel(false)

    local szCoolDown = SkillData.GetSkillCDDesc(self.nSkillID, nSkillLevel, self.player)

    local szText = self.bBaiZhan and string.format("第%s重", tLevelToName[nSkillLevel]) or
            string.format("等级 %d", nSkillLevel)
    UIHelper.SetString(self.LabelSkillLevel, szText)
    UIHelper.SetVisible(self.LabelSkillLevel, self.bBaiZhan)

    UIHelper.SetString(self.LabelSkillTime, szCoolDown)
    UIHelper.LayoutDoLayout(self.LayoutSkillTitle)
end

function WidgetSkillInfoTips:UpdateDetailInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewSkillDetailsList)
    SkillData.ClearSpecialNoun()

    local tSkillInfo = TabHelper.GetUISkill(self.nSkillID)
    local hPlayer = g_pClientPlayer

    if self.player and OBDungeonData.IsPlayerInOBDungeon() then
        hPlayer = self.player
    end

    if not tSkillInfo then
        local szTip = ""  --- 动态技能相关展示

        if self.bBaiZhan then
            -- 是百战技能就处理一下占位符问题
            szTip = GetSkillDesc(self.nSkillID, self.nSkillLevel, nil, nil, true)
            szTip = UIHelper.GBKToUTF8(szTip)
            if szTip then
                UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList, szTip, false, false)
            end
        elseif self.bTreasureBFDynamic then
            szTip = GetSkillDesc(self.nSkillID, self.nSkillLevel, nil, nil, false)
            szTip = UIHelper.GBKToUTF8(szTip)
            if szTip then
                UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList, szTip, false, false)
            end
        else
            local nSkillLevel = self.nSkillLevel or hPlayer.GetSkillLevel(self.nSkillID)
            local tRecipeKey = hPlayer.GetSkillRecipeKey(self.nSkillID, nSkillLevel)
            local dwID = tRecipeKey.skill_id
            local nLevel = tRecipeKey.skill_level
            local hSkillInfo = GetSkillInfoEx(tRecipeKey, hPlayer.dwID)
            local tDescSkillInfo = Table_GetSkill(self.nSkillID, self.nSkillLevel)
            local szBasic = GetDxBasicTips(dwID, nLevel, tDescSkillInfo, tRecipeKey, true, nil, hPlayer)
            if szBasic and szBasic ~= "" then
                szTip = szTip .. UIHelper.AttachTextColor(ParseTextHelper.ParseNormalText(szBasic), FontColorID.Text_Level2_Backup) .. "\n"
            end

            if tDescSkillInfo and tDescSkillInfo.szSpecialDesc ~= "" then
                local szConverted = (UIHelper.GBKToUTF8(tDescSkillInfo.szSpecialDesc) .. "\n")
                szTip = szTip .. UIHelper.AttachTextColor(szConverted, FontColorID.ValueChange_Blue)
            end

            local szDesc1, szAdditionalDesc1 = GetSkillDesc(self.nSkillID, nSkillLevel, tRecipeKey, hSkillInfo, false)
            szDesc1 = szDesc1 and UIHelper.GBKToUTF8(szDesc1)
            if szDesc1 then
                szTip = szTip .. (szDesc1)
                szTip = SkillData.FormSpecialNoun(szTip, self.nSkillID)
                UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList, szTip, false, false)
            end

            if szAdditionalDesc1 and szAdditionalDesc1 ~= "" then
                local szConverted = SkillData.FormSpecialNoun(UIHelper.GBKToUTF8(szAdditionalDesc1), self.nSkillID)
                local szSplited = string.split(szConverted, "\n")
                for _, szline in ipairs(szSplited) do
                    if szline ~= "" then
                        UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeAddCell, self.ScrollViewSkillDetailsList, szline, false, false)
                    end
                end
            end

            if tRecipeKey then
                local szRecipeDesc, szRecipeList = FormatRecipeList(tRecipeKey)
                if szRecipeDesc ~= "" then
                    local szConverted = SkillData.FormSpecialNoun(UIHelper.GBKToUTF8(szRecipeDesc), self.nSkillID)
                    local szSplited = string.split(szConverted, "\n")
                    for _, szline in ipairs(szSplited) do
                        if szline ~= "" then
                            UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeAddCell, self.ScrollViewSkillDetailsList, szline, true, false)
                        end
                    end
                end
            end

            if tDescSkillInfo and tDescSkillInfo.szHelpDesc ~= "" then
                UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList, UIHelper.GBKToUTF8(tDescSkillInfo.szHelpDesc), false, false)
            end
        end
        return
    end

    local szDesc1 = tSkillInfo.szDesc
    szDesc1 = SkillData.FormSpecialNoun(szDesc1, self.nSkillID)
    szDesc1 = SkillData.ProcessSkillPlaceholder(szDesc1)
    UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList, szDesc1, false, false)

    local nCount = 1
    for i = 1, SKILL_INFO_DESC_NUM do
        local szDesc = tSkillInfo.tbSkillEffectDesc[i]
        if szDesc then
            szDesc = SkillData.FormSpecialNoun(szDesc, self.nSkillID)
            UIHelper.AddPrefab(PREFAB_ID.WidgetListAttributeCell, self.ScrollViewSkillDetailsList, szDesc, nCount, true)
            nCount = nCount + 1
        end
    end

    if self.nIndex > 1 then
        return
    end

    local nActiveMijiID
    for nIndex, tRecipe in ipairs(self.tRecipes) do
        local bShow = tRecipe.active
        if self.nFakeMijiIndex ~= -1 then
            bShow = self.nFakeMijiIndex == nIndex
        end
        if bShow then
            nActiveMijiID = tRecipe.recipe_id
            local tSkillRecipe = Table_GetSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
            local szDesc = UIHelper.GBKToUTF8(tSkillRecipe.szDesc)
            szDesc = SkillData.FormSpecialNoun(szDesc, self.nSkillID)
            szDesc = SkillData.ProcessSkillPlaceholder(szDesc)
            UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeAddCell, self.ScrollViewSkillDetailsList, szDesc, true, false)
        end
    end

    local tSkillID2QiXueID = SkillData.GetQiXueModifiedSkillIDList(self.nCurrentKungFuID, self.nCurrentSetID, self.player)
    local tInfoList = tSkillID2QiXueID[self.nSkillID]
    if tInfoList and self.bShowQiXueModification then
        for _, tInfo in ipairs(tInfoList) do
            local nQiXueID = tInfo.nQiXueID
            local nMijiID = tInfo.nMijiID
            local tQiXueSkillInfo = TabHelper.GetUISkillMap(nQiXueID)
            if tQiXueSkillInfo and tQiXueSkillInfo.szDesc and (not nMijiID or nActiveMijiID == nMijiID) then
                --local szDesc = tQiXueSkillInfo.tbSkillEffectDesc[self.nSkillID]
                ----LOG.WARN("Current Qixue  Desc is %s", szDesc)
                local szDesc = SkillData.FormSpecialNoun(tQiXueSkillInfo.szDesc, nQiXueID)
                UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeAddCell, self.ScrollViewSkillDetailsList, szDesc, false, false)
            end
        end
    end
end

function WidgetSkillInfoTips:UpdateSkillList()
    self.tAppendSkillDict = SkillData.GetAppendSkillDict(self.nCurrentKungFuID, self.bDisplayOnly)
    self.tMainSkillChildGroupList = {}

    local tSkillInfo = TabHelper.GetUISkill(self.nMainSkillID)
    local nMainSkill = self.nMainSkillID
    if tSkillInfo and tSkillInfo.tbParentSkillID and #tSkillInfo.tbParentSkillID >= 1 then
        nMainSkill = tSkillInfo.tbParentSkillID[1]
    end
    local tAvailableSkillList = self.tAppendSkillDict[nMainSkill] or {}
    if #tAvailableSkillList > 0 then
        table.insert_tab(self.tMainSkillChildGroupList, tAvailableSkillList)
        table.insert(self.tMainSkillChildGroupList, 1, nMainSkill)
    end
end

function WidgetSkillInfoTips:UpdateToggles()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    UIHelper.RemoveAllChildren(self.LayoutToggle)

    local tAvailableSkillList = self.tAppendSkillDict[self.nSkillID] or {}
    if #tAvailableSkillList > 0 then
        table.insert(tAvailableSkillList, 1, self.nMainSkillID) -- 将主技能加入tog生成
        for nIndex, nSkillID in ipairs(tAvailableSkillList) do
            local nOrder = TabHelper.GetUISkillMap(nSkillID).nAppendSkillOrder
            local szName = nOrder >= SPECIAL_ORDER and "特殊" or tIndexToName[nIndex]
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillTipTog, self.LayoutToggle)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, script.TogFold)
            UIHelper.SetTouchDownHideTips(script.TogFold, false)
            UIHelper.SetString(script.LabelSelect, szName)
            UIHelper.SetString(script.LabelFold, szName)
            UIHelper.BindUIEvent(script.TogFold, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    self.nSkillID = nSkillID
                    self.nIndex = nIndex
                    self:UpdateInfo()
                end
            end)

            if nIndex == 1 then
                UIHelper.SetSelected(script.TogFold, true, false)
            end
        end
        UIHelper.LayoutDoLayout(self.LayoutToggle)
    end
    UIHelper.SetVisible(self.WidgetTitleTog, #tAvailableSkillList > 0)
end

function WidgetSkillInfoTips:SetBtnVisible(bVisible)
    UIHelper.SetVisible(self.WidgetBtn, bVisible)
end

function WidgetSkillInfoTips:SetLeftButtonInfo(szLabel, fnFunc, bEnabled)
    UIHelper.SetString(self.LabelEquip1, szLabel)
    UIHelper.SetVisible(self.BtnEquip, true)
    if IsFunction(fnFunc) then
        self.fnEquip = fnFunc
    end

    --Timer.AddFrame(self,1,function()
    --    UIHelper.SetHeight(self.ScrollViewSkillDetailsList, nShortHeight)
    --    UIHelper.ScrollViewDoLayout(self.ScrollViewSkillDetailsList)
    --    UIHelper.ScrollToTop(self.ScrollViewSkillDetailsList, 0)
    --end)
end

function WidgetSkillInfoTips:SetRightButtonInfo(szLabel, fnFunc)
    UIHelper.SetString(self.LabelEquip2, szLabel)
    UIHelper.SetVisible(self.BtnEquipMiji, true)
    if IsFunction(fnFunc) then
        self.fnEquipMiji = fnFunc
    end
end

function WidgetSkillInfoTips:HideMiji()
    UIHelper.SetVisible(self.WidgetMijiParent, false)
end

function WidgetSkillInfoTips:SetForbidShowMiji(bForbid)
    self.bForbidShowMiji = bForbid
end

function WidgetSkillInfoTips:BindExitFunc(fnFunc)
    if IsFunction(fnFunc) then
        self.fnExit = fnFunc
    end
end

function WidgetSkillInfoTips:PlayAnim()
    if not self.bPlayAni then
        self.bPlayAni = true
        UIHelper.SetOpacity(self.AniTip, 0) --设置初始状态，防止闪
        Timer.Add(self, 0.05, function()
            UIHelper.PlayAni(self, self.AniTip, "AniItemTip", function()
                self.bPlayAni = false
            end)
        end)
    end
end

function WidgetSkillInfoTips:UpdateScrollGuild()
    local bCanSlide = UIHelper.GetScrollViewSlide(self.ScrollViewSkillDetailsList, _, SHOW_SCROLL_GUILD_CRITICAL_VALUE)
    self.bFirstSlide = self.bFirstSlide or true
    UIHelper.SetVisible(self.WidgetArrow, false)
    if bCanSlide and self.bFirstSlide then
        UIHelper.SetVisible(self.WidgetArrow, true)
        UIHelper.ScrollToTop(self.ScrollViewSkillDetailsList, 0)
        UIHelper.BindUIEvent(self.ScrollViewSkillDetailsList, EventType.OnScrollingScrollView, function(_, eventType)
            -- local nScrollPercent = UIHelper.GetScrollPercent(self.ScrollViewSkillDetailsList)
            if eventType == ccui.ScrollviewEventType.scrollToBottom then
                UIHelper.SetVisible(self.WidgetArrow, false)
                self.bFirstSlide = false
            end
            UIHelper.UnBindUIEvent(self.ScrollViewSkillDetailsList, EventType.OnScrollingScrollView)
        end)
    end
end

function WidgetSkillInfoTips:ShowSkillType(bShow)
    UIHelper.SetVisible(self.ImgType, bShow)
end

return WidgetSkillInfoTips
