-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetSkillCombine
-- Date: 2025-7-21 11:45:31
-- Desc: UIWidgetSkillCombine 技能轮盘
-- ---------------------------------------------------------------------------------
local tQingGongSkillList = {
    {
        nSkillID = UI_DXSKILL_DASH_ID,
        nShortcutIndex = SkillData.tDXSkillID2FightIndex[UI_DXSKILL_DASH_ID]
    },
    {
        nSkillID = UI_DXSKILL_YAOTAI_ID,
        nShortcutIndex = SkillData.tDXSkillID2FightIndex[UI_DXSKILL_YAOTAI_ID]
    },
    {
        nSkillID = UI_DXSKILL_YINGFENG_ID,
        nShortcutIndex = SkillData.tDXSkillID2FightIndex[UI_DXSKILL_YINGFENG_ID]
    },
    {
        nSkillID = UI_DXSKILL_LINGXIAO_ID,
        nShortcutIndex = SkillData.tDXSkillID2FightIndex[UI_DXSKILL_LINGXIAO_ID]
    }
}

local kUnlockDragMinDir = 20          -- 最小滑动距离
local tMinRad = {
    [2] = 85 * math.pi / 180,
    [3] = 55 * math.pi / 180,
    [4] = 40 * math.pi / 180,
    [5] = 31 * math.pi / 180,
    [6] = 25 * math.pi / 180,
    [7] = 22 * math.pi / 180,
} -- 最小误差角度
local tSliderWidgetName = {
    WidgetBar2 = "WidgetBar2",
    WidgetBar3 = "WidgetBar3",
    WidgetBar3Small = "WidgetBar3Small",
    WidgetBar4 = "WidgetBar4",
    WidgetBar6 = "WidgetBar6",
    WidgetBar7 = "WidgetBar7",
}

---@class UIWidgetSkillCombine
local UIWidgetSkillCombine = class("UIWidgetSkillCombine")

function UIWidgetSkillCombine:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bPressStart = false
        self.bIsQingGong = false
        self.tbCellScriptList = {}
        self.tbFirstSkillList = {}
        self.tbSecondSkillList = {}
    end
    self.tScripts = {}
    self.tSlotScript2Cast = nil
end

function UIWidgetSkillCombine:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSkillCombine:BindUIEvent()

end

function UIWidgetSkillCombine:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.DelTimer(self, self.nUpdateSize)
        self.nUpdateSize = Timer.AddFrame(self, 5, function()
            self:UpdatePositionByNode()
        end)
    end)
end

function UIWidgetSkillCombine:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetSkillCombine:OnDragStart()
    self.bPressStart = true
    self.nPressX, self.nPressY = 0, 0
    local tCursor = (Platform.IsWindows() or Device.IsPad()) and GetViewCursorPoint() or GetCursorPoint()
    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self._rootNode, tCursor.x, tCursor.y)

    UIHelper.SetActiveAndCache(self, self.WidgetRangeIn, self.bIsQingGong) -- 轻功在屏幕中间显示
    if self.bIsQingGong then
        UIHelper.SetPosition(self.WidgetRangeIn, nLocalX, nLocalY)
        UIHelper.SetPosition(self.ImgRangeNode, 0, 0)
    else
        UIHelper.SetPosition(self.WidgetRangeIn, 0, 0)
    end

    for nIndex, script in ipairs(self.tScripts) do
        UIHelper.SetActiveAndCache(self, script.ImgRangeIn, false)
    end

    self:SetVisible(true)
end

function UIWidgetSkillCombine:OnJoystickDrag(nX, nY)
    if not self.bPressStart then
        return
    end

    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetRangeIn, nX, nY)
    local nCursorX, nCursorY = kmath.normalize2(nLocalX - self.nPressX, nLocalY - self.nPressY)
    local nDistance = kmath.len2(nLocalX, nLocalY, self.nPressX, self.nPressY)
    local bReachedMinDistance = nDistance > kUnlockDragMinDir
    local nSlotCount = #self.tScripts
    local nMinRad = tMinRad[nSlotCount] or 20

    nDistance = math.min(nDistance, 50)

    if self.bIsQingGong then
        local currentRotation = math.acos(nCursorX * 1 + nCursorY * 0) * 180 / math.pi
        UIHelper.SetRotation(self.ImgRangeNode, nCursorY > 0 and -currentRotation or currentRotation)
    end

    self.tSlotScript2Cast = nil
    for nIndex, script in ipairs(self.tScripts) do
        if bReachedMinDistance then
            local nNodeX, nNodeY = UIHelper.GetPosition(script.SlotParent)
            local nNormX, nNormY = kmath.normalize2(nNodeX, nNodeY)

            local rad = math.acos(nCursorX * nNormX + nCursorY * nNormY)
            local bInRange = rad <= nMinRad

            UIHelper.SetActiveAndCache(self, script.ImgRangeIn, bInRange)
            if bInRange then
                self.tSlotScript2Cast = self.tbCellScriptList[nIndex]
            end
        else
            UIHelper.SetActiveAndCache(self, script.ImgRangeIn, false)
        end
    end
end

function UIWidgetSkillCombine:OnDragEnd()
    if self.bPressStart then
        if self.tSlotScript2Cast then
            self.tSlotScript2Cast:OnPressDown()
            self.tSlotScript2Cast:OnPressUp()
        end
        self.bPressStart = false
        self:SetVisible(false)
    end
end

function UIWidgetSkillCombine:InitQingGong()
    self:OnEnter()
    self.tSkillList = tQingGongSkillList
    self:RemoveUnUsedWidget(self.FourSkillsGroup)
    self.bIsQingGong = true
    self.szSliderWidgetName = tSliderWidgetName.WidgetBar4

    for nIndex, node in ipairs(self.fourSkillCombines) do
        local script = UIHelper.GetBindScript(node)
        table.insert(self.tScripts, script)

        local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, script.SlotParent)
        cellScript:InitSkill(self.tSkillList[nIndex].nSkillID, self.tSkillList[nIndex].nShortcutIndex)
        cellScript:HideSkillBg()
        cellScript:SetCDSlider(script.SliderCD)
        self.tbCellScriptList[nIndex] = cellScript
        UIHelper.SetAnchorPoint(cellScript._rootNode, 0.5, 0.5)
    end
    UIHelper.SetVisible(self.FourSkillsGroup, true)
end

function UIWidgetSkillCombine:InitPet()
    self:OnEnter()
    self.tSkillList = SpecialDXSkillData.tPetList
    self:RemoveUnUsedWidget(self.SevenSkillsGroup)
    self.szSliderWidgetName = tSliderWidgetName.WidgetBar7

    for nIndex, node in ipairs(self.sevenSkillCombines) do
        local script = UIHelper.GetBindScript(node)
        table.insert(self.tScripts, script)

        local cellScript = self.tbCellScriptList[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, script.SlotParent)
        cellScript:InitSkill(SpecialDXSkillData.tPetList[nIndex].nSkillID, SpecialDXSkillData.tPetList[nIndex].nShortcutIndex)
        cellScript:HideSkillBg()
        self.tbCellScriptList[nIndex] = cellScript
        UIHelper.SetAnchorPoint(cellScript._rootNode, 0.5, 0.5)
    end
    UIHelper.SetVisible(self.SevenSkillsGroup, true)
    return true
end

function UIWidgetSkillCombine:InitPetSkill(tbPetSkillGroup)
    if not tbPetSkillGroup or table.is_empty(tbPetSkillGroup) then
        return
    end

    self:OnEnter()
    self.tSkillList = tbPetSkillGroup
    self:RemoveUnUsedWidget(self.ThreeSkillsGroup)
    self.szSliderWidgetName = tSliderWidgetName.WidgetBar3Small

    for nIndex, node in ipairs(self.threeSkillCombines) do
        local script = UIHelper.GetBindScript(node)
        table.insert(self.tScripts, script)

        local nGroupIndex = tbPetSkillGroup[nIndex].nPrefabIndex or 1
        local cellScript = self.tbCellScriptList[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, script.SlotParent)
        cellScript:InitSkill(tbPetSkillGroup[nIndex].nSkillID, SpecialDXSkillData.tPetSkillList[nGroupIndex][nIndex])
        cellScript:HideSkillBg()
        self.tbCellScriptList[nIndex] = cellScript
        UIHelper.SetAnchorPoint(cellScript._rootNode, 0.5, 0.5)
    end
    UIHelper.SetVisible(self.ThreeSkillsGroup, true)
    return true
end

function UIWidgetSkillCombine:InitPuppetSkill(tbPuppetSkillGroup, dwNpcTemplateID)
    if not tbPuppetSkillGroup or table.is_empty(tbPuppetSkillGroup) or table.get_len(tbPuppetSkillGroup) < 2 or not dwNpcTemplateID then
        return false
    end

    self:OnEnter()
    self.tSkillList = tbPuppetSkillGroup
    self:RemoveUnUsedWidget({ self.ThreeSkillsGroup, self.TwoSkillsGroup })

    local nSkillLen = table.get_len(tbPuppetSkillGroup)
    --local SkillsGroup = nSkillLen == 3 and self.ThreeSkillsGroup or self.TwoSkillsGroup
    local skillCombines = nSkillLen == 3 and self.threeSkillCombines or self.twoSkillCombines
    local tbCurScriptList = nSkillLen == 3 and self.tbFirstSkillList or self.tbSecondSkillList
    self.szSliderWidgetName = nSkillLen == 3 and tSliderWidgetName.WidgetBar3 or tSliderWidgetName.WidgetBar2

    for nIndex, node in ipairs(skillCombines) do
        local script = UIHelper.GetBindScript(node)
        table.insert(self.tScripts, script)

        local cellScript = tbCurScriptList[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, script.SlotParent)
        cellScript:InitSkill(tbPuppetSkillGroup[nIndex][1], SpecialDXSkillData.tPuppetShortcutIndexList[dwNpcTemplateID][nIndex])
        cellScript:HideSkillBg()
        tbCurScriptList[nIndex] = cellScript
        UIHelper.SetAnchorPoint(cellScript._rootNode, 0.5, 0.5)
    end

    self.tbCellScriptList = tbCurScriptList

    UIHelper.SetVisible(self.ThreeSkillsGroup, nSkillLen == 3)
    UIHelper.SetVisible(self.TwoSkillsGroup, nSkillLen == 2)
    return true
end

function UIWidgetSkillCombine:InitShadowSkill(tbShadowSkillGroup)
    if not tbShadowSkillGroup or table.is_empty(tbShadowSkillGroup) then
        return false
    end
    self:OnEnter()
    self:RemoveUnUsedWidget(self.SixSkillsGroup)
    self.szSliderWidgetName = tSliderWidgetName.WidgetBar6

    for nIndex, node in ipairs(self.sixSkillCombines) do
        local script = UIHelper.GetBindScript(node)
        table.insert(self.tScripts, script)
        local cellScript = self.tbCellScriptList[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, script.SlotParent)
        self.tbCellScriptList[nIndex] = cellScript

        if tbShadowSkillGroup[nIndex] then
            local nSkillID = tbShadowSkillGroup[nIndex].id
            local nBuff = tbShadowSkillGroup[nIndex].buff or 0
            cellScript:InitSkill(nSkillID, SpecialDXSkillData.tShadowShortcutIndexList[nIndex])
            cellScript:HideSkillBg()
            local szIcon, szSecondIcon = SpecialDXSkillData.GetSkillIconByBuff(nBuff)
            if szIcon and szSecondIcon then
                cellScript:UpdateIcon(szIcon, szSecondIcon)
            end
            SpecialDXSkillData.SetSkillBuffTimeEnd(nSkillID, nBuff) --设置buff结束时间
            UIHelper.SetAnchorPoint(cellScript._rootNode, 0.5, 0.5)
        end

        UIHelper.SetActiveAndCache(self, node, tbShadowSkillGroup[nIndex] ~= nil)
        UIHelper.SetActiveAndCache(self, cellScript._rootNode, tbShadowSkillGroup[nIndex] ~= nil)
    end
    UIHelper.SetVisible(self.SixSkillsGroup, true)
    return true
end

function UIWidgetSkillCombine:UnInitShadowSkill()
    for nIndex, node in ipairs(self.sixSkillCombines) do
        local cellScript = self.tbCellScriptList and self.tbCellScriptList[nIndex]
        if cellScript then
            local widgetKeyBoard = UIHelper.FindChildByName(UIHelper.GetParent(cellScript._rootNode), "WidgetKeyBoardKey")
            if widgetKeyBoard then
                local script = UIHelper.GetBindScript(widgetKeyBoard)
                script:SetID(-1)
                script:RefreshUI()
            end
        end
    end
end

function UIWidgetSkillCombine:BindCDSlider(cdScript)
    local parent = cdScript[self.szSliderWidgetName]
    if parent then
        for _, node in ipairs(cdScript.tSliderParents) do
            if parent ~= node then
                UIHelper.RemoveFromParent(node, true)
            end
        end
        UIHelper.SetVisible(parent, true)

        local tSliders = UIHelper.GetBindScript(parent).tSliders
        for nIndex, Slider in ipairs(tSliders) do
            local cellScript = self.tbCellScriptList[nIndex]
            if cellScript then
                cellScript:SetCDSlider(Slider)
            end
            UIHelper.SetActiveAndCache(self, Slider, cellScript ~= nil and UIHelper.GetVisible(cellScript._rootNode))
        end
    end
end

function UIWidgetSkillCombine:ClearCDSlider()
    for nIndex, cellScript in ipairs(self.tbCellScriptList) do
        cellScript:ClearCDSlider()
    end
    for nIndex, cellScript in ipairs(self.tbFirstSkillList) do
        cellScript:ClearCDSlider()
    end
    for nIndex, cellScript in ipairs(self.tbSecondSkillList) do
        cellScript:ClearCDSlider()
    end
end

function UIWidgetSkillCombine:RemoveUnUsedWidget(node)
    local tNodeTables = IsTable(node) and node or { node }
    if not self.bRemoved then
        self.bRemoved = true
        for _, otherParent in ipairs(self.totalCombines) do
            if not table.contain_value(tNodeTables, otherParent) then
                UIHelper.RemoveFromParent(otherParent, true)
            end
        end
    end
end

function UIWidgetSkillCombine:SetVisible(bState)
    UIHelper.SetVisible(self._rootNode, bState)
    for _, skillScript in ipairs(self.tbCellScriptList) do
        skillScript:SetSkillVisible(bState)
    end
end

function UIWidgetSkillCombine:UpdatePositionByNode(node)
    self.tPositionNode = node or self.tPositionNode
    if self.tPositionNode then
        local nWX, nWY = UIHelper.GetWorldPosition(self.tPositionNode)
        local parent = UIHelper.GetParent(self._rootNode)
        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(parent, nWX, nWY)

        UIHelper.SetPosition(self._rootNode, nLocalX, nLocalY)
    end
end

return UIWidgetSkillCombine