-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoice
-- Date: 2022-12-22 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nSpecialSprintShortcutSlot = 22

local tSkillID2FightIndex = {
    [UI_SKILL_DASH_ID] = 18,
    [UI_SKILL_FUYAO_ID] = 24,
    [UI_SKILL_JUMP_ID] = 17,
}

---@class UIWidegtSkillKeyboardSettingMain
local UIWidgetSkillKeyboardSettingMain = class("UIWidgetSettingsSwitch")

function UIWidgetSkillKeyboardSettingMain:OnEnter(parentScript, bGamePad)
    if bGamePad then
        UIHelper.SetVisible(self.WidgetJoyStickTip, true)
        self.gamePadScript = UIHelper.GetBindScript(self.GamePadScriptNode)
        self.gamePadScript:OnEnter(parentScript)
        return
    end
    self.filterTogs = { self.TogMode1, self.TogMode2 }
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.parentScript = parentScript ---@type UIGameSettingView
    end
    self.nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMount().dwSkillID
    self.nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
    self.tSkillSlotScripts = {}
    self.bIsHD = SkillData.IsUsingHDKungFu()
    self.bShowFirstPage = true

    UIHelper.SetTouchEnabled(self.LayoutModList, true)

    Timer.AddFrame(self, 20, function()
        UIHelper.SetSelected(self.TogMode1, true)
    end)

    self:UpdateInfo()
end

function UIWidgetSkillKeyboardSettingMain:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSkillKeyboardSettingMain:BindUIEvent()
    for i = 1, 2 do
        local nIndex = i
        UIHelper.BindUIEvent(self.filterTogs[i], EventType.OnSelectChanged, function(tog, bSelected)
            if bSelected then
                UIHelper.SetVisible(self.WidgetCommonNode, nIndex ~= 3)
                UIHelper.SetVisible(self.WidgetSkillPanelNode, nIndex == 1)
                UIHelper.SetVisible(self.ScrollViewFightList, nIndex == 1)

                UIHelper.SetVisible(self.WidgetRightBottonFunctionNode, nIndex == 2)
                UIHelper.SetVisible(self.ScrollViewNomalList, nIndex == 2)
            end
        end)
    end
end

function UIWidgetSkillKeyboardSettingMain:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function(arg0, arg1)
        Timer.AddFrame(self, 5, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFightList)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDynamicList)
        end)
    end)

    Event.Reg(self, EventType.OnKeyboardSettingSwitchPage, function()
        self:SwitchPage()
    end)
end

function UIWidgetSkillKeyboardSettingMain:UnRegEvent()

end

function UIWidgetSkillKeyboardSettingMain:InitSkillSlots()
    for i = 1, #self.skillSlotParents, 1 do
        local nSlotIndex = i
        local nSkillID = nSlotIndex == UI_SKILL_UNIQUE_SLOT_ID and SkillData.GetUniqueSkillID(self.nCurrentKungFuID, self.nCurrentSetID)
                or SkillData.GetSlotSkillID(nSlotIndex, self.nCurrentKungFuID, self.nCurrentSetID)
        if nSkillID then
            local script = self.tSkillSlotScripts[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.skillSlotParents[i]) ---@type UIWidgetSkillCell
            script:UpdateInfo(nSkillID)
            script.nSlotIndex = i
            self.tSkillSlotScripts[i] = script

            UIHelper.SetLocalZOrder(script._rootNode, -1) --使按钮显示在按键映射标签下,触发技有背景 特殊处理
        end
    end

    UIHelper.SetVisible(self.BtnUniqueNode, self.tSkillSlotScripts[6] == nil)
    UIHelper.SetLocalZOrder(self.ImgUniqueSkillBg, -5)

    self:ApplyShortCut(self.skillSlotParents, SHORTCUT_KEY_BOARD_STATE.Fight, true)
    self:ApplyShortCut(self.normalParents, SHORTCUT_KEY_BOARD_STATE.Normal)
    self:ApplyShortCut(self.dynamicParents, SHORTCUT_KEY_BOARD_STATE.Normal)

    UIHelper.SetButtonState(self.BtnSprint, BTN_STATE.Disable, "轻功快捷键不可更改")
end

function UIWidgetSkillKeyboardSettingMain:ApplyShortCut(tList, nShortcutState, bIsSkill)
    for nIndex, tParent in ipairs(tList) do
        local widgetKeyBoard = UIHelper.FindChildByName(tParent, "WidgetKeyBoardKey")
        if widgetKeyBoard then
            local script = UIHelper.GetBindScript(widgetKeyBoard)
            for _, child in ipairs(UIHelper.GetChildren(widgetKeyBoard)) do
                local szName = UIHelper.GetName(child)
                if string.starts(szName, "ID") then
                    local tSpilt = string.split(szName, "_")

                    script:SetID(tonumber(tSpilt[2]), nShortcutState, false, SHORTCUT_SHOW_TYPE.KEYBOARD)
                    script:UpdateInfo()

                    if bIsSkill then
                        local tSkillScript = self.tSkillSlotScripts[nIndex]
                        if tSkillScript then
                            if VK_SPRINT_SHORTCUT_FUNC_NAME[tSkillScript.nSlotIndex] then
                                local nIndex = tSkillID2FightIndex[tSkillScript.nSkillID] or nSpecialSprintShortcutSlot
                                if nIndex then
                                    script:SetID(nIndex, nShortcutState, false, SHORTCUT_SHOW_TYPE.KEYBOARD)
                                    script:UpdateInfo()
                                end
                            end
                            script:SetKeyBoardProps(tSkillScript.TogSkill, tSkillScript.ImgHighLight)
                        end
                    end
                    break
                end
            end
        end
    end
end

function UIWidgetSkillKeyboardSettingMain:InitSkillSlotsDX()
    local nCommonScale = 0.7
    local listScript1 = UIHelper.AddPrefab(PREFAB_ID.WidgetSkilSwitchListDX, self.WidgetSkillSwitchListDX)
    local listScript2 = UIHelper.AddPrefab(PREFAB_ID.WidgetSkilSwitchListDX, self.WidgetSkillSwitchListDXSecond)
    local twoPageScripts = { listScript1, listScript2 }

    local slotParents = {}
    for _, listScript in ipairs(twoPageScripts) do
        for nIndex, tParent in ipairs(listScript.tSlots) do
            table.insert(slotParents, tParent)
        end
    end
    table.insert_tab(slotParents, self.skillSlotParentsDX)

    local nStartShortcutIndex = 49
    for i, parent in ipairs(slotParents) do
        local slotIndex = i
        local tSlotData = SkillData.GetDxSlotData(slotIndex, SkillData.GetCurrentDxSkillBarIndex())
        local script = self.tSkillSlotScripts[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent) ---@type UIWidgetSkillCell
        script.nSlotIndex = i
        script:UpdateInfoDX(tSlotData)
        self.tSkillSlotScripts[i] = script

        local nShortcutIndex = nStartShortcutIndex + i
        local keyboardScript = UIHelper.AddPrefab(PREFAB_ID.WidgetKeyBoardKey, parent) ---@type UIWidgetSkillCell
        if table.contain_value(SkillData.tDXSprintSlots, slotIndex) then
            nShortcutIndex = script.nSkillID and SkillData.tDXSkillID2FightIndex[script.nSkillID] or -1
        end

        keyboardScript:SetID(nShortcutIndex, SHORTCUT_KEY_BOARD_STATE.DXFight, false, SHORTCUT_SHOW_TYPE.KEYBOARD)
        keyboardScript:UpdateInfo()
        keyboardScript:SetKeyBoardProps(script.TogSkill, script.ImgHighLight)
        UIHelper.SetAnchorPoint(keyboardScript._rootNode, 0.5, 0.5)
        UIHelper.SetPositionX(keyboardScript._rootNode, UIHelper.GetWidth(parent) / 2)

        local nParentScale = UIHelper.GetScaleX(parent)
        local nFinaleTraverseScale = nCommonScale / nParentScale
        UIHelper.SetScale(keyboardScript._rootNode, nFinaleTraverseScale, nFinaleTraverseScale)
    end

    self:ApplyShortCut(self.normalParentsDX, SHORTCUT_KEY_BOARD_STATE.Normal)
    self:ApplyShortCut({ self.BtnSwitchPage }, SHORTCUT_KEY_BOARD_STATE.DXFight)
    self:ApplyShortCut(self.dynamicParents, SHORTCUT_KEY_BOARD_STATE.Normal)

    UIHelper.SetButtonState(self.BtnSprintDX, BTN_STATE.Disable, "轻功快捷键不可更改")
end

function UIWidgetSkillKeyboardSettingMain:UpdateInfo(bDynamic)
    UIHelper.SetVisible(self.WidgetMod, not bDynamic)

    UIHelper.SetVisible(self.WidgetMainCityActionBar, bDynamic)
    UIHelper.SetVisible(self.ScrollViewDynamicList, bDynamic)

    if bDynamic then
        UIHelper.SetVisible(self.WidgetCommonNode, false)
        UIHelper.SetVisible(self.WidgetSkillPanelNode, false)
        UIHelper.SetVisible(self.WidgetRightBottonFunctionNode, false)

        UIHelper.SetVisible(self.ScrollViewSkillList, false)
        UIHelper.SetVisible(self.ScrollViewFightList, false)
    else
        UIHelper.SetSelected(self.filterTogs[1], true)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFightList)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDynamicList)
end

function UIWidgetSkillKeyboardSettingMain:SwitchPage()
    self.bShowFirstPage = not self.bShowFirstPage
    UIHelper.SetVisible(self.WidgetSkillSwitchListDX, self.bShowFirstPage)
    UIHelper.SetVisible(self.WidgetSkillSwitchListDXSecond, not self.bShowFirstPage)
end

function UIWidgetSkillKeyboardSettingMain:Clear()
    if self.bIsHD then
        self:InitSkillSlotsDX()
    else
        self:InitSkillSlots()
    end
    UIHelper.SetVisible(self.WidgetSkillDX, self.bIsHD)
    UIHelper.SetVisible(self.WidgetSkill, not self.bIsHD)

    self.WidgetCommonNode = self.bIsHD and self.WidgetCommonDX or self.WidgetCommon
    self.WidgetSkillPanelNode = self.bIsHD and self.WidgetSkillPanelDX or self.WidgetSkillPanel
    self.WidgetRightBottonFunctionNode = self.bIsHD and self.WidgetRightBottonFunctionDX or self.WidgetRightBottonFunction

    UIHelper.RemoveAllChildren(self.ScrollViewSkillList)
    UIHelper.RemoveAllChildren(self.ScrollViewFightList)
    UIHelper.RemoveAllChildren(self.ScrollViewDynamicList)
end

return UIWidgetSkillKeyboardSettingMain