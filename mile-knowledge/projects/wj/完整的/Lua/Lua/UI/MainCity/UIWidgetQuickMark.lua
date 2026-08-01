-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetQuickMark
-- Date: 2023-08-18 17:05:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

-- 2772

local UIWidgetQuickMark = class("UIWidgetQuickMark")

function UIWidgetQuickMark:OnEnter(nSlotID, nMarkID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSlotID = nSlotID
    self.nMarkID = nMarkID
    self:UpdateInfo()
end

function UIWidgetQuickMark:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetQuickMark:BindUIEvent()
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchBegan, function(_, x, y)
        self:OnPressDown(x, y)
    end)

    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchMoved, function(_, x, y)
        if self.bInDirection and self.lbSkillDirection then
            self.lbSkillDirection:OnJoystickDrag(x, y)
        end

        if self.scriptSkillCancelCtrl then
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
end

function UIWidgetQuickMark:RegEvent()
    Event.Reg(self, EventType.OnSkillSlotChanged, function(nSlotID)
        if nSlotID == self.nSlotID then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnShortcutSkillQuick, function(nPressType)
        if not self.tQuickMark or not self.tQuickMark.dwSkillID then
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
        elseif nPressType == 4 then
            self:OnPressUp()
        end
    end)

    -- Event.Reg(self, EventType.OnDXTeamMarkChanged, function(nPressType)
    --     if SkillData.IsUsingHDKungFu() then
    --         self:UpdateInfo()
    --     end
    -- end)
end

function UIWidgetQuickMark:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetQuickMark:UpdateInfo()
    local bQuickUseVisible = false
    local bCanCastSkill = QTEMgr.CanCastSkill()
    if not self.scriptSkill then
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
        self.scriptSkill = scriptView and scriptView.scriptSkill
    end

    if self.scriptSkill then
        bQuickUseVisible = self.scriptSkill.bWidgetQuickUseVisible
    end

    self.tQuickMark = TeamData.GetQuickMarkSlotInfo(self.nMarkID)
    if not self.tQuickMark or not self.tQuickMark.dwSkillID or not bQuickUseVisible or not bCanCastSkill then
        self:_SetVisible(false)
    else
        UIHelper.SetActiveAndCache(self, self.cdLabel, false)
        UIHelper.SetActiveAndCache(self, self.imgSkillCd, false)
        UIHelper.SetSpriteFrame(self.imgSkillIcon, self.tQuickMark.szIconPath)
        self:_SetVisible(true)
        self:UpdateFuncName()
    end
end

function UIWidgetQuickMark:UpdateFuncName()
    local nIndex = 23
    local keyBoardNode = UIHelper.FindChildByName(UIHelper.GetParent(self._rootNode), "WidgetKeyBoardKey")
    local keyBoardScript = keyBoardNode and UIHelper.GetBindScript(keyBoardNode)  ---@type UIShortcutInteraction
    local bUpdate = false
    if SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Common][nIndex].szFuncName ~= "" then
        SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Common][nIndex].szFuncName = ""
        bUpdate = true
    end
    if keyBoardScript and bUpdate then
        keyBoardScript:UpdateInfo()
    end
end

function UIWidgetQuickMark:_SetVisible(bValue)
    local node = UIHelper.GetParent(self._rootNode) or self._rootNode
    UIHelper.SetVisible(node, bValue)
end

function UIWidgetQuickMark:SetSkillDirectionCtrl(ctrl)
    self.lbSkillDirection = ctrl ---@type UISkillDirection
end

function UIWidgetQuickMark:SetSkillCancelCtrl(ctrl)
    self.scriptSkillCancelCtrl = ctrl ---@type UISkillCancel
end

function UIWidgetQuickMark:BeginDirectionSkill(nTouchX, nTouchY)
    local tbSkillConfig = nil
    self.lbSkillDirection:OnPressDown(
        nTouchX, nTouchY,
        self.nSlotID, self.tQuickMark.dwSkillID, tbSkillConfig, nil,
        function(x, y, z)
            SkillData.CastSkillXYZ(g_pClientPlayer, self.tQuickMark.dwSkillID, self.tQuickMark.dwSkillLevel, x, y, z)
            RemoteCallToServer("On_Mobile_GetSceneMarkNum")
        end,
        function(x, y, z)
            return SkillData.CanCastSkillXYZ(g_pClientPlayer, self.tQuickMark.dwSkillID, self.tQuickMark.dwSkillLevel, x, y, z)
        end
    )

    if SkillData.IsUseSkillDirectionCancel() then
        self.scriptSkillCancelCtrl:Show()
    end

    self.bInDirection = true
end


function UIWidgetQuickMark:EndDirectionSkill()
    if self.scriptSkillCancelCtrl:IsDragIn() then
        if TeamData.CheckWorldMarkID(self.nMarkID) then
            TeamData.CancelWorldMarkID(self.nMarkID)
        end
    end

    self.scriptSkillCancelCtrl:Hide()
    self.lbSkillDirection:OnPressUp(self.nSlotID)

    self.bInDirection = false
end

function UIWidgetQuickMark:OnPressDown(nX, nY)
    if self.bInPress then
        return
    end
    local dwSkillID = self.tQuickMark.dwSkillID
    local dwSkillLevel = self.tQuickMark.dwSkillLevel

    self.bInPress = true

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
end

function UIWidgetQuickMark:OnPressUp()
    if not self.bInPress then
        return
    end

    self.bInPress = false

    if self.bInDirection then
        if self.lbSkillDirection then
            self:EndDirectionSkill()
        end
    end
end

return UIWidgetQuickMark