local SHOW_SPINRT_TIME = 0.5 --手指移动到指定范围多久后显示轻功触发区域
local SPRINT_TRIGGER_TIME = 0.3 --手指在轻功触发范围内停留多久触发刷新
local SPRINT_REFRESH_TIME = 0 --手指在轻功触发范围外停留多久刷新按钮位置
local HIT_TEST_RADIUS = 120 --触发范围半径
local HIT_TEST_OFFSET_FACTOR = 1.2 --触发范围偏移系数
local END_SPRINT_TIME = 1 --轻功时，手指停留在摇杆下半部分多久之内停止轻功
local DOUBLE_CLICK_INTERVAL = 0.3 --双击触发间隔，端游为0.25，考虑到手机端操作/延迟/卡顿等因素，加长一点

local tDXResponseWASDKeyConvert = {
    [MOVE_DIRECTION_KEY_TYPE.MoveUp] = "Forward",
    [MOVE_DIRECTION_KEY_TYPE.MoveDown] = "Backward",
    [MOVE_DIRECTION_KEY_TYPE.MoveLeft] = "TurnLeft",
    [MOVE_DIRECTION_KEY_TYPE.MoveRight] = "TurnRight",
}

local FLY_BUFF_ID = 33572

--轻功触发范围可视化
local m_bDebugDraw = false

local UIMainCityJoyStick = class("UIMainCityJoyStick")

function UIMainCityJoyStick:OnEnter()
    self.bJoystickSprintEnabled = false --若打开此开关，则通过左侧摇杆进入轻功？2023.7.11 取消摇杆进入轻功，只用右边操作按钮进出轻功
    self.bDragEndStopSprint = GameSettingData.GetNewValue(UISettingKey.ReleaseJoystickToExitSprint) --若打开此开关，则松开摇杆退出轻功

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        -- if self.bDragEndStopSprint then
        --     Timer.AddFrameCycle(self, 1, function()
        --         self:UpdateCheckSprintEnd()
        --     end)
        -- end

        Timer.AddFrameCycle(self, 1, function()
            self:UpdateLockMove()
        end)
    end

    UIHelper.SetClickInterval(self.BoxJoystick, 0)
    UIHelper.SetVisible(self.WidgetLight, false)
    self:InitData()
    self:UpdateTouchMode()
end

function UIMainCityJoyStick:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:OnJoyStickEnd()
    self.bIsMouseControlling = false
end

function UIMainCityJoyStick:InitData()
    self.bEnable = true

    self.bIsKeyboardControlling = false
    self.bIsMouseControlling = false

    self.nVirtualCursorX = nil
    self.nVirtualCursorY = nil

    self.tCurKeys = {}
    self.nRadius = 115 -- 半径

    self.nOrgiX, self.nOrgiY = UIHelper.GetPosition(self.ImgJoystick)
    self.nWorldOrigX, self.nWorldOrigY = UIHelper.GetWorldPosition(self.ImgJoystick)

    self.bCanSprintBtnShow = true
    self.nSprintOrigX, self.nSprintOrigY = UIHelper.GetWorldPosition(self.BtnFly)

    self.nParentOrgiX, self.nParentOrgiY = UIHelper.GetPosition(self.WidgetParent)
    self.nOrgiBoxX, self.nOrgiBoxY = UIHelper.GetPosition(self.BoxJoystick)
    self.nOrgiBoxW, self.nOrgiBoxH = UIHelper.GetContentSize(self.BoxJoystick)
    self.nOrgiFixBoxX, self.nOrgiFixBoxY = UIHelper.GetPosition(self.BoxJoystickFix)
    self.nOrgiFixBoxW, self.nOrgiFixBoxH = UIHelper.GetContentSize(self.BoxJoystickFix)
    self.nParentWidth, self.nParentHeight = UIHelper.GetContentSize(self.WidgetParent)
    self.nParentAnchorX, self.nParentAnchorY = UIHelper.GetAnchorPoint(self.WidgetParent)
end

function UIMainCityJoyStick:_bindBoxTouch()
    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchBegan, function(btn, nX, nY)
        if self.bIsKeyboardControlling then
            return false
        end

        self:OnJoyStickStart(nX, nY)
        self:OnJoyStickUpdate(nX, nY)
        if not self:CheckDoubleClickSkill() then
            self:CheckDoubleClickSprint()
        end

        self.bIsMouseControlling = true
    end)

    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchMoved, function(btn, nX, nY)
        if self.bIsKeyboardControlling then
            return
        end

        self:OnJoyStickUpdate(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchEnded, function(btn, nX, nY)
        if self.bIsKeyboardControlling then
            return
        end

        self:OnJoyStickEnd()

        self.bIsMouseControlling = false
    end)

    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchCanceled, function(btn, nX, nY)
        self:OnJoyStickEnd()

        self.bIsMouseControlling = false
    end)
end

function UIMainCityJoyStick:_unBindBoxTouch()
    UIHelper.UnBindUIEvent(self.BoxJoystick, EventType.OnTouchBegan)
    UIHelper.UnBindUIEvent(self.BoxJoystick, EventType.OnTouchMoved)
    UIHelper.UnBindUIEvent(self.BoxJoystick, EventType.OnTouchEnded)
    UIHelper.UnBindUIEvent(self.BoxJoystick, EventType.OnTouchCanceled)
end

function UIMainCityJoyStick:BindUIEvent()
    self:_bindBoxTouch()
    UIHelper.SetButtonClickSound(self.BoxJoystick, "")
end

function UIMainCityJoyStick:RegEvent()
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if CameraMgr.CheckAimMode() or CameraMgr.CheckHomeBuilding() then
            --载具瞄准状态 不响应摇杆
            return
        end

        self:OnKeyBoardMoveStart(szKeyName)
    end)

    Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
        self:OnKeyBoardMoveStop(szKeyName)
    end)

    Event.Reg(self, EventType.SetKeyBoardEnable, function(bEnabled)
        if not bEnabled then
            SprintData.SetAutoForward(false)
            SprintData.EndSprint() --锁键盘时退出轻功
            self:OnJoyStickEnd()
        end
    end)

    Event.Reg(self, EventType.SetJoyStickEnable, function(bEnabled)
        if not bEnabled then
            SprintData.SetAutoForward(false)
            SprintData.EndSprint() --锁操作时退出轻功
            self:OnJoyStickEnd()
        end

        LOG.INFO("UIMainCityJoyStick, SetJoyStickEnable, bEnable = " .. tostring(bEnabled))

        self.bEnable = bEnabled
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function()
        self.tCurKeys = {}
        self:OnJoyStickEnd(true)
        self.nVirtualCursorX = nil
        self.nVirtualCursorY = nil
        self.bIsKeyboardControlling = false
    end)

    Event.Reg(self, EventType.OnSprintFightStateChanged, function(bSprint)
        self:UpdateSprintCanShow(bSprint)
    end)

    Event.Reg(self, EventType.OnSprintSettingChange, function()
        self.bDragEndStopSprint = GameSettingData.GetNewValue(UISettingKey.ReleaseJoystickToExitSprint)
    end)

    Event.Reg(self, EventType.OnJoystickSettingChange, function()
        local bStart = self.nTouchX ~= nil and self.nTouchY ~= nil
        self:UpdateTouchMode(bStart, self.nTouchX, self.nTouchY)
    end)

    Event.Reg(self, EventType.OnFuncSlotChanged, function(tbAction)
        --特殊处理，当快捷键中存在的【双击W (nActionID:13)】时，按下键盘WASD时触发端游原本的ResponseWASDKey函数而不拖动摇杆
        --例：长歌切入
        self.bResponseWASDKey = table.contain_value(tbAction and tbAction.tAction, 13)
    end)

    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
        if id == FLY_BUFF_ID then
            self:UpdateReplaceControl()
        end
    end)

    Event.Reg(self, "LOADING_END", function()
        self:UpdateReplaceControl()
    end)

    -- Event.Reg(self, EventType.OnViewOpen, function(nViewID)
    --     if nViewID == VIEW_ID.PanelMiddleMap then
    --         self:_unBindBoxTouch()

    --         if not self.bIsKeyboardControlling then
    --             self:OnJoyStickEnd()
    --             self.bIsMouseControlling = false
    --         end
    --     end
    -- end)

    -- Event.Reg(self, EventType.OnViewClose, function(nViewID)
    --     if nViewID == VIEW_ID.PanelMiddleMap then
    --         self:_bindBoxTouch()
    --     end
    -- end)

    Event.Reg(self, EventType.OnGamepadJoyStickMove, function(nX, nY)
        self:OnGamepadJoyStickUpdate(nX, nY)
    end)

    Event.Reg(self, EventType.OnApplicationWillEnterForeground, function()
        self:OnJoyStickEnd()
        self.bIsMouseControlling = false
    end)
end

function UIMainCityJoyStick:UnRegEvent()

end

function UIMainCityJoyStick:OnJoyStickStart(nX, nY)
    if not self.bEnable then
        return
    end

    UIHelper.SetVisible(self.WidgetLight, true)

    --打坐时按摇杆起身
    if ChatHelper.GetCanToggleSitDown() then
        local player = GetClientPlayer()
        if player and player.nMoveState == MOVE_STATE.ON_SIT then
            ToggleSitDown()
        end
    end

    SprintData.SetAutoForward(false)

    self:UpdateTouchMode(true, nX, nY)
    self:StartSprint()

    Event.Dispatch(EventType.OnJoyStickStart)
end

---@param nX number X轴位置(-1~1)
---@param nY number Y轴位置(-1~1)
---@note 手柄遥感更新
function UIMainCityJoyStick:OnGamepadJoyStickUpdate(nNormalizeX, nNormalizeY)
    if not self.bEnable then
        return
    end
    local nDistance = math.sqrt(nNormalizeX * nNormalizeX + nNormalizeY * nNormalizeY)
    if nDistance < 0.1 then
        if self.bGamepadMoving then
            UIHelper.SetVisible(self.WidgetLight, false)
            UIHelper.SetPosition(self.ImgJoystick, self.nOrgiX, self.nOrgiY)
            self:StopControlPlayer()
            self.bGamepadMoving = false
        end
    else
        if not self.bGamepadMoving then
            UIHelper.SetVisible(self.WidgetLight, true)
            --打坐时按摇杆起身
            local player = GetClientPlayer()
            if player and player.nMoveState == MOVE_STATE.ON_SIT then
                ToggleSitDown()
            end
            self.bGamepadMoving = true
        else
            local player = GetClientPlayer()
            if player and player.nMoveState == MOVE_STATE.ON_SIT then
                return
            end
            local nX = self.nOrgiX + nNormalizeX * self.nRadius
            local nY = self.nOrgiY + nNormalizeY * self.nRadius
            UIHelper.SetPosition(self.ImgJoystick, nX, nY)

            local nRadian = math.atan2(nNormalizeY, nNormalizeX) -- 弧度
            local nAngle = -(nRadian * 180 / math.pi) -- 角度
            UIHelper.SetRotation(self.WidgetLight, nAngle)
            self:StartControlPlayer(nRadian, nNormalizeX, nNormalizeY)
        end
    end
end
---@param nX number X轴位置
---@param nY number Y轴位置
---@note 摇杆更新事件回调
function UIMainCityJoyStick:OnJoyStickUpdate(nX, nY)
    if not self.bEnable then
        return
    end

    --打坐时移动摇杆不反应
    local player = GetClientPlayer()
    if player and player.nMoveState == MOVE_STATE.ON_SIT then
        return
    end

    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.WidgetParent, nX, nY)
    if self.bIsKeyboardControlling then
        nCursorX = self.nVirtualCursorX
        nCursorY = self.nVirtualCursorY
        self.nTouchX, self.nTouchY = UIHelper.ConvertToWorldSpace(self.WidgetParent, nCursorX, nCursorY)
        self.nTouchX = self.nTouchX + self.nParentAnchorX * self.nParentWidth
        self.nTouchY = self.nTouchY + self.nParentAnchorY * self.nParentHeight
    else
        self.nTouchX = nX
        self.nTouchY = nY
    end

    local nNormalizeX, nNormalizeY
    local nDistance = kmath.len2(nCursorX, nCursorY, self.nOrgiX, self.nOrgiY)
    if nDistance > 0 then
        nNormalizeX, nNormalizeY = kmath.normalize2(nCursorX - self.nOrgiX, nCursorY - self.nOrgiY)
    else
        nNormalizeX, nNormalizeY = 0, 0
    end

    if nDistance < self.nRadius then
        UIHelper.SetPosition(self.ImgJoystick, nCursorX, nCursorY)
    else
        local nX = self.nOrgiX + nNormalizeX * self.nRadius
        local nY = self.nOrgiY + nNormalizeY * self.nRadius
        UIHelper.SetPosition(self.ImgJoystick, nX, nY)
    end

    local nRadian = math.atan2(nCursorY - self.nOrgiY, nCursorX - self.nOrgiX) -- 弧度
    local nAngle = -(nRadian * 180 / math.pi) -- 角度
    UIHelper.SetRotation(self.WidgetLight, nAngle)

    --拖动距离太小或锁操作
    if nDistance <= 3 then
        self:StopControlPlayer()
    else
        self:StartControlPlayer(nRadian, nNormalizeX, nNormalizeY)
    end

    self:UpdateSprintBtnState(nAngle, nDistance)
end

function UIMainCityJoyStick:OnJoyStickEnd(bLostFocus)
    UIHelper.SetVisible(self.WidgetLight, false)
    UIHelper.SetPosition(self.ImgJoystick, self.nOrgiX, self.nOrgiY)

    self:StopControlPlayer()
    self:StopSprint()
    self:UpdateTouchMode(false)

    self.nTouchX, self.nTouchY = nil, nil
    self.bIsMouseControlling = false
    self.bIsKeyboardControlling = false
    self.tCurKeys = {}

    Event.Dispatch(EventType.OnJoyStickEnd)
    if not bLostFocus then
        SprintData.SetAutoForward(false) --松开摇杆，停止自动前进
    end
end

function UIMainCityJoyStick:UpdateLockMove()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local bLockMove = player.nDisableMoveCtrlCounter > 0
    if self.bLockMove ~= bLockMove then
        self.bLockMove = bLockMove
        self:UpdateControlPlayer()
    end
end

function UIMainCityJoyStick:StartControlPlayer(nRotate, nNormalizeX, nNormalizeY)
    if self.nNormalizeX == nNormalizeX and self.nNormalizeY == nNormalizeY then
        return
    end

    self.nNormalizeX = nNormalizeX
    self.nNormalizeY = nNormalizeY
    self:UpdateControlPlayer()

    -- local nDirection = nRotate * 255 / (math.pi * 2)
    -- if (nDirection >= 255) then
    --     nDirection = nDirection - 255
    -- end
end

function UIMainCityJoyStick:StopControlPlayer()
    self.nNormalizeX = 0
    self.nNormalizeY = 0
    self:UpdateControlPlayer()
end

function UIMainCityJoyStick:UpdateControlPlayer()
    local nNormalizeX = 0
    local nNormalizeY = 0
    if not self.bLockMove then
        nNormalizeX = self.nNormalizeX or 0
        nNormalizeY = self.nNormalizeY or 0
    end

    if self.bReplaceControl then
        local nNormalizeXAbs = math.abs(nNormalizeX)
        local nNormalizeYAbs = math.abs(nNormalizeY)
        local nControl
        if nNormalizeX > 0 and nNormalizeXAbs >= nNormalizeYAbs then
            nControl = ControlDef.CONTROL_STRAFE_RIGHT
        elseif nNormalizeX < 0 and nNormalizeXAbs >= nNormalizeYAbs then
            nControl = ControlDef.CONTROL_STRAFE_LEFT
        elseif nNormalizeY > 0 and nNormalizeYAbs >= nNormalizeXAbs then
            nControl = ControlDef.CONTROL_JUMP
        elseif nNormalizeY < 0 and nNormalizeYAbs >= nNormalizeXAbs then
            nControl = ControlDef.CONTROL_BACKWARD
        end
        if nControl ~= self.nLastControl then
            if self.nLastControl then
                Camera_EnableControl(self.nLastControl, false)
            end
            if nControl then
                Camera_EnableControl(nControl, true)
            end
            self.nLastControl = nControl
        end
        return
    end

    CameraMgr.SetDirectionVector(nNormalizeX, nNormalizeY)
end

function UIMainCityJoyStick:StartRotateCamera(szDirectionKey)
    local szJoystickType = ShortcutInteractionData.GetDirectionKeyJoyStickType(szDirectionKey)
    if szJoystickType == MOVE_DIRECTION_KEY_TYPE.MoveLeft then
        Camera_EnableControl(ControlDef.CONTROL_TURN_LEFT, true)
    else
        Camera_EnableControl(ControlDef.CONTROL_TURN_RIGHT, true)
    end
    if not self.tbInRotateCamera then
        self.tbInRotateCamera = {}
    end
    self.tbInRotateCamera[szDirectionKey] = true
end

function UIMainCityJoyStick:StopRotateCamera(szDirectionKey)
    local szJoystickType = ShortcutInteractionData.GetDirectionKeyJoyStickType(szDirectionKey)
    if szJoystickType == MOVE_DIRECTION_KEY_TYPE.MoveLeft then
        Camera_EnableControl(ControlDef.CONTROL_TURN_LEFT, false)
    else
        Camera_EnableControl(ControlDef.CONTROL_TURN_RIGHT, false)
    end
    self.tbInRotateCamera[szDirectionKey] = false
end

function UIMainCityJoyStick:IsInRotateCamera(szDirectionKey)
    return self.tbInRotateCamera and self.tbInRotateCamera[szDirectionKey] == true
end

function UIMainCityJoyStick:OnKeyBoardMoveStart(szDirectionKey)
    if not ShortcutInteractionData.IsMoveKey(szDirectionKey) or ShortcutInteractionData.CheckSingleKeySwallow(szDirectionKey) then
        return
    end
    
    if GameSettingData.GetNewValue(UISettingKey.OnlyRotateCamera) and ShortcutInteractionData.IsMoveLeftOrRightKey(szDirectionKey) then
        self:StartRotateCamera(szDirectionKey)
        return
    end
    if self.bResponseWASDKey then
        local szJoystickType = ShortcutInteractionData.GetDirectionKeyJoyStickType(szDirectionKey)
        local szDirection = szJoystickType and tDXResponseWASDKeyConvert[szJoystickType]
        if szDirection then
            ResponseWASDKey(szDirection, true, false)
            return
        end
    end
    if self.bIsMouseControlling then
        return
    end
    if self.tCurKeys[szDirectionKey] then
        return
    end

    self.tCurKeys[szDirectionKey] = true
    self.bIsKeyboardControlling = true

    local nDirX, nDirY = ShortcutInteractionData.GetJoyStickDirection(self.tCurKeys)
    local bStart = table.get_len(self.tCurKeys) == 1
    if bStart then
        self:OnJoyStickStart()
    end

    self.nVirtualCursorX = self.nOrgiX + self.nRadius * nDirX
    self.nVirtualCursorY = self.nOrgiY + self.nRadius * nDirY
    self:OnJoyStickUpdate()

    if bStart then
        if not self:CheckDoubleClickSkill() then
            self:CheckDoubleClickSprint()
        end
    end
end

function UIMainCityJoyStick:OnKeyBoardMoveStop(szDirectionKey)
    if not ShortcutInteractionData.IsMoveKey(szDirectionKey) or ShortcutInteractionData.CheckSingleKeySwallow(szDirectionKey) then
        return
    end
    if self:IsInRotateCamera(szDirectionKey) and ShortcutInteractionData.IsMoveLeftOrRightKey(szDirectionKey) then
        self:StopRotateCamera(szDirectionKey)
        return
    end
    if self.bIsMouseControlling then
        return
    end
    if self.bResponseWASDKey then
        local szJoystickType = ShortcutInteractionData.GetDirectionKeyJoyStickType(szDirectionKey)
        local szDirection = szJoystickType and tDXResponseWASDKeyConvert[szJoystickType]
        if szDirection then
            ResponseWASDKey(szDirection, false, false)
            --return
        end
    end
    if not self.tCurKeys[szDirectionKey] then
        return
    end

    self.tCurKeys[szDirectionKey] = nil
    if table.is_empty(self.tCurKeys) then
        self:OnJoyStickEnd()

        self.nVirtualCursorX = nil
        self.nVirtualCursorY = nil

        self.bIsKeyboardControlling = false
    else
        local nDirX, nDirY = ShortcutInteractionData.GetJoyStickDirection(self.tCurKeys)
        self.nVirtualCursorX = self.nOrgiX + self.nRadius * nDirX
        self.nVirtualCursorY = self.nOrgiY + self.nRadius * nDirY
        self:OnJoyStickUpdate()
    end
end

-- ===========================================================================
-- 摇杆模式
-- ===========================================================================
function UIMainCityJoyStick:UpdateTouchMode(bStart, nX, nY)
    --[[
        后面有设置可以设置是固定模式还是跟随模式
        固定模式：一直显示，位置固定
        跟随模式：使用时显示，位置跟随手指
    ]]

    local bIsFix = false
    local bIsShow = false

    if Channel.Is_WLColud() or Platform.IsMobile() then
        bIsFix = GameSettingData.GetNewValue(UISettingKey.FixedJoystick)
        bIsShow = GameSettingData.GetNewValue(UISettingKey.JoystickDisplay)
    else
        bIsFix = GameSettingData.GetNewValue(UISettingKey.FixedJoystick)
        bIsShow = GameSettingData.GetNewValue(UISettingKey.DisplayJoystick)

        UIHelper.SetVisible(self.WidgetParent, bIsShow)
        UIHelper.SetVisible(self.BoxJoystick, bIsShow)
        self.bIsJoystickFix = true
    end

    if bIsFix then
        UIHelper.SetPosition(self.BoxJoystick, self.nOrgiFixBoxX, self.nOrgiFixBoxY)
        UIHelper.SetContentSize(self.BoxJoystick, self.nOrgiFixBoxW, self.nOrgiFixBoxH)
    else
        UIHelper.SetPosition(self.BoxJoystick, self.nOrgiBoxX, self.nOrgiBoxY)
        UIHelper.SetContentSize(self.BoxJoystick, self.nOrgiBoxW, self.nOrgiBoxH)
    end

    local bVisible = bIsFix and true or (bIsShow or bStart)
    local nPosX, nPosY = self.nParentOrgiX, self.nParentOrgiY
    if not bIsFix and nX and nY then
        nPosX, nPosY = UIHelper.ConvertToNodeSpace(self.BoxJoystick, nX, nY)
    end

    --[[
    if not bIsFix and bStart then
        local nDeltaX, nDeltaY = nPosX - self.nParentOrgiX, nPosY - self.nParentOrgiY
        local nNormalizeX, nNormalizeY = kmath.normalize2(nPosX - self.nParentOrgiX, nPosY - self.nParentOrgiY)
        local nNormalizeX2, nNormalizeY2 = kmath.normalize2(self.nParentOrgiX - nPosX, self.nParentOrgiY - nPosY)
        nPosX = nDeltaX > 0 and nPosX - (self.nRadius * nNormalizeX) or nPosX + (self.nRadius * nNormalizeX2)
        nPosY = nDeltaY > 0 and nPosY - (self.nRadius * nNormalizeY) or nPosY + (self.nRadius * nNormalizeY2)
    end
    ]]

    UIHelper.SetPosition(self.WidgetParent, nPosX, nPosY)
    UIHelper.SetVisible(self.WidgetParent, bVisible)
end











-- =================================================================
-- 冲刺、疾跑
-- =================================================================

function UIMainCityJoyStick:UpdateSprintBtnState(nAngle, nDistance)
    local nCurrentTime = GetTickCount()
    if not SprintData.GetExpectSprint() then
        self.nBackSprintBtnTime = nil

        if not self.bJoystickSprintEnabled then
            return
        end

        local player = GetClientPlayer()
        if not player then
            return
        end

        if not SprintData.CanSprint() or player.bFightState then
            self:SetSprintEnabled(false)
            self:SetSprintBtnVisible(false)
            return
        end

        --手指移到特定范围显示显示按钮
        local bShow = false
        if nAngle and nDistance then
            bShow = nAngle >= -120 and nAngle <= -37.5 and nDistance >= self.nRadius
        end

        local bCanSprint = player.IsFollowController() and player.nFollowType ~= FOLLOW_TYPE.HOLDHORSE
        if bShow and self.bCanSprintBtnShow and bCanSprint then
            self.nAngle = nAngle
            if not self.nShowSprintBtnTime then
                self.nShowSprintBtnTime = nCurrentTime
            end
        else
            self.nShowSprintBtnTime = nil
            self:SetSprintBtnVisible(false)
        end
    else
        self.nShowSprintBtnTime = nil
        local bBackward = nAngle and nDistance and nAngle > 30 and nAngle < 150 and nDistance >= 5
        if bBackward then
            if not self.nBackSprintBtnTime then
                self.nBackSprintBtnTime = nCurrentTime
            end
        else
            self.nBackSprintBtnTime = nil
        end
    end
end

function UIMainCityJoyStick:UpdateSprintBtnPos()
    if not self.nAngle then
        return
    end

    local nUIAngle = self.nAngle + 90
    UIHelper.SetRotation(self.WidgetFly, nUIAngle)
    UIHelper.SetRotation(self.BtnFly, -nUIAngle)
end

function UIMainCityJoyStick:UpdateSprintCanShow(bSprint)
    if not self.bJoystickSprintEnabled then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if bSprint == nil then
        bSprint = SprintData.GetViewState()
    end

    self:SetSprintEnabled(bSprint)
    self.bCanSprintBtnShow = bSprint

    local bShow = UIHelper.GetVisible(self.WidgetFly)
    self:SetSprintBtnVisible(bShow and self.bCanSprintBtnShow)
end

function UIMainCityJoyStick:SetSprintEnabled(bEnabled, bImmediately)
    if bEnabled == SprintData.GetExpectSprint() then
        return
    end

    if bEnabled then
        SprintData.StartSprint(bImmediately)
        self:SetSprintBtnVisible(false)
    else
        SprintData.EndSprint(false, bImmediately)
    end
end

function UIMainCityJoyStick:UpdateSprintEnabled()
    local bDragging = self:IsDragging()
    local bAutoForward = SprintData.GetAutoForward()
    local bCanSprint = not SprintData.GetExpectSprint() and (bDragging or bAutoForward)

    local player = GetClientPlayer()
    local bFight = player and player.bFightState

    if not bCanSprint then
        self:ResetSprintState()
        return
    end

    local nCurrentTime = GetTickCount()
    if not UIHelper.GetVisible(self.WidgetFly) then
        if self.nShowSprintBtnTime and nCurrentTime - self.nShowSprintBtnTime >= SHOW_SPINRT_TIME * 1000 then
            self.nShowSprintBtnTime = nil
            self:SetSprintBtnVisible(true)
            self:UpdateSprintBtnPos()
        else
            self:ResetSprintState()
            return
        end
    end

    if self:HitTest(self.BtnFly, self.nTouchX, self.nTouchY, HIT_TEST_RADIUS, HIT_TEST_OFFSET_FACTOR) then
        self.nExitSprintBtnTime = nil

        --手指在轻功按钮上连续停留一段时间则开始轻功
        if not self.nEnterSprintBtnTime then
            self.nEnterSprintBtnTime = nCurrentTime
        end
        if nCurrentTime - self.nEnterSprintBtnTime >= SPRINT_TRIGGER_TIME * 1000 then
            self.nEnterSprintBtnTime = nil
            self:SetSprintEnabled(true)
        end
    else
        self.nEnterSprintBtnTime = nil

        --手指在轻功按钮外连续停留一段时间则刷新按钮显示位置
        if not self.nExitSprintBtnTime then
            self.nExitSprintBtnTime = nCurrentTime
        end
        if nCurrentTime - self.nExitSprintBtnTime >= SPRINT_REFRESH_TIME * 1000 then
            self.nExitSprintBtnTime = nil
            self:UpdateSprintBtnPos()
        end
    end
end

function UIMainCityJoyStick:HitTest(node, nTouchX, nTouchY, nRadius, nOffsetFactor)
    if not self.tbCenterPos then
        local nCenterX, nCenterY = UIHelper.GetWorldPosition(self.WidgetFly)
        self.tbCenterPos = cc.p(nCenterX, nCenterY)
    end

    nOffsetFactor = nOffsetFactor or 1
    local nPosX, nPosY = UIHelper.GetWorldPosition(node)
    local nCheckX = (nPosX - self.tbCenterPos.x) * nOffsetFactor + self.tbCenterPos.x
    local nCheckY = (nPosY - self.tbCenterPos.y) * nOffsetFactor + self.tbCenterPos.y

    if m_bDebugDraw then
        DebugDraw.Clear()
        DebugDraw.DrawCircleXY(nCheckX, nCheckY, nRadius)
        DebugDraw.DrawCircle(self.tbCenterPos, 10)
        DebugDraw.DrawCircleXY(nTouchX, nTouchY, 10)
        DebugDraw.DrawCircleXY(nPosX, nPosY, 10)
        DebugDraw.DrawCircleXY(nCheckX, nCheckY, 10)
    end

    local nDeltaX = nCheckX - nTouchX
    local nDeltaY = nCheckY - nTouchY
    return nDeltaX * nDeltaX + nDeltaY * nDeltaY <= nRadius * nRadius
end

function UIMainCityJoyStick:UpdateCheckSprintEnd()
    if not SprintData.GetExpectSprint() then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local bDragging = self:IsDragging()
    if not bDragging then
        --若进入轻功后在空中松开摇杆，则落地时再退出，所以把下面这行注释了；否则落地后不会自动退出轻功
        --self.bDragEndStopSprint = false

        --松开摇杆时，若不在空中则退出轻功
        if player.nJumpCount == 0 then
            self:SetSprintEnabled(false)
        end
    end
end

--检测双击摇杆前进开始轻功
function UIMainCityJoyStick:CheckDoubleClickSprint()
    if self.bReplaceControl then
        return
    end

    if not self.nTouchX or not self.nTouchY then
        self.nLastForwardTime = nil
        return
    end

    if not GameSettingData.GetNewValue(UISettingKey.DoubleTapToSprint) then
        self.nLastForwardTime = nil
        return
    end

    local bForward = not self.bIsJoystickFix or self:IsDraggingForward()
    if not bForward then
        self.nLastForwardTime = nil
        return
    end

    local nCurTime = GetTickCount()
    if self.nLastForwardTime and nCurTime - self.nLastForwardTime < DOUBLE_CLICK_INTERVAL * 1000 then
        self:SetSprintEnabled(true, true)
    end
    self.nLastForwardTime = nCurTime
end

function UIMainCityJoyStick:CheckDoubleClickSkill()
    if not self.nTouchX or not self.nTouchY then
        self.nLastClickTime = nil
        return
    end

    if ShortcutInteractionData.IsPressingMultiKey() then
        return
    end

    local szDirection = self:GetDraggingDirection()
    if not szDirection then
        self.nLastClickTime = nil
        return
    end

    local nCurTime = GetTickCount()
    if szDirection == self.szLastDirection and self.nLastClickTime and nCurTime - self.nLastClickTime < DOUBLE_CLICK_INTERVAL * 1000 then
        return ResponseWASDKey(szDirection, true, true)
    end
    self.nLastClickTime = nCurTime
    self.szLastDirection = szDirection
end

function UIMainCityJoyStick:SetSprintBtnVisible(bVisible)
    UIHelper.SetVisible(self.WidgetFly, bVisible)
    if not bVisible and m_bDebugDraw then
        DebugDraw.Clear()
    end
end

function UIMainCityJoyStick:ResetSprintState()
    self.nEnterSprintBtnTime = nil
    self.nExitSprintBtnTime = nil

    if not self:IsDragging() then
        self.nShowSprintBtnTime = nil
    end
end

function UIMainCityJoyStick:StartSprint()
    if not self.bJoystickSprintEnabled then
        return
    end

    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddFrameCycle(self, 1, function()
        self:UpdateSprintEnabled()
    end)
end

function UIMainCityJoyStick:StopSprint()
    if not self.bResponseWASDKey and not self.bReplaceControl then
        if self.bDragEndStopSprint then
            self:SetSprintEnabled(false, true)
        elseif self.nBackSprintBtnTime and GetTickCount() - self.nBackSprintBtnTime <= END_SPRINT_TIME * 1000 then
            --若未开启松开摇杆退出轻功，仅当松开摇杆时，若摇杆在下半停留时间小，且不在空中，则结束轻功
            local player = GetClientPlayer()
            if player and player.nJumpCount == 0 then
                self:SetSprintEnabled(false)
            end
        end
    end

    self.nBackSprintBtnTime = nil

    if not self.bJoystickSprintEnabled then
        return
    end

    Timer.DelTimer(self, self.nTimerID)

    --松开摇杆时隐藏轻功按钮
    self:SetSprintBtnVisible(false)

    self:ResetSprintState()
end

function UIMainCityJoyStick:UpdateReplaceControl()
    local player = GetClientPlayer()
    self:OnJoyStickEnd()
    self.bIsMouseControlling = false
    self.bReplaceControl = player and player.IsHaveBuff(FLY_BUFF_ID, 1)
    if self.nLastControl then
        Camera_EnableControl(self.nLastControl, false)
        self.nLastControl = nil
    end
end

--是否正在拖拽摇杆
function UIMainCityJoyStick:IsDragging()
    return self.nTouchX and self.nTouchY
end

function UIMainCityJoyStick:IsDraggingForward()
    if not self:IsDragging() then
        return
    end

    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.WidgetParent, self.nTouchX, self.nTouchY)
    local nDistance = kmath.len2(nCursorX, nCursorY, self.nOrgiX, self.nOrgiY)
    local nRadian = math.atan2(nCursorY - self.nOrgiY, nCursorX - self.nOrgiX) -- 弧度
    local nAngle = -(nRadian * 180 / math.pi) -- 角度

    local bForward = nAngle > -150 and nAngle < -30 and nDistance >= 5
    return bForward
end

function UIMainCityJoyStick:GetDraggingDirection()
    if not self:IsDragging() then
        return
    end

    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.WidgetParent, self.nTouchX, self.nTouchY)
    local nDistance = kmath.len2(nCursorX, nCursorY, self.nOrgiX, self.nOrgiY)
    local nRadian = math.atan2(nCursorY - self.nOrgiY, nCursorX - self.nOrgiX) -- 弧度
    local nAngle = -(nRadian * 180 / math.pi) -- 角度

    local bForward = nAngle > -135 and nAngle < -45 and nDistance >= 5
    if bForward then
        return tDXResponseWASDKeyConvert[MOVE_DIRECTION_KEY_TYPE.MoveUp]
    end

    local bLeft = (nAngle < -135 or nAngle > 135) and nDistance >= 5
    if bLeft then
        return tDXResponseWASDKeyConvert[MOVE_DIRECTION_KEY_TYPE.MoveLeft]
    end

    local bBackward = nAngle < 135 and nAngle > 45 and nDistance >= 5
    if bBackward then
        return tDXResponseWASDKeyConvert[MOVE_DIRECTION_KEY_TYPE.MoveDown]
    end

    local bRight = nAngle < 45 and nAngle > -45 and nDistance >= 5
    if bRight then
        return tDXResponseWASDKeyConvert[MOVE_DIRECTION_KEY_TYPE.MoveRight]
    end
end

return UIMainCityJoyStick