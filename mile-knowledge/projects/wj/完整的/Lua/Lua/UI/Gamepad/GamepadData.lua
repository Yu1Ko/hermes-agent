GamepadData = GamepadData or {}
local self = GamepadData

GamepadMoveMode =
{
    Normal  = 1, -- 正常模式
    Cursor  = 2, -- 光标模式
    Count   = 2,
}

GamepadKeyCode =
{
    KEY_A          = 1,
    KEY_B          = 2,
    KEY_X          = 3,
    KEY_Y          = 4,
    KEY_MENU       = 5,
    KEY_OPTIONS    = 6,
    KEY_DPAD_UP    = 7,
    KEY_DPAD_DOWN  = 8,
    KEY_DPAD_LEFT  = 9,
    KEY_DPAD_RIGHT = 10,
    KEY_L_SHOULDER = 11, -- LB
    KEY_R_SHOULDER = 12, -- RB
    KEY_L_TRIGGER  = 13, -- LT
    KEY_R_TRIGGER  = 14, -- RT
    KEY_L_THUMB    = 15, -- 左摇杆
    KEY_R_THUMB    = 16, -- 右摇杆
}

GamePadType =
{
    NONE        = 0,
    PS4         = 1,
    PS5         = 2,
    XBOX        = 3,
    SWITCH      = 4,
    TYPE_COUNT  = 5
};

GamepadKeyCode2Name =
{
    [GamepadKeyCode.KEY_A          ] = "A",
    [GamepadKeyCode.KEY_B          ] = "B",
    [GamepadKeyCode.KEY_X          ] = "X",
    [GamepadKeyCode.KEY_Y          ] = "Y",
    [GamepadKeyCode.KEY_MENU       ] = "MENU",
    [GamepadKeyCode.KEY_OPTIONS    ] = "OPTIONS",
    [GamepadKeyCode.KEY_DPAD_UP    ] = "DPAD_UP",
    [GamepadKeyCode.KEY_DPAD_DOWN  ] = "DPAD_DOWN",
    [GamepadKeyCode.KEY_DPAD_LEFT  ] = "DPAD_LEFT",
    [GamepadKeyCode.KEY_DPAD_RIGHT ] = "DPAD_RIGHT",
    [GamepadKeyCode.KEY_L_SHOULDER ] = "L_SHOULDER", -- LB
    [GamepadKeyCode.KEY_R_SHOULDER ] = "R_SHOULDER", -- RB
    [GamepadKeyCode.KEY_L_TRIGGER  ] = "L_TRIGGER", -- LT
    [GamepadKeyCode.KEY_R_TRIGGER  ] = "R_TRIGGER", -- RT
    [GamepadKeyCode.KEY_L_THUMB    ] = "L_THUMB", -- 左摇杆
    [GamepadKeyCode.KEY_R_THUMB    ] = "R_THUMB", -- 右摇杆
}

GamepadKeyName2Code = {}

local GamePadIcon = {
    [GamePadType.SWITCH] = {
        [GamepadKeyCode.KEY_A] = "UIAtlas2_GameSetting_JoyStick_NS_A",
        [GamepadKeyCode.KEY_B] = "UIAtlas2_GameSetting_JoyStick_NS_B",
        [GamepadKeyCode.KEY_X] = "UIAtlas2_GameSetting_JoyStick_NS_X",
        [GamepadKeyCode.KEY_Y] = "UIAtlas2_GameSetting_JoyStick_NS_Y",
        [GamepadKeyCode.KEY_L_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_NS_L",
        [GamepadKeyCode.KEY_R_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_NS_R",
        [GamepadKeyCode.KEY_L_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_NS_ZL",
        [GamepadKeyCode.KEY_R_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_NS_ZR",

        [GamepadKeyCode.KEY_L_THUMB] = "UIAtlas2_GameSetting_JoyStick_NS_7",
        [GamepadKeyCode.KEY_R_THUMB] = "UIAtlas2_GameSetting_JoyStick_NS_8",

        [GamepadKeyCode.KEY_MENU] = "UIAtlas2_GameSetting_JoyStick_NS_2",
        [GamepadKeyCode.KEY_OPTIONS] = "UIAtlas2_GameSetting_JoyStick_NS_1",

        [GamepadKeyCode.KEY_DPAD_UP] = "UIAtlas2_GameSetting_JoyStick_NS_3",
        [GamepadKeyCode.KEY_DPAD_DOWN] = "UIAtlas2_GameSetting_JoyStick_NS_4",
        [GamepadKeyCode.KEY_DPAD_LEFT] = "UIAtlas2_GameSetting_JoyStick_NS_5",
        [GamepadKeyCode.KEY_DPAD_RIGHT] = "UIAtlas2_GameSetting_JoyStick_NS_6",
    },
    [GamePadType.XBOX] = {
        [GamepadKeyCode.KEY_A] = "UIAtlas2_GameSetting_JoyStick_XBOX_A",
        [GamepadKeyCode.KEY_B] = "UIAtlas2_GameSetting_JoyStick_XBOX_B",
        [GamepadKeyCode.KEY_X] = "UIAtlas2_GameSetting_JoyStick_XBOX_X",
        [GamepadKeyCode.KEY_Y] = "UIAtlas2_GameSetting_JoyStick_XBOX_Y",
        [GamepadKeyCode.KEY_L_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_XBOX_LB",
        [GamepadKeyCode.KEY_R_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_XBOX_RB",
        [GamepadKeyCode.KEY_L_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_XBOX_LT",
        [GamepadKeyCode.KEY_R_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_XBOX_RT",

        [GamepadKeyCode.KEY_L_THUMB] = "UIAtlas2_GameSetting_JoyStick_XBOX_Press_L",
        [GamepadKeyCode.KEY_R_THUMB] = "UIAtlas2_GameSetting_JoyStick_XBOX_Press_R",

        [GamepadKeyCode.KEY_MENU] = "UIAtlas2_GameSetting_JoyStick_XBOX_2",
        [GamepadKeyCode.KEY_OPTIONS] = "UIAtlas2_GameSetting_JoyStick_XBOX_1",

        [GamepadKeyCode.KEY_DPAD_UP] = "UIAtlas2_GameSetting_JoyStick_XBOX_3",
        [GamepadKeyCode.KEY_DPAD_DOWN] = "UIAtlas2_GameSetting_JoyStick_XBOX_4",
        [GamepadKeyCode.KEY_DPAD_LEFT] = "UIAtlas2_GameSetting_JoyStick_XBOX_5",
        [GamepadKeyCode.KEY_DPAD_RIGHT] = "UIAtlas2_GameSetting_JoyStick_XBOX_6",
    },
    [GamePadType.PS4] = {
        [GamepadKeyCode.KEY_A] = "UIAtlas2_GameSetting_JoyStick_PS_1",
        [GamepadKeyCode.KEY_B] = "UIAtlas2_GameSetting_JoyStick_PS_4",
        [GamepadKeyCode.KEY_X] = "UIAtlas2_GameSetting_JoyStick_PS_2",
        [GamepadKeyCode.KEY_Y] = "UIAtlas2_GameSetting_JoyStick_PS_3",
        [GamepadKeyCode.KEY_L_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_PS_L1",
        [GamepadKeyCode.KEY_R_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_PS_R1",
        [GamepadKeyCode.KEY_L_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_PS_L2",
        [GamepadKeyCode.KEY_R_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_PS_R2",

        [GamepadKeyCode.KEY_L_THUMB] = "UIAtlas2_GameSetting_JoyStick_PS_L3",
        [GamepadKeyCode.KEY_R_THUMB] = "UIAtlas2_GameSetting_JoyStick_PS_R3",

        [GamepadKeyCode.KEY_MENU] = "UIAtlas2_GameSetting_JoyStick_PS_9",
        [GamepadKeyCode.KEY_OPTIONS] = "UIAtlas2_GameSetting_JoyStick_PS_10",

        [GamepadKeyCode.KEY_DPAD_UP] = "UIAtlas2_GameSetting_JoyStick_PS_5",
        [GamepadKeyCode.KEY_DPAD_DOWN] = "UIAtlas2_GameSetting_JoyStick_PS_6",
        [GamepadKeyCode.KEY_DPAD_LEFT] = "UIAtlas2_GameSetting_JoyStick_PS_8",
        [GamepadKeyCode.KEY_DPAD_RIGHT] = "UIAtlas2_GameSetting_JoyStick_PS_7",
    },
    [GamePadType.PS5] = {
        [GamepadKeyCode.KEY_A] = "UIAtlas2_GameSetting_JoyStick_PS_1",
        [GamepadKeyCode.KEY_B] = "UIAtlas2_GameSetting_JoyStick_PS_4",
        [GamepadKeyCode.KEY_X] = "UIAtlas2_GameSetting_JoyStick_PS_2",
        [GamepadKeyCode.KEY_Y] = "UIAtlas2_GameSetting_JoyStick_PS_3",
        [GamepadKeyCode.KEY_L_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_PS_L1",
        [GamepadKeyCode.KEY_R_SHOULDER] = "UIAtlas2_GameSetting_JoyStick_PS_R1",
        [GamepadKeyCode.KEY_L_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_PS_L2",
        [GamepadKeyCode.KEY_R_TRIGGER] = "UIAtlas2_GameSetting_JoyStick_PS_R2",

        [GamepadKeyCode.KEY_L_THUMB] = "UIAtlas2_GameSetting_JoyStick_PS_L3",
        [GamepadKeyCode.KEY_R_THUMB] = "UIAtlas2_GameSetting_JoyStick_PS_R3",

        [GamepadKeyCode.KEY_MENU] = "UIAtlas2_GameSetting_JoyStick_PS_9",
        [GamepadKeyCode.KEY_OPTIONS] = "UIAtlas2_GameSetting_JoyStick_PS_10",

        [GamepadKeyCode.KEY_DPAD_UP] = "UIAtlas2_GameSetting_JoyStick_PS_5",
        [GamepadKeyCode.KEY_DPAD_DOWN] = "UIAtlas2_GameSetting_JoyStick_PS_6",
        [GamepadKeyCode.KEY_DPAD_LEFT] = "UIAtlas2_GameSetting_JoyStick_PS_8",
        [GamepadKeyCode.KEY_DPAD_RIGHT] = "UIAtlas2_GameSetting_JoyStick_PS_7",
    }
}

self.nCurGamepadType = GamePadType.NONE
self.nCurMoveMode = GamepadMoveMode.Normal
self.CursorLastPos = {x = 0, y = 0}
self.CursorNode = nil
self.CursorNodeSize = {width = 0, height = 0}
-- 鼠标灵敏度
self.nCursorSensitivity = 20
-- 镜头旋转偏移量
self.tCameraMoveOffset = {x = 0 , y = 0}
-- 镜头旋转方向
self.tCameraMoveDire = {x = 0 , y = 0}
self.fInvalidArea = 0.01
-- 镜头旋转灵敏度
self.tbCameraSensitivity = {x = 5,y = 5}
-- 右摇杆界面滚动敏感值
self.nRThumbWheelSensitivity = 10
self.nRThumbWheelCount = 1
self.nRThumbWheelLastPos = 0

self.fCursorMoveOffsetPos = {x=0 , y=0}

self.tbKeyDown = {}

---- 组合键相关-------
self.bTriggerCombination = false
self.tbCombinationSymbol = {GamepadKeyCode.KEY_L_TRIGGER , GamepadKeyCode.KEY_R_TRIGGER}
self.nCurTriggerSymbolKey = GamepadKeyCode.KEY_L_TRIGGER
self.bInvokeCombination = false
---------------------
self.bGamepadTouchState = false
self.bEnable = true
self.nLastMoveMode = GamepadMoveMode.Normal
-- 需要切换成光标模式的界面ID
self.tbNeedSwitchModeViewID =
{
    VIEW_ID.PanelWorldMap,
    VIEW_ID.PanelPlotDialogue,
    VIEW_ID.PanelVideoPlayer
}
self._gamepadKeyDownFlags = {}

function GamepadData.Init()
    self._gamepadKeyDownFlags = {}
    Event.Reg(GamepadData, "OnGamepadKeyDown", function(nKey)
        GamepadData.ResumeInput()
        self.OnGamepadKeyDown(nKey)
    end)

    Event.Reg(GamepadData, "OnGamepadKeyUp", function(nKey)
        GamepadData.ResumeInput()
        self.OnGamepadKeyUp(nKey)
    end)

    Event.Reg(GamepadData, "OnGamepadMove", function(nKey , normalX , normalY)
        GamepadData.ResumeInput()
        normalY = -normalY
        --LOG.INFO("[Gamepad] OnGamepadMove   key:%2d normalX:%s  normalY:%s", nKey, tostring(normalX), tostring(normalY))
        local szKeyName = GamepadKeyCode2Name[nKey]
        if nKey == GamepadKeyCode.KEY_L_THUMB then
            self.Update_L_Thumb(normalX , normalY)
        elseif nKey == GamepadKeyCode.KEY_R_THUMB then
            self.Update_R_Thumb(normalX , normalY)
        elseif nKey == GamepadKeyCode.KEY_L_TRIGGER or nKey == GamepadKeyCode.KEY_R_TRIGGER then
            if normalX == 0 then
                self.OnGamepadKeyUp(nKey)
                self._gamepadKeyDownFlags[nKey] = false
            elseif not self._gamepadKeyDownFlags[nKey] then
                self.OnGamepadKeyDown(nKey)
                self._gamepadKeyDownFlags[nKey] = true
            end
        end
    end)

    Event.Reg(GamepadData, EventType.SetGamepadGameSettingEnable, function(bEnable)
        self.bEnableGameSetting = bEnable
        if not bEnable then
            self.tbKeyDown = {}
            if self.bIsDown then
                self.CursorClick(false)
            end
        end
    end)

    Event.Reg(GamepadData, EventType.SetKeyBoardGameSettingEnable, function(bEnable)
        self.bEnableKeyboardGameSetting = bEnable
    end)

    Event.Reg(GamepadData, EventType.OnWindowsLostFocus, function()
        self.tbKeyDown = {}
        if self.bIsDown then
            self.CursorClick(false)
        end
    end)

    Event.Reg(GamepadData, EventType.SetGamepadEnable, function(bEnable, tbIgnoreGamepadOnDisable)
        self.bEnable = bEnable
        self.tbIgnoreGamepadOnDisable = tbIgnoreGamepadOnDisable or {}
    end)

    Event.Reg(GamepadData, EventType.OnViewOpen, function(nViewID)
        if self.bGamepadTouchState and self.nCurMoveMode == GamepadMoveMode.Normal then
            self.nLastMoveMode = GamepadMoveMode.Normal
            if table.contain_value(self.tbNeedSwitchModeViewID , nViewID) then
                self.SwitchMoveMode(false , GamepadMoveMode.Cursor)
            end
            --LOG.INFO("[Gamepad]  OnViewOpen  %d,%s,%s",nViewID , tostring(self.nLastMoveMode) , tostring(self.nCurMoveMode))
        end
    end)

    Event.Reg(GamepadData, EventType.OnViewClose, function(nViewID)
        --LOG.INFO("[Gamepad]  OnViewClose  %d,%s,%s",nViewID , tostring(self.nLastMoveMode) , tostring(self.nCurMoveMode))
        if self.bGamepadTouchState and self.nLastMoveMode ~= self.nCurMoveMode then
            if table.contain_value(self.tbNeedSwitchModeViewID , nViewID) then
                self.SwitchMoveMode(false , self.nLastMoveMode)
            end
            self.nLastMoveMode = self.nCurMoveMode
        end
    end)

    GamepadKeyName2Code = {}
    for k, v in pairs(GamepadKeyCode2Name) do
        GamepadKeyName2Code[v] = k
    end
    self.UpdateKey2Func()

    Timer.AddCycle(self, 2, function()
        if self.bGamepadTouchState then
            local nGamepadType = self.GetGamepadType()
            if nGamepadType ~= self.nCurGamepadType then
                LOG.INFO("[Gamepad] GamepadTypeChanged, %s(%s)", tostring(table.get_key(GamePadType, nGamepadType)), tostring(nGamepadType))
                self.nCurGamepadType = nGamepadType
                Event.Dispatch(EventType.OnGamepadTypeChanged, nGamepadType)

                --若拔掉手柄时在光标模式，就切回来
                if nGamepadType == GamePadType.NONE and self.nCurMoveMode == GamepadMoveMode.Cursor then
                    self.SwitchMoveMode(false)
                end

                if nGamepadType > GamePadType.NONE and nGamepadType < GamePadType.TYPE_COUNT then
                    local szKeyName = GamepadKeyCode2Name[GamepadKeyCode.KEY_OPTIONS]
                    local szGamepadViewName = self.GetGamepadRichTextIcon(szKeyName)
                    TipsHelper.ShowImportantBlueTip(string.format("已连接手柄，可以按下%s进入光标模式", szGamepadViewName), true, 5)
                end
            end
        end
    end)
    LOG.INFO("GamepadData.Init")
end

function GamepadData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
    LOG.INFO("GamepadData.UnInit")
end

-- 鼠标灵敏度
function GamepadData.SetCursorSensitivity(nSensitivity)
    self.nCursorSensitivity = nSensitivity
end
-- 镜头旋转灵敏度
function GamepadData.SetCameraSensitivity(tbSensitivity)
    self.tbCameraSensitivity = tbSensitivity
end

function GamepadData.SetCameraSensitivityX(nVal)
    self.tbCameraSensitivity.x = nVal
end

function GamepadData.SetCameraSensitivityY(nVal)
    self.tbCameraSensitivity.y = nVal
end

-- 右摇杆界面滚动敏感值
function GamepadData.SetWheelSensitivity(nSensitivity)
    self.nRThumbWheelSensitivity = nSensitivity
end

function GamepadData.SetCursorNode(node)
    self.CursorNode = node
    local width, height = UIHelper.GetContentSize(self.CursorNode)
    self.CursorNodeSize.width = width
    self.CursorNodeSize.height = height
    self._UpdateGamepadCursorPosition(0,0)
end

function GamepadData.OnGamepadKeyDown(nKey)
    local szKeyName = GamepadKeyCode2Name[nKey]

    if self.tbKeyDown[nKey] then
        return
    end
    --LOG.INFO("[Gamepad] KeyDown key:%2d keyname:%s", nKey, szKeyName or "")
    if self.bEnableGameSetting then
        Event.Dispatch(EventType.OnGamepadKeyDownForGameSetting, szKeyName)
    else
        GamepadData._ExcuteBtnFunc(nKey , true)
    end

    self.tbKeyDown[nKey] = true
end

function GamepadData.OnGamepadKeyUp(nKey)
    local szKeyName = GamepadKeyCode2Name[nKey]

    if not self.tbKeyDown[nKey] then
        return
    end
    --LOG.INFO("[Gamepad] KeyUp   key:%2d keyname:%s", nKey, szKeyName or "")
    if self.bEnableGameSetting then
        Event.Dispatch(EventType.OnGamepadKeyUpForGameSetting, szKeyName)
    else
        GamepadData._ExcuteBtnFunc(nKey , false)
    end

    self.tbKeyDown[nKey] = false
end

function GamepadData.GetCurMoveMode()
    return self.nCurMoveMode
end

function GamepadData.GetCurCursorPosition()
    local devicePos_x = (self.CursorLastPos.x + self.tMidleScreenSize.width) * self.tDeviceToScreenScale.x
    local devicePos_y = (self.tMidleScreenSize.height - self.CursorLastPos.y) * self.tDeviceToScreenScale.y
    return devicePos_x , devicePos_y
end

-- 右摇杆
-- 鼠标模式下：光标输入方式
-- 正常模式下：角色移动
function GamepadData.Update_L_Thumb(nNormalX, nNormalY)
    if self.nCurMoveMode == GamepadMoveMode.Cursor then
        self.fCursorMoveOffsetPos.x = nNormalX
        self.fCursorMoveOffsetPos.y = nNormalY
    elseif self._CheckEnable(GamepadKeyCode2Name[GamepadKeyCode.KEY_L_THUMB]) then
        Event.Dispatch(EventType.OnGamepadJoyStickMove, nNormalX, nNormalY)
    end
end

-- 右摇杆
-- 鼠标模式下：界面滚动
-- 正常模式下：镜头旋转
function GamepadData.Update_R_Thumb(normalX, normalY, bForceRotateCamera, nForceSensitivity)
    if self.nCurMoveMode == GamepadMoveMode.Cursor then
        local nDire = normalY < 0 and -1 or 1
        local absY = math.abs(normalY)
        if absY < 0.95 and absY < self.nRThumbWheelLastPos then
            self.nRThumbWheelCount  = self.nRThumbWheelCount - 2
        else
            if absY < 0.1 then
                self.nRThumbWheelCount = 0
                absY = 0
            elseif absY >= 0.1 and absY < 0.5 then
                self.nRThumbWheelCount  = self.nRThumbWheelCount + 1
            elseif absY >= 0.5 and absY < 0.75 then
                self.nRThumbWheelCount  = self.nRThumbWheelCount + 2
                nDire = nDire * 2
            elseif absY >= 0.75 then
                self.nRThumbWheelCount  = self.nRThumbWheelCount + 3
                nDire = nDire * 3
            end
        end
        self.nRThumbWheelLastPos = absY
        if self.nRThumbWheelCount >= self.nRThumbWheelSensitivity then
            SimulateMouseWheel(nDire, self.GetCurCursorPosition())
            self.nRThumbWheelCount = 0
        end
    elseif bForceRotateCamera or self._CheckEnable(GamepadKeyCode2Name[GamepadKeyCode.KEY_R_THUMB]) then
        -- 镜头旋转
        local nDistance = math.sqrt(normalX*normalX + normalY*normalY)
        if nDistance < 0.1 then
            if self.bGamepadCameraRotate then
                Camera_EnableControl(ControlDef.CONTROL_OBJECT_STICK_CAMERA, false)
                Camera_EnableControl(ControlDef.CONTROL_CAMERA, false)
                Camera_EndDrag(self.nBeginTouchX, self.nBeginTouchY, 1)
                self.bGamepadCameraRotate = false
                if not bForceRotateCamera then
                    Event.Dispatch(EventType.OnGamepadCameraRotateEnd)
                end
            end
        else
            if not self.bGamepadCameraRotate then
                Camera_EnableControl(ControlDef.CONTROL_CAMERA, true)
                Camera_EnableControl(ControlDef.CONTROL_OBJECT_STICK_CAMERA, false)
                self.nBeginTouchX, self.nBeginTouchY = Camera_BeginDrag(1, 1)
                self.bGamepadCameraRotate = true
                self.tCameraMoveOffset.x = 0
                self.tCameraMoveOffset.y = 0
                self.tCameraMoveDire.x = 0
                self.tCameraMoveDire.y = 0
                if not bForceRotateCamera then
                    Event.Dispatch(EventType.OnGamepadCameraRotateStart)
                end
            else
                local newX = math.abs(normalX)
                local newY = math.abs(normalY)
                if newX < 0.1 then
                    newX = 0
                end
                if newY < 0.1 then
                    newY = 0
                end
                self.tCameraMoveOffset.x = self.tCameraMoveOffset.x + newX
                self.tCameraMoveOffset.y = self.tCameraMoveOffset.y + newY
                local dragOffset_x = 0
                local dragOffset_y = 0
                local dragDire_x = normalX > 0 and -1 or 1
                local dragDire_y = normalY > 0 and 1 or -1
                if self.tCameraMoveDire.x ~= dragDire_x then
                    self.tCameraMoveOffset.x = 0
                    self.tCameraMoveDire.x = dragDire_x
                end
                if self.tCameraMoveDire.y ~= dragDire_y then
                    self.tCameraMoveOffset.y = 0
                    self.tCameraMoveDire.y = dragDire_y
                end

                local nRate = IsNumber(nForceSensitivity) and nForceSensitivity or 1
                if self.tCameraMoveOffset.x >= 1 then
                    dragOffset_x = self.tCameraMoveDire.x * self.tbCameraSensitivity.x * nRate
                    self.tCameraMoveOffset.x = self.tCameraMoveOffset.x - 1
                end
                if self.tCameraMoveOffset.y >= 1 then
                    dragOffset_y = self.tCameraMoveDire.y * self.tbCameraSensitivity.y * nRate
                    self.tCameraMoveOffset.y = self.tCameraMoveOffset.y - 1
                end

                Camera_SetDragParams(dragOffset_x ,dragOffset_y)
            end
        end
    end
end

function GamepadData.ResetScreenSize()
    self.tUIScreenSize = nil
end

function GamepadData.PauseInput()
    if self.bGamepadTouchState then
        self.bGamepadTouchState = false
        if self.nCurMoveMode == GamepadMoveMode.Cursor then
            Event.Dispatch(EventType.On_UI_ShowGamepadCursor,false)
            self.AddCursorMoveFrameCycle(false)
        end
        Event.Dispatch(EventType.OnGamepadTypeChanged, GamePadType.NONE)
    end
end

function GamepadData.ResumeInput()
    if not self.bGamepadTouchState then
        self.bGamepadTouchState = true
        Event.Dispatch(EventType.On_UI_ShowGamepadCursor,self.nCurMoveMode == GamepadMoveMode.Cursor)
        self.AddCursorMoveFrameCycle(self.nCurMoveMode == GamepadMoveMode.Cursor)
        Event.Dispatch(EventType.OnGamepadTypeChanged, self.nCurGamepadType)
    end
end

function GamepadData._UpdateGamepadCursorPosition(normalX, normalY)
    if not self.tUIScreenSize then
        local screenSize = UIHelper.GetCurResolutionSize()
        self.tUIScreenSize =
        {
            width = screenSize.width,
            height = screenSize.height,
        }
        local deviceSize = UIHelper.GetScreenSize()
        self.tDeviceToScreenScale =
        {
            x = deviceSize.width / screenSize.width,
            y = deviceSize.height / screenSize.height,
        }
        self.tScreenLimitPos =
        {
            left    =   (self.CursorNodeSize.width - self.tUIScreenSize.width)   * 0.5,
            right   =   (self.tUIScreenSize.width - self.CursorNodeSize.width)   * 0.5,
            top     =   (self.tUIScreenSize.height - self.CursorNodeSize.height)  * 0.5,
            bottom  =   (self.CursorNodeSize.height - self.tUIScreenSize.height)  * 0.5,
        }


        self.tMidleScreenSize =
        {
            width = screenSize.width * 0.5,
            height = screenSize.height * 0.5,
        }

    end
    local newX = normalX
    local newY = normalY
    if math.abs(normalX)  < self.fInvalidArea then
        newX = 0
    end
    if math.abs(normalY) < self.fInvalidArea then
        newY = 0
    end
    self.CursorLastPos.x = self.CursorLastPos.x + newX * self.nCursorSensitivity
    self.CursorLastPos.y = self.CursorLastPos.y + newY * self.nCursorSensitivity

    if self.CursorLastPos.x < self.tScreenLimitPos.left then
        self.CursorLastPos.x = self.tScreenLimitPos.left
    elseif self.CursorLastPos.x > self.tScreenLimitPos.right then
        self.CursorLastPos.x = self.tScreenLimitPos.right
    end

    if self.CursorLastPos.y < self.tScreenLimitPos.bottom then
        self.CursorLastPos.y = self.tScreenLimitPos.bottom
    elseif self.CursorLastPos.y > self.tScreenLimitPos.top then
        self.CursorLastPos.y = self.tScreenLimitPos.top
    end
    UIHelper.SetPosition(self.CursorNode, self.CursorLastPos.x, self.CursorLastPos.y)
end

function GamepadData._ExcuteBtnFunc(nKeyCode , bIsDown)
    -- 正常模式下，触发组合键
    local szKeyName = ""
    if self.CheckCombination(nKeyCode , bIsDown) then
        szKeyName = GamepadKeyCode2Name[self.nCurTriggerSymbolKey].."+"..GamepadKeyCode2Name[nKeyCode]
    else
        szKeyName = GamepadKeyCode2Name[nKeyCode]
    end

    local tInfo = self.tbKey2Func[self.nCurMoveMode][szKeyName]
    local szFuncModeName = tInfo and tInfo.szModeFunc
    if string.is_nil(szFuncModeName) then
        return
    end

    if not self._CheckEnable(szKeyName, szFuncModeName) then
        return
    end

    if self[szFuncModeName] then
        self[szFuncModeName](bIsDown)
    end

    Event.Dispatch(EventType.OnGamepadKeyExecute, szKeyName)
end

function GamepadData.UpdateKey2Func()
    self.tbKey2Func = {
        [GamepadMoveMode.Normal] = {},
        [GamepadMoveMode.Cursor] = {},
    }
    for i, v in ipairs(UISettingStoreTab.GamepadInteraction) do
        self.tbKey2Func[v.nModeState][v.VKey] = v
    end
end

function GamepadData.AddCursorMoveFrameCycle(bAdd)
    Timer.DelTimer(self , self.nCursorMoveTimerID)
    if bAdd then
        self.nCursorMoveTimerID = Timer.AddFrameCycle(self , 1 , function ()
            self._UpdateGamepadCursorPosition(self.fCursorMoveOffsetPos.x, self.fCursorMoveOffsetPos.y)
            Event.Dispatch(EventType.OnUpdateGamepadCursor, self.fCursorMoveOffsetPos.x, self.fCursorMoveOffsetPos.y)
        end)
    end
end

function GamepadData.GetGamepadType()
    return GetGamepadType()
end

function GamepadData.IsGamepadMode()
    if self.bGamepadTouchState then
        return self.GetGamepadType() ~= GamePadType.NONE
    else
        return false
    end

end

function GamepadData.GetGamepadRichTextIcon(szKeyName, nSize)
    local nGamepadType = self.GetGamepadType()
    if nGamepadType == GamePadType.NONE then
        nGamepadType = GamePadType.XBOX
    end

    nSize = nSize or 45

    local nKey = GamepadKeyName2Code[szKeyName]
    local szPath = nKey and GamePadIcon[nGamepadType][nKey]

    if szPath then
        local szImg = string.format("<img src='%s' width='%d' height='%d' />", szPath, nSize, nSize)
        return szImg
    end

    return szKeyName
end

function GamepadData.CheckCombination(nKeyCode , bIsDown)
    if self.nCurMoveMode == GamepadMoveMode.Normal then
        -- 检测到是组合键的标识
        if table.contain_value(self.tbCombinationSymbol , nKeyCode) then
            if bIsDown then
                if self.bTriggerCombination then
                    self.bInvokeCombination = true
                else
                    self.nCurTriggerSymbolKey = nKeyCode
                    self.bTriggerCombination = true
                    self.bInvokeCombination = false
                end
                return true
            else
                if not self.bInvokeCombination then
                    self.bTriggerCombination = false
                else
                    if self.nCurTriggerSymbolKey == nKeyCode then
                        self.bTriggerCombination = false
                        self.bInvokeCombination = false
                    end
                    return true
                end
            end
        else
            if self.bTriggerCombination then
                self.bInvokeCombination = true
                return true
            end
        end
    else
        self.bInvokeCombination = false
        self.bTriggerCombination = false
    end
    return false
end

function GamepadData._CheckEnable(szKeyName, szFuncModeName)
    --任意情况下，光标都允许使用
    if szFuncModeName == "SwitchMoveMode" then
        return true
    end

    if self.nCurMoveMode == GamepadMoveMode.Cursor then
        return true
    end

    if self.bEnableKeyboardGameSetting then
        return false
    end

    if table.contain_value(self.tbIgnoreGamepadOnDisable, szKeyName) then
        return true
    end

    --若禁用了键盘/快捷键，则手柄键位也不响应
    if not self.bEnable or not ShortcutInteractionData.IsEnableKeyBoard or not KeyBoard.bEnable or KeyBoard.bCustom then
        return false
    end

    return true
end

----------------------------------------------配置表调用函数-----------------------------------------------
function GamepadData.FuncSlot(nSlotIndex , bFight , bIsDown)
    if bFight  then
        Event.Dispatch(EventType.OnShortcutUseSkillSelect, nSlotIndex, bIsDown and 1 or 3)
    else
        Event.Dispatch(EventType.OnMainViewButtonSlotClick, nSlotIndex, bIsDown)
    end
end

function GamepadData.FuncSlot_1(bIsDown)
    self.FuncSlot(1, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

function GamepadData.FuncSlot_2(bIsDown)
    self.FuncSlot(2, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

function GamepadData.FuncSlot_3(bIsDown)
    self.FuncSlot(3, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

function GamepadData.FuncSlot_4(bIsDown)
    self.FuncSlot(4, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

function GamepadData.FuncSlot_5(bIsDown)
    self.FuncSlot(5, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

function GamepadData.FuncSlot_6(bIsDown)
    self.FuncSlot(6, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

function GamepadData.FuncSlot_11(bIsDown)
    self.FuncSlot(11, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

-- 选中目标
function GamepadData.SelectTarget(bIsDown)
    if not bIsDown then
        Event.Dispatch(EventType.OnShortcutTargetSelect)
    end
end

-- 跳跃
function GamepadData.Jump(bIsDown)
    if not bIsDown then
        Jump()
    end
end

-- 武学助手
function GamepadData.SkillAuto(bIsDown)
    if not bIsDown then
       Event.Dispatch(EventType.OnShortcutSkillAuto)
    end
end

-- 目标锁定
function GamepadData.Attention(bIsDown)
    if not bIsDown then
        Event.Dispatch(EventType.OnShortcutAttention)
    end
end

-- 切换模式
function GamepadData.SwitchMoveMode(bIsDown , newMode)
    if bIsDown then
        return
    end
    --LOG.INFO("SwitchMoveMode  %s",tostring(newMode))
    if newMode then
        self.nCurMoveMode = newMode
    else
        self.nCurMoveMode = self.nCurMoveMode % GamepadMoveMode.Count + 1
    end
    local script = UIMgr.GetViewScript(VIEW_ID.PanelGamepadCursor)
    if not script then
        UIMgr.Open(VIEW_ID.PanelGamepadCursor)
    else
        script:UpdateInfo()
    end
    self.AddCursorMoveFrameCycle(self.nCurMoveMode == GamepadMoveMode.Cursor)
end

-- 切换技能（R）
function GamepadData.SwitchSkill(bIsDown)
    if bIsDown then
        return
    end
    FuncSlotMgr.ExecuteCommand("SwitchSkill")
end

-- 扶摇
function GamepadData.FuYao(bIsDown)
    if bIsDown then
        return
    end
    SkillMgr.FuYao()
end

-- F交互键
function GamepadData.FInteract(bIsDown)
    if bIsDown then
        return
    end
    Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
end

GamepadData.NieYunIndex = 10
GamepadData.QingGongIndex = 7

-- 蹑云
function GamepadData.NieYun(bIsDown)
    self.FuncSlot(GamepadData.NieYunIndex, true, bIsDown)
end

-- 门派轻功
function GamepadData.QingGong(bIsDown)
    self.FuncSlot(GamepadData.QingGongIndex, true, bIsDown)
end

-- 特殊道具/团队标记
function GamepadData.SkillQuick(bIsDown)
    Event.Dispatch(EventType.OnShortcutSkillQuick, bIsDown and 1 or 3)
end

-- 全部拾取
function GamepadData.ALLPicker(bIsDown)
    if bIsDown then
        return
    end
    Event.Dispatch(EventType.OnSceneInteractByHotkey, true)
end

function GamepadData.AutoForward(bIsDown)
    if bIsDown then
        return
    end
    HotkeyCommand.ExecuteKeyDownCommand(17)
end

----------------------------------------------光标模式下键位-----------------------------------------------
function GamepadData.CursorClick(bIsDown)
    self.bIsDown = bIsDown
    if bIsDown then
        SimulateLButtonDown(self.GetCurCursorPosition())
    else
        SimulateLButtonUp(self.GetCurCursorPosition())
    end
end

function GamepadData.CursorEsc(bIsDown)
    Event.Dispatch(bIsDown and "OnGamepadSimulateCCKeyDown" or "OnGamepadSimulateCCKeyUp", cc.KeyCode.KEY_ESCAPE , true)
end

function GamepadData.MouseWheelUp()
    SimulateMouseWheel(1, self.GetCurCursorPosition())
end

function GamepadData.MouseWheelDown()
    SimulateMouseWheel(-1, self.GetCurCursorPosition())
end

----------------------------------------------------------------------------------------------------------