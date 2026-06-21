--**********************************************************************************
-- 脚本名称: UIWidgetQuickUseItem
-- 创建时间: 2023年4月18日
-- 功能概述: 战斗技能槽位 快捷使用道具
--**********************************************************************************
local Timer = Timer
local UIWidgetQuickUseItem = class("UIWidgetQuickUseItem")

local bDecimalPoint = true
local szDisabled = "不满足释放条件"

function UIWidgetQuickUseItem:OnEnter(nSlotID, tbDefaultItemInfo, bList)
    -- 数据初始化
    self.nSlotID = nSlotID
    self._isShown = true

    if not self.bInit then
        self:RegEvents()
        self:BindUIEventListener() -- 绑定组件消息
        self.bInit = true
    end

    if bList then
        self.tbDefaultItemInfoList = tbDefaultItemInfo
    else
        self.tbDefaultItemInfo = tbDefaultItemInfo
    end

    self:UpdateInfo()

    self.nCDTimer = self.nCDTimer or Timer.AddCycle(self, 0.3, function()
        self:UpdateCD()
    end)

end

function UIWidgetQuickUseItem:OnExit()
    self.bInit = false
    self:UnRegEvents()
    self.nCDTimer = nil
    Timer.DelAllTimer(self)
end

function UIWidgetQuickUseItem:BindUIEventListener()
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchBegan, function(_, x, y)
        self:OnPressDown(x, y)
    end)

    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchMoved, function(_, x, y)
        if self.bInDirection and self.lbSkillDirection then
            self.lbSkillDirection:OnJoystickDrag(x, y)
        end

        if self.bSHowSkillCancelCtrl and self.scriptSkillCancelCtrl then
            self.scriptSkillCancelCtrl:Tick(x, y)
        end
    end)

    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchEnded, function()
        -- print("OnTouchEnded")
        self:OnPressUp()
    end)

    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchCanceled, function()
        -- print("OnTouchCanceled")
        self:OnPressUp()
    end)

    UIHelper.SetButtonClickSound(self.skillBtn, "")

    UIHelper.BindUIEvent(self.skillBtn, EventType.OnLongPress, function(_, x, y)
        if not self.tbItemSlotInfo then
            return
        end
        local tCursor = GetCursorPoint()
        local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetItemTip, tCursor.x, tCursor.y)
        tipsScriptView:SetFunctionButtons({})
        tipsScriptView:OnInitWithTabID(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)

        self:OnPressUp(true)
    end)

    UIHelper.BindUIEvent(self.skillBtn, EventType.OnClick, function()
        if self.bInClickUse then
            ItemData.QuickUseItem(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
        end
    end)
end

function UIWidgetQuickUseItem:RegEvents()
    Event.Reg(self, EventType.OnSkillSlotChanged, function(nSlotID)
        LOG.INFO("UIWidgetQuickUseItem OnSkillSlotChanged %d", nSlotID)
        if nSlotID == self.nSlotID then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnQuestTracingTargetChanged, function ()
        self:UpdateTrackingQuestItem()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(_nBox, _nIndex, _bNewAdd)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSkillSlotQuickUseChange, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "FIGHT_HINT", function(bFight)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnShortcutUseQuickItem, function(nSlotId, nPressType)
        if self.nSlotID ~= nSlotId then
            return
        end
        if not UIHelper.GetHierarchyVisible(self.skillBtn) then
            return
        end
        if nPressType == 1 then
            self:OnPressDown()
        elseif nPressType == 2 then
            if self.bInDirection and self.lbSkillDirection then
                self.lbSkillDirection:OnJoystickDrag()
            end
        elseif nPressType == 3 then
            self:OnPressUp()
            if self.bInClickUse then
                ItemData.QuickUseItem(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
            end
        elseif nPressType == 4 then
            self:OnPressUp()
        end
    end)

    Event.Reg(self, EventType.OnShortcutSkillQuick, function(nPressType)
        if nPressType ~= 3 then
            return
        end
        if not self.tbItemSlotInfo then
            return
        end
        if not UIHelper.GetHierarchyVisible(self.skillBtn) then
            return
        end
        ItemData.QuickUseItem(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
    end)
end

function UIWidgetQuickUseItem:UnRegEvents()
    Event.UnRegAll(self)
end

function UIWidgetQuickUseItem:UpdateInfo()
    self.tbItemSlotInfo = self:GetDefaultItemInfo() or ItemData.GetQuickUseSlotInfo()
    if self.tbItemSlotInfo and self.tbItemSlotInfo.dwTabType then
        self.tbItemInfo = ItemData.GetItemInfo(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)

        self:UpdateIcon()
        self:UpdateCD()
        self:UpdateAmount()
    end
    self:UpdateNodeVisible()
end

function UIWidgetQuickUseItem:SetSkillDirectionCtrl(ctrl)
    self.lbSkillDirection = ctrl ---@type UISkillDirection
end

function UIWidgetQuickUseItem:SetSkillSelectPlayerCtrl(ctrl)
    self.lbSkillTargetSelect = ctrl
end

function UIWidgetQuickUseItem:SetSkillCancelCtrl(ctrl)
    self.scriptSkillCancelCtrl = ctrl ---@type UISkillCancel
end

function UIWidgetQuickUseItem:SetSkillGreyAndCache(isGrey, bHideEffect, bEquipment)
    local isCurIconGrey = self._IsSkillIconGreyCache
    local bHasDefaultItem = self:HasDefaultItem()
    if isGrey ~= isCurIconGrey then
        -- UIHelper.SetTouchEnabled(self.skillBtn, not isGrey or bHasDefaultItem)
        UIHelper.SetButtonState(self.skillBtn, isGrey and BTN_STATE.Disable or BTN_STATE.Normal, function()
            if self.tbItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
                local bEquiped = ItemData.HasItemInBox(INVENTORY_INDEX.EQUIP, self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
                if not bEquiped then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_USE_FAILED_NOT_EQUIPED)
                end
            end
        end)
        self._IsSkillIconGreyCache = isGrey
    end
    Event.Dispatch("ON_QUICKUSEITEM_STATE_CHANGE", bHideEffect, bEquipment)
end

function UIWidgetQuickUseItem:SetCountDownAndCache(fTime)
    local cacheTime = self._CountDownCache
    if fTime ~= cacheTime then
        if fTime < 1 then
            if bDecimalPoint then
                UIHelper.SetString(self.cdLabel, string.format("%0.1f", fTime))
            else
                UIHelper.SetString(self.cdLabel, string.format("0"))
            end
        else
            UIHelper.SetString(self.cdLabel, string.format("%.0f", fTime))
        end
        self._CountDownCache = fTime
    end
end

function UIWidgetQuickUseItem:OnEnable()
end

function UIWidgetQuickUseItem:OnDisable()
    self:OnPressUp()
end

function UIWidgetQuickUseItem:BeginDirectionSkill(nTouchX, nTouchY)
    local tbSkillConfig = TabHelper.GetUISkill(self.tbItemInfo.dwSkillID)

    self.lbSkillDirection:OnPressDown(
        nTouchX, nTouchY,
        self.nSlotID, self.tbItemInfo.dwSkillID, tbSkillConfig, nil,
        function(x, y, z)
            ItemData.QuickUseItem(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex, {nX = x, nY = y, nZ = z})
        end,
        function(x, y, z)
            local skill = GetSkill(self.tbItemInfo.dwSkillID, self.tbItemInfo.dwSkillLevel)
            if not skill then return false end

            return skill.CheckDistance(g_pClientPlayer.dwID, x, y, z) == SKILL_RESULT_CODE.SUCCESS
        end
    )

    if SkillData.IsUseSkillDirectionCancel() then
        self.scriptSkillCancelCtrl:Show()
        self.bSHowSkillCancelCtrl = true
    end

    self.bInDirection = true
end

function UIWidgetQuickUseItem:EndDirectionSkill(bForceCancel)
    bForceCancel = bForceCancel or false
    self.scriptSkillCancelCtrl:Hide()
    self.bSHowSkillCancelCtrl = false

    if bForceCancel then
        self.lbSkillDirection:OnDirectionSkillEnd(self.nSlotID)
    else
        self.lbSkillDirection:OnPressUp(self.nSlotID)
    end

    self.bInDirection = false
end

function UIWidgetQuickUseItem:UpdateCD()
    if not self.tbItemSlotInfo then return end
    if not self._isShown then return end
    if not g_pClientPlayer or not g_pClientPlayer.GetScene() then return end

    local bShowCD = false
    local bIsCooldown, nLeftCooldown, nTotalCooldown, _bBroken, _nCDCount = ItemData.GetItemCDProgressByTab(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)

    if bIsCooldown then
        if nLeftCooldown > 0 then
            bShowCD = true

            self:SetCountDownAndCache(nLeftCooldown / GLOBAL.GAME_FPS)
            UIHelper.SetProgressBarPercent(self.imgSkillCd, nLeftCooldown / nTotalCooldown * 100)
        end
    end

    UIHelper.SetActiveAndCache(self, self.cdLabel, bShowCD)
    UIHelper.SetActiveAndCache(self, self.imgSkillCd, bShowCD)

    self:UpdateGreyState(bShowCD)
end

function UIWidgetQuickUseItem:UpdateIcon()
    local bResult = UIHelper.SetItemIconByItemInfo(self.imgSkillIcon, self.tbItemInfo, nil, true, function()
        UIHelper.UpdateMask(self.MaskSkillIcon)
    end)
    if not bResult then
        UIHelper.ClearTexture(self.imgSkillIcon)
    end

    UIHelper.UpdateMask(self.MaskSkillIcon)
end

function UIWidgetQuickUseItem:OnPressDown(nX, nY)
    if self.bInPress then
        return
    end

    if not self.tbItemSlotInfo then
        return
    end

    local nAmount = ItemData.GetItemCanUseAmount(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
    if nAmount <= 0 then
        TipsHelper.ShowNormalTip("数量不足")
        return
    end

    local dwSkillID = self.tbItemInfo.dwSkillID
    local dwSkillLevel = self.tbItemInfo.dwSkillLevel

    self.bInPress = true
    self.bInClickUse = false

    if dwSkillID and dwSkillID ~= 0 then
        local skill = GetSkill(dwSkillID, dwSkillLevel)
        if skill then
            local nMode = skill.nCastMode
            if nMode == SKILL_CAST_MODE.POINT_AREA or nMode == SKILL_CAST_MODE.POINT then
                if self.lbSkillDirection then
                    self:BeginDirectionSkill(nX, nY)
                    return
                end
            end
        end
    end

    self.bInClickUse = true
    -- ItemData.QuickUseItem(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
end

function UIWidgetQuickUseItem:OnPressUp(bForceCancel)
    bForceCancel = bForceCancel or false

    if not self.bInPress then
        return
    end

    self.bInPress = false

    if self.bInDirection then
        if self.lbSkillDirection then
            self:EndDirectionSkill(bForceCancel)
        end
    end

    if self.bInClickUse and bForceCancel then
        self.bInClickUse = false
    end
end

function UIWidgetQuickUseItem:_SetVisible(bValue)
    local node = UIHelper.GetParent(self._rootNode) or self._rootNode
    UIHelper.SetVisible(node, bValue)
end

function UIWidgetQuickUseItem:UpdateNodeVisible()
    local bQuickUseVisible = false
    if not self.scriptSkill then
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
        self.scriptSkill = scriptView and scriptView.scriptSkill
    end

    if self.scriptSkill then
        bQuickUseVisible = self.scriptSkill.bWidgetQuickUseVisible
    end

    local bCanCastSkill = QTEMgr.CanCastSkill()
    local bInXunbao = QTEMgr.IsInXunBaoState()
    local bHasDefaultItem = self:HasDefaultItem()

    UIHelper.SetVisible(self._rootNode, self.tbItemSlotInfo and self.tbItemSlotInfo.dwTabType and (bCanCastSkill or bHasDefaultItem or bInXunbao))
    local bShowSkill = (bQuickUseVisible and bCanCastSkill or bHasDefaultItem or bInXunbao) and self.tbItemSlotInfo and self.tbItemSlotInfo.dwTabType
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.SetVisible(parent, bShowSkill and JiangHuData.bHideSkill)
    if bShowSkill and JiangHuData.bHideSkill then
        self:UpdateFuncName()
    end
end

function UIWidgetQuickUseItem:UpdateAmount()
    if not self.tbItemSlotInfo then
        return
    end

    local bHasDefaultItem = self:HasDefaultItem()
    local nAmount = ItemData.GetItemCanUseAmount(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
    local nItemQuality = self.tbItemInfo and self.tbItemInfo.nQuality or 0
    UIHelper.SetVisible(self.ChargeLabel, bHasDefaultItem and nAmount > 0)
    UIHelper.SetString(self.ChargeLabel, tostring(nAmount))
    UIHelper.SetVisible(self.ImgColorFrame, (bHasDefaultItem and nItemQuality) and nAmount > 0)
    UIHelper.SetColor(self.ImgColorFrame, ItemQualityColorC4b[nItemQuality + 1])
end

function UIWidgetQuickUseItem:UpdateFuncName()
    local nIndex = 23
    local keyBoardNode = UIHelper.FindChildByName(UIHelper.GetParent(self._rootNode), "WidgetKeyBoardKey")
    local keyBoardScript = keyBoardNode and UIHelper.GetBindScript(keyBoardNode)  ---@type UIShortcutInteraction
    SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Common][nIndex].szFuncName = ""
    if keyBoardScript then
        keyBoardScript:UpdateInfo()
    end
end

function UIWidgetQuickUseItem:UpdateGreyState(bInCD)
    local nAmount = ItemData.GetItemCanUseAmount(self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)
    local bGrey = nAmount == 0
    local bHideEffect = false
    local bNotInFightState = true
    local bEquipment = false
    local bInXunbao = QTEMgr.IsInXunBaoState()

    if g_pClientPlayer and g_pClientPlayer.bFightState then
        bNotInFightState = false
    end

    bHideEffect = bGrey
    if self.tbItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
        local bEquiped = ItemData.HasItemInBox(INVENTORY_INDEX.EQUIP, self.tbItemSlotInfo.dwTabType, self.tbItemSlotInfo.dwIndex)

        bGrey = bGrey or bInCD or not bEquiped
        bHideEffect = bHideEffect or bInCD or bNotInFightState
        bEquipment = true
    end

    if bInXunbao then
        bHideEffect = true -- 寻宝模式下隐藏特效
    end

    self:SetSkillGreyAndCache(bGrey, bHideEffect, bEquipment)
end

function UIWidgetQuickUseItem:GetTraceQuestID()
    local tbQuestID = QuestData.GetTracingQuestIDList()
    local nMinDistance = 9999999
    local nTraceQuestID = 0
    for nIndex, nQuestID in ipairs(tbQuestID) do
        local nDistance = QuestData.GetQuestDistance(nQuestID)
        if nDistance and nDistance < nMinDistance then
            nMinDistance = nDistance
            nTraceQuestID = nQuestID
        end
    end
    return nTraceQuestID
end

function UIWidgetQuickUseItem:UpdateTrackingQuestItem()
    local nQuestID = self:GetTraceQuestID()
    if nQuestID == self.nQuestID then return end
    self.nQuestID = nQuestID

    local bNeedQuickUse = false
    local tbQuestInfo = QuestData.GetQuestInfo(self.nQuestID)
    if tbQuestInfo then
        local tbConf = QuestData.GetQuestConfig(self.nQuestID)
        local dwItemType = tbQuestInfo["dwOfferItemType1"]
        local dwItemIndex = tbQuestInfo["dwOfferItemIndex1"]
        if dwItemType > 0 and dwItemIndex > 0 and tbConf and tbConf.bUseItem then
            if ItemData.CanQuickUseOnSkillSlot(dwItemType, dwItemIndex, ItemData.QuickUseOperateType.TrackQuest) then
                ItemData.AddQuickUseSlotType(dwItemType, dwItemIndex, ItemData.QuickUseOperateType.TrackQuest)
                bNeedQuickUse = true
            end
        end
    end

    if not bNeedQuickUse then
        ItemData.RemoveQuickUseSlotTypeByOperateType(ItemData.QuickUseOperateType.TrackQuest)
    end
    self:UpdateInfo()
end

-- 是否有预设道具
function UIWidgetQuickUseItem:HasDefaultItem()
    local defaultItemInfo = self:GetDefaultItemInfo()
    return defaultItemInfo ~= nil
end

function UIWidgetQuickUseItem:SetDefaultItemInfo(itemInfo)
    self.tbDefaultItemInfo = itemInfo
    self:UpdateInfo()
end

function UIWidgetQuickUseItem:SetDefaultItemInfoList(itemInfoList)
    self.tbDefaultItemInfoList = itemInfoList
    self:UpdateInfo()
end

function UIWidgetQuickUseItem:GetDefaultItemInfo()
    if self.tbDefaultItemInfo then
        return self.tbDefaultItemInfo
    end
    if self.tbDefaultItemInfoList then
        local defaultItemInfo = self.tbDefaultItemInfoList[1]
        for _, itemInfo in ipairs(self.tbDefaultItemInfoList) do
            local nAmount = ItemData.GetItemCanUseAmount(itemInfo.dwTabType, itemInfo.dwIndex)
            if nAmount > 0 then
                defaultItemInfo = itemInfo
                break
            end
        end
        return defaultItemInfo
    end
end

return UIWidgetQuickUseItem
