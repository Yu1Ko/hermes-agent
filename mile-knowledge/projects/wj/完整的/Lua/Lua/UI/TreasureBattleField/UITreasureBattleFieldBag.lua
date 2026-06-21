-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldBag
-- Date: 2023-05-19 16:06:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local _tEquipIndex2ImgIndex =
{
	[EQUIPMENT_INVENTORY.MELEE_WEAPON] = 1,
	[EQUIPMENT_INVENTORY.RANGE_WEAPON] = 10,
	[EQUIPMENT_INVENTORY.CHEST] = 2,
	[EQUIPMENT_INVENTORY.HELM] = 8,
	[EQUIPMENT_INVENTORY.AMULET] = 9,
	[EQUIPMENT_INVENTORY.LEFT_RING] = 11,
	[EQUIPMENT_INVENTORY.RIGHT_RING] = 12,
	[EQUIPMENT_INVENTORY.WAIST] = 5,
	[EQUIPMENT_INVENTORY.PENDANT] = 6,
	[EQUIPMENT_INVENTORY.PANTS] = 3,
	[EQUIPMENT_INVENTORY.BOOTS] = 4,
	[EQUIPMENT_INVENTORY.BANGLE] = 7,
}

local _tQualityColor = {
    [1] = cc.c3b(195, 195, 195),
    [2] = cc.c3b(138, 255, 164),
    [3] = cc.c3b(102, 213, 244),
    [4] = cc.c3b(190, 102, 244),
    [5] = cc.c3b(244, 150, 102),
}

local Page2Tog = {
    [1] = "TogTypeGoods",
    [2] = "TogTypeHorse",
    [3] = "TogTypeSkill",
}


local UITreasureBattleFieldBag = class("UITreasureBattleFieldBag")

function UITreasureBattleFieldBag:OnEnter(nPage, dwDoodadID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbSelected = { dwItemID = nil, tbPos = { nBox = nil, nIndex = nil }, tbBatch = nil }
    if not nPage then
        nPage = 1
    end
    self:UpdateInfo(nPage)

    self.tMoveParam = {}

    Timer.AddCycle(self, 1, function ()
        self:Tick()
    end)

    local skillScript = UIHelper.GetBindScript(self.WidgetAnchorSkillContent)
    skillScript:OnEnter()
    if nPage == 3 and dwDoodadID then
        skillScript:EnterLootMode(dwDoodadID)
    end
end

function UITreasureBattleFieldBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITreasureBattleFieldBag:BindUIEvent()
    -- UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function ()
    --     UIMgr.Close(self)
    -- end)

    UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelBattleFieldPubgSetPop)
    end)

    UIHelper.BindUIEvent(self.BtnSorting, EventType.OnClick, function ()
        TravellingBagData.BeginSort()
    end)

    UIHelper.BindUIEvent(self.BtnDiscard, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy") then
            return
        end
        local tItemList = TravellingBagData.GetTravellingBagItems()
        local tDestoryList = {}
        local nMaxQuality = 1
        for _, tItemInfo in ipairs(tItemList) do
            local hItem = tItemInfo.hItem
            if hItem and hItem.dwTabType ~= 5 and hItem.nQuality <= TreasureBattleFieldData.nDropColor then
                if TreasureBattleFieldData.bIncludeHorse or hItem.nSub ~= EQUIPMENT_SUB.HORSE then
                    table.insert(tDestoryList, {tItemInfo.nBox, tItemInfo.nIndex})
                    nMaxQuality = math.max(nMaxQuality, hItem.nQuality)
                end
            end
        end
        if #tDestoryList == 0 then
        elseif #tDestoryList == 1 then
            if TravellingBagData.tbSorting then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CANNOT_DESTROY_IN_SORT)
                return
            end
            RemoteCallToServer("On_Item_Drop", tDestoryList[1][1], tDestoryList[1][2])
        else
            if TravellingBagData.tbSorting then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CANNOT_DESTROY_IN_SORT)
                return
            end
            RemoteCallToServer("On_Item_DropTable", tDestoryList, nMaxQuality)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UITreasureBattleFieldBag:RegEvent()
    Event.Reg(self, EventType.OnClientPlayerLeave, function (nPlayerID)
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        local item = ItemData.GetItemByPos(nBox, nIndex)

        -- 更新选中道具详细信息
        if (item and item.dwID == self.tbSelected.dwItemID) or (nBox == self.tbSelected.tbPos.nBox and nIndex == self.tbSelected.tbPos.nIndex) then
            self:DoUpdateSelect(self.tbSelected.dwItemID)
        end

        -- 更新背包格子计数（used/total）
        if bNewAdd or not item then
            self:UpdateBagSize()
            -- self:UpdateEmptyWidget()
        end

        -- 更新格子
        local scriptCell = self:GetCellScript(nBox, nIndex)
        if scriptCell then
            scriptCell:UpdateInfo()
            local itemScript = scriptCell:GetItemScript()
            if itemScript then
                self:InitItemIcon(itemScript)
            end
        else
            self:UpdateBagCell()
        end

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    end)

    -- Event.Reg(self, EventType.BagItemLongPress, function(_, _, _, _, itemScript)
    --     if self.tMoveParam.puppetScript then
    --         return
    --     end
    --     if self.tMoveParam.itemScript ~= itemScript then
    --         return
    --     end
    --     self.tMoveParam.puppetScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetAnchorRight)
    --     self.tMoveParam.puppetScript:OnInit(itemScript.nBox, itemScript.nIndex)
    --     UIHelper.SetVisible(itemScript._rootNode, false)
    --     itemScript:SetToggleSwallowTouches(true)

    --     local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetAnchorRight, self.tMoveParam.nStartX, self.tMoveParam.nStartY)
    --     UIHelper.SetPosition(self.tMoveParam.puppetScript._rootNode, nLocalX, nLocalY, self.WidgetAnchorRight)
    -- end)

    Event.Reg(self,"HORSE_ITEM_UPDATE",function ()
        self:UpdateHorseCell()
    end)


    Event.Reg(self,"EQUIP_HORSE",function ()
        self:UpdateHorseCell()
    end)

    Event.Reg(self, EventType.OnSceneTouchTarget, function()
        if self.bTipsJustHide then
            return
        end

        if not UIHelper.GetVisible(self._rootNode) then
            return
        end

        UIMgr.Close(VIEW_ID.PanelBattleFieldPubgEquipBagRightPop)
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        if self.bTipsJustHide then
            return
        end

        if not UIHelper.GetVisible(self._rootNode) then
            return
        end

        UIMgr.Close(VIEW_ID.PanelBattleFieldPubgEquipBagRightPop)
    end)
end

function UITreasureBattleFieldBag:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldBag:UpdateInfo(nPage)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupType)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupType, self.TogTypeGoods)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupType, self.TogTypeHorse)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupType, self.TogTypeSkill)
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupType, self[Page2Tog[nPage]])
    UIHelper.SetVisible(self.TogTypeSkill, TreasureBattleFieldSkillData.InSkillMap())


    self:UpdateBagCell()
    self:UpdateHorseCell()
    self:UpdateEquipInfo()
end

function UITreasureBattleFieldBag:UpdateBagCell()
    UIHelper.RemoveAllChildren(self.ScrollViewGoods)
    self.tbBox = {}
    local nSize = ItemData.GetBagSize(ItemData.BoxSet.TravellingBag)
    for i = 0, nSize-1 do
        local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBagBottom, self.ScrollViewGoods)
        cellScript:OnEnter(INVENTORY_INDEX.LIMITED_PACKAGE, i)
        local itemScript = cellScript:GetItemScript()
        if itemScript then
            self:InitItemIcon(itemScript)
            self:StoreCellScript(INVENTORY_INDEX.LIMITED_PACKAGE, i, cellScript)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewGoods)
    UIHelper.ScrollToTop(self.ScrollViewGoods)
    self:UpdateBagSize()
end

function UITreasureBattleFieldBag:UpdateBagSize()
    UIHelper.SetString(self.LabelBagNum, string.format("(%d/%d)",
        ItemData.GetBagUsedSize(ItemData.BoxSet.TravellingBag), ItemData.GetBagSize(ItemData.BoxSet.TravellingBag)))
end

function UITreasureBattleFieldBag:InitItemIcon(itemScript)
    itemScript:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
    itemScript:SetSelectMode(false)
    itemScript:EnableTimeLimitFlag(true)
    itemScript:SetSelectChangeCallback(function(dwItemID, bSelected) self:OnItemSelectChange(dwItemID, bSelected) end)
    itemScript:SetLongPressDelay(0.3)
    itemScript:UnRegisterTouchEvent()
    itemScript:RegisterTouchEvent(function (script, x, y)
        self:OnItemTouchBegan(script, x, y)
    end, function (script, x, y)
        self:OnItemTouchMoved(script, x, y)
    end, function (script, x, y)
        self:OnItemTouchEnded(script)
    end, function (script)
        self:OnItemTouchEnded(script)
    end)
end

function UITreasureBattleFieldBag:OnItemSelectChange(dwItemID, bSelected)
    if bSelected then
        self:DoUpdateSelect(dwItemID)
    elseif self.tbSelected.dwItemID == dwItemID then
        self:DoUpdateSelect(nil)
    end

    -- self:UpdateSelectedItemDetails()
end

function UITreasureBattleFieldBag:DoUpdateSelect(dwItemID)
    self.tbSelected.dwItemID = dwItemID

    if self.tbSelected.dwItemID then
        local nBox, nIndex = ItemData.GetItemPos(self.tbSelected.dwItemID)
        if not nBox or not table.contain_value(ItemData.BoxSet.TravellingBag, nBox) then   -- 如果选中道具已经不在背包中
            local item = ItemData.GetItemByPos(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex) -- 用选中的格子信息找到新的选中道具
            if item then
                self.tbSelected.dwItemID = item.dwID
            else                            -- 选中的格子中页没有新的道具，无选中
                self.tbSelected.dwItemID = nil
                self.tbSelected.tbPos = {nBox = nil, nIndex = nil}
                --self:DelayAutoSelectFirstItem()
            end
        else
            self.tbSelected.tbPos = {nBox = nBox, nIndex = nIndex}
        end
    else
        self.tbSelected.tbPos = {nBox = nil, nIndex = nil}
        --self:DelayAutoSelectFirstItem()
    end
    self:UpdateSelectedItemDetails()
end

function UITreasureBattleFieldBag:DelayAutoSelectFirstItem()
    Timer.AddFrame(self, 1, function()
        if self.tbSelected.dwItemID then return end

        local tbItemList = ItemData.GetItemList(ItemData.BoxSet.TravellingBag)
        for _, tbItemInfo in ipairs(tbItemList) do
            if tbItemInfo.hItem then
                local ScriptCell = self:GetCellScript(tbItemInfo.nBox, tbItemInfo.nIndex)
                if ScriptCell then
                    local ScriptItem = ScriptCell:GetItemScript()
                    if ScriptItem then
                        ScriptItem:SetSelected(true)
                        return
                    end
                end
            end
        end
    end)
end

function UITreasureBattleFieldBag:StoreCellScript(nBox, nIndex, script)
    self.tbBox[nBox + 1] = self.tbBox[nBox + 1] or {}
    self.tbBox[nBox + 1][nIndex + 1] = script
end

function UITreasureBattleFieldBag:GetCellScript(nBox, nIndex)
    if not self.tbBox[nBox + 1] then
        return nil
    end

    return self.tbBox[nBox + 1][nIndex + 1]
end

function UITreasureBattleFieldBag:UpdateSelectedItemDetails()
    if self.tbSelected.tbPos.nBox and self.tbSelected.tbPos.nIndex then
        local tips, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.WidgetAnchorRight)
        scriptItemTip:OnInit(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)
    end
end

function UITreasureBattleFieldBag:UpdateHorseCell()
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    UIHelper.RemoveAllChildren(self.ScrollViewHorse)
    self.tbHorse = {}
    for i = 0, 19 do
        local dwBox = INVENTORY_INDEX.HORSE
        local dwIndex = i
        local item = ItemData.GetPlayerItem(g_pClientPlayer, dwBox, dwIndex)
        if item then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetHoresListTog, self.ScrollViewHorse, dwBox, dwIndex, self.WidgetAnchorRight)
            table.insert(self.tbHorse, script)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHorse)
end

function UITreasureBattleFieldBag:ClearSelect()
    self.bTipsJustHide = false
    if self.tbSelected.tbPos.nBox and self.tbSelected.tbPos.nIndex then
        local cellScript = self:GetCellScript(self.tbSelected.tbPos.nBox, self.tbSelected.tbPos.nIndex)
        local itemScript = cellScript:GetItemScript()
        if itemScript then
            itemScript:SetSelected(false)
        end
        self.bTipsJustHide = true
    end
    if self.tbHorse then
        for _, script in ipairs(self.tbHorse) do
            if script:IsSelected() then
                script:OnSelected(false)
                self.bTipsJustHide = true
            end
        end
    end
end

function UITreasureBattleFieldBag:OnItemTouchBegan(itemScript, x, y)
    if self.tMoveParam.puppetScript then
        return
    end
    self.tMoveParam.nStartX = x
    self.tMoveParam.nStartY = y
    self.tMoveParam.itemScript = itemScript
    UIHelper.SetInertiaScrollEnabled(self.ScrollViewGoods, true)
end

function UITreasureBattleFieldBag:OnItemTouchMoved(itemScript, x, y)
    if self.tMoveParam.itemScript ~= itemScript then
        return
    end
    if self.tMoveParam.puppetScript then
        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetAnchorRight, x, y)
        UIHelper.SetPosition(self.tMoveParam.puppetScript._rootNode, nLocalX, nLocalY, self.WidgetAnchorRight)
        return
    end

    local dx = x - self.tMoveParam.nStartX
    local dy = y - self.tMoveParam.nStartY
    if dx > 0 and dx * dx + dy * dy > 400 then
        local nXMin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(self.BtnMoving)
        local k1 = (nYMax - self.tMoveParam.nStartY) / (nXMin - self.tMoveParam.nStartX)
        local k2 = (nYMax - self.tMoveParam.nStartY) / (nXMax - self.tMoveParam.nStartX)
        local k3 = (nYMin - self.tMoveParam.nStartY) / (nXMin - self.tMoveParam.nStartX)
        local k4 = (nYMin - self.tMoveParam.nStartY) / (nXMax - self.tMoveParam.nStartX)
        local k0 = dy / dx
        if k0 < math.max(k1, k2) and k0 > math.min(k3, k4) then
            self.tMoveParam.puppetScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetAnchorRight)
            self.tMoveParam.puppetScript:OnInit(itemScript.nBox, itemScript.nIndex)
            UIHelper.SetVisible(itemScript._rootNode, false)
            itemScript:SetToggleSwallowTouches(true)
            UIHelper.SetInertiaScrollEnabled(self.ScrollViewGoods, false)

            local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetAnchorRight, self.tMoveParam.nStartX, self.tMoveParam.nStartY)
            UIHelper.SetPosition(self.tMoveParam.puppetScript._rootNode, nLocalX, nLocalY, self.WidgetAnchorRight)
        end
    end
end

function UITreasureBattleFieldBag:OnItemTouchEnded(itemScript)
    UIHelper.SetVisible(itemScript._rootNode, true)
    itemScript:SetToggleSwallowTouches(false)
    if self.tMoveParam.puppetScript then
        local x, y = UIHelper.GetWorldPosition(self.tMoveParam.puppetScript._rootNode)

        local nSizeX, nSizeY = UIHelper.GetContentSize(self.BtnMoving)
        local nAnchX, nAnchY = UIHelper.GetAnchorPoint(self.BtnMoving)
        local nXMin = - nSizeX * nAnchX
        local nXMax = nSizeX * (1 - nAnchX)
        local nYMin = - nSizeY * nAnchY
        local nYMax = nSizeY * (1 - nAnchY)
        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.BtnMoving, x, y)
        local bIntersect = nLocalX > nXMin and nLocalX < nXMax and nLocalY > nYMin and nLocalY < nYMax

        if bIntersect then
            local bCheckHaveLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy")
            if not bCheckHaveLocked then
                RemoteCallToServer("On_Item_Drop", itemScript.nBox, itemScript.nIndex)
            end
        end

        self.tMoveParam.puppetScript._rootNode:removeFromParent(true)
        self.tMoveParam.puppetScript = nil
    end
    self.tMoveParam = {}
end

function UITreasureBattleFieldBag:UpdateEquipInfo()
    local player = GetClientPlayer()
    for dwIndex, nImgName in pairs(_tEquipIndex2ImgIndex) do
        local img = self.tbEquipImg[nImgName]
        local item = player.GetItem(INVENTORY_INDEX.EQUIP, dwIndex)
        local nQuality = item and item.nQuality or 0
        nQuality = math.max(nQuality, 1)
        local c3b = _tQualityColor[nQuality]
        UIHelper.SetColor(img, c3b)
	end

    local nEquipScore = player.GetBaseEquipScore() + player.GetStrengthEquipScore() + player.GetMountsEquipScore()
    UIHelper.SetString(self.LabelNum, nEquipScore)
end

function UITreasureBattleFieldBag:Tick()
    self:UpdateEquipInfo()
end

return UITreasureBattleFieldBag