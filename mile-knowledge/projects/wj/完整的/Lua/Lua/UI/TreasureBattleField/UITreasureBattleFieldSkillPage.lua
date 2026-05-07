-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldSkillPage
-- Date: 2024-07-19 10:31:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldSkillPage = class("UITreasureBattleFieldSkillPage")

function UITreasureBattleFieldSkillPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tLootScripts = {}
    self.tSlotScripts = {}
    self.tWaitUpdateSlot = {}
    self:UpdateInfo()
end

function UITreasureBattleFieldSkillPage:OnExit()
    if self:InLootMode() then
        Event.Dispatch(EventType.CloseLootList)
    end
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldSkillPage:BindUIEvent()
end

function UITreasureBattleFieldSkillPage:RegEvent()
    Event.Reg(self, "OPEN_DOODAD", function()
		if arg1 == UI_GetClientPlayerID() then
			self:EnterLootMode(arg0)
        end
    end)

    Event.Reg(self, "CLOSE_DOODAD", function()
		if arg1 == UI_GetClientPlayerID() and self:InLootMode(arg0) then
            self:ExitLootMode()
		end
	end)

    Event.Reg(self, "DOODAD_LEAVE_SCENE", function()
        if self:InLootMode(arg0) then
            self:ExitLootMode()
        end
	end)

    Event.Reg(self, "SYNC_LOOT_LIST", function()
        if self:InLootMode(arg0) then
			self:UpdateLootList()
		end
	end)

    Event.Reg(self, EventType.OnUpdateTreasureBattleFieldSkill, function()
        self:UpdateSlotSkills()
    end)
end

function UITreasureBattleFieldSkillPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldSkillPage:UpdateInfo()
    self:UpdateLootList()
    self:UpdateSlotSkills()
end

function UITreasureBattleFieldSkillPage:InLootMode(dwDoodadID)
    dwDoodadID = dwDoodadID or self.dwDoodadID
    return self.dwDoodadID and self.dwDoodadID == dwDoodadID
end

function UITreasureBattleFieldSkillPage:EnterLootMode(dwDoodadID)
    self.dwDoodadID = dwDoodadID
    self:UpdateLootList()
end

function UITreasureBattleFieldSkillPage:ExitLootMode()
    self.dwDoodadID = nil
    self:UpdateLootList()
end

function UITreasureBattleFieldSkillPage:UpdateLootList()
    self:CancelPuppet()
    for _, script in ipairs(self.tLootScripts) do
        local tog = script:GetToggle()
        UIHelper.ToggleGroupRemoveToggle(self.ToggleGroupAction, tog)
        UIHelper.RemoveFromParent(script._rootNode, true)
    end
    self.tLootScripts = {}
    self.tLootItemList = {}
    UIHelper.SetVisible(self.WidgetEmpty, false)
    if not self:InLootMode() then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        return
    end
    self.tLootItemList = TreasureBattleFieldSkillData.GetDoodadSkillItemList(self.dwDoodadID) or {}
    local nCount = #self.tLootItemList
    local parent
    if nCount == 0 then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        return
    elseif nCount <= 3 then
        parent = self.LayoutSkillCellLess
    else
        parent = self.LayoutSkillCellMore
    end
    UIHelper.SetVisible(self.LayoutSkillCellLess, parent == self.LayoutSkillCellLess)
    UIHelper.SetVisible(self.LayoutSkillCellMore, parent == self.LayoutSkillCellMore)
    for i, tSkillItem in ipairs(self.tLootItemList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent)
        local tog = script:GetToggle()
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupAction, tog)
        local nSkillID = tSkillItem.nSkillID
        script:UpdateInfo(nSkillID)
        local fnDragStart = function(nX, nY)
            return self:DragStart(nSkillID, {
               bLoot = true,
               dwDoodadID = self.dwDoodadID,
               tSkillItem = tSkillItem,
            }, nX, nY)
        end
        local fnDragMoved = function(nX, nY)
            self:MoveNode(nX, nY)
        end
        local fnDragEnd = function(nX, nY)
            self:DragEnd(nX, nY)
        end
        script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bSelected)
            local fnExit = function()
                UIHelper.SetSelected(tog, false)
            end
            if bSelected then
                local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, tog, TipsLayoutDir.LEFT_CENTER, nSkillID, nil, nil, 1)
                tipsScriptView:BindExitFunc(fnExit)
            end
        end)
        table.insert(self.tLootScripts, script)
    end
    UIHelper.LayoutDoLayout(parent)
end

function UITreasureBattleFieldSkillPage:UpdateSlotSkills()
    for _, script in ipairs(self.tSlotScripts) do
        local tog = script:GetToggle()
        UIHelper.ToggleGroupRemoveToggle(self.ToggleGroupAction, tog)
        UIHelper.RemoveFromParent(script._rootNode, true)
    end
    self.tSlotScripts = {}
    for i, tParent in ipairs(self.tSkillSlots) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tParent)
        local tSkillData = TreasureBattleFieldSkillData.GetSkillInfoByIndex(i)
        if tSkillData then
            local nSkillID = tSkillData.nSkillID
            script:UpdateInfo(nSkillID)
            local tog = script:GetToggle()
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupAction, tog)
            local fnDragStart = function(nX, nY)
                return self:DragStart(nSkillID, {
                    bLoot = false,
                    nSlotIndex = i,
                }, nX, nY)
            end
            local fnDragMoved = function(nX, nY)
                self:MoveNode(nX, nY)
            end
            local fnDragEnd = function(nX, nY)
                self:DragEnd(nX, nY)
            end
            script:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)
            UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bSelected)
                local fnExit = function()
                    UIHelper.SetSelected(tog, false)
                end
                if bSelected then
                    local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, tog, TipsLayoutDir.LEFT_CENTER, nSkillID, nil, nil, 1)
                    tipsScriptView:BindExitFunc(fnExit)
                end
            end)
            if self.tWaitUpdateSlot and self.tWaitUpdateSlot[i] then
                self.tWaitUpdateSlot[i] = nil
                script:ShowEffect()
            end
        end
        self.tSlotScripts[i] = script
    end
end

function UITreasureBattleFieldSkillPage:DragStart(nSkillID, userData, nX, nY)
    self.tWaitUpdateSlot = {}
    if self.tPuppetInfo then
        self:CancelPuppet()
    end
    self:CreatePuppet(nSkillID, userData, nX, nY)
    return true
end

function UITreasureBattleFieldSkillPage:MoveNode(nX, nY)
    if self.puppetNode then
        local node = self.puppetNode._rootNode
        local nodeX, nodeY = UIHelper.ConvertToNodeSpace(UIHelper.GetParent(node), nX, nY)
        local w, h = UIHelper.GetContentSize(node)
        UIHelper.SetPosition(node, nodeX - w / 2, nodeY - h / 2)
    end
end

function UITreasureBattleFieldSkillPage:DragEnd(nX, nY)
    if self.puppetNode then
        local nSlotIndex = self:CheckPuppetPosition()
        if nSlotIndex >= 1 then
            local userData = self.tPuppetInfo.userData
            if userData.bLoot then
                self.tWaitUpdateSlot[nSlotIndex] = true
                TreasureBattleFieldSkillData.ReplaceDynamicSkill(nSlotIndex, userData.dwDoodadID, userData.tSkillItem)
            else
                self.tWaitUpdateSlot[nSlotIndex] = true
                self.tWaitUpdateSlot[userData.nSlotIndex] = true
                TreasureBattleFieldSkillData.ExchangeSkill(nSlotIndex, userData.nSlotIndex)
            end
        end
    end
    self:CancelPuppet()
end

function UITreasureBattleFieldSkillPage:CreatePuppet(nSkillID, userData, nX, nY)
    self.tPuppetInfo = {
        nSkillID = nSkillID,
        userData = userData,
    }
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self._rootNode, nSkillID)
    script:SetHighlight(true)
    local nodeX, nodeY = UIHelper.ConvertToNodeSpace(self._rootNode, nX, nY)
    local w, h = UIHelper.GetContentSize(script._rootNode)
    UIHelper.SetPosition(script._rootNode, nodeX - w / 2, nodeY - h / 2)
    self.puppetNode = script
    local bDynamicSlot = false
    if userData.bLoot then
        bDynamicSlot = true
    else
        bDynamicSlot = TreasureBattleFieldSkillData.IsDynamicSkillIndex(userData.nSlotIndex)
    end
    for i, script in ipairs(self.tSlotScripts) do
        if TreasureBattleFieldSkillData.IsDynamicSkillIndex(i) == bDynamicSlot then
            script:SetHighlight(true)
        else
            script:SetGrey(true)
        end
    end
end

function UITreasureBattleFieldSkillPage:CancelPuppet()
    self.tPuppetInfo = nil
    if self.puppetNode then
        self.puppetNode._rootNode:removeFromParent(true)
        self.puppetNode = nil
    end
    for i, script in ipairs(self.tSlotScripts) do
        script:SetHighlight(false)
        script:SetGrey(false)
    end
end

function UITreasureBattleFieldSkillPage:CheckPuppetPosition()
    if not self.puppetNode then
        return -1
    end
    local nodeX, nodeY = UIHelper.GetPosition(self.puppetNode._rootNode)
    local w, h = UIHelper.GetContentSize(self.puppetNode._rootNode)
    local rect1 = cc.rect(nodeX, nodeY, w, h)
    local nMinDistance = 2^30
    local nSlotIndex = -1
    for i, script in ipairs(self.tSlotScripts) do
        local x, y = UIHelper.GetWorldPosition(script._rootNode)
        x, y = UIHelper.ConvertToNodeSpace(self._rootNode, x, y)
        local rect2 = cc.rect(x, y, w, h)
        if cc.rectIntersectsRect(rect1, rect2) then
            local nDistance = math.sqrt(math.abs(rect1.x - rect2.x)^2+math.abs(rect1.y-rect2.y)^2)
            if nDistance < nMinDistance then
                nMinDistance = nDistance
                nSlotIndex = i
            end
        end
    end
    LOG.INFO("[UITreasureBattleFieldSkillPage] CheckPuppetPosition=%d", nSlotIndex)
    LOG.TABLE(self.tPuppetInfo)
    return nSlotIndex
end

return UITreasureBattleFieldSkillPage