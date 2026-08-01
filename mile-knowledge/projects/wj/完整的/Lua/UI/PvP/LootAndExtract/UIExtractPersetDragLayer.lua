-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetDragLayer
-- Date: 2025-03-26 19:40:53
-- Desc: ?
-- ---------------------------------------------------------------------------------
local LEFT = 1
local RIGHT = 2
local EQUIP = 3
local nLongPressDalay = 1000
local nDragOffset = 40
local DOUBLE_CLICK_INTERVAL = 0.3 --双击触发间隔，端游为0.25，考虑到手机端操作/延迟/卡顿等因素，加长一点
local UIExtractPersetDragLayer = class("UIExtractPersetDragLayer")

function UIExtractPersetDragLayer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bBatchSell = false

    self.bDraging = false
    self.nLastForwardTime = nil
    self.tbDragInfo = {}
    self.scriptHandOnItem = nil
    self.scriptItemTip = nil
end

function UIExtractPersetDragLayer:OnExit()
    self.bInit = false
    self.scrollList_Left = nil
    self.scrollList_Right = nil

    if self.nDragTimerID then
        Timer.DelTimer(self, self.nDragTimerID)
        self.nDragTimerID = nil
    end

    if self.nLongPressTimer then
        Timer.DelTimer(self, self.nLongPressTimer)
        self.nLongPressTimer = nil
    end

    if self.nScrollTime then
        Timer.DelTimer(self, self.nScrollTime)
        self.nScrollTime = nil
    end

    self:UnRegEvent()
end

function UIExtractPersetDragLayer:BindUIEvent()
    self._rootNode:setTouchEnabled(true)
    self._rootNode:setClippingEnabled(true)
    self._rootNode:setSwallowTouches(false)
    UIHelper.SetTouchDownHideTips(self._rootNode, false)

    UIHelper.BindUIEvent(self._rootNode, EventType.OnTouchBegan, function(_, x, y)
        self.scrollList_Left:SetScrollEnabled(true)
        self.scrollList_Right:SetScrollEnabled(true)
        self.tbDragInfo.tbStartPos = nil
        local node, bInParent = self:GetTouchNode(x, y)
        if not node then
            return
        end
        local scriptItem = UIHelper.GetBindScript(node)
        if not scriptItem then
            return
        end

        self:CheckLongPress(scriptItem, x, y)

        local nCurTime = GetTickCount()
        if self.nLastForwardTime and nCurTime - self.nLastForwardTime < DOUBLE_CLICK_INTERVAL * 1000 then
            self:OnDoubleClick(scriptItem)
        end

        self.tbDragInfo.tbHandItemInfo = nil
        self.tbDragInfo.scriptHandItem = nil

        local tbInfo = scriptItem:GetItemInfo()
        local tbPos = {nStartX = x, nStartY = y}
        self.tbDragInfo.tbStartPos = tbPos
        self.tbDragInfo.tbHandItemInfo = tbInfo
        self.tbDragInfo.scriptHandItem = clone(scriptItem, true)

        self.nLastForwardTime = nCurTime
	end)

	UIHelper.BindUIEvent(self._rootNode, EventType.OnTouchMoved, function(node, x, y)
        if not self.tbDragInfo.tbStartPos then
            return
        end

        local nOffsetX = x - self.tbDragInfo.tbStartPos.nStartX
        local nOffsetY = y - self.tbDragInfo.tbStartPos.nStartY

        local tbInfo = self.tbDragInfo.tbHandItemInfo
        local bSkill = tbInfo and tbInfo.dwItemType == "skill"
        if not bSkill then
            if math.abs(nOffsetY) >= nDragOffset and not self.bDraging then
                -- 视为玩家滑动列表，不处理拖拽
                if self.nLongPressTimer then
                    Timer.DelTimer(self, self.nLongPressTimer)
                    self.nLongPressTimer = nil
                end
                return
            end
        end

        if math.abs(nOffsetX) >= nDragOffset or (bSkill and math.abs(nOffsetY) >= nDragOffset) then
            local dwType, dwIndex = tbInfo.dwItemType, tbInfo.dwItemIndex
            if dwType and dwIndex then
                self:OnDragBeging(dwType, dwIndex)
            end
        end

        if self.bDraging and self.scriptHandOnItem then
            local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self._rootNode, x, y)
            UIHelper.SetPosition(self.scriptHandOnItem._rootNode, nLocalX, nLocalY, self._rootNode)
        end
        self:AutoScrollUpdate(x, y)
	end)

	UIHelper.BindUIEvent(self._rootNode, EventType.OnTouchEnded, function(_, x, y)
        if self.nLongPressTimer then
            Timer.DelTimer(self, self.nLongPressTimer)
            self.nLongPressTimer = nil
        end

        if self.nScrollTime then
            Timer.DelTimer(self, self.nScrollTime)
            self.nScrollTime = nil
        end

        if not self.bDraging or not self.tbDragInfo.tbHandItemInfo then
            return
        end

        self.bDraging = false
        self.scrollList_Left:SetScrollEnabled(true)
        self.scrollList_Right:SetScrollEnabled(true)
        self:CreatHandOnItem()
        local nodeTarget, bInParent = self:GetTouchNode(x, y)
        local scriptTargetItem = UIHelper.GetBindScript(nodeTarget)

        if self.tbDragInfo and self.tbDragInfo.scriptHandItem then
            if self.bBatchSell then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSELL)
                return
            end
            self.tbDragInfo.scriptHandItem:OnDragEnd(scriptTargetItem, nodeTarget, bInParent)
        end
	end)
end

function UIExtractPersetDragLayer:RegEvent()
    Event.Reg(self, EventType.OnSceneTouchNothing, function ()
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.scriptItemTip then
            UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
        end

        if self.scriptSkillTip then
            UIHelper.SetVisible(self.scriptSkillTip._rootNode, false)
        end
    end)
end

function UIExtractPersetDragLayer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function JudgeInNode(x, y, node)
    if not x or not y then
        return false
    end

    if not UIHelper.GetHierarchyVisible(node) then
        return false
    end

    local nXmin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(node)
    if nXmin and nXMax and nYMin and nYMax then
        if x >= nXmin and x <= nXMax and y >= nYMin and y <= nYMax then
            return true
        else
            return false
        end
    else
        return false
    end
end

function UIExtractPersetDragLayer:OnDragBeging(dwType, dwIndex)
    self:CreatHandOnItem(dwType, dwIndex)
    self.bDraging = true
    self.scrollList_Left:SetScrollEnabled(false)
    self.scrollList_Right:SetScrollEnabled(false)
    self.scrollList_Left.m.bDragging = false
    self.scrollList_Right.m.bDragging = false

    if self.nLongPressTimer then
        Timer.DelTimer(self, self.nLongPressTimer)
        self.nLongPressTimer = nil
    end
end

function UIExtractPersetDragLayer:GetTouchNode(x, y)
    local bInParent = false

    if JudgeInNode(x, y, self.WidgetEquipList) then
        for index, node in ipairs(self.tbEquipList) do
            if JudgeInNode(x, y, node) then
                local item = UIHelper.GetChildren(node)[1]
                local scriptNode = UIHelper.GetBindScript(item)
                if scriptNode then
                    return item
                end
            end
        end
        return
    elseif UIHelper.GetVisible(self.WidgetAnchorSetting) and JudgeInNode(x, y, self.WidgetAnchorSetting) then
        for index, node in ipairs(self.tbSkillWidget) do
            if JudgeInNode(x, y, node) then
                return node
            end
        end
        return
    end

    for _, parent in ipairs(self.tbItemParent) do
        if JudgeInNode(x, y, parent) then
            bInParent = true
            local nodeParent = UIHelper.FindChildByName(parent, "Content")
            local tbChildren = UIHelper.GetChildren(nodeParent) or {}
            for _, node in ipairs(tbChildren) do
                local scriptNode = UIHelper.GetBindScript(node)
                if scriptNode then
                    local nodeItems = UIHelper.GetChildren(scriptNode.LayoutBagItem)
                    for _, item in pairs(nodeItems) do
                        if JudgeInNode(x, y, item) then
                            return item, bInParent
                        end
                    end
                end
            end
            return nil, bInParent
        end
    end
    return nil, bInParent
end

function UIExtractPersetDragLayer:CreatHandOnItem(nType, nIndex)
    if not self.bDraging and self.scriptHandOnItem then
        UIHelper.RemoveFromParent(self.scriptHandOnItem._rootNode)
        self.scriptHandOnItem = nil
    end

    if not nType or not nIndex then
        return
    end

    if not self.scriptHandOnItem then
        local nPrefabID = PREFAB_ID.WidgetItem_100
        if nType == "skill" then
            nPrefabID = PREFAB_ID.WidgetSkillCell1
        end
        self.scriptHandOnItem = UIHelper.AddPrefab(nPrefabID, self._rootNode)
        UIHelper.SetScale(self.scriptHandOnItem._rootNode, 0.5, 0.5)
    end

    if self.scriptHandOnItem.nTabType == nType and self.scriptHandOnItem.nTabID == nIndex then
        return
    end

    if nType == 0 or nIndex == 0 then
        Timer.DelTimer(self, self.nDragTimerID)
        self.nDragTimerID = nil
        UIHelper.SetVisible(self.scriptHandOnItem._rootNode, false)
        return
    end

    if IsString(nType) and nType == "skill" then
        self.scriptHandOnItem.bInit = false
        self.scriptHandOnItem:OnEnter(nIndex, 1)
        self.scriptHandOnItem.nTabType = nType
        self.scriptHandOnItem.nTabID = nIndex
        UIHelper.SetAnchorPoint(self.scriptHandOnItem._rootNode, 0.5, 0.5)
    else
        self.scriptHandOnItem:OnInitWithTabID(nType, nIndex)
    end

    self.nDragTimerID = self.nDragTimerID or Timer.AddFrameCycle(self, 1, function ()
        if not self.bDraging
            or (not self.scriptHandOnItem.nTabType or not self.scriptHandOnItem.nTabID) then
                Timer.DelTimer(self, self.nDragTimerID)
                self.nDragTimerID = nil
                if self.scriptHandOnItem then
                    UIHelper.RemoveFromParent(self.scriptHandOnItem._rootNode)
                    self.scriptHandOnItem = nil
                end
                return
        end
        UIHelper.SetVisible(self.scriptHandOnItem._rootNode, true)
    end)
end

function UIExtractPersetDragLayer:OnDoubleClick(scriptTouchNode)
    if not self.tbDragInfo or not self.tbDragInfo.scriptHandItem then
        return false
    end

    if not self.tbDragInfo.scriptHandItem.GetItemInfo or not scriptTouchNode.GetItemInfo then
        return false
    end

    if self.bBatchSell then
        return
    end

    local tLastInfo = self.tbDragInfo.scriptHandItem:GetItemInfo()
    local tCurInfo = scriptTouchNode:GetItemInfo()

    if not table.deepCompare(tLastInfo, tCurInfo) then
        return false
    end

    if scriptTouchNode.OnDoubleClick then
        scriptTouchNode:OnDoubleClick()
    end

    return true
end

function UIExtractPersetDragLayer:CheckLongPress(scriptItem, x, y)
    if self.bDraging then
        return
    end

    local nBeginTime = GetTickCount()
    self.nLongPressTimer = self.nLongPressTimer or Timer.AddFrameCycle(self, 1, function ()
        local nDalay = GetTickCount() - nBeginTime
        local tbInfo = scriptItem:GetItemInfo()
        if nDalay >= nLongPressDalay then
            self:OnDragBeging(tbInfo.dwItemType, tbInfo.dwItemIndex)

            if self.scriptHandOnItem then
                local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self._rootNode, x, y)
                UIHelper.SetPosition(self.scriptHandOnItem._rootNode, nLocalX, nLocalY, self._rootNode)
            end

            Timer.DelTimer(self, self.nLongPressTimer)
            self.nLongPressTimer = nil
        end
    end)
end

--------------ScrollList相关--------------------
local ITEM_DRAG_ACC = -0.1
local TIME_TO_MAX_SPEED = 1
local STANDARD_MOVE_SPEED = 10
local MAX_INCREMENT_SPEED = 30

local function _GetScorllSpeed(nStayTime, nFpsLimit)
    nFpsLimit = nFpsLimit or GetFpsLimit()
    nStayTime = nStayTime or 0
    local nDelta = STANDARD_MOVE_SPEED + MAX_INCREMENT_SPEED / (1 + math.exp(ITEM_DRAG_ACC * (nStayTime - nFpsLimit * TIME_TO_MAX_SPEED)))
    return nDelta
end

function UIExtractPersetDragLayer:SetScrollList(scrollListLeft, scrollListRight)
    self.scrollList_Left = scrollListLeft
    self.scrollList_Right = scrollListRight
end

function UIExtractPersetDragLayer:AutoScrollUpdate(nPosX, nPosY)
    local tScrollList
    local widget, key = table.find_if(self.tbWidgetBorder_L, function (node)
        local bInNode = JudgeInNode(nPosX, nPosY, node)
        if bInNode then
            tScrollList = self.scrollList_Left
        end
        return bInNode
    end)

    if not key then
        widget, key = table.find_if(self.tbWidgetBorder_R, function (node)
            local bInNode = JudgeInNode(nPosX, nPosY, node)
            if bInNode then
                tScrollList = self.scrollList_Right
            end
            return bInNode
        end)
    end

    if key then
        local nStayTime = 0
        local nFpsLimit = GetFPS()
        local direction = key == 2 and -1 or 1

        self.nScrollTime = self.nScrollTime or Timer.AddFrameCycle(self, 1, function()
            local nCurPercent = tScrollList:GetPercentage()
            if self.bDraging and nCurPercent >= 0 and nCurPercent <= 1 then
                local nDelta = _GetScorllSpeed(nStayTime, nFpsLimit) * direction
                tScrollList:_SetContentPosWithOffset(nDelta, false)
                nStayTime = nStayTime + 1
            end
        end)
    else
        if self.nScrollTime then
            Timer.DelTimer(self, self.nScrollTime)
            self.nScrollTime = nil
        end
    end
end
--------------ScrollList相关--------------------

--------------------外部接口--------------------------
function UIExtractPersetDragLayer:OpenItemTip(nDir)
    nDir = nDir or RIGHT
    local parent = self.tbWidgetItemTip[nDir]

    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode)
        self.scriptItemTip = nil
    end

    self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, parent)
    UIHelper.SetAnchorPoint(self.scriptItemTip._rootNode, 0.5, 1)
    return self.scriptItemTip
end

function UIExtractPersetDragLayer:OpenSkillTip(nDir)
    nDir = nDir or RIGHT
    local parent = self.tbWidgetItemTip[nDir]

    if self.scriptSkillTip then
        UIHelper.RemoveFromParent(self.scriptSkillTip._rootNode)
        self.scriptSkillTip = nil
    end

    self.scriptSkillTip = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillInfoTips, parent)
    UIHelper.SetAnchorPoint(self.scriptSkillTip._rootNode, 0.5, 1)
    return self.scriptSkillTip
end

function UIExtractPersetDragLayer:SetSellMode(bSet)
    self.bBatchSell = bSet
end
--------------------外部接口--------------------------

return UIExtractPersetDragLayer