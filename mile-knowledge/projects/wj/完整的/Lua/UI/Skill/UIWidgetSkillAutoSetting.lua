-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillAutoSetting
-- Date: 2024.01.16 10:31:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nIndexShouldBeDeleted = -99

---@class UIWidgetSkillAutoSetting
local UIWidgetSkillAutoSetting = class("UIWidgetSkillAutoSetting")

function UIWidgetSkillAutoSetting:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.tNewSkillIndex = {}

        self.bModified = false
    end
    self.tSlotScripts = {}
    
    UIHelper.SetSelected(self.TogFlySkill, AutoBattle.IsAutoClosedAfterSprint())
end

function UIWidgetSkillAutoSetting:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSkillAutoSetting:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFlySkill, EventType.OnSelectChanged, function(tog, bSelected)
        AutoBattle.SetAutoClosedAfterSprint(bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        if self.bModified and not AutoBattle.IsCustomized(self.nCurrentKungFuID) then
            UIHelper.ShowConfirm("武学助手自定义队列发生修改，是否开启武学助手自定义配置？", function()
                AutoBattle.SetCustomized(true, self.nCurrentKungFuID)
            end)
        end
        self:SetVisible(false)
    end)

    UIHelper.BindUIEvent(self.BtnCloseAutoSettingHint, EventType.OnClick, function()
        UIHelper.SetVisible(self.ImgAutoSettingHint, false)
    end)

    UIHelper.BindUIEvent(self.ToggleSwitch, EventType.OnSelectChanged, function(toggle, bSelected)
        AutoBattle.SetCustomized(bSelected, self.nCurrentKungFuID)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        local szDesc = "使用自定义配置【关闭】：开启武学助手时，按默认优先级<color=#ffe26e>释放槽位上技能</color>\n使用自定义配置【开启】：开启武学助手时，按从左至右的<color=#ffe26e>队列顺序释放技能</color>，如果队列中的技能未装配或未满足释放条件，则会跳过，自动释放下一个技能"
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, TipsLayoutDir.LEFT_CENTER, szDesc)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)
end

function UIWidgetSkillAutoSetting:RegEvent()
end

function UIWidgetSkillAutoSetting:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetSkillAutoSetting:UpdateSkillList()
    self.tAppendSkillDict = SkillData.GetAppendSkillDict(self.nCurrentKungFuID)
end

local TotalSlotIndexes = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
function UIWidgetSkillAutoSetting:UpdateSlottedSkill()
    self.tAvailableSkillList = {}

    for i = 1, #TotalSlotIndexes do
        local nSlotIndex = TotalSlotIndexes[i]
        if self.tSlotScripts[nSlotIndex] and self.tSlotScripts[nSlotIndex]._rootNode then
            UIHelper.RemoveFromParent(self.tSlotScripts[nSlotIndex]._rootNode, true)
        end

        local nSkillID = nSlotIndex == UI_SKILL_UNIQUE_SLOT_ID and SkillData.GetUniqueSkillID(self.nCurrentKungFuID, self.nCurrentSetID)
                or SkillData.GetSlotSkillID(nSlotIndex, self.nCurrentKungFuID, self.nCurrentSetID)
        if nSkillID then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.tSkillSlotParents[i])
            self.tSlotScripts[nSlotIndex] = script

            self.tAvailableSkillList[nSkillID] = 1
            for _, nAppendSkillID in ipairs(self.tAppendSkillDict[nSkillID] or {}) do
                self.tAvailableSkillList[nAppendSkillID] = 1 --标志技能存在
            end

            script:UpdateInfo(nSkillID)
            script:SetToggleGroup(self.ToggleGroup)
            script:BindSelectFunction(function()
                self:ShowSkillTip(script:GetToggle(), nSkillID, TipsLayoutDir.LEFT_CENTER)
            end)

            local fnDragStart = function(nX, nY)
                return self:DragStart(nSkillID, script)
            end
            local fnDragMoved = function(nX, nY)
                self:MoveNode(nX, nY)
            end
            local fnDragEnd = function(nX, nY)
                self:DragEnd(nX, nY)
            end
            script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)
        end
    end
end

function UIWidgetSkillAutoSetting:UpdateAutoConfigurationList()
    local bHasInvalidSkill = false

    local list = AutoBattle.GetCustomizeSkillList(self.nCurrentKungFuID, self.nCurrentSetID)
    UIHelper.RemoveAllChildren(self.LayoutAutoSetting)
    self.tConfigurationCellList = {}
    for i = 1, AutoBattle.nMaxCustomizeNum, 1 do
        local nSkillID = list[i]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.LayoutAutoSetting)
        table.insert(self.tConfigurationCellList, script)

        if nSkillID then
            script:UpdateInfo(nSkillID)
            script:BindSelectFunction(function()
                local tipScript = self:ShowSkillTip(script:GetToggle(), nSkillID, TipsLayoutDir.TOP_CENTER)
                tipScript:SetLeftButtonInfo("删除", function()
                    self:DeleteAutoIndex(i)
                end)
                tipScript:UpdateInfo()
            end)
            if table.contain_value(self.tNewSkillIndex, i) then
                script:ShowEffect()
            end

            local fnDragStart = function(nX, nY)
                return self:DragStart(nSkillID, script, i)
            end
            local fnDragMoved = function(nX, nY)
                self:MoveNode(nX, nY)
            end
            local fnDragEnd = function(nX, nY)
                self:DragEnd(nX, nY)
            end
            script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)

            if not self.tAvailableSkillList[nSkillID] then
                bHasInvalidSkill = true -- 该自定义技能未装备
                script:SetRed(true)
            end
        else
            script:BindSelectFunction(function()
                Timer.AddFrame(self, 1, function()
                    script:SetSelected(false)
                end)
            end)
        end
    end

    UIHelper.SetVisible(self.LabelNotEquippedHint, bHasInvalidSkill)
    UIHelper.SetVisible(self.ImgAutoSettingHint, bHasInvalidSkill)
end

function UIWidgetSkillAutoSetting:UpdateInfo()
    self:UpdateSkillList()
    self:UpdateSlottedSkill()
    self:UpdateAutoConfigurationList()
    UIHelper.SetSelected(self.ToggleSwitch, AutoBattle.IsCustomized(self.nCurrentKungFuID))
end

--{{{ -------------------------Drag---------------------------------

function UIWidgetSkillAutoSetting:SetDragNode(bVisible)
    assert(self.tSelectedInfo)

    local tSkillScript = self.tSelectedInfo.tSkillScript
    local nSkillID = self.tSelectedInfo.nSkillID

    if not bVisible then
        --tSkillScript:SetSelected(false)
        UIHelper.RemoveFromParent(self.draggableNode._rootNode, true)
        self.draggableNode = nil
    else
        --UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, tSkillScript:GetToggle())

        local worldX, worldY = UIHelper.GetWorldPosition(tSkillScript._rootNode)
        local nodeX, nodeY = UIHelper.ConvertToNodeSpace(self.WidgetSlotSkillParent, worldX, worldY)

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.WidgetSlotSkillParent, nSkillID)
        script:HideLabel()
        script:SetSelected(true)
        script:SetSelectEnable(false)
        UIHelper.SetPosition(script._rootNode, nodeX, nodeY)

        self.draggableNode = script
    end
end

function UIWidgetSkillAutoSetting:DragStart(nSkillID, tSkillScript, nAutoIndex)
    self.tNewSkillIndex = {}
    if nSkillID and not self.tSelectedInfo then
        self.tSelectedInfo = {
            nSkillID = nSkillID,
            tSkillScript = tSkillScript,
            nOriginAutoIndex = nAutoIndex, -- 在自定义技能序列中的序号
        }
        self:SetDragNode(true)
        self.nTouchBeganX, self.nTouchBeganY = UIHelper.GetPosition(self.draggableNode._rootNode)
        self.tCursor = GetViewCursorPoint()
        return true
    end
    return false
end

function UIWidgetSkillAutoSetting:MoveNode(nX, nY)
    if self.draggableNode then
        local node = self.draggableNode._rootNode
        self.tCursor = GetViewCursorPoint()

        local nodeX, nodeY = UIHelper.ConvertToNodeSpace(UIHelper.GetParent(node), nX, nY)
        local w, h = UIHelper.GetContentSize(node)
        UIHelper.SetPosition(node, nodeX - w / 2, nodeY - h / 2)
    end
end

function UIWidgetSkillAutoSetting:DragEnd(nX, nY)
    local nIndex = self:CollectNodeByPoint(nX, nY)
    if nIndex >= 1 then
        self:ApplySelection(nIndex, self.tSelectedInfo.nSkillID)
    end

    if self.tSelectedInfo.nOriginAutoIndex and nIndex == nIndexShouldBeDeleted then
        self:DeleteAutoIndex(self.tSelectedInfo.nOriginAutoIndex)
    end

    self:SetDragNode(false)
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

function UIWidgetSkillAutoSetting:CollectNodeByPoint()
    local x, y = self.tCursor.x, self.tCursor.y
    local tbPoint = cc.p(x, y)    -- 鼠标位置的世界坐标

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

    for nIndex, script in pairs(self.tConfigurationCellList) do
        if table.contain_value(tbNodes, script:GetToggle()) then
            return nIndex
        end
    end

    if not table.contain_value(tbNodes, self.BtnNotDelete) then
        return nIndexShouldBeDeleted
    end

    return -1
end

--}}}

function UIWidgetSkillAutoSetting:ApplySelection(nIndex, nSkillID)
    local lst = self.tAppendSkillDict[nSkillID]
    -- 自定义技能序列内部移动
    if self.tSelectedInfo.nOriginAutoIndex then
        local lst = AutoBattle.GetCustomizeSkillList(self.nCurrentKungFuID, self.nCurrentSetID)
        local nOldAutoSkillID = lst[nIndex]

        AutoBattle.SaveCustomizeSkill(nIndex, nSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
        if nOldAutoSkillID then
            AutoBattle.SaveCustomizeSkill(self.tSelectedInfo.nOriginAutoIndex, nOldAutoSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
        else
            AutoBattle.ClearCustomizeSkill(self.tSelectedInfo.nOriginAutoIndex, self.nCurrentKungFuID, self.nCurrentSetID)
        end

        table.insert(self.tNewSkillIndex, nIndex)
        table.insert(self.tNewSkillIndex, self.tSelectedInfo.nOriginAutoIndex)
        self:UpdateInfo()
    else
        -- 从已装备技能添加到自定义技能序列
        if not lst then
            AutoBattle.SaveCustomizeSkill(nIndex, nSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
            table.insert(self.tNewSkillIndex, nIndex)
            self:UpdateInfo()
        else
            local tFinalList = clone(lst)
            table.insert(tFinalList, 1, nSkillID)
            UIMgr.Open(VIEW_ID.PanelSkillAutoSettingPop, tFinalList, function(nSubIndex)
                AutoBattle.SaveCustomizeSkill(nIndex, tFinalList[nSubIndex], self.nCurrentKungFuID, self.nCurrentSetID)
                table.insert(self.tNewSkillIndex, nIndex)
                self:UpdateInfo()
            end)
        end
    end
    self.bModified = true
end

function UIWidgetSkillAutoSetting:DeleteAutoIndex(nIndex)
    AutoBattle.ClearCustomizeSkill(nIndex, self.nCurrentKungFuID, self.nCurrentSetID)
    self:UpdateAutoConfigurationList()
end

function UIWidgetSkillAutoSetting:Show(nCurrentKungFuID, nCurrentSetID)
    self.nCurrentKungFuID = nCurrentKungFuID
    self.nCurrentSetID = nCurrentSetID
    self:SetVisible(true)
    self:UpdateInfo()
end

function UIWidgetSkillAutoSetting:SetVisible(bVisible)
    self.tNewSkillIndex = {}
    self.bModified = false
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIWidgetSkillAutoSetting:ShowSkillTip(tog, nSkillID, nTipDirection)
    local fnExit = function()
        UIHelper.SetSelected(tog, false)
    end
    local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, tog, nTipDirection,
            nSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
    tipsScriptView:BindExitFunc(fnExit)
    return tipsScriptView
end

function UIWidgetSkillAutoSetting:UpdateInvalid(nCurrentKungFuID, nCurrentSetID)
    self.nCurrentKungFuID = nCurrentKungFuID
    self.nCurrentSetID = nCurrentSetID
    self:UpdateSkillList()

    self.tAvailableSkillList = {}

    for i = 1, #TotalSlotIndexes do
        local nSlotIndex = TotalSlotIndexes[i]
        local nSkillID = nSlotIndex == UI_SKILL_UNIQUE_SLOT_ID and SkillData.GetUniqueSkillID(self.nCurrentKungFuID, self.nCurrentSetID)
                or SkillData.GetSlotSkillID(nSlotIndex, self.nCurrentKungFuID, self.nCurrentSetID)
        if nSkillID then


            self.tAvailableSkillList[nSkillID] = 1
            for _, nAppendSkillID in ipairs(self.tAppendSkillDict[nSkillID] or {}) do
                self.tAvailableSkillList[nAppendSkillID] = 1 --标志技能存在
            end
        end
    end

    local list = AutoBattle.GetCustomizeSkillList(nCurrentKungFuID, nCurrentSetID)
    local bHasInvalidSkill = false

    for i = 1, AutoBattle.nMaxCustomizeNum, 1 do
        local nSkillID = list[i]
        if nSkillID then
            if not self.tAvailableSkillList[nSkillID] then
                bHasInvalidSkill = true -- 该自定义技能未装备
                break
            end
        end
    end

    UIHelper.SetVisible(self.ImgAutoSettingHint, bHasInvalidSkill)
end

return UIWidgetSkillAutoSetting