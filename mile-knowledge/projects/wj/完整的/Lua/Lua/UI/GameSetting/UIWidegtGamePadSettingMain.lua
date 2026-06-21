-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetGamePadSettingMain
-- Date: 2024-8-9 16:19:35
-- Desc: UIWidgetGamePadSettingMain
-- ---------------------------------------------------------------------------------

local nSpecialSprintShortcutSlot = 22

local tSkillID2FightIndex = {
    [UI_SKILL_DASH_ID] = 18,
    [UI_SKILL_FUYAO_ID] = 24,
    [UI_SKILL_JUMP_ID] = 17,
}


local GAME_PAD_SHORTCUT_PREFAB_ID_MAP = {
    PREFAB = {
        --@ PREFAB_ID or VIEW_ID
        ["WidgetRightBottonFunction"] = {
            ["FunctionSlot1"] = 1,
            ["FunctionSlot2"] = 2,
            ["FunctionSlot3"] = 3,
            ["FunctionSlot4"] = 4,
            ["FunctionSlot5"] = 5,
            ["FunctionSlot6"] = 6,
            ["FunctionSlot7"] = 7,
            ["FunctionSlot8"] = 8,
            ["FunctionSlot9"] = 9,
        },
        ["WidgetSkillPanel"] = {
            ["WidgetChange"] = 10,
            ["SkillSlot1"] = 11,
            ["SkillSlot2"] = 12,
            ["SkillSlot3"] = 13,
            ["SkillSlot4"] = 14,
            ["SkillSlot5"] = 15,
            ["SkillSlot6"] = 16,
            ["SkillSlot7"] = 22,
            ["SkillSlot8"] = 17,
            ["SkillSlot9"] = 24,
            ["SkillSlot11"] = 25,
            ["SkillSlotQuickUse"] = 23,
            ["SkillSlotQuickMark"] = 23,
            ["WidgetSkillRoll"] = 18,
            ["WidgetTargetSelect"] = 19,
            ["WidgetQuickUse"] = 20,
            ["WidgetSkillAuto"] = 30,
            ["BtnTargetLock"] = 201,
        },
        ["WidgetCommon"] = {
            ["WidgetChange"] = 10,
            ["SkillSlot1"] = 11,
            ["SkillSlot2"] = 12,
            ["SkillSlot3"] = 13,
            ["SkillSlot4"] = 14,
            ["SkillSlot5"] = 15,
            ["SkillSlot6"] = 16,
            ["SkillSlot7"] = 22,
            ["SkillSlot8"] = 17,
            ["SkillSlot9"] = 24,
            ["SkillSlot11"] = 25,
            ["SkillSlotQuickUse"] = 23,
            ["SkillSlotQuickMark"] = 23,
            ["WidgetSkillRoll"] = 18,
            ["WidgetTargetSelect"] = 19,
            ["WidgetQuickUse"] = 20,
            ["WidgetSkillAuto"] = 30,
            ["BtnTargetLock"] = 201,
        },
    }
}

---@class UIWidgetGamePadSettingMain
local UIWidgetGamePadSettingMain = class("UIWidgetGamePadSettingMain")

function UIWidgetGamePadSettingMain:OnEnter(parentScript)
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

    UIHelper.SetTouchEnabled(self.LayoutModList, true)

    Timer.AddFrame(self, 1, function()
        UIHelper.SetSelected(self.TogMode1, true)
    end)

    for szKey, tList in pairs(GAME_PAD_SHORTCUT_PREFAB_ID_MAP.PREFAB) do
        local node = self[szKey]
        if node then
            for i, v in pairs(tList) do
                local cell = UIHelper.FindChildByName(node, i)
                if cell then
                    local widgetKeyBoard = UIHelper.FindChildByName(cell, "WidgetKeyBoardKey")
                    if widgetKeyBoard then
                        local script = UIHelper.GetBindScript(widgetKeyBoard)
                        script:SetID(v, szKey == "WidgetRightBottonFunction" and SHORTCUT_KEY_BOARD_STATE.Normal 
                                or SHORTCUT_KEY_BOARD_STATE.Fight, nil, SHORTCUT_SHOW_TYPE.GAMEPAD)
                        script:UpdateInfo()
                    end
                end
            end
        end
    end

    UIHelper.SetOpacity(UIHelper.GetParent(self._rootNode), 0)
    Timer.AddFrame(self, 3, function()
        UIHelper.SetOpacity(UIHelper.GetParent(self._rootNode), 255) -- 防止闪烁
    end)

    self:InitTogs()
    self:UpdateInfo()
end

function UIWidgetGamePadSettingMain:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetGamePadSettingMain:BindUIEvent()
    for i = 1, 2 do
        local nIndex = i
        UIHelper.BindUIEvent(self.filterTogs[nIndex], EventType.OnSelectChanged, function(tog, bSelected)
            if bSelected then
                UIHelper.SetVisible(self.WidgetCommon, nIndex ~= 3)
                UIHelper.SetVisible(self.WidgetSkillPanel, nIndex == 1)
                UIHelper.SetVisible(self.WidgetRightBottonFunction, nIndex == 2)
            end
        end)
    end
end

function UIWidgetGamePadSettingMain:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CancelKeyboardSelectedState()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
        end)
    end)
end

function UIWidgetGamePadSettingMain:UnRegEvent()

end

function UIWidgetGamePadSettingMain:InitSkillSlots()
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

    for nIndex, tParent in ipairs(self.skillSlotParents) do
        local szState = SHORTCUT_KEY_BOARD_STATE.Fight
        local widgetKeyBoard = UIHelper.FindChildByName(tParent, "WidgetKeyBoardKey")
        if widgetKeyBoard then
            local script = UIHelper.GetBindScript(widgetKeyBoard)
            for _, child in ipairs(UIHelper.GetChildren(widgetKeyBoard)) do
                local szName = UIHelper.GetName(child)
                local tSkillScript = self.tSkillSlotScripts[nIndex]
                if tSkillScript then
                    if VK_SPRINT_SHORTCUT_FUNC_NAME[tSkillScript.nSlotIndex] then
                        local nIndex = tSkillID2FightIndex[tSkillScript.nSkillID] or nSpecialSprintShortcutSlot
                        if nIndex then
                            script:SetID(nIndex, szState, false, SHORTCUT_SHOW_TYPE.GAMEPAD)
                            script:UpdateInfo()
                        end
                    end
                    script:SetKeyBoardProps(tSkillScript.TogSkill, tSkillScript.ImgSkillFrameSelect)
                end
                break
            end
        end
    end

    UIHelper.SetVisible(self.BtnUniqueNode, self.tSkillSlotScripts[6] == nil)
    UIHelper.SetLocalZOrder(self.ImgUniqueSkillBg, -5)

    -- UIHelper.SetButtonState(self.BtnSprint, BTN_STATE.Disable, "轻功手柄键位不可更改")
end

function UIWidgetGamePadSettingMain:InitTogs()
    for _, v in ipairs(UISettingStoreTab.GamepadInteraction) do
        local tInfo = v
        local nPrefabID = PREFAB_ID.WidgetSkillKeyboardSettingList
        local nSubIndex = tInfo.nID
        local script = UIHelper.AddPrefab(nPrefabID, self.ScrollViewNomalList, nSubIndex, tInfo.szName, tInfo.VKey, SHORTCUT_SETTING_TYPE.GAMEPAD)
        script.tParent = self.ScrollViewNomalList
        script:SetSelectCallback(function(bSelected, bShouldScrollToNode)
            if bSelected and self.nKeyboardSelectedCode ~= nSubIndex then
                self:CancelKeyboardSelectedState()
                self:StartKeyboardSelectedState(nSubIndex, tInfo, script, bShouldScrollToNode)
            elseif not bSelected and self.nKeyboardSelectedCode == nSubIndex then
                self:CancelKeyboardSelectedState()
                self.nKeyboardSelectedCode = nil
            end
        end)
        UIHelper.SetCanSelect(script.BtnKeybord, tInfo.nMaxKeyLen > 0, "当前功能手柄键位不可更改", true)
        
        script:SetKeyIndex(tInfo.szDef)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewNomalList)
end

function UIWidgetGamePadSettingMain:UpdateInfo()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewNomalList)
end

function UIWidgetGamePadSettingMain:Clear()
    UIHelper.SetSelected(self.filterTogs[1], true)
    self:InitSkillSlots()
end

function UIWidgetGamePadSettingMain:CancelKeyboardSelectedState()
    self.parentScript:CancelKeyboardSelectedState()
    Event.Dispatch(EventType.SetGamepadGameSettingEnable, false)
end

function UIWidgetGamePadSettingMain:StartKeyboardSelectedState(nSubIndex, tShortCutInfo, selectedScript, bShouldScrollToNode)
    Event.Dispatch(EventType.SetGamepadGameSettingEnable, true)
    self.parentScript:StartKeyboardSelectedState(nSubIndex, tShortCutInfo, selectedScript, bShouldScrollToNode, true)
    self.nKeyboardSelectedCode = nSubIndex

    UIHelper.SetString(self.parentScript.LabelHoverTips, string.format("*请按下【%s】的新手柄键位；点击空白处取消修改", tShortCutInfo.szName))
    UIHelper.LayoutDoLayout(self.parentScript.LayoutKeyBoardDes)
end

return UIWidgetGamePadSettingMain