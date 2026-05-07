
NewModule("HLBOp_Camera")

m_bCamIndoors = false
m_fOuterCamSpeed = nil
m_nMovingVertically = nil --{nil, -1, 1}
m_nMovingAlongLookAt = nil --{nil, -1, 1}
m_nRotatingYaw = nil --{nil, -1, 1}
m_bRotatingCamYaw = false
m_bRotatingPitch = false
m_bMovingVertically = false
m_bInRBtnDrag = false
m_nDragFlag = 0
m_bLock = false
m_MoveFactor = Platform.IsMobile() and 0.56 or 1 --家园建造模式下的镜头移动速度（移动端 0r PC端）
m_nS2R_X, m_nS2R_Y = 1, 1

local tPreCursorPos = {nX = nil, nY = nil}
local tBeginCursorPos = {nX = nil, nY = nil}

CONTROL_FORWARD = 0
CONTROL_BACKWARD = 1
CONTROL_TURN_LEFT = 2
CONTROL_TURN_RIGHT = 3
CONTROL_STRAFE_LEFT = 4
CONTROL_STRAFE_RIGHT = 5
CONTROL_CAMERA = 6
CONTROL_OBJECT_STICK_CAMERA = 7
CONTROL_WALK = 8
CONTROL_JUMP = 9
CONTROL_AUTO_RUN = 10
CONTROL_FOLLOW = 11
CONTROL_UP = 12
CONTROL_DOWN = 13

function SwitchIndoorsMode()
    m_bCamIndoors = not m_bCamIndoors
    rlcmd(("homeland -set camera 2nd mode %d"):format(m_bCamIndoors and 1 or 0))
    rlcmd("homeland -camera smooth 140")
    UpdateCamMoveSpeed()
end

function SwitchCamMode()
    StopAllCamMovements()
end

function IsCameraIndoorsMode()
    return m_bCamIndoors
end

function GetCurCameraSpeed()
    if m_bCamIndoors then
        return g_HomelandBuildingData.nCamSpeedIndoors
    else
        return g_HomelandBuildingData.nCamSpeedOutdoors
    end
end

function GetCurCameraMoveSpeed()
    if m_bCamIndoors then
        return g_HomelandBuildingData.nCamMoveSpeedIndoors
    else
        return g_HomelandBuildingData.nCamMoveSpeedOutdoors
    end
end

function SetDragFlag(nBitPos, bAdd)
    if bAdd then
        m_nDragFlag = kmath.add_bit(m_nDragFlag, nBitPos)
    else
        m_nDragFlag = kmath.del_bit(m_nDragFlag, nBitPos)
    end
end

function OnWKeyDown()
    Camera_EnableControl(CONTROL_FORWARD, true)
    SetDragFlag(1, true)
end

function OnWKeyUp()
    Camera_EnableControl(CONTROL_FORWARD, false)
    SetDragFlag(1, false)
end

function OnAKeyDown()
    Camera_EnableControl(CONTROL_STRAFE_LEFT, true)
    SetDragFlag(2, true)
end

function OnAKeyUp()
    Camera_EnableControl(CONTROL_STRAFE_LEFT, false)
    SetDragFlag(2, false)
end

function OnSKeyDown()
    Camera_EnableControl(CONTROL_BACKWARD, true)
    SetDragFlag(3, true)
end

function OnSKeyUp()
    Camera_EnableControl(CONTROL_BACKWARD, false)
    SetDragFlag(3, false)
end

function OnDKeyDown()
    Camera_EnableControl(CONTROL_STRAFE_RIGHT, true)
    SetDragFlag(4, true)
end

function OnDKeyUp()
    Camera_EnableControl(CONTROL_STRAFE_RIGHT, false)
    SetDragFlag(4, false)
end

function OnQKeyDown()
    m_nMovingVertically = -1
end

function OnQKeyUp()
    m_nMovingVertically = nil
end

function OnEKeyDown()
    m_nMovingVertically = 1
end

function OnEKeyUp()
    m_nMovingVertically = nil
end

function OnOEMMinusKeyDown()
    m_nMovingAlongLookAt = -1
end

function OnOEMMinusKeyUp()
    m_nMovingAlongLookAt = nil
end

function OnOEMPlusKeyDown()
    m_nMovingAlongLookAt = 1
end

function OnOEMPlusKeyUp()
    m_nMovingAlongLookAt = nil
end

function OnOEMCommaKeyDown()
    m_nRotatingYaw = 1
end

function OnOEMCommaKeyUp()
    m_nRotatingYaw = nil
end

function OnOEMPeriodKeyDown()
    m_nRotatingYaw = -1
end

function OnOEMPeriodKeyUp()
    m_nRotatingYaw = nil
end

function OnRBtnDrag()
    m_bInRBtnDrag = true
    if g_HomelandBuildingData.eCurCameraOpMode == BUILD_CAM_OP_MODE.BASIC then
        if m_bRotatingCamYaw then
            return
        end
        tBeginCursorPos.nX, tBeginCursorPos.nY = Station.GetMessagePos(true)
        tPreCursorPos.nX, tPreCursorPos.nY = tBeginCursorPos.nX, tBeginCursorPos.nY
        Cursor.Show(false)
        m_bRotatingCamYaw = true
    else
        local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
        if tConfig.bDesign then
            local nSceneID = HLBOp_Enter.GetSceneID()
            Camera_BeginDrag(nSceneID, 0, 2)
        else
            Camera_BeginDrag(2)
        end
        Camera_EnableControl(CONTROL_OBJECT_STICK_CAMERA, true)

        tBeginCursorPos.nX, tBeginCursorPos.nY = Station.GetMessagePos(false)
    end
end

function OnRBtnClick()
    if not m_bInRBtnDrag then
        return
    end
    m_bInRBtnDrag = false
    if g_HomelandBuildingData.eCurCameraOpMode == BUILD_CAM_OP_MODE.BASIC then
        if not m_bRotatingCamYaw then
            return
        end
        Cursor.Show(true)
        m_bRotatingCamYaw = false
    else
        if tBeginCursorPos.nX and tBeginCursorPos.nY then
            Camera_EnableControl(CONTROL_OBJECT_STICK_CAMERA, false)
            Camera_EndDrag(tBeginCursorPos.nX, tBeginCursorPos.nY, 2)
        end
    end
    tBeginCursorPos.nX, tBeginCursorPos.nY = nil, nil
end

function OnMButtonDrag()
    m_bMovingVertically = true
    if g_HomelandBuildingData.eCurCameraOpMode == BUILD_CAM_OP_MODE.BASIC then
        m_bRotatingPitch = true
    end
    tBeginCursorPos.nX, tBeginCursorPos.nY = Homeland_GetTouchingPosInPixels()
    tPreCursorPos.nX, tPreCursorPos.nY = tBeginCursorPos.nX, tBeginCursorPos.nY
    -- Cursor.Show(false)
end

function OnMButtonUp()
    if not m_bMovingVertically then
        return
    end
    m_bMovingVertically = false
    if g_HomelandBuildingData.eCurCameraOpMode == BUILD_CAM_OP_MODE.BASIC then
        m_bRotatingPitch = false
    end
    -- Cursor.Show(true)
    -- Cursor.SetPos(tPreCursorPos.nX, tPreCursorPos.nY)
    tBeginCursorPos.nX, tBeginCursorPos.nY = nil, nil
end

function OnMouseWheel(nDelta)
    if nDelta == 0 then
        return
    end

    local nFactor = (nDelta > 0) and 0.2 or -0.2
    local fDeltaDist = nFactor * BUILD_SETTING.UNIT_CAM_MOVE_DIST_BY_MOUSE_WHEEL * GetCurCameraSpeed()
    if Platform.IsMobile() then
        fDeltaDist = nFactor * BUILD_SETTING.UNIT_CAM_MOVE_DIST_BY_MOUSE_WHEEL_MOBLIE * GetCurCameraSpeed()
    end
    rlcmd(("set homeland camera dir offset %f"):format(fDeltaDist))
end

function SetCamMoveSpeed(nMoveSpeed)
    nMoveSpeed = nMoveSpeed * m_MoveFactor
    rlcmd(("set homeland camera move speed %f"):format(nMoveSpeed))
end

function UpdateCamMoveSpeed()
    SetCamMoveSpeed(GetCurCameraMoveSpeed())
end

function StopAllCamMovements()
    Camera_EnableControl(CONTROL_FORWARD, false)
	Camera_EnableControl(CONTROL_BACKWARD, false)
	Camera_EnableControl(CONTROL_TURN_LEFT, false)
	Camera_EnableControl(CONTROL_TURN_RIGHT, false)
	Camera_EnableControl(CONTROL_STRAFE_LEFT, false)
	Camera_EnableControl(CONTROL_STRAFE_RIGHT, false)
	MoveUpStop()
	MoveDownStop()

    m_fOuterCamSpeed = nil
    m_nMovingVertically = nil
    m_nMovingAlongLookAt = nil
    m_nRotatingYaw = nil
    m_bRotatingCamYaw = false
    m_bRotatingPitch = false
    m_bMovingVertically = false
end

function Init()
    m_bCamIndoors = false
    m_fOuterCamSpeed = nil
    m_nMovingVertically = nil
    m_nMovingAlongLookAt = nil
    m_nRotatingYaw = nil
    m_bRotatingCamYaw = false
    m_bRotatingPitch = false
    m_bMovingVertically = false
    m_bInRBtnDrag = false
    m_bLock = false
    m_nDragFlag = 0

    StopAllCamMovements()

    m_nS2R_X, m_nS2R_Y = UIHelper.GetScreenToDesignScale()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        m_nS2R_X, m_nS2R_Y = UIHelper.GetScreenToDesignScale()
    end)

    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    if (not tConfig.bDesign) or tConfig.bTest then
        rlcmd("set homeland camera mode")
    end

    rlcmd(("set homeland camera lol mode %d %f"):format(0, BUILD_SETTING.CAM_SCREEN_EDGE_SPEED))

    UpdateCamMoveSpeed()

    if not m_fOuterCamSpeed then
        local fCameraSpeed, a, b, c, d = Camera_GetParams()
		fOuterCamSpeed = fCameraSpeed
		Camera_SetParams(0.2, a, b, c, d) -- 为了让右键拖拽镜头速度变慢些
    end

    rlcmd(("homeland -set camera 2nd mode %d"):format(m_bCamIndoors and 1 or 0))
    rlcmd("homeland -camera smooth 140")
end

function UnInit()
    m_bCamIndoors = false
    m_fOuterCamSpeed = nil
    m_nMovingVertically = nil
    m_nMovingAlongLookAt = nil
    m_nRotatingYaw = nil
    m_bRotatingCamYaw = false
    m_bRotatingPitch = false
    m_bMovingVertically = false
    m_bInRBtnDrag = false
    m_bLock = false
    m_nDragFlag = 0

    StopAllCamMovements()

    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    if (not tConfig.bDesign) or tConfig.bTest then
        rlcmd(("set local camera mode %d"):format(1000))
    end

    k3dcmd("ddgi.relocate")

    if fOuterCamSpeed then --> 重要； 可能根本没有被设置过就走到了这里； 待改进
		local fCameraSpeed, a, b, c, d = Camera_GetParams()
		Camera_SetParams(fOuterCamSpeed, a, b, c, d)
		fOuterCamSpeed = nil
	end
end

function IsInRBtnDrag()
    return m_bInRBtnDrag
end

function IsInDrag()
    return m_nDragFlag ~= 0
end

function IsInMovingVertically()
    return m_bMovingVertically
end

function GetCameraLock()
    return m_bLock
end

function SetCameraLock(bLock)
    m_bLock = bLock
end

function OnCameraRotateYaw(nDelta)
    if m_bLock then
        return
    end
    local fDiffAngle = nDelta * BUILD_SETTING.UNIT_CAM_ROTATE_YAW_ANGLE * GetCurCameraSpeed()
    rlcmd(("homeland -rotate yaw %f"):format(fDiffAngle * 1.5))
end

function OnCameraRotatePitch(nDelta)
    if m_bLock then
        return
    end
    local fDiffAngle = nDelta * BUILD_SETTING.UNIT_CAM_ROTATE_PITCH_ANGLE * GetCurCameraSpeed()
    rlcmd(("homeland -rotate pitch %f"):format(fDiffAngle * 1.5))
end

function OnCameraOffset(nDelta)
    local fDeltaDist = nDelta * BUILD_SETTING.UNIT_CAM_VERTICAL_MOVE_DIST * GetCurCameraMoveSpeed()
    rlcmd(("set homeland camera offset %f"):format(fDeltaDist))
end

function OnMButtonDrag()
    m_bMovingVertically = true
    if g_HomelandBuildingData.eCurCameraOpMode == BUILD_CAM_OP_MODE.BASIC then
        m_bRotatingPitch = true
    end
    tBeginCursorPos.nX, tBeginCursorPos.nY = Homeland_GetTouchingPosInPixels()
    tPreCursorPos.nX, tPreCursorPos.nY = tBeginCursorPos.nX, tBeginCursorPos.nY
    -- Cursor.Show(false)
end

function OnMButtonUp()
    if not m_bMovingVertically then
        return
    end
    m_bMovingVertically = false
    if g_HomelandBuildingData.eCurCameraOpMode == BUILD_CAM_OP_MODE.BASIC then
        m_bRotatingPitch = false
    end
    -- Cursor.Show(true)
    -- Cursor.SetPos(tPreCursorPos.nX, tPreCursorPos.nY)
    tBeginCursorPos.nX, tBeginCursorPos.nY = nil, nil
end

function OnFrameBreathe()
    if m_nMovingVertically then
        local fDeltaDist = m_nMovingVertically * BUILD_SETTING.UNIT_CAM_VERTICAL_MOVE_DIST * GetCurCameraSpeed()
        rlcmd(("set homeland camera offset %f"):format(fDeltaDist))
    end

    if m_nMovingAlongLookAt then
        local fDeltaDist = m_nMovingAlongLookAt * BUILD_SETTING.UNIT_CAM_MOVE_DIST_BY_KEY_DOWN * GetCurCameraSpeed()
        rlcmd(("set homeland camera dir offset %f"):format(fDeltaDist))
    end

    if m_nRotatingYaw then
        local fDiffAngle = m_nRotatingYaw * BUILD_SETTING.UNIT_CAM_ROTATE_ANGLE * GetCurCameraSpeed()
        rlcmd(("homeland -rotate yaw %f"):format(fDiffAngle))
    end

    if m_bRotatingCamYaw then
        local nCurPosX, nCurPosY = Homeland_GetTouchingPosInPixels()
		local nDeltaX, nDeltaY = nCurPosX - tPreCursorPos.nX, nCurPosY - tPreCursorPos.nY
        local fDiffAngle = nDeltaX * BUILD_SETTING.UNIT_CAM_ROTATE_YAW_ANGLE * GetCurCameraSpeed()
        rlcmd(("homeland -rotate yaw %f"):format(fDiffAngle))
        -- Cursor.SetPos(tBeginCursorPos.nX, tBeginCursorPos.nY)
		tPreCursorPos.nX, tPreCursorPos.nY = tBeginCursorPos.nX, tBeginCursorPos.nY
    end

    if m_bMovingVertically then
        local nCurPosX, nCurPosY = Homeland_GetTouchingPosInPixels()
	    local nDeltaX, nDeltaY = nCurPosX - tPreCursorPos.nX, nCurPosY - tPreCursorPos.nY
        if m_bRotatingPitch then
            local fDiffAngle = -nDeltaY * BUILD_SETTING.UNIT_CAM_ROTATE_PITCH_ANGLE * GetCurCameraSpeed()
            rlcmd(("homeland -rotate pitch %f"):format(fDiffAngle))
        else
            rlcmd(("set homeland camera offset 0 %f %f"):format(nDeltaX * BUILD_SETTING.UNIT_CAM_MOVE_DIST_BY_MOUSE_MOVE * GetCurCameraSpeed(),
				nDeltaY * BUILD_SETTING.UNIT_CAM_MOVE_DIST_BY_MOUSE_MOVE * GetCurCameraSpeed()))
        end
        -- Cursor.SetPos(tBeginCursorPos.nX, tBeginCursorPos.nY)
		tPreCursorPos.nX, tPreCursorPos.nY = tBeginCursorPos.nX, tBeginCursorPos.nY
    end
end