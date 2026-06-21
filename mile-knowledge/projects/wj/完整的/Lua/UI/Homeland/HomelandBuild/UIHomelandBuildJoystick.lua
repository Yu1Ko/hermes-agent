local UIHomelandJoystick = class("UIHomelandJoystick")
local MinOpacity = 100
function UIHomelandJoystick:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bIsKeyboardControlling = false
    self.bIsMouseControlling = false
    self.bIsCtrlDown = false

    self.nVirtualCursorX = nil
    self.nVirtualCursorY = nil

    self.tCurKeys = {}
    self.nRadius = 115 -- 半径

    self.nOrgiX, self.nOrgiY = UIHelper.GetPosition(self.ImgJoystick)

    self.nWorldOrigX, self.nWorldOrigY = UIHelper.GetWorldPosition(self.ImgJoystick)
    self.nSprintOrigX, self.nSprintOrigY = UIHelper.GetWorldPosition(self.BtnFly)

    UIHelper.SetVisible(self.WidgetLight, false)
    self:Hide()

    if HomelandBuildData.GetInputType() == HLB_INPUT_TYPE.MAK then
        UIHelper.SetVisible(self._rootNode, false)
    end
end

function UIHomelandJoystick:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandJoystick:BindUIEvent()
    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchBegan, function(btn, nX, nY)
        if self.bIsKeyboardControlling then return end

        self:OnJoyStickStart()
        self:OnJoyStickUpdate(nX, nY)

        self.bIsMouseControlling = true
    end)

    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchMoved, function(btn, nX, nY)
        if self.bIsKeyboardControlling then return end

        self:OnJoyStickUpdate(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchEnded, function(btn, nX, nY)
        self:OnJoyStickEnd()
    end)

    UIHelper.BindUIEvent(self.BoxJoystick, EventType.OnTouchCanceled, function(btn, nX, nY)
        self:OnJoyStickEnd()
    end)

    UIHelper.SetButtonClickSound(self.BoxJoystick, "")
end

function UIHomelandJoystick:RegEvent()
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_CTRL then
            self.bIsCtrlDown = true
            return
        end
        self:OnKeyBoardMoveStart(szKeyName)
    end)

    Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_CTRL then
            self.bIsCtrlDown = false
            return
        end
        self:OnKeyBoardMoveStop(szKeyName)
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function()
        self:OnJoyStickEnd()
    end)
end

function UIHomelandJoystick:UnRegEvent()
    Event.UnReg(self, EventType.OnKeyboardDown)
    Event.UnReg(self, EventType.OnKeyboardUp)
    Event.UnReg(self, EventType.OnWindowsLostFocus)
end

function UIHomelandJoystick:OnJoyStickStart()
    UIHelper.SetVisible(self.WidgetLight, true)
    self:Show()

    Event.Dispatch(EventType.OnHomelandJoyStickStart)
end

---@param nX number X轴位置
---@param nY number Y轴位置
---@note 摇杆更新事件回调
function UIHomelandJoystick:OnJoyStickUpdate(nX, nY)
    if self.bIsCtrlDown then return end
    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.BoxJoystick, nX, nY)
    if self.bIsKeyboardControlling then
        nCursorX = self.nVirtualCursorX
        nCursorY = self.nVirtualCursorY

        self.nTouchX, self.nTouchY = UIHelper.ConvertToWorldSpace(self.BoxJoystick, nCursorX, nCursorY)
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

    if nDistance > 3 then
        self:StartControlPlayer(nRadian, nNormalizeX, nNormalizeY)
    end
end

function UIHomelandJoystick:OnJoyStickEnd()
    self.nTouchX, self.nTouchY = nil, nil
    self:Hide()

    UIHelper.SetVisible(self.WidgetLight, false)
    UIHelper.SetPosition(self.ImgJoystick, self.nOrgiX, self.nOrgiY)

    self:StopControlPlayer()

    self.bIsMouseControlling = false
    self.bIsKeyboardControlling = false
    self.tCurKeys = {}
    self.nVirtualCursorX = nil
    self.nVirtualCursorY = nil

    Event.Dispatch(EventType.OnHomelandJoyStickEnd)
end

function UIHomelandJoystick:StartControlPlayer(nRotate, nNormalizeX, nNormalizeY)
    local bForward = nNormalizeY > 0.2
    local bBackward = nNormalizeY < -0.2
    local bLeft = nNormalizeX < -0.2
    local bRight = nNormalizeX > 0.2

    if bForward or bBackward or bLeft or bRight then
        HLBOp_Other.ResetCameraMode()
    end

    -- A
    if bLeft then
        if not self.bIsCtrlDown then
            HLBOp_Camera.OnAKeyDown()
        end
    else
        HLBOp_Camera.OnAKeyUp()
    end

    -- S
    if bBackward then
        if not self.bIsCtrlDown then
            HLBOp_Camera.OnSKeyDown()
        end
    else
        HLBOp_Camera.OnSKeyUp()
    end

    -- D
    if bRight then
        if not self.bIsCtrlDown then
            HLBOp_Camera.OnDKeyDown()
        end
    else
        HLBOp_Camera.OnDKeyUp()
    end

    -- W
    if bForward then
        if not self.bIsCtrlDown then
            HLBOp_Camera.OnWKeyDown()
        end
    else
        HLBOp_Camera.OnWKeyUp()
    end
end

function UIHomelandJoystick:StopControlPlayer()
    HLBOp_Camera.OnAKeyUp()
    HLBOp_Camera.OnSKeyUp()
    HLBOp_Camera.OnDKeyUp()
    HLBOp_Camera.OnWKeyUp()
end

function UIHomelandJoystick:OnKeyBoardMoveStart(szDirectionKey)
    if self.bIsMouseControlling or self.bIsCtrlDown then return end
    if not ShortcutInteractionData.IsMoveKey(szDirectionKey) then return end

    if self.tCurKeys[szDirectionKey] then return end

    self.tCurKeys[szDirectionKey] = true
    self.bIsKeyboardControlling = true

    local nDirX, nDirY = ShortcutInteractionData.GetJoyStickDirection(self.tCurKeys)
    if table.get_len(self.tCurKeys) == 1 then
        self:OnJoyStickStart()
    end

    self.nVirtualCursorX = self.nOrgiX + self.nRadius * nDirX
    self.nVirtualCursorY = self.nOrgiY + self.nRadius * nDirY
    self:OnJoyStickUpdate()
end

function UIHomelandJoystick:OnKeyBoardMoveStop(szDirectionKey)
    if self.bIsMouseControlling or self.bIsCtrlDown then return end
    if not ShortcutInteractionData.IsMoveKey(szDirectionKey) then return end
    if not self.tCurKeys[szDirectionKey] then return end

    self.tCurKeys[szDirectionKey] = nil
    if table.is_empty(self.tCurKeys) then
        self:OnJoyStickEnd()
    else
        local nDirX, nDirY = ShortcutInteractionData.GetJoyStickDirection(self.tCurKeys)
        self.nVirtualCursorX = self.nOrgiX + self.nRadius * nDirX
        self.nVirtualCursorY = self.nOrgiY + self.nRadius * nDirY
        self:OnJoyStickUpdate()
    end
end

function UIHomelandJoystick:Show()
    Timer.DelTimer(self, self.nHideTimerID)
    UIHelper.SetOpacity(self._rootNode, 255)
end

function UIHomelandJoystick:Hide()
    self.nCurOpacity = UIHelper.GetOpacity(self._rootNode)
    self.nHideTimerID = Timer.AddFrameCycle(self, 1, function()
        if self.nCurOpacity <= MinOpacity then
            Timer.DelTimer(self, self.nHideTimerID)
            return
        end

        self.nCurOpacity = self.nCurOpacity - 1
        UIHelper.SetOpacity(self._rootNode, self.nCurOpacity)
    end)
end



return UIHomelandJoystick