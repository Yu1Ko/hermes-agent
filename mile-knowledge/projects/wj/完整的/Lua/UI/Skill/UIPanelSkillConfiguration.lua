-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2023-11-24 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class DXSlotData
---@field nType number 槽位类型 DX_ACTIONBAR_TYPE
---@field data1 number 数据1
---@field data2 number 数据2
---@field data3 number 数据3

local JiangHuQingGongID = 10082
local TianCeRideGroupID = 10061
local FangShenID = 10005
local LeaveHorseSkillID = 605
local VKMaxSlotNum = 10
local nCancelIndex = -999

local nTransparent = 64
local nOpaque = 255

---@class UIPanelSkillConfiguration
local UIPanelSkillConfiguration = class("UIPanelSkillConfiguration")

function UIPanelSkillConfiguration:OnEnter(dwKungFuID, nSetID, bShowFirstPage, nInitBarIndex)
    if not self.bInit then
        self.nCurrentKungFuID = dwKungFuID or g_pClientPlayer.GetActualKungfuMountID()
        self.nCurrentSetID = nSetID or 0
        self.tSlotIndexToSkillID = {}
        self.tSkillIDtoSlotIndex = {}
        self.tSelectedInfo = nil -- 当前选中的技能信息
        self.tSlotToNewSkillID = {}

        self.bIsHD = TabHelper.IsHDKungfuID(self.nCurrentKungFuID)
        if self.bIsHD then
            self.bShowFirstPage = bShowFirstPage
            self.nDXSkillBarIndex = nInitBarIndex or SkillData.GetCurrentDxSkillBarIndex()
        end

        if bShowFirstPage == nil then
            bShowFirstPage = true
        end

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitSlotScript()
        self:InitLeftSkillScript()

        if g_pClientPlayer and g_pClientPlayer.nLevel >= SKILL_RESTRICTION_LEVEL then
            UIHelper.SetSpriteFrame(self.ImgSkillBg, SZ_UNLOCKED_BIG_SKILL_BG_PATH) -- 解锁奇穴时触发技背景变更
        end

        UIHelper.SetVisible(self.WidgetSkill, not self.bIsHD)
        UIHelper.SetVisible(self.WidgetAction, not self.bIsHD)
        UIHelper.SetVisible(self.WidgetSkillDX, self.bIsHD)
        UIHelper.SetVisible(self.WidgetActionDX, self.bIsHD)
    end

    self:UpdatePageState()
    self:UpdateInfo()
end

function UIPanelSkillConfiguration:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DebugDraw.Clear()
end

function UIPanelSkillConfiguration:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchPage, EventType.OnClick, function()
        self.bShowFirstPage = not self.bShowFirstPage
        self:UpdatePageState()
    end)

    UIHelper.BindUIEvent(self.BtnCancelDX, EventType.OnClick, function()
        self:Click({ bCancel = true })
    end)
end

function UIPanelSkillConfiguration:RegEvent()
    Event.Reg(self, "ON_UPDATE_TALENT", function()
        Timer.AddFrame(self, 1, function()
            self:UpdateInfo()
        end)
    end)

    Event.Reg(self, "UPDATE_TALENT_SET_SLOT_SKILL", function()
        Timer.AddFrame(self, 1, function()
            self:UpdateInfo()
        end)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            UIHelper.ScrollViewDoLayout(self.ScrollViewSkillListDX)
        end)
    end)

    if self.bIsHD then
        Event.Reg(self, "ON_SKILL_REPLACE_DX", function(dwOldSkillID, dwNewSkillID)
            self:ReplaceDxSkill(dwOldSkillID, dwNewSkillID)
        end)

        Event.Reg(self, EventType.OnDxSkillBarIndexChange, function()
            Timer.AddFrame(self, 1, function()
                self.nDXSkillBarIndex = SkillData.GetCurrentDxSkillBarIndex()
                self:UpdateInfo()
            end)
        end)

        Event.Reg(self, EventType.OnPoseChange, function(nIndex)
            self.nDXSkillBarIndex = nIndex
            self:UpdateInfo()
        end)

        Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function(arg0)
            self.nCurrentKungFuID = arg0
            self:InitLeftSkillScript()
        end)
    end
end

function UIPanelSkillConfiguration:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSkillConfiguration:UpdateInfo()
    if self.bIsHD then
        self:UpdateSkillListDX()
        self:UpdateSlottedSkillDX()
    else
        UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupLeft)
        self:UpdateSkillList()
        self:UpdateTotalSkills()
        self:UpdateSlottedSkill()
    end

    self.tSlotToNewSkillID = {}
    local Toggle = UIHelper.ToggleGroupGetToggleByIndex(self.ToggleGroupLeft, 0)
    UIHelper.SetSelected(Toggle, false)
end

function UIPanelSkillConfiguration:InitSlotScript()
    self.tSlotScripts = {} ---@type UIWidgetSkillCell[]

    if not self.bIsHD then
        for i = 1, VKMaxSlotNum do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.slotSkills[i])
            self.tSlotScripts[i] = script
            script.nRecordedIndex = i
        end
        return
    end

    local listScript1 = UIHelper.AddPrefab(PREFAB_ID.WidgetSkilSwitchListDX, self.WidgetSkillSwitchListDX)
    local listScript2 = UIHelper.AddPrefab(PREFAB_ID.WidgetSkilSwitchListDX, self.WidgetSkillSwitchListDXSecond)
    local twoPageScripts = { listScript1, listScript2 }

    ---------------------------初始化前22个槽位----------------------------
    local nSlotRecordedIndex = 1
    for _, listScript in ipairs(twoPageScripts) do
        for nIndex, tParent in ipairs(listScript.tSlots) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tParent)
            script.nRecordedIndex = nSlotRecordedIndex
            if nIndex == 1 then
                --local fPercentage = 130 / 90
                --UIHelper.SetScale(script._rootNode, fPercentage, fPercentage)
                --UIHelper.SetScale(script.LabelSkillName, 1 / fPercentage, 1 / fPercentage)
                --UIHelper.SetScale(script.WidgetExchange, 1 / fPercentage, 1 / fPercentage)
            end
            table.insert(self.tSlotScripts, script)
            nSlotRecordedIndex = nSlotRecordedIndex + 1
        end
    end

    local tWidgets = {
        self.WidgetSkill12DX,
        self.WidgetSkill13DX,
        self.WidgetSkill14DX, -- 左侧固定三槽

        self.WidgetSkillQingGong2,
        self.WidgetSkillJump, -- 左侧固定三槽
        self.WidgetSkillQingGong1,

        self.WidgetSkillQingGongCombine, -- 29
    }

    local nStartIndex = #self.tSlotScripts
    for nIndex, tParent in ipairs(tWidgets) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tParent)
        script.nRecordedIndex = nStartIndex + nIndex
        table.insert(self.tSlotScripts, script)
    end

    for nIndex, script in ipairs(self.tSlotScripts) do
        local parent = UIHelper.GetParent(script._rootNode)
        local nScale = UIHelper.GetScaleX(parent)
        if nScale >= 1 then
            UIHelper.SetScale(script.LabelSkillName, 0.7, 0.7) -- 对大图标特殊大小缩放
        end
    end
end

local tCommonSlots = { 1 }
local tNormalSlots = { 2, 3, 4, 5 }
local tSprintSlots = { 7, 8, 9, 10 }

local tHDNormalSlots = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22,
    23, 24, 25
}

local tHDSprintSlots = {
    26, 27, 28, 29
}

local tHDTotalSlots = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25,
    26, 27, 28, 29
}

local tHDSprintSkills = {
    9002, 9003, 9004, 9005, 9006, 9007, UI_SKILL_JUMP_ID
}

function UIPanelSkillConfiguration:GetRightSlotList(tSlotData, nDragStartSlot)
    local resultList = tNormalSlots
    if self.bIsHD then
        if nDragStartSlot and table.contain_value(tHDSprintSlots, nDragStartSlot) then
            return tHDSprintSlots -- 只允许轻功槽位之间的拖拽
        end
        if tSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
            if table.contain_value(tHDSprintSkills, tSlotData.data1) then
                return tHDTotalSlots
            end
        end

        return tHDNormalSlots
    end

    local nSkillID = tSlotData.data1
    if nSkillID then
        local skillInfo = TabHelper.GetUISkill(nSkillID)
        if skillInfo.nType == UISkillType.Common then
            resultList = tCommonSlots
        elseif skillInfo.nType == UISkillType.Skill then
            resultList = tNormalSlots
        elseif skillInfo.nType == UISkillType.SecSprint then
            resultList = tSprintSlots
        end
    end

    return resultList
end

function UIPanelSkillConfiguration:ConfigureSlotToggle(script, tSlotData, nSlotIndex)
    script:SetToggleGroup(self.ToggleGroupLeft)
    if not self.bIsHD and nSlotIndex == UI_SKILL_UNIQUE_SLOT_ID then
        local fnClickUnique = function(_nSkillID)
            local tog = script.TogSkill
            local fnExit = function()
                UIHelper.SetSelected(tog, false)
            end

            if not _nSkillID then
                local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetConfigurationAcupointTip, tog
                , TipsLayoutDir.LEFT_CENTER, self.nCurrentKungFuID, self.nCurrentSetID)
                script:BindExitFunc(fnExit)
            else
                local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, self.WidgetAction,
                        TipsLayoutDir.LEFT_CENTER, _nSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
                tipsScriptView:BindExitFunc(fnExit)
            end
        end
        script:BindSelectFunction(fnClickUnique)
    else
        script:BindExchangeFunction(function()
            self:StartChange(tSlotData, script, nSlotIndex)
        end)

        local fnDragStart = function(nX, nY)
            return self:DragStart(tSlotData, script, nSlotIndex)
        end
        local fnDragMoved = function(nX, nY)
            self:MoveNode(nX, nY)
        end
        local fnDragEnd = function(nX, nY)
            self:DragEnd(nX, nY)
        end
        script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)

        script:BindSelectFunction(function()
            if not SkillData.IsDXSlotEmpty(tSlotData) then
                self:Click(tSlotData, script, nSlotIndex)
            else
                self:StartChange(tSlotData, script, nSlotIndex)
            end
        end)
    end
end

-----------------------------------无界--------------------------------------------

function UIPanelSkillConfiguration:UpdateSkillList()
    local tKungFuSkill = GetSkill(self.nCurrentKungFuID, 1)
    local nMountType = tKungFuSkill.dwMountType
    local skillInfoList = IsNoneSchoolKungfu(self.nCurrentKungFuID) and SkillData.GetSchoolSkillList(MountTypeToSchoolType[nMountType]) or
            SkillData.GetCurrentPlayerSkillList(self.nCurrentKungFuID)

    self.commonSkillList = {}
    self.secSprintSkillList = {}
    self.normalSkillList = {}

    for _, tSkill in ipairs(skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if skillInfo.nType == UISkillType.Common then
            table.insert(self.commonSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.Skill then
            table.insert(self.normalSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.SecSprint then
            table.insert(self.secSprintSkillList, nSkillID)
        end
    end

    self.tSlotIndexToSkillID = {}
    self.tSkillIDtoSlotIndex = {}

    local AvailableSlotIndexes = { 1, 2, 3, 4, 5, 7, 8, 9, 10 }
    for _, slotIndex in ipairs(AvailableSlotIndexes) do
        local nSkillID = SkillData.GetSlotSkillID(slotIndex, self.nCurrentKungFuID, self.nCurrentSetID)
        if nSkillID then
            self.tSlotIndexToSkillID[slotIndex] = nSkillID
            self.tSkillIDtoSlotIndex[nSkillID] = slotIndex
        end
    end
end

function UIPanelSkillConfiguration:UpdateTotalSkills()
    self.tLeftSkillScripts = {}
    self:UpdateSkillGroup(self.commonSkillList, self.LayoutSkillCell1)
    self:UpdateSkillGroup(self.secSprintSkillList, self.LayoutSkillCell3)
    self:UpdateSkillGroup(self.normalSkillList, self.LayoutSkillCell2)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, false)
end

function UIPanelSkillConfiguration:UpdateSkillGroup(skillIDList, parentList)
    local layout = parentList
    UIHelper.RemoveAllChildren(layout)

    for _, skillID in ipairs(skillIDList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, layout)
        local nSlotIndex = self.tSkillIDtoSlotIndex[skillID]
        local bLearned = g_pClientPlayer.GetSkillLevel(skillID) > 0
        local szQuestList = Table_GetSkillQuestList(skillID)

        script:UpdateInfo(skillID)
        if szQuestList and not bLearned then
            script:ShowQuest()
        else
            script:ShowName(true)
        end

        UIHelper.SetVisible(script.ImgBlackCover, not bLearned) -- 未学习时透明
        script:SetToggleGroup(self.ToggleGroupLeft)
        script:SetUsed(nSlotIndex ~= nil)
        local tSlotData = { nType = DX_ACTIONBAR_TYPE.SKILL, data1 = skillID }
        script:BindSelectFunction(function()
            self:Click(tSlotData, script)
        end)

        local fnDragStart = function(nX, nY)
            return self:DragStart(tSlotData, script)
        end
        local fnDragMoved = function(nX, nY)
            self:MoveNode(nX, nY)
        end
        local fnDragEnd = function(nX, nY)
            self:DragEnd(nX, nY)
        end
        script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)

        table.insert(self.tLeftSkillScripts, script)
    end
end

function UIPanelSkillConfiguration:UpdateSlottedSkill()
    for nSlotIndex, script in pairs(self.tSlotScripts) do
        local skillID = SkillData.GetSlotSkillID(nSlotIndex, self.nCurrentKungFuID, self.nCurrentSetID)
        if nSlotIndex == UI_SKILL_UNIQUE_SLOT_ID then
            skillID = SkillData.GetUniqueSkillID(self.nCurrentKungFuID, self.nCurrentSetID)
        end

        if skillID then
            script:UpdateInfo(skillID)
            script:ShowShortcutAndType(nSlotIndex)
        else
            UIHelper.ClearTexture(script.ImgSkillIcon)
            script:HideLabel()
        end
        UIHelper.SetVisible(script.ImgAdd, nSlotIndex ~= UI_SKILL_UNIQUE_SLOT_ID and skillID == nil) -- 空槽位 显示+号

        self:ConfigureSlotToggle(script, { nType = DX_ACTIONBAR_TYPE.SKILL, data1 = skillID }, nSlotIndex)
        if self.tSlotToNewSkillID[nSlotIndex] then
            script:ShowEffect()
        end

        if nSlotIndex == 1 then
            UIHelper.SetScale(script._rootNode, 1.33, 1.33)
        elseif nSlotIndex == 9 then
            UIHelper.SetScale(script._rootNode, 0.64, 0.64)
        end
        script:UpdateLabelSize()

        local nSkillLevel = g_pClientPlayer.GetSkillLevel(skillID)
        if nSkillLevel == 0 and table.contain_value(tSprintSlots, nSlotIndex) and g_pClientPlayer.nLevel < SPRINT_ENABLE_LEVEL then
            UIHelper.SetVisible(script._rootNode, false)
        end
    end
end

-----------------------------------端游--------------------------------------------

function UIPanelSkillConfiguration:InitLeftSkillScript()
    if not self.bIsHD then
        return
    end
    self.tLeftSkillScripts = {}
    self.nSkillID2LeftSkillScripts = {}
    self.tLeftGroupTitleLabels = {}
    local hPlayer = g_pClientPlayer
    
    UIHelper.RemoveAllChildren(self.ScrollViewSkillListDX)

    local fnInitCell = function(script, szDragErrorMsg)
        script:SetToggleGroup(self.ToggleGroupLeft)
        UIHelper.SetScale(script._rootNode, 0.9, 0.9)
        --script:SetUsed(nSlotIndex ~= nil)

        script:BindSelectFunction(function()
            self:Click(script.tSlotData, script)
        end)

        if not szDragErrorMsg then
            local fnDragStart = function()
                return self:DragStart(script.tSlotData, script)
            end
            local fnDragMoved = function(nX, nY)
                self:MoveNode(nX, nY)
            end
            local fnDragEnd = function(nX, nY)
                self:DragEnd(nX, nY)
            end
            script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)
        else
            local fnDragStart = function()
                self.bShowErrorTip = false
                return true
            end
            local fnDragMoved = function(nX, nY)
                if not self.bShowErrorTip then
                    TipsHelper.ShowImportantYellowTip(szDragErrorMsg)
                    self.bShowErrorTip = true -- 拖动时显示错误码
                    return false
                end
            end

            script:BindMoveFunction(fnDragStart, fnDragMoved, function()
            end)
        end

        UIHelper.SetAnchorPoint(script._rootNode, 0, 0.5) -- 锚点和Layout保持一致
        table.insert(self.tLeftSkillScripts, script)
    end

    local fnInitSkill = function(lst, parent)
        for _, tSkill in pairs(lst) do
            local dwID = tSkill[1]
            local dwLevel = tSkill[2]
            local bLearned = dwLevel > 0

            dwID = SkillData.CheckDXSkillReplace(dwID) -- 应用DX替换逻辑
            dwLevel = dwLevel == 0 and 1 or dwLevel

            local hSkill = GetSkill(dwID, dwLevel)
            local nOpenLevel = Table_OpenSkillLevel(dwID, dwLevel)
            local szQuestList = Table_GetSkillQuestList(dwID)
            local bPassive = hSkill and hSkill.bIsPassiveSkill
            local tUISkill = Table_GetSkill(dwID, dwLevel)
            local nPrefabID = bPassive and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
            local script = UIHelper.AddPrefab(nPrefabID, parent)
            local tSlotData = { nType = DX_ACTIONBAR_TYPE.SKILL, data1 = dwID }
            script:UpdateInfoDX(tSlotData)

            if szQuestList and not bLearned then
                script:ShowQuest()
            elseif not bLearned then
                script:ShowLearnLevel(nOpenLevel)
            else
                script:ShowName(true)
            end

            UIHelper.SetVisible(script.ImgBlackCover, not bLearned) -- 未学习时透明
            UIHelper.SetVisible(script.ImgArrow, not tUISkill.bCanDrag) -- 不可拖动则显示箭头

            local szErrorMsg
            if bPassive then
                szErrorMsg = g_tStrings.STR_ERROR_SKILL_PASSIVE_SKILL
            elseif not tUISkill.bCanDrag then
                szErrorMsg = g_tStrings.SKILL_CAN_NOT_DRAG
            elseif not bLearned then
                szErrorMsg = g_tStrings.SKILL_UNLEARNED_CAN_NOT_DRAG
            end
            fnInitCell(script, szErrorMsg)
            script.szErrorMsg = szErrorMsg
            self.nSkillID2LeftSkillScripts[dwID] = script
        end
    end

    --local fnInitEquip = function(lst, parent)
    --    for _, tbItemInfo in pairs(lst) do
    --        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent)
    --        local tSlotData = { nType = DX_ACTIONBAR_TYPE.EQUIP,
    --                            data1 = tbItemInfo.nBox, data2 = tbItemInfo.nIndex, data3 = hPlayer.GetEquipIDArray(INVENTORY_INDEX.EQUIP) }
    --        script:UpdateInfoDX(tSlotData)
    --        fnInitCell(script)
    --    end
    --end

    local fnInitItemInfo = function(lst, parent)
        for _, tbItemInfo in pairs(lst) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent)
            local tSlotData = { nType = DX_ACTIONBAR_TYPE.ITEM_INFO, data1 = tbItemInfo.dwTabType, data2 = tbItemInfo.dwIndex }
            script:UpdateInfoDX(tSlotData)
            script:ShowName(true)
            fnInitCell(script)
        end
    end

    local fnInitMacro = function(lst, parent)
        for _, nMacroID in pairs(lst) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent)
            local tSlotData = { nType = DX_ACTIONBAR_TYPE.MACRO, data1 = nMacroID }
            script:UpdateInfoDX(tSlotData)
            script:ShowName(true)
            fnInitCell(script)
        end
    end

    ------------------遍历对阵技能------------------
    local tKungfu = Table_GetMKungfuList(self.nCurrentKungFuID)
    table.insert(tKungfu, JiangHuQingGongID) -- 10082为端游江湖轻功的ID
    table.insert(tKungfu, FangShenID) -- 普攻所在的防身技艺ID

    for nIndex, dwID in ipairs(tKungfu) do
        local dwLevel = hPlayer.GetSkillLevel(dwID)
        local dwShowLevel = dwLevel
        if dwLevel == 0 then
            dwShowLevel = 1
        end
        if Table_IsSkillShow(dwID, dwShowLevel) then
            local lst = SkillData.GetDXSkillList(self.nCurrentKungFuID, dwID)
            local finalList = {}
            for nIndex, tGroup in ipairs(lst) do
                for _, tSkill in pairs(tGroup) do
                    local dwID = tSkill[1]
                    local dwLevel = tSkill[2]
                    local bLearned = dwLevel > 0
                    local bCommon, bCurrent, bMelee = SkillData.IsCommonDXSkill(dwID)
                    local hSkill = GetSkill(dwID, math.max(1, dwLevel))
                    local bMatchSelectMount = NewSkillPanel_IsMatchSelectMount(hSkill, self.nCurrentKungFuID)
                    if bMatchSelectMount and (not bCommon or bCurrent) and NewSkillPanel_IsShowSkill(dwID, dwLevel) then
                        table.insert(finalList, tSkill)
                    end
                end
            end

            if dwID == JiangHuQingGongID then
                table.insert(finalList, { UI_SKILL_JUMP_ID, 1 }) -- 插入跳跃技能
            end
            if dwID == TianCeRideGroupID then
                table.insert(finalList, { LeaveHorseSkillID, 1 }) -- 插入奇遇技能
            end
            if dwID == FangShenID then
                local tCommon = {}
                local tSpecialSkills = { [36158] = 1, [3373] = 1, [3374] = 1 } -- 唐门万灵特殊技能
                for _, tSkill in pairs(finalList) do
                    local dwID = tSkill[1]
                    local dwLevel = tSkill[2]
                    local bCommon, bCurrent, bMelee = SkillData.IsCommonDXSkill(dwID)
                    if bCommon then
                        table.insert(tCommon, tSkill)
                    elseif tSpecialSkills[dwID] then
                        table.insert(tCommon, tSkill)
                    end
                end
                finalList = tCommon -- 只要普攻
            end

            if #finalList > 0 then
                local listScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillListDXCell, self.ScrollViewSkillListDX)
                local szName = Table_GetSkillName(dwID, dwShowLevel)
                UIHelper.SetLabel(listScript.LabelSkillTypeTitle, UIHelper.GBKToUTF8(szName))
                table.insert(self.tLeftGroupTitleLabels, listScript)
                fnInitSkill(finalList, listScript.LayoutSkillDXCell)
            end
        end
    end

    ------------------遍历奇穴主动技能------------------
    local activeQiXueSkillList = {  }
    local tList = SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)
    for nIndex, data in ipairs(tList) do
        if tList[nIndex] then
            local nSelectIndex = data.nSelectIndex
            local tSkillArray = data.SkillArray
            if nSelectIndex > 0 then
                local nSkillID = tSkillArray[nSelectIndex].dwSkillID
                local nSkillLevel = tSkillArray[nSelectIndex].dwSkillLevel
                local tSkill = nSkillID > 0 and GetSkill(nSkillID, nSkillLevel)
                if tSkill and not tSkill.bIsPassiveSkill then
                    table.insert(activeQiXueSkillList, { nSkillID, nSkillLevel })
                end
            end
        end
    end

    if #activeQiXueSkillList > 0 then
        local listScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillListDXCell, self.ScrollViewSkillListDX)
        UIHelper.SetLabel(listScript.LabelSkillTypeTitle, "奇穴技能")
        fnInitSkill(activeQiXueSkillList, listScript.LayoutSkillDXCell)
        table.insert(self.tLeftGroupTitleLabels, listScript)
    end

    ------------------遍历可快捷使用装备------------------
    local tbUsableEquipList = { }
    local nItemType = ItemData.BoxSet.Equip
    for _, tbItemInfo in ipairs(ItemData.GetItemList(nItemType)) do
        if tbItemInfo.hItem and ItemData.CanQuickUse(tbItemInfo) then
            table.insert(tbUsableEquipList, tbItemInfo.hItem)
        end
    end

    if #tbUsableEquipList > 0 then
        local listScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillListDXCell, self.ScrollViewSkillListDX)
        UIHelper.SetLabel(listScript.LabelSkillTypeTitle, "主动装备")
        fnInitItemInfo(tbUsableEquipList, listScript.LayoutSkillDXCell)
        table.insert(self.tLeftGroupTitleLabels, listScript)
    end

    ------------------遍历宏------------------
    local tbUsableMacro = { }
    for k, tMacro in pairs(g_Macro) do
        if IsNumber(k) and not IsMacroRemoved(k) then
            table.insert(tbUsableMacro, k)
        end
    end

    if #tbUsableMacro > 0 then
        local listScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillListDXCell, self.ScrollViewSkillListDX)
        UIHelper.SetLabel(listScript.LabelSkillTypeTitle, "宏")
        fnInitMacro(tbUsableMacro, listScript.LayoutSkillDXCell)
        table.insert(self.tLeftGroupTitleLabels, listScript)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewSkillListDX, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillListDX)
    Timer.AddFrame(self, 1, function()
        UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewSkillListDX, false, true) -- 标题栏挂靠刷新
    end)
end

function UIPanelSkillConfiguration:UpdateSkillListDX()
    local player = g_pClientPlayer
    local tData
    self.tDXSlotToSkill = {}
    for nSlotID = 1, SkillData.DXMaxSlotNum do
        tData = SkillData.GetDxSlotData(nSlotID, self.nDXSkillBarIndex)

        if tData.nType == DX_ACTIONBAR_TYPE.SKILL then
            local dwNewSkillID = GetMultiStageSkillCanCastID(tData.data1, g_pClientPlayer)
            if dwNewSkillID ~= tData.data1 then
                tData.data1 = dwNewSkillID
            end
        end

        self.tDXSlotToSkill[nSlotID] = tData
    end
end

function UIPanelSkillConfiguration:UpdateSlottedSkillDX()
    if not g_pClientPlayer then
        return
    end

    for i, script in ipairs(self.tSlotScripts) do
        local nSlotIndex = i
        local tSlotData = self:GetShowSkill(nSlotIndex)
        local bHaveData = not SkillData.IsDXSlotEmpty(tSlotData)
        if not bHaveData then
            tSlotData = {}
        end

        UIHelper.SetVisible(script.ImgAdd, not bHaveData) -- 空槽位 显示+号
        UIHelper.SetVisible(script.ImgSkillIcon, bHaveData)

        if bHaveData then
            script:UpdateInfoDX(tSlotData)
            script:ShowShortcutDX(nSlotIndex)
        else
            script:HideLabel()
            script:UpdateMijiDot(false)
        end

        self:ConfigureSlotToggle(script, tSlotData, nSlotIndex)
        if self.tSlotToNewSkillID[nSlotIndex] then
            script:ShowEffect()
        end
    end
end

function UIPanelSkillConfiguration:GetShowSkill(nSlotIndex)
    return self.tDXSlotToSkill[nSlotIndex]
end

function UIPanelSkillConfiguration:ReplaceDxSkill(dwOldSkillID, dwNewSkillID)
    local skillScript = self.nSkillID2LeftSkillScripts[dwOldSkillID]
    if skillScript then
        skillScript.tSlotData.data1 = dwNewSkillID
        self.nSkillID2LeftSkillScripts[dwOldSkillID] = nil
        self.nSkillID2LeftSkillScripts[dwNewSkillID] = skillScript
        skillScript:UpdateInfoDX()
    end
end

function UIPanelSkillConfiguration:UpdatePageState()
    UIHelper.SetVisible(self.WidgetSkillSwitchListDX, self.bShowFirstPage)
    UIHelper.SetVisible(self.WidgetSkillSwitchListDXSecond, not self.bShowFirstPage)
    UIHelper.SetOpacity(self.ImgPage1, self.bShowFirstPage and 255 or 70)
    UIHelper.SetOpacity(self.ImgPage2, not self.bShowFirstPage and 255 or 70)
end

--{{{ -------------------------Drag---------------------------------

function UIPanelSkillConfiguration:Click(tSlotData, tSkillScript, nSlotID)
    local fnIsIdentical = function(tSlot1, tSlot2)
        if tSlot1 and tSlot2 then
            return tSlot1.nType == tSlot2.nType and tSlot1.data1 == tSlot2.data1 and tSlot1.data2 == tSlot2.data2 and tSlot1.data3 == tSlot2.data3
        end
        return false
    end
    local fnClearToggle = function()
        Timer.AddFrame(self, 1, function()
            if tSkillScript then
                local toggle = tSkillScript.TogSkill
                UIHelper.SetSelected(toggle, false)
            end
        end)
    end

    if not self.tSelectedInfo then
        local tParent = nSlotID and self.WidgetActionDX or self.ScrollViewSkillListDX
        local nDirection = nSlotID and TipsLayoutDir.LEFT_CENTER or TipsLayoutDir.RIGHT_CENTER
        SkillData.ShowDxSlotTips(tSlotData, tParent, fnClearToggle, nDirection)
    else
        if not IsTableEmpty(tSlotData) then
            if self.tSelectedInfo.nSlotID and tSlotData.bCancel then
                self:ClearDxSlotData(self.tSelectedInfo.nSlotID) -- 清空槽位
            elseif tSkillScript.szErrorMsg then
                TipsHelper.ShowImportantYellowTip(tSkillScript.szErrorMsg)
            elseif self.tSelectedInfo.nSlotID and not fnIsIdentical(tSlotData, self.tSelectedInfo.tSlotData) then
                self:SaveDataToSlot(tSlotData, self.tSelectedInfo.nSlotID)
            end
        end

        self:SetChangeStateVisible(false)
        self.tSelectedInfo = nil
        fnClearToggle()
    end
end

function UIPanelSkillConfiguration:DragStart(tSlotData, tSkillScript, nStartSlot)
    if tSlotData and not SkillData.IsDXSlotEmpty(tSlotData) and not self.tSelectedInfo then
        self.tSelectedInfo = {
            tSlotData = tSlotData,
            tSkillScript = tSkillScript,
            nStartSlot = nStartSlot
        }
        self:SetBlackMaskVisible(true)
        self.nTouchBeganX, self.nTouchBeganY = UIHelper.GetPosition(self.draggableNode._rootNode)
        self.tCursor = GetViewCursorPoint()
        return true
    end
    return false
end

function UIPanelSkillConfiguration:MoveNode(nX, nY)
    if self.draggableNode then
        local node = self.draggableNode._rootNode
        self.tCursor = GetViewCursorPoint()

        local nodeX, nodeY = UIHelper.ConvertToNodeSpace(UIHelper.GetParent(node), nX, nY)
        local w, h = UIHelper.GetContentSize(node)
        UIHelper.SetPosition(node, nodeX - w / 2, nodeY - h / 2)
    end
end

function UIPanelSkillConfiguration:DragEnd(nX, nY)
    local nSlotIndex = self:CollectNodeByPoint(nX, nY)
    if nSlotIndex >= 1 then
        local tSlotData = self.tSelectedInfo.tSlotData
        self:SaveDataToSlot(tSlotData, nSlotIndex, self.tSelectedInfo.nStartSlot)
    elseif nSlotIndex == nCancelIndex and self.tSelectedInfo.nStartSlot then
        self:ClearDxSlotData(self.tSelectedInfo.nStartSlot) -- 如果是从槽位上拖到取消按钮则清空槽位
    end

    self:SetBlackMaskVisible(false)
    self.tSelectedInfo = nil
    self.tCursor = nil
end

local function _forEachValidNode(node, func)
    -- 筛选widget
    if not node then
        return
    end
    if node:getName() == "PanelHoverTips" then
        return
    end
    if node:getName() == "PanelNodeExplorer" then
        return
    end
    if not UIHelper.GetVisible(node) then
        return
    end
    if node.isEnabled and not node:isEnabled() then
        return
    end

    local aChildren = node:getChildren()
    if aChildren then
        for i = 1, #aChildren do
            local childNode = aChildren[i]
            if UIHelper.GetVisible(childNode) and (not childNode.isEnabled or childNode:isEnabled()) then
                func(childNode)
                _forEachValidNode(childNode, func)
            end
        end
    end
end

function UIPanelSkillConfiguration:CollectNodeByPoint()
    local x, y = self.tCursor.x, self.tCursor.y
    local tbPoint = cc.p(x, y) -- 鼠标位置的世界坐标

    --DebugDraw.DrawCircle(tbPoint, 10)

    local sceneNode = cc.Director:getInstance():getRunningScene()
    local camera = sceneNode:getDefaultCamera()
    local tbNodes = {}

    -- 遍历所有节点
    _forEachValidNode(sceneNode, function(node)
        local bIsHit = false

        -- hitTest for button etc.
        if node.hitTest and node:hitTest(tbPoint, camera) then
            if node:isClippingParentContainsPoint(tbPoint) then
                bIsHit = true
                table.insert(tbNodes, node)
            end
        end
    end)

    local tAvailableSlotList = self:GetRightSlotList(self.tSelectedInfo.tSlotData, self.tSelectedInfo.nStartSlot)

    for nSlotIndex, script in pairs(self.tSlotScripts) do
        if table.contain_value(tAvailableSlotList, nSlotIndex) and table.contain_value(tbNodes, script:GetToggle()) then
            return nSlotIndex
        end
    end

    if table.contain_value(tbNodes, self.BtnCancelDX) then
        return nCancelIndex
    end

    return -1
end

--}}}

function UIPanelSkillConfiguration:SetBlackMaskVisible(bShowMask)
    local tDraggableParent = self.DraggableParent
    UIHelper.SetVisible(self.ImgBlackBg, bShowMask)
    assert(self.tSelectedInfo)

    local tSkillScript = self.tSelectedInfo.tSkillScript
    local tSlotIndexes = self:GetRightSlotList(self.tSelectedInfo.tSlotData, self.tSelectedInfo.nStartSlot)

    ---------------------------------隐藏无关的槽位-----------------------------------
    local nMaxSlotNum = self.bIsHD and SkillData.DXMaxSlotNum or VKMaxSlotNum
    for i = 1, nMaxSlotNum do
        local script = self.tSlotScripts[i]
        if script and not table.contain_value(tSlotIndexes, script.nRecordedIndex) then
            UIHelper.SetOpacity(UIHelper.GetParent(script._rootNode), bShowMask and nTransparent or nOpaque)
            UIHelper.SetEnable(script.TogSkill, not bShowMask)
        end
    end
    ---------------------------------隐藏无关的不可用技能-----------------------------------
    for _, script in ipairs(self.tLeftSkillScripts) do
        if tSkillScript ~= script then
            UIHelper.SetOpacity(script._rootNode, bShowMask and nTransparent or nOpaque)
            UIHelper.SetEnable(script.TogSkill, not bShowMask)
        end
    end

    self:OperateCertainObject(bShowMask)

    if bShowMask then
        local worldX, worldY = UIHelper.GetWorldPosition(tSkillScript._rootNode)
        local nodeX, nodeY = UIHelper.ConvertToNodeSpace(tDraggableParent, worldX, worldY)

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tDraggableParent)
        if self.bIsHD then
            script:UpdateInfoDX(self.tSelectedInfo.tSlotData)
        else
            script:UpdateInfo(self.tSelectedInfo.tSlotData.data1)
        end

        script:HideLabel()
        script:SetSelected(true)
        script:SetSelectEnable(false)
        UIHelper.SetPosition(script._rootNode, nodeX, nodeY)

        self.draggableNode = script
    end

    if not bShowMask then
        UIHelper.RemoveAllChildren(tDraggableParent)
        self.draggableNode = nil
    end
end

----------------------------直接点击槽位的交换按钮时-----------------------------------------------

---@note 显示替换技能遮罩时隐藏特定对象
function UIPanelSkillConfiguration:OperateCertainObject(bShowMask)
    UIHelper.SetOpacity(self.BtnSwitchPage, bShowMask and nTransparent or nOpaque)
    UIHelper.SetEnable(self.BtnSwitchPage, not bShowMask)

    if self.tSelectedInfo.nStartSlot ~= nil then
        for _, script in ipairs(self.tLeftGroupTitleLabels) do
            UIHelper.SetOpacity(script._rootNode, bShowMask and nTransparent or nOpaque)
        end
    end

    --UIHelper.SetVisible(self.SkillSlotCombine29Slider, not bShowMask)
    UIHelper.SetVisible(self.BtnCancelDX, bShowMask)
    UIHelper.SetVisible(self.LayoutTogNavSpecialPage, not bShowMask)
end

function UIPanelSkillConfiguration:StartChange(tSlotData, tSkillScript, nSlotID)
    if self.tSelectedInfo then
        return
    end

    self.tSelectedInfo = {
        tSlotData = tSlotData,
        nSlotID = nSlotID,
        tSkillScript = tSkillScript,
    }
    self:SetChangeStateVisible(true)
end

function UIPanelSkillConfiguration:SaveDataToSlot(tSlotData, nTargetSlot, nStartSlot)
    local tSlotToNewSkillID = {}
    assert(tSlotData)
    assert(nTargetSlot)

    if ArenaData.IsInBattle() then
        TipsHelper.ShowNormalTip("战斗中无法进行此操作")
        return false
    end

    -- todo 用上nStartSlot
    if not self.bIsHD then
        local nSkillID = tSlotData.data1
        local nTargetSkillID = self.tSlotIndexToSkillID[nTargetSlot]
        local nSecondSlot = self.tSkillIDtoSlotIndex[nSkillID]
        if nTargetSlot ~= nSecondSlot then
            tSlotToNewSkillID[nTargetSlot] = nSkillID           -- 将选中的技能放入第一次点击的槽位
            if nSkillID and nSecondSlot then
                tSlotToNewSkillID[nSecondSlot] = nTargetSkillID -- 若选中的技能已装配且目标槽位已有技能 则执行执行交换操作
            end

            self.tSlotToNewSkillID = tSlotToNewSkillID
            SkillData.ChangeSkill(tSlotToNewSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
        end
    else
        self:ClearDxSlotData(nTargetSlot, false)
        
        self.tSlotToNewSkillID = { [nTargetSlot] = true }
        SkillData.SaveDXSlotData(tSlotData, nTargetSlot, self.nDXSkillBarIndex)

        if nStartSlot and nTargetSlot ~= nStartSlot then
            local nToBeExchangeSlotData = self.tDXSlotToSkill[nTargetSlot]
            if nToBeExchangeSlotData.nType then
                self.tSlotToNewSkillID[nStartSlot] = true
                SkillData.SaveDXSlotData(nToBeExchangeSlotData, nStartSlot, self.nDXSkillBarIndex)
            else
                self:ClearDxSlotData(nStartSlot, false)
            end
        end

        Event.Dispatch("UPDATE_TALENT_SET_SLOT_SKILL") -- 发送槽位变更事件
    end

    return true
end

function UIPanelSkillConfiguration:ClearDxSlotData(nSlot, bUpdate)
    assert(nSlot)

    if bUpdate == nil then
        bUpdate = true
    end

    if ArenaData.IsInBattle() then
        TipsHelper.ShowNormalTip("战斗中无法进行此操作")
        return false
    end

    local tOldData = SkillData.GetDxSlotData(nSlot, self.nDXSkillBarIndex)
    if tOldData and tOldData.nType == DX_ACTIONBAR_TYPE.SKILL and table.contain_value(SkillData.tDXSprintSlots, nSlot) then
        ShortcutInteractionData.ClearDXSkillShortcutInfo(SkillData.tDXSkillID2FightIndex[tOldData.data1]) -- 清除老快捷键
    end

    SkillData.ClearDXSlotData(nSlot, self.nDXSkillBarIndex)
    if bUpdate then
        Event.Dispatch("UPDATE_TALENT_SET_SLOT_SKILL") -- 发送槽位变更事件
    end
end

function UIPanelSkillConfiguration:SetChangeStateVisible(bShowMask)
    UIHelper.SetVisible(self.ImgBlackBg, bShowMask)
    assert(self.tSelectedInfo)

    local nSlotID = self.tSelectedInfo.nSlotID
    local tSlotHighLights = self:GetRelatedLeftSkillList(nSlotID)
    if not tSlotHighLights then
        return
    end

    ---------------------------------隐藏无关的槽位-----------------------------------
    local nMaxSlotNum = self.bIsHD and SkillData.DXMaxSlotNum or VKMaxSlotNum
    for i = 1, nMaxSlotNum do
        local script = self.tSlotScripts[i]
        if script and script.nRecordedIndex ~= nSlotID then
            UIHelper.SetOpacity(UIHelper.GetParent(script._rootNode), bShowMask and nTransparent or nOpaque)
            UIHelper.SetEnable(script.TogSkill, not bShowMask)
        end
    end

    ---------------------------------隐藏无关的不可用技能-----------------------------------
    for _, script in ipairs(self.tLeftSkillScripts) do
        if not table.contain_value(tSlotHighLights, script) then
            UIHelper.SetOpacity(script._rootNode, bShowMask and nTransparent or nOpaque)
            UIHelper.SetEnable(script.TogSkill, not bShowMask)
        end
    end

    self:OperateCertainObject(bShowMask)
end

function UIPanelSkillConfiguration:GetRelatedLeftSkillList(nSlotID)
    if self.bIsHD then
        if table.contain_value(tHDSprintSlots, nSlotID) then
            local lst = {}
            for _, script in ipairs(self.tLeftSkillScripts) do
                if table.contain_value(tHDSprintSkills, script.nSkillID) then
                    table.insert(lst, script)
                end
            end
            return lst
        end
        return self.tLeftSkillScripts
    end

    local tLayout = nil
    if nSlotID then
        if nSlotID == 1 then
            tLayout = self.LayoutSkillCell1
        elseif nSlotID >= 2 and nSlotID <= 5 then
            tLayout = self.LayoutSkillCell2
        elseif nSlotID >= 7 and nSlotID <= 10 then
            tLayout = self.LayoutSkillCell3
        end
    end

    local tRes = {}
    for _, node in ipairs(UIHelper.GetChildren(tLayout)) do
        table.insert(tRes, UIHelper.GetBindScript(node))
    end
    return tRes
end

return UIPanelSkillConfiguration
