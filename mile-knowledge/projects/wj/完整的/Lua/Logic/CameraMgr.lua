-- 镜头管理器
CameraMgr = CameraMgr or {className = "CameraMgr"}
local this = CameraMgr

local CameraDef = ControlDef
local LERP_SPEED = 0.3                      -- 角色旋转速度
local kCameraStartRotateAngle = 10          -- 镜头方向和人物面向的最大角度差，超过这个值后镜头会开始追随（逻辑角度，仅限智能追随）
local kCameraStartRotateSpeed = 1 / 800     -- 摇杆模式下镜头智能追随的速度
local kCameraSprintSpeed = 3                -- 摇杆模式下进入轻功后智能追随的镜头速度倍率
local kCameraEnterWaterPitch = -0.8         -- 玩家在水面上入水的最小角度(弧度)
local kUIModeDistance = 204.39              -- 焦点模式镜头距离(厘米)
local kUIModeDistanceRange = {124, 239.9}   -- 焦点模式镜头范围(厘米)
local kDragFactorX = function(bForceMobile)    -- 镜头缩放速度系数 X
    local nValue = 0.72  --PC端的镜头左右旋转的速度，越大越快
    if Platform.IsMobile() or Channel.Is_WLColud() or bForceMobile then
        nValue = UIHelper.GetScreenPortrait() and 0.35 or 0.8   --移动端的镜头左右旋转的速度，越大越快（竖屏 or 横屏）
    end
    return nValue
end
local kDragFactorY = function(bForceMobile)     -- 镜头缩放速度系数 Y
    local nValue = 0.35   --PC端的镜头上下翻转的速度，越大越快
    if Platform.IsMobile() or Channel.Is_WLColud() or bForceMobile then
        nValue = UIHelper.GetScreenPortrait() and 0.2 or 0.15   --移动端的镜头上下翻转的速度，越大越快（竖屏 or 横屏）
    end
    return nValue
end
local kZoomMinDis, kZoomFactor              -- 镜头缩放相关系数

local JoystickDirection = {
    Up = "Up",
    Down = "Down",
    Left = "Left",
    Right = "Right",
    RightUp = "RightUp",
    RightDown = "RightDown",
    LeftUp = "LeftUp",
    LeftDown = "LeftDown",
}

if Platform.IsMobile() or Channel.Is_WLColud() then     -- 移动端
    kZoomMinDis = 121           -- 限制镜头最近在1档
    kZoomFactor = 1.2           -- 手指拉动摄像机缩放比例
else                            --PC端
    kZoomMinDis = 121           -- 限制镜头最近在1档
    kZoomFactor = 0.09        -- 每次滚轮滚动缩放比例
end

function CameraMgr.Init()
    local nScaleX, nScaleY = UIHelper.GetScreenToDesignScale()
    local fDragSpeed, nMaxDis, _, _, nResetMode = Camera_GetParams()

    this.tSegmentConfig = {             -- 0档镜头相关开关
        bFacesLimit = true,             -- 是否切高清脸
        bEnableDof = true,              -- 是否开启景深
        bUseLod0 = true,                -- 是否切换lod0
        bEnableTurnFront = true,        -- 是否允许特写镜头
        nCameraLightQualityLevel = 0,   -- 开启镜头光时的画质等级
    }
    this.nDesignScaleX = nScaleX
    this.nDesignScaleY = nScaleY
    this.nDragSpeed = fDragSpeed
    this.fMaxDistance = nMaxDis
    this.nDragFactorX = kDragFactorX() * nScaleX
    this.nDragFactorY = kDragFactorY() * nScaleY

    this.nZoomFactor = kZoomFactor
    this.nResolutionScale = nScaleY
    this.nScreenWidth = UIHelper.GetScreenSize().width
    this.nResetMode = nResetMode    -- 镜头跟随模式，由于设置操作是异步的，如果需要立即获取数据会取得旧值导致设置错误
    this.nLastTouchX = 0            -- 上一次单指触屏的X
    this.nLastTouchY = 0            -- 上一次单指触屏的Y
    this.nLastPinchDist = 0         -- 上一次双指的距离
    this.nAroundTargetID = nil      -- 绕目标旋转
    this.nLastDivingCount = 0       -- 潜水时长计数
    this.nLogicLoop = 0
    this.nEnableSegmentCount = nil  -- 镜头分档开启计数
    this.nUIModeProtectTimerID = nil-- UI模式保护定时器ID，避免平滑过渡过程被打断

    this.nFov = nil
    this.nLastMoveState = nil
    this.tZoomLimit = {0, 1}    -- 镜头缩放范围
    this.tDirectionVector = {nX = 0, nY = 0}
    this.tLerpDirectionVector = {nX = 0, nY = 0}
    this.bIsMoving = false
    this.bCanDrag = false
    this.bIsDraging = false
    this.bAimMode = false
    this.tVehicelParam = {      -- 交通参数
        bLimitScale = nil,      -- 是否禁止镜头缩放
        nBackupScale = nil,
    }
    this.nZoomScale = this.calcCurrentScale()

    this.SetZoomLimit()
    this.EnableSegment(true)    -- 开启新版的镜头分档逻辑
    this.regEvents()

    rlcmd("enable animation camera 0")      -- 关闭DX版的0档镜头效果
    --rlcmd("enable adjust camera by move 1") -- 开启角色移动过程中修正镜头
end

function CameraMgr.UnInit()
    Event.UnRegAll(this)
    Timer.DelAllTimer(this)
end

function CameraMgr.Tick()
    -- 当鼠标停止不动时，Cocos的DragMove事件没能及时通知
    -- 导致鼠标即使已经停止拖动了，摄像机镜头仍在转动
    local bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
    local bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)
    if this.bIsDraging and (SceneMgr.GetTouchingCount() == 1 or (bLDown and bRDown)) then
        --if this.nAroundTargetID then
        --    Camera_SetDragParams(0, 0)      -- 锁定摄像机的转动
        --else
        Camera_SetDragParams(
            (this.nLastTouchX - this.nCurTouchX) * this.nDragFactorX,
            (this.nCurTouchY - this.nLastTouchY) * this.nDragFactorY
        )
        --end
        --LOG.DEBUG("Camera Drag Param: Last(%f,%f),Cur(%f,%f),DragFactor(%f,%f)",this.nLastTouchX, this.nLastTouchY, this.nCurTouchX, this.nCurTouchY, this.nDragFactorX, this.nDragFactorY)
        this.nLastTouchX = this.nCurTouchX
        this.nLastTouchY = this.nCurTouchY
    end

    this._clearMoveStateByPlayerState()
    this._updatePlayerPitch()
    this._rotatePlayer()
    this._updateJoystickHold()
end

function CameraMgr.OnReload()
    Event.UnRegAll(this)
    Timer.DelAllTimer(this)

    this.regEvents()
    if g_pClientPlayer then
        this._regInputEvents()

        Timer.AddFrameCycle(this, 1, this.Tick)
    end
end

function CameraMgr.LockTarget(nTargetID, nConfigID, nPriority, bIgnoreMoveStateLimit)
    if not nTargetID or nTargetID == 0 then
        this.nAroundTargetID = nil
        this.nCameraLockConfigID = nil
        this.nCameraLockPriority = nil
        this.bCameraLockIgnoreMove = nil
        rlcmd("set character camera lock target 0")
    else
        this.nAroundTargetID = nTargetID
        this.nCameraLockConfigID = nConfigID
        this.nCameraLockPriority = nPriority
        this.bCameraLockIgnoreMove = bIgnoreMoveStateLimit
        Camera_SetResetSpeed(0)
        nPriority = nPriority or 0
        rlcmd(string.format("set character camera lock target %d %d %d %d", nTargetID, nConfigID or 1, nPriority, bIgnoreMoveStateLimit and 1 or 0))
    end
end

function CameraMgr.ClearCameraLockTarget()
	if not this.dwCameraLockTargetID then
		return
	end

	this.dwCameraLockTargetID = nil
end

function CameraMgr.regEvents()
    Event.Reg(this, "SET_MAIN_PLAYER", function(nPlayerID)
        if nPlayerID == 0 then
            this.nLastDivingCount = 0
            this.nLogicLoop = 0
            this.tVehicelParam = {}
            this.nUIModeProtectTimerID = nil
            Timer.DelAllTimer(this)
            return
        end

        this._regInputEvents()

        Timer.AddFrameCycle(this, 1, this.Tick)
        this._clearMoveState()

        -- 关闭摄像机裁剪
        -- 2023-04-23，关闭引擎的摄像机裁剪，开启表现逻辑裁剪
        --rlcmd("enable camera frustum clip 0")

        -- 进入场景以后重新设置一遍镜头, 避免镜头无故移动
        local nScale = Camera_GetRTParams()
        this.Zoom(nScale)

        -- 骑乘状态下需关闭镜头光阴影
        if g_pClientPlayer then
            rlcmd(string.format("mb enable camera spot light camera %d" , g_pClientPlayer.bOnHorse and 0 or 1))
        end

        if QualityMgr.bDisableCameraLight then
            rlcmd("bd enable focus face 0")             -- 关闭镜头光
            this.SetSegmentConfig(false, false, false)  -- 关闭0档的HDface, Lod0, 景深
        end

        -- 作用玩家设置参数
        GameSettingData.InitSettingInGameByKey(SettingCategory.General)
    end)

    Event.Reg(this, EventType.OnClientPlayerLeave, function()
        rlcmd("mb enable camera spot light camera 1")
    end)

    Event.Reg(this, "PLAYER_MOUNT_HORSE", function(dwPlayerID, bMount, dwParam, bHoldHorse)
        if not g_pClientPlayer or g_pClientPlayer.dwID ~= dwPlayerID then
            return
        end

        -- 骑乘状态下需关闭镜头光阴影
        rlcmd(string.format("mb enable camera spot light camera %d", bMount and 0 or 1))
    end)

    Event.Reg(this, "END_CAMERA_ANIMATION", function ()
        --TODO_xt: 2024.6.3 镜头动画暂不能恢复镜头的fov值，在脚本里面临时恢复
        if this.nFov then
            this.SetCameraFov(this.nFov)
        end
    end)

    Event.Reg(this, "UI_START_AUTOFLY", this.onStartAutoFly)
    Event.Reg(this, "UI_END_AUTOFLY", this.onEndAutoFly)

    -- 横竖屏切换时需要重新计算
    Event.Reg(this, EventType.OnSetScreenPortrait, function()
        local nScaleX, nScaleY = UIHelper.GetScreenToDesignScale()
        this.nDragFactorX = kDragFactorX() * nScaleX
        this.nDragFactorY = kDragFactorY() * nScaleY
        this.nResolutionScale = nScaleY
    end)

    Event.Reg(this, EventType.OnWindowsSizeChanged, function()
        local nScaleX, nScaleY = UIHelper.GetScreenToDesignScale()
        this.nDragFactorX = kDragFactorX() * nScaleX
        this.nDragFactorY = kDragFactorY() * nScaleY
        this.nResolutionScale = nScaleY
    end)

    Event.Reg(this, "PLAYER_REVERSE_MOVE", function()
        if this.bIsMoving then
            if g_pClientPlayer.bReverseMove then    -- 操作反向
                Camera_EnableControl(CameraDef.CONTROL_FORWARD, false)
                Camera_EnableControl(CameraDef.CONTROL_BACKWARD, true)
            else
                Camera_EnableControl(CameraDef.CONTROL_BACKWARD, false)
                Camera_EnableControl(CameraDef.CONTROL_FORWARD, true)
            end
        end
    end)

    Event.Reg(this, EventType.OnViewOpen, function(nViewID)
        if Platform.IsMobile() or Channel.Is_WLColud() then
            return
        end

        if UIMgr.IsInLayer(nViewID, UILayer.Page) or
            UIMgr.IsInLayer(nViewID, UILayer.Popup) or
            UIMgr.IsInLayer(nViewID, UILayer.MessageBox) or
            UIMgr.IsInLayer(nViewID, UILayer.SystemPop) then
                if this.bIsDraging then
                    this._onDragEnded(nil, nil, true)
                end
        end
    end)

    Event.Reg(this, "OnPointTouchBegin", function(id, nX , nY)
        local nScaleX, nScaleY = UIHelper.GetScreenToDesignScale()
        this.nDragFactorX = kDragFactorX(true) * nScaleX
        this.nDragFactorY = kDragFactorY(true) * nScaleY
        this.bIsPointTouch = true
    end)

    Event.Reg(this, "OnPointTouchEnd", function(id, nX , nY)
        local nScaleX, nScaleY = UIHelper.GetScreenToDesignScale()
        this.nDragFactorX = kDragFactorX() * nScaleX
        this.nDragFactorY = kDragFactorY() * nScaleY
        this.bIsPointTouch = false
    end)

    Event.Reg(this, "LOADING_END", function ()
        -- 0档镜头光使用推荐画质关联的QualityLevel
        local nType = QualityMgr.GetRecommendQualityType()
        local tCfg = {}
        if Platform.IsMobile() then
            tCfg[GameQualityType.LOW] = 1
            tCfg[GameQualityType.MID] = 2
            tCfg[GameQualityType.HIGH] = 3
            tCfg[GameQualityType.EXTREME_HIGH] = 4
        else
            tCfg[GameQualityType.LOW] = 3
            tCfg[GameQualityType.MID] = 3
            tCfg[GameQualityType.HIGH] = 3
            tCfg[GameQualityType.EXTREME_HIGH] = 4
        end
        this.SetSegmentConfig(nil, nil, nil, nil, tCfg[nType])

        -- 接触锁定
        if this.bLockCHAndGJ then
            CameraMgr.SetLockCHAndGJ(false)
        end
    end)

    Event.Reg(this, "PLAYER_LEAVE_SCENE", function ()
        CameraMgr.ClearCameraLockTarget()
    end)
end

function CameraMgr._regInputEvents()
    -- 鼠标滚轮
    Event.Reg(this, EventType.OnHotkeyCameraZoom, function (nDelta, bHandled)
        if nDelta == 0 then return end
        if bHandled then return end
        this.doCameraZoom(nDelta > 0 and -1 or 1)
    end)

    -- 笔记本触控板 双指扫的动作
    Event.Reg(this, EventType.OnSwipeTouchPad, function (nDeltaX, nDeltaY)
        if nDeltaX == nil or nDeltaY == nil then return end
        LOG.INFO("CameraMgr, OnSwipeTouchPad nDeltaX = %s, nDeltaY = %s", tostring(nDeltaX), tostring(nDeltaY))

        nDeltaX = -nDeltaX

        if math.abs(nDeltaX) < 2 then nDeltaX = 0 end
        if math.abs(nDeltaY) < 2 then nDeltaY = 0 end
        GamepadData.Update_R_Thumb(nDeltaX, nDeltaY, true, 3)
    end)

    Event.Reg(this, EventType.OnSceneTouchBegan, this._onDragBegan)
    Event.Reg(this, EventType.OnSceneTouchMoved, this._onDragMoved)
    Event.Reg(this, EventType.OnSceneTouchEnded, this._onDragEnded)
    Event.Reg(this, EventType.OnSceneTouchCancelled, this._onDragEnded)
    Event.Reg(this, EventType.OnSceneTouchsBegan, this._onMultiTouchsBegan)
    Event.Reg(this, EventType.OnSceneTouchsMoved, this._onMultiTouchsMoved)
    Event.Reg(this, EventType.OnSceneTouchsEnded, this._onMultiTouchsEnded)
    Event.Reg(this, EventType.OnSceneTouchsCancelled, this._onMultiTouchsEnded)

    this.BindKeyboard()
end

-- ================================================================
-- 镜头拖拽
-- ================================================================
function CameraMgr._onDragBegan(nX, nY)
    local bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
    local bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)
    if SceneMgr.GetTouchingCount() > 1 and not (bLDown and bRDown) then
        this._onDragEnded(nX, nY)
        return
    end

    this.nCurTouchX = nX
    this.nCurTouchY = nY
    this.nLastTouchX = nX
    this.nLastTouchY = nY
    this.bIsDraging = true

    if this.CheckAimMode() then
        this.bAimMode = true
    end

    local bTouch = 1
    if (Platform.IsWindows() and not Channel.Is_WLColud()) and (not this.bIsPointTouch) then
        bTouch = false
    end
    if this.bAimMode or (bLDown and bRDown) then
        Camera_EnableControl(CameraDef.CONTROL_OBJECT_STICK_CAMERA, true)  --在载具战斗状态时，拖动镜头瞄准，以及左右键同时点击时自动行走
        if not this.nBeginTouchX or not this.nBeginTouchY then
            this.nBeginTouchX, this.nBeginTouchY = Camera_BeginDrag(bTouch, 1)
        else
            Camera_BeginDrag(bTouch, 1)
        end
    else
        Camera_EnableControl(CameraDef.CONTROL_CAMERA, true)
        Camera_EnableControl(CameraDef.CONTROL_OBJECT_STICK_CAMERA, false)
        if not this.nBeginTouchX or not this.nBeginTouchY then
            this.nBeginTouchX, this.nBeginTouchY = Camera_BeginDrag(bTouch, 1)
        else
            Camera_BeginDrag(bTouch, 1)
        end
    end
    -- local tbScreenSize = UIHelper.GetScreenSize()
    -- if nX > tbScreenSize.width / 2 then -- 屏幕右侧才能拖拽
    --     this.bCanDrag = true
    -- end
end

function CameraMgr._onDragMoved(nX, nY)
    --if not this.bCanDrag then return end
    --if InputHelper.IsLockCamera() then return end

    this.nCurTouchX = nX
    this.nCurTouchY = nY
end

function CameraMgr.CheckAimMode()
    if not g_pClientPlayer then
        return false
    end

    local dwShapeShiftID = g_pClientPlayer.dwShapeShiftID
    if dwShapeShiftID ~= 0 then
        local pShapeShiftInfo = GetShapeShiftInfo(dwShapeShiftID)
        if pShapeShiftInfo and pShapeShiftInfo.nMoveSpeed == 0 then --目前所有移速为0的载具都有瞄准状态，若之后有变化则在Shapeshift.tab表里加列
            return true
        end
    end

    return false
end

function CameraMgr.CheckHomeBuilding()
    return UIMgr.IsViewOpened(VIEW_ID.PanelConstructionMain)
end

function CameraMgr._onDragEnded(nX, nY, bForce)
    local nTouchingCount = SceneMgr.GetTouchingCount()

    if nTouchingCount ~= 2 then
        this.bMultiMoved = false
    end

    -- 这里为了解决双指变单指的不能拖拽的问题
    if nTouchingCount == 1 and not bForce then
        local pos = SceneMgr.GetTouchPos()
        if pos then
            this._onDragBegan(pos.nX, pos.nY)
        end
        return
    end

    -- nTouchingCount == 0:
    Camera_EnableControl(CameraDef.CONTROL_OBJECT_STICK_CAMERA, false)
    Camera_EnableControl(CameraDef.CONTROL_CAMERA, false)

    if this.nBeginTouchX and this.nBeginTouchY then
        Camera_EndDrag(this.nBeginTouchX, this.nBeginTouchY, 1)
        this.nBeginTouchX = nil
        this.nBeginTouchY = nil
    end

    this.bCanDrag = false
    this.bIsDraging = false
    this.nLastScale = nil
end

-- ================================================================
-- 镜头缩放
-- ================================================================
function CameraMgr._onMultiTouchsBegan(nX1, nY1, nX2, nY2)
    this._onDragBegan(nX1, nY1)
    this._onDragBegan(nX2, nY2)
end

function CameraMgr._onMultiTouchsMoved(nX1, nY1, nX2, nY2)
    if SceneMgr.GetTouchingCount() ~= 2 then
        this.bMultiMoved = false
        return
    end

    if not this.bMultiMoved then
        this.bMultiMoved = true
        this.nLastScale = this.GetCameraScale()
        this.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)
        return
    end

    local bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
    local bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)
    if bLDown and bRDown then
        this._onDragMoved(nX1, nY1)
        return
    end

    local nDist = kmath.len2(nX1, nY1, nX2, nY2)
    local nDelta = nDist - this.nLastPinchDist

    if math.abs(nDelta) < 2 then
        return
    end

    this.nLastPinchDist = nDist

    if Platform.IsMobile() or Channel.Is_WLColud() then
        local nZoomValue = -nDelta * this.nResolutionScale / UIHelper.GetDpi()
        this.doCameraZoom(-nDelta * this.nResolutionScale / UIHelper.GetDpi())
    else
        -- 屏幕像素距离转换为实际CM
        local nZoomValue = -nDelta * this.nResolutionScale / UIHelper.GetDpi() / 2.54
        this.doCameraZoom(nZoomValue)
    end
end

function CameraMgr._onMultiTouchsEnded(nX1, nY1, nX2, nY2)
    this._onDragEnded(nX1, nY1)
    this._onDragEnded(nX2, nY2)
end

-- ===============================================================
-- 其他
-- ===============================================================
function CameraMgr._getCameraYaw()
    local _, nYaw = Camera_GetRTParams()
    return (math.pi * 2 - nYaw) / (math.pi * 2) * 256 + 64
end

function CameraMgr._setPlayerRotation(nOffset)
    local nYaw = this._getCameraYaw()
    nYaw = nYaw - nOffset
    nYaw = nYaw % 256

    if g_pClientPlayer.bReverseMove then
        nYaw = nYaw + 128
        nYaw = nYaw % 256
    end

    this.nYaw = nYaw
    TurnTo(nYaw, false)
end

function CameraMgr._rotatePlayer()
    if IsPlayerFaceLocked() or this.bFreeView then
        return
    end

    local bAutoForward = SprintData.GetAutoForward()
    if not this.bIsMoving and not bAutoForward then
        return
    end

    this.tLerpDirectionVector.nX = this.tLerpDirectionVector.nX + (this.tDirectionVector.nX - this.tLerpDirectionVector.nX) * LERP_SPEED
    this.tLerpDirectionVector.nY = this.tLerpDirectionVector.nY + (this.tDirectionVector.nY - this.tLerpDirectionVector.nY) * LERP_SPEED

    local nOffset = 64  -- 默认朝前方移动(Y轴正方向)
    local nX, nY = math.abs(this.tLerpDirectionVector.nX), math.abs(this.tLerpDirectionVector.nY)
    if nY ~= 0 then
        nOffset = kmath.fastArcTan(nX / nY)
    end

    if not this.nAroundTargetID then
        local nMagnification = 1
        if g_pClientPlayer.bSprintFlag then
            nMagnification = kCameraSprintSpeed
        end
        if nOffset < kCameraStartRotateAngle then
            Camera_SetResetSpeed(0)
        else
            local nTempOffset = nOffset
            if this.tLerpDirectionVector.nY < 0 then
                nTempOffset = 128 - nTempOffset
            end
            Camera_SetResetSpeed(nTempOffset * nMagnification * kCameraStartRotateSpeed)
        end
    end

    if this.tLerpDirectionVector.nX >= 0 and this.tLerpDirectionVector.nY < 0 then
        nOffset = 128 - nOffset
    elseif this.tLerpDirectionVector.nX < 0 and this.tLerpDirectionVector.nY < 0 then
        nOffset = 128 + nOffset
    elseif this.tLerpDirectionVector.nX < 0 and this.tLerpDirectionVector.nY >= 0 then
        nOffset = 256 - nOffset
    end
    if nOffset == 256 then
        nOffset = 0
    end

    if bAutoForward then
        nOffset = 0
    end

    this._setPlayerRotation(nOffset)
end

function CameraMgr._updateJoystickHold()
    local bJoystickHold = this.tDirectionVector.nX ~= 0 or this.tDirectionVector.nY ~= 0
    local nJoystickDirection = this.nYaw

    UpdateJoystickHold(bJoystickHold, nJoystickDirection)
end

function CameraMgr._updatePlayerPitch()
    local nLogicLoop = GetLogicFrameCount()
    if nLogicLoop == this.nLogicLoop then   -- 逻辑帧变化了才有意义
        return
    end
    this.nLogicLoop = nLogicLoop

    local pPlayer = g_pClientPlayer
    local nMoveState = pPlayer.nMoveState
    local _, _, nPitch = Camera_GetRTParams()

    -- 获取潜水状态
    local nDivingCount = pPlayer.nDivingCount
    local isDiving = nDivingCount > this.nLastDivingCount
    this.nLastDivingCount = nDivingCount

    if this.nLastMoveState ~= MOVE_STATE.ON_SWIM_JUMP
        and this.nLastMoveState ~= MOVE_STATE.ON_SWIM
        and this.nLastMoveState ~= MOVE_STATE.ON_FLOAT and
        (nMoveState == MOVE_STATE.ON_SWIM_JUMP or nMoveState == MOVE_STATE.ON_SWIM or nMoveState == MOVE_STATE.ON_FLOAT) then
        pPlayer.PitchTo(0)
    elseif (nMoveState == MOVE_STATE.ON_SWIM or nMoveState == MOVE_STATE.ON_FLOAT) and not isDiving then
        if nPitch < kCameraEnterWaterPitch then
            pPlayer.PitchTo(nPitch * 128 / math.pi)
        else
            pPlayer.PitchTo(0)
        end
    else
        pPlayer.PitchTo(nPitch * 128 / math.pi)
    end
    this.nLastMoveState = nMoveState
end

function CameraMgr._clearMoveStateByPlayerState()
    local pPlayer = g_pClientPlayer
    if this.nFollowType ~= pPlayer.nFollowType and
        (pPlayer.nFollowType == FOLLOW_TYPE.SIMMOVE or this.nFollowType == FOLLOW_TYPE.SIMMOVE) then
        this._clearMoveState()
    end
    this.nFollowType = pPlayer.nFollowType

    if this.bLockedFace ~= pPlayer.bLockedFace then
        this._clearMoveState()
    end
    this.bLockedFace = pPlayer.bLockedFace
end

function CameraMgr._clearMoveState()
    this.bIsMoving = false
    this.tDirectionVector = {nX = 0, nY = 0}
    this.tLerpDirectionVector = {nX = 0, nY = 0}
    Camera_EnableControl(CameraDef.CONTROL_FORWARD, false)
    Camera_EnableControl(CameraDef.CONTROL_BACKWARD, false)
    Camera_EnableControl(CameraDef.CONTROL_TURN_LEFT, false)
    Camera_EnableControl(CameraDef.CONTROL_TURN_RIGHT, false)
    Camera_EnableControl(CameraDef.CONTROL_STRAFE_LEFT, false)
    Camera_EnableControl(CameraDef.CONTROL_STRAFE_RIGHT, false)
    if g_pClientPlayer then
        g_pClientPlayer.HoldW(0)
    end
end

function CameraMgr.onStartAutoFly()
    local nTrackID = g_pClientPlayer.nCurrentTrack
    local nModelID = Global_GetVehicleModelIDByTrackID and Global_GetVehicleModelIDByTrackID(nTrackID) or 0
    LOG("player start auto fly VehicleModelID:%s, traceID:%s", nModelID, nTrackID)
    if nModelID == 0 then
        return
    end

    local nTargetScale = 1.0
    local tVehicelParam = this.tVehicelParam
    tVehicelParam.bLimitScale = true
    tVehicelParam.nBackupScale = this.GetCameraScale()
    CameraCharacter_Zoom(nTargetScale)
end

function CameraMgr.onEndAutoFly()
    local tVehicelParam = this.tVehicelParam
    tVehicelParam.bLimitScale = false

    if tVehicelParam.nBackupScale and tVehicelParam.nBackupScale ~= 0 then
        CameraCharacter_Zoom(tVehicelParam.nBackupScale)
        tVehicelParam.nBackupScale = nil
    end
end

-- ================================================================
-- 镜头相关接口
-- ================================================================

---comment 开关镜头分档设置
---@param bEnable boolean 是否开启
---@param bKeepCameraLight boolean|nil 是否保留镜头光功能
function CameraMgr.EnableSegment(bEnable, bKeepCameraLight)
    if not this.nEnableSegmentCount then
        this.nEnableSegmentCount = bEnable and 1 or 0
    else
        this.nEnableSegmentCount = this.nEnableSegmentCount + (bEnable and 1 or -1)
    end

    if this.nEnableSegmentCount == 0 then
        rlcmd(string.format("mb enable camera segment 0 %d", bKeepCameraLight and 1 or 0))
    elseif this.nEnableSegmentCount == 1 then
        rlcmd(string.format("mb enable camera segment 1 %d", bKeepCameraLight and 1 or 0))
    end
end

---comment 设置镜头分档的开关逻辑
---@param bFacesLimit boolean|nil 是否切高清脸
---@param bUseLod0 boolean|nil 是否切换lod0
---@param bEnableDof boolean|nil 是否开启景深
---@param bEnableTurnFront boolean|nil 是否开启特写镜头
---@param nCameraLightQualityLevel integer|nil 开启镜头光时的画质等级
function CameraMgr.SetSegmentConfig(bFacesLimit, bUseLod0, bEnableDof, bEnableTurnFront, nCameraLightQualityLevel)
    local tCfg = this.tSegmentConfig
    if type(bFacesLimit) == "boolean" then
        tCfg.bFacesLimit = bFacesLimit
    end
    if type(bUseLod0) == "boolean" then
        tCfg.bUseLod0 = bUseLod0
    end
    if type(bEnableDof) == "boolean" then
        tCfg.bEnableDof = bEnableDof
    end
    if type(bEnableTurnFront) == "boolean" then
        tCfg.bEnableTurnFront = bEnableTurnFront
    end
    if type(nCameraLightQualityLevel) == "number" then
        tCfg.nCameraLightQualityLevel = nCameraLightQualityLevel
    end

    rlcmd(string.format(
        "mb set camera segment config %d %d %d %d %d",
        tCfg.bFacesLimit and 1 or 0,
        tCfg.bUseLod0 and 1 or 0,
        tCfg.bEnableDof and 1 or 0,
        tCfg.bEnableTurnFront and 1 or 0,
        tCfg.nCameraLightQualityLevel
    ))
end

---comment 设置摄像机拖拽速度
---@param speed number 速度
function CameraMgr.SetDragSpeed(speed)
    if speed ~= this.nDragSpeed then
        this.nDragSpeed = speed

        local _, _, nSpringResetSpeed, nCameraResetSpeed = Camera_GetParams()
        Camera_SetParams(speed, this.fMaxDistance, nSpringResetSpeed, nCameraResetSpeed, this.nResetMode)
    end
end

function CameraMgr.GetMaxDistance()
    return this.fMaxDistance
end

---comment 设置摄像机最大距离
---@param distance number 距离
function CameraMgr.SetMaxDistance(distance)
    if distance == this.fMaxDistance then
        return
    end

    this.fMaxDistance = distance
    if distance > 0 and math.abs(this.fMaxDistance * this.tZoomLimit[1] - kZoomMinDis) < 1 then
        this.tZoomLimit[1] = kZoomMinDis / distance
    end

    local _, _, nSpringResetSpeed, nCameraResetSpeed = Camera_GetParams()
    Camera_SetParams(this.nDragSpeed, distance, nSpringResetSpeed, nCameraResetSpeed, this.nResetMode)
    --CameraCharacter_ZoomEx(this.nZoomScale, 500) -- 刷新镜头分档
end

---comment 设置镜头缩放限制[0, 1]
---@param minScale number 最小缩放
---@param maxScale number 最大缩放
function CameraMgr.SetZoomLimit(minScale, maxScale)
    if minScale then
        this.tZoomLimit[1] = minScale
    elseif this.fMaxDistance > 0 then
        this.tZoomLimit[1] = kZoomMinDis / this.fMaxDistance
    else
        this.tZoomLimit[1] = 0
    end
    this.tZoomLimit[2] = maxScale or 1
end

---comment 缩放镜头
---@param scale number 缩放系数[0, 1]
function CameraMgr.Zoom(scale , bUnSendEvent)
    if InputHelper.IsLockCamera() then
        return
    end

    if this.fMaxDistance == 0 then
        return  -- 镜头被强制拉到最近
    end

    if this.tVehicelParam.bLimitScale then
        return  -- 交通中, 禁止缩放镜头
    end

    if this.nAroundTargetID then
        return  -- 镜头锁定目标
    end

    if this.nLastScale and math.abs(this.nLastScale - scale) < 0.03 then
        return
    end

    if scale <= this.tZoomLimit[1] then scale = this.tZoomLimit[1] end
    if scale >= this.tZoomLimit[2] then scale = this.tZoomLimit[2] end

    this.nLastScale = scale -- 拖动镜头时用于比较拖动幅度
    this.nZoomScale = scale

    CameraCharacter_Zoom(scale)
    if not bUnSendEvent then
        Event.Dispatch(EventType.OnCameraZoom, scale)
    end
end

---comment 设置摄像机的拖拽俯仰角限制(角色摄像机), 注:垂直向下的角度为-90, 水平方向的角为0, 垂直向上的角度为90
---@param minPitch number
---@param maxPitch number
function CameraMgr.SetDragPitchLimit(minPitch, maxPitch)
    assert(minPitch and maxPitch)
    minPitch = minPitch * math.pi / 180
    maxPitch = maxPitch * math.pi / 180
    rlcmd(string.format("set character camera pitch limit %f %f", minPitch, maxPitch))
end

---comment 设置镜头的跟随模式
---@param mode integer (0:从不跟随, 1:智能跟随, 2:总是追随)
function CameraMgr.SetFollowMode(mode)
    this.nResetMode = mode

    if not this.bCacheParam then
        local _, _, nSpringResetSpeed, nCameraResetSpeed = Camera_GetParams()
        Camera_SetParams(this.nDragSpeed, this.fMaxDistance, nSpringResetSpeed, nCameraResetSpeed, mode)
    end
end

---comment 重置摄像机拖拽俯仰角限制（角色摄像机）
function CameraMgr.ResetDragPitchLimit()
    rlcmd("set character camera pitch limit")
end

function CameraMgr.calcCurrentScale()
    local fCameraDistance = this.GetCameraDistance()
    local _, fCameraMaxDistance = Camera_GetParams()
    local nScale = fCameraDistance / fCameraMaxDistance
    return math.min(1, nScale)
end

function CameraMgr.doCameraZoom(delta)
    if this.nUIModeProtectTimerID then
        return  -- 正在UI模式平滑过渡中
    end
    if this.nLastScale == nil then
        this.nLastScale = this.calcCurrentScale()
    end

    local nCurScale = this.nLastScale
    local nScale = nCurScale + delta * this.nZoomFactor
    this.Zoom(nScale)
end

function CameraMgr.GetCameraScale()
    return this.nZoomScale or this.calcCurrentScale()
end

function CameraMgr.GetCameraDistance()
    local _, _, _, fPosX, fPosY, fPosZ, fLookAtX, fLookAtY, fLookAtZ = Camera_GetRTParams()
    return kmath.len3(fPosX, fPosY, fPosZ, fLookAtX, fLookAtY, fLookAtZ)
end

function CameraMgr.SetDirectionVector(nX, nY)
    if not nX then nX = 0 end
    if not nY then nY = 0 end

    this.tDirectionVector.nX = nX
    this.tDirectionVector.nY = nY
    this.bIsMoving = nX ~= 0 or nY ~= 0

    local bLocked = IsPlayerFaceLocked()
    local bReverse = g_pClientPlayer and g_pClientPlayer.bReverseMove

     if this.bIsMoving then
         if not bLocked and not this.bFreeView then
             local dir = bReverse and CameraDef.CONTROL_BACKWARD or CameraDef.CONTROL_FORWARD
             Camera_EnableControl(dir, true)
         else
             local szDir = this.GetDraggingDirection_8()
             if szDir ~= this.szLockedDirection then
                 this.szLockedDirection = szDir
                 Camera_EnableControl(ControlDef.CONTROL_FORWARD, false)
                 Camera_EnableControl(ControlDef.CONTROL_BACKWARD, false)
                 Camera_EnableControl(ControlDef.CONTROL_STRAFE_LEFT, false)
                 Camera_EnableControl(ControlDef.CONTROL_STRAFE_RIGHT, false)

                 if szDir == JoystickDirection.Up or szDir == JoystickDirection.RightUp or szDir == JoystickDirection.LeftUp then
                     Camera_EnableControl(bReverse and CameraDef.CONTROL_BACKWARD or CameraDef.CONTROL_FORWARD, true)
                 end
                 if szDir == JoystickDirection.Down or szDir == JoystickDirection.RightDown or szDir == JoystickDirection.LeftDown then
                     Camera_EnableControl(bReverse and CameraDef.CONTROL_FORWARD or CameraDef.CONTROL_BACKWARD, true)
                 end
                 if szDir == JoystickDirection.Left or szDir == JoystickDirection.LeftDown or szDir == JoystickDirection.LeftUp then
                     Camera_EnableControl(bReverse and CameraDef.CONTROL_STRAFE_RIGHT or CameraDef.CONTROL_STRAFE_LEFT, true)
                 end
                 if szDir == JoystickDirection.Right or szDir == JoystickDirection.RightUp or szDir == JoystickDirection.RightDown then
                     Camera_EnableControl(bReverse and CameraDef.CONTROL_STRAFE_LEFT or CameraDef.CONTROL_STRAFE_RIGHT, true)
                 end
             end
         end
     else
         this.szLockedDirection = nil
         -- 取消移动时将正、反方向的状态都置空，解决移动过程中设置bReverseMove后不能正确清理状态的问题
         Camera_EnableControl(CameraDef.CONTROL_FORWARD, false)
         Camera_EnableControl(CameraDef.CONTROL_BACKWARD, false)
         Camera_EnableControl(CameraDef.CONTROL_STRAFE_LEFT, false)
         Camera_EnableControl(CameraDef.CONTROL_STRAFE_RIGHT, false)
     end
    Event.Dispatch(EventType.OnPlayerMove)
end

---comment 异步获取摄像机的透视投影参数
---@param fnCall function
function CameraMgr.GetPerspectiveAsync(fnCall)
    local pScene  = SceneMgr.GetGameScene()
    if not pScene then
        return
    end

    PostSceneThreadCall(
        function(pScene, nFov, nAspect, nNear, nFar)
            fnCall(nFov, nAspect, nNear, nFar)
        end,
        pScene,
        "GetCameraPerspective"
    )
end

---comment 异步获取摄像机的正交投影参数
---@param fnCall function
function CameraMgr.GetOrthogonalAsync(fnCall)
    local pScene  = SceneMgr.GetGameScene()
    if not pScene then
        return
    end

    PostSceneThreadCall(
        function(pScene, nWidth, nHeight, nNear, nFar)
            fnCall(nWidth, nHeight, nNear, nFar)
        end,
        pScene,
        "GetCameraOrthogonal"
    )
end

---comment 异步获取场景的主光源方向
---@param fnCall function
function CameraMgr.GetMainLightDirectionAsync(fnCall)
    local pScene  = SceneMgr.GetGameScene()
    if not pScene then
        return
    end

    PostSceneThreadCall(
        function(pScene, fX, fY, fZ)
            fnCall(fX, fY, fZ)
        end,
        pScene,
        "GetMainLightDirection"
    )
end

function CameraMgr.SetMainLightDirection(fX, fY, fZ)
    rlcmd(string.format("set main light direction %d %f %f %f", 1, fX, fY, fZ))
end

---comment 开关镜头动画，即镜头拉近以后转向正面。
---@param bEnable boolean
function CameraMgr.EnableAnimationCamera(bEnable)
    -- -- 0: 无效果, 1: 动画&0档效果, 2:动画, 3:0档效果
    -- if bEnable then
    --     rlcmd("enable animation camera 1")
    -- else
    --     local nLevel = VideoBase_Level()
    --     if VideoBase.IsBD(nLevel) then
    --         rlcmd("enable animation camera 3")
    --     else
    --         rlcmd("enable animation camera 0")
    --     end
    -- end

    --2024.8.26 楼下策划biyueyang需求
    if bEnable == true or bEnable == 1 then
        rlcmd("mb enable camera segment 0 0")
    else
        rlcmd("mb enable camera segment 1 1")
    end
end

function CameraMgr.GetDraggingDirection_8()
    if not this.bIsMoving then
        return
    end

    local nX = this.tDirectionVector.nX
    local nY = this.tDirectionVector.nY
    local nDistance = kmath.len2(nX, nY, 0, 0)
    local nRadian = math.atan2(nY, nX) -- 弧度
    local nAngle = -(nRadian * 180 / math.pi) -- 角度
    local nOffsetAngle = 22.5

    if nDistance > 0 then
        local bForward = nAngle > -(90 + nOffsetAngle) and nAngle < -(90 - nOffsetAngle)
        if bForward then
            return JoystickDirection.Up
        end

        local bBackward = nAngle < (90 + nOffsetAngle) and nAngle > (90 - nOffsetAngle)
        if bBackward then
            return JoystickDirection.Down
        end

        local bLeft = (nAngle < -180 + nOffsetAngle or nAngle > 180 - nOffsetAngle)
        if bLeft then
            return JoystickDirection.Left
        end

        local bRight = nAngle < nOffsetAngle and nAngle > -nOffsetAngle
        if bRight then
            return JoystickDirection.Right
        end

        local bRightDown = nAngle > nOffsetAngle and nAngle < 90 - nOffsetAngle
        if bRightDown then
            return JoystickDirection.RightDown
        end

        local bRightUp = nAngle < -nOffsetAngle and nAngle > -(90 - nOffsetAngle)
        if bRightUp then
            return JoystickDirection.RightUp
        end

        local bLeftUp = nAngle > -180 + nOffsetAngle and nAngle < -(90 + nOffsetAngle)
        if bLeftUp then
            return JoystickDirection.LeftUp
        end

        local bLeftDown = nAngle < 180 - nOffsetAngle and nAngle > 90 + nOffsetAngle
        if bLeftDown then
            return JoystickDirection.LeftDown
        end
    end
end

function CameraMgr.OnReload()
end

























-- UI打开或者关闭时候的相关操作
function CameraMgr.EnterUIMode(bForceFaceCamera)
    local nEnterTime = 400 -- 单位 毫秒

    if this.bIsEnterUIMode then
        if bForceFaceCamera then
            rlcmd(string.format("reset camera offset %d 1", nEnterTime))
        end
        return
    end

    local _, nMaxCameraDis = Camera_GetParams()
    local nScale = kUIModeDistance / nMaxCameraDis
    this.fEnterCameraScale = this.GetCameraScale()
    this.nLastScale = nScale
    Event.Dispatch(EventType.OnCameraZoom, nScale)

    CameraMgr.SetZoomLimit(kUIModeDistanceRange[1] / nMaxCameraDis, kUIModeDistanceRange[2] / nMaxCameraDis)
    CameraMgr.SetDragPitchLimit(-90, 5)

    rlcmd("debug option -set force update camera 1")
    if bForceFaceCamera then
        rlcmd(string.format("reset camera offset %d 1", nEnterTime))
    end

    this.tEnvCtrl = RLEnv.PushVisibleCtrl()     -- 压栈
    --this.EnableDof(true)                      --TODO: 2023.7.6 与镜头分档有冲突, 2024.3.29: 景深开关由0档镜头设置
    this.HidePlayer(true)
    this.HideNpc(true)

    TargetMgr.doSelectTarget(0, TARGET.NO_TARGET)
    -- UIMgr.HideView(VIEW_ID.PanelMainCityInteractive)
    UIHelper.HideInteract()
    Event.Dispatch(EventType.SetNpcHeadBallonVisible, false)

    if GetClientPlayer().bOnHorse then
        CameraMgr.Status_Push({
            mode    = "local camera",
            scale   = nScale,
            yaw     = 2 * math.pi - (GetClientPlayer().nFaceDirection / 255 * math.pi * 2 + math.pi / 4),
            pitch   = - math.pi / 8,
            tick    = nEnterTime,
        }, true)
    else
        CameraMgr.Status_Push({
            mode    = "local camera",
            scale   = nScale,
            yaw     = 2 * math.pi - (GetClientPlayer().nFaceDirection / 255 * math.pi * 2 + math.pi / 2),
            pitch   = -6 * math.pi / 180,
            tick    = nEnterTime,
        }, true)
    end

    this.bIsEnterUIMode = true

    local tSetting = GameSettingData.GetNewValue(UISettingKey.CameraMode)
    if tSetting.szDec == GameSettingType.OperationMode.Locked.szDec then
        rlcmd("set character camera lock ctrl 0")
    end
end

function CameraMgr.ExitUIMode(nExitTime)
    nExitTime = nExitTime or 350 -- 单位 毫秒

    if not this.bIsEnterUIMode then
        return
    end

    CameraMgr.SetZoomLimit()
    CameraMgr.ResetDragPitchLimit()

    --[[
        触发分档逻辑，
        需要注意由于CameraMgr.Status_Backward("all")绕过分档调整镜头距离
        所以需要手动设置Zoom以正确更新的分档状态
    ]]
    local nScale = this.fEnterCameraScale or 1
    this.nLastScale = nScale
    this.nZoomScale = nScale

    RLEnv.RemoveVisibleCtrl(this.tEnvCtrl)      -- 弹出
    -- this.EnableDof(false)                     --TODO: 2023.7.6 与镜头分档有冲突
    -- UIMgr.ShowView(VIEW_ID.PanelMainCityInteractive)
    UIHelper.ShowInteract()
    Event.Dispatch(EventType.SetNpcHeadBallonVisible, true)
    CameraMgr.Status_Backward("all", nExitTime)

    this.bIsEnterUIMode = false

    local tSetting = GameSettingData.GetNewValue(UISettingKey.CameraMode)
    if tSetting.szDec == GameSettingType.OperationMode.Locked.szDec then
        rlcmd("set character camera lock ctrl 1")
    end

    rlcmd("debug option -set force update camera 0")
    Event.Dispatch(EventType.OnCameraZoom, nScale)
end

function CameraMgr.protectUIMode(nDuration)
    if not nDuration or nDuration < 1 then
        return
    end

    if this.nUIModeProtectTimerID then
        Timer.DelTimer(this, this.nUIModeProtectTimerID)
    end

    this.nUIModeProtectTimerID = Timer.Add(this, nDuration / 1000, function ()
        this.nUIModeProtectTimerID = nil
    end)
end

function CameraMgr.EnableDof(bEnable)
    Timer.DelTimer(this, this.nEnableDofTimerID)
    if bEnable then
        this.nEnableDofTimerID = Timer.Add(this, 0.5, function ()
            QualityMgr.ModifyCurQuality("bEnableDof", true)
        end)
    else
        QualityMgr.ModifyCurQuality("bEnableDof", false)
    end
end

function CameraMgr.HidePlayer(bHide, bShowTips)
    local tCtrl = this.tEnvCtrl or RLEnv.GetLowerVisibleCtrl()

    if not tCtrl then
        LOG.ERROR("CameraMgr.HidePlayer not ctrl")
        return
    end

    if bHide then
        tCtrl:ShowPlayer(PLAYER_SHOW_MODE.kNone)
        tCtrl:ShowObjHeadFlags(HEAD_FLAG_OBJ.OTHERPLAYER, false)
        if bShowTips then
            TipsHelper.ShowNormalTip("你已开启屏蔽玩家功能")
        end
    else
        tCtrl:ShowPlayer(PLAYER_SHOW_MODE.kAll)
        tCtrl:ShowObjHeadFlags(HEAD_FLAG_OBJ.OTHERPLAYER, true)
        if bShowTips then
            TipsHelper.ShowNormalTip("你已关闭屏蔽玩家功能")
        end
    end

    Global_UpdateHeadTopPosition()

    Event.Dispatch(EventType.OnCameraHidePlayer, bHide)
end

function CameraMgr.HideNpc(bHide)
    if not this.tEnvCtrl then
        LOG.ERROR("not in UIMode")
        return
    end

    local tCtrl = this.tEnvCtrl
    if bHide then
        tCtrl:ShowNpc(false)
        tCtrl:ShowObjHeadFlags(HEAD_FLAG_OBJ.NPC, false)
    else
        tCtrl:ShowNpc(true)
        tCtrl:ShowObjHeadFlags(HEAD_FLAG_OBJ.NPC, true)
    end

    Global_UpdateHeadTopPosition()
end
----------------------------------------------------------------------------------------------------
-- 镜头平移/旋转设置
----------------------------------------------------------------------------------------------------
local l_cameraOffsetX = 0
local l_cameraOffsetY = 0
local l_cameraOffsetZ = 0
local fCameraOffsetAngle = 0
local fLastCameraOffsetAngle = 0
local CONDITION_DISTANCE = 600
local MAX_CAMERA_OFFSET_Z = -120
local MAX_CAMERA_DISTANCE = 2400
local MAX_CAMERA_ROTATION_ANGLE =50
local function GetRotationDirection(fAngle)
    local bClockwise = -1
    if fAngle < fLastCameraOffsetAngle then
        bClockwise = 0
    elseif fAngle > fLastCameraOffsetAngle then
        bClockwise = 1
    end
    fLastCameraOffsetAngle = fAngle
    return bClockwise
end

local function AdjustTranslation()
    local fDistance = CameraMgr.GetCameraDistance()
    if fDistance <= CONDITION_DISTANCE then
        l_cameraOffsetZ = math.max(l_cameraOffsetZ, MAX_CAMERA_OFFSET_Z)
    end
end

local function TryAddDistance(nDistance, nOffset)
    if not nOffset then
        return nDistance
    end
    if math.abs(nDistance + nOffset) > MAX_CAMERA_DISTANCE then
        return nDistance
    end
    return nDistance + nOffset
end

local function TryAddAngle(fAngle, noffset)
    if not noffset then
        return fAngle
    end
    if math.abs(fAngle + noffset) > MAX_CAMERA_ROTATION_ANGLE then
        return fAngle
    end
    return fAngle + noffset
end

--Camera_ResetOffset
function CameraMgr.ResetOffset(fSmoothTime)
    local fTime = fSmoothTime or 250
    rlcmd(string.format("reset camera offset %f %d",fTime, GetRotationDirection(0)))
    --CameraCharacter_Zoom(0.05)
    l_cameraOffsetX = 0
    l_cameraOffsetY = 0
    l_cameraOffsetZ = 0
    fCameraOffsetAngle = 0
    fLastCameraOffsetAngle = 0
end
--Camera_TranslationOffset
function CameraMgr.TranslationOffset(x, y, z, r)
    if x or y or z or r then
        l_cameraOffsetX = x or l_cameraOffsetX
        l_cameraOffsetY = y or l_cameraOffsetY
        l_cameraOffsetZ = z or l_cameraOffsetZ
        fCameraOffsetAngle = r or fCameraOffsetAngle
        rlcmd(string.format("set camera offset %d %d %d %f %d",l_cameraOffsetX, l_cameraOffsetY, l_cameraOffsetZ, fCameraOffsetAngle, GetRotationDirection(fCameraOffsetAngle)))
    else
        return l_cameraOffsetX, l_cameraOffsetY, l_cameraOffsetZ, fCameraOffsetAngle
    end
end

function CameraMgr.TranslationMove(nOffsetX, nOffsetY, nOffsetZ, noffsetAngle)
    l_cameraOffsetX = TryAddDistance(l_cameraOffsetX, nOffsetX)
    l_cameraOffsetY = TryAddDistance(l_cameraOffsetY, nOffsetY)
    l_cameraOffsetZ = TryAddDistance(l_cameraOffsetZ, nOffsetZ)
    fCameraOffsetAngle = TryAddAngle(fCameraOffsetAngle, noffsetAngle)
    AdjustTranslation()
    local nClockwise = GetRotationDirection(fCameraOffsetAngle)
    rlcmd(string.format("set camera offset %d %d %d %f %d",l_cameraOffsetX, l_cameraOffsetY, l_cameraOffsetZ, fCameraOffsetAngle, nClockwise))
end

function CameraMgr.SetCameraFov(fFov)
    -- 兼容镜头分档逻辑中设置的fov值
    this.nFov = fFov
    Camera_SetAngle(fFov)
    --LOG.WARN("CameraMgr.SetCameraFov(%s)", math.floor(fFov * 180 / math.pi))
end

function CameraMgr.GetCameraMaxRotationAngle()
   return MAX_CAMERA_ROTATION_ANGLE
end

----------------------------------------------------------------------------------------------------
-- 镜头景深设置(DoF)
----------------------------------------------------------------------------------------------------

local m_nDoF_Dis  = 50
local m_nDoF_Near = 100
local _DOF_DEGREE_MIN = 700
local m_nDof_Degree = _DOF_DEGREE_MIN
--Camera_SetPostRenderDoFParam
function CameraMgr.SetPostRenderDoFParam(nDistance, nNear, nDofDegree)
    m_nDoF_Dis = nDistance or m_nDoF_Dis
    m_nDoF_Near = nNear or m_nDoF_Near
    m_nDof_Degree = nDofDegree or m_nDof_Degree

    local fY = m_nDoF_Dis - 0.5 * m_nDoF_Near
    local fZ = m_nDoF_Dis + 0.5 * m_nDoF_Near
    local fX = fY - m_nDof_Degree
    local fW = fZ + m_nDof_Degree

    fX = math.max(0, fX)
    fY = math.max(fX, fY)
    fZ = math.max(fY, fZ)
    fW = math.max(fZ, fW)

    KG3DEngine.SetPostRenderDoFParam(fX, fY, fZ, fW)
end

function CameraMgr.GetDofDegreeMin()
    return _DOF_DEGREE_MIN
end

----------------------------------------------------------------------------------------------------
-- 镜头状态
----------------------------------------------------------------------------------------------------
local l_cameraHistory = {}
local l_cameraHisPos  = 0
local l_cameraHisMode = false
local nTimerID   = nil
local l_free_view, l_dis_ctrl
local l_TurnLeftStart, l_TurnLeftStop,
      l_TurnRightStart, l_TurnRightStop

local function SetFreeViewEnableState(is_enter)
    if l_free_view == is_enter then
        return
    end
    this.bFreeView = is_enter
    if is_enter then -- hook left/right turn hotkey
        l_TurnLeftStart , l_TurnLeftStop  = TurnLeftStart   , TurnLeftStop
        TurnLeftStart   , TurnLeftStop    = StrafeLeftStart , StrafeLeftStop
        l_TurnRightStart, l_TurnRightStop = TurnRightStart  , TurnRightStop
        TurnRightStart  , TurnRightStop   = StrafeRightStart, StrafeRightStop
    else
        TurnLeftStart , TurnLeftStop  = l_TurnLeftStart  or TurnLeftStart , l_TurnLeftStop  or TurnLeftStop
        TurnRightStart, TurnRightStop = l_TurnRightStart or TurnRightStart, l_TurnRightStop or TurnRightStop
    end
    l_free_view = is_enter
end

function CameraMgr.Status_Push(opt, clearhistory)
    for i = l_cameraHisPos + 1, #l_cameraHistory do
        table.remove(l_cameraHistory)
    end
    if clearhistory then
        l_cameraHistory = {}
        l_cameraHisPos = 0
    end
    if #l_cameraHistory <= 1 then
        local oriscale, oriyaw, oripitch = Camera_GetRTParams()
        local orioffsetx, orioffsety, orioffsetz, orioffsetangle = CameraMgr.TranslationOffset()
        l_cameraHistory[1] = {mode = "local camera", scale = oriscale, yaw = oriyaw, pitch = oripitch, tick = 800, offsetx = orioffsetx, offsety = orioffsety, offsetz = orioffsetz, offsetangle = orioffsetangle}
        l_cameraHisPos = 1
    end
    -- push history camera
    l_cameraHisMode = false
    l_cameraHisPos = l_cameraHisPos + 1
    table.insert(l_cameraHistory, opt)
    CameraMgr.Status_Set(l_cameraHistory[l_cameraHisPos])
end

-- opt 可选支持 fix_camera / lock_zoom 字段，用于在回退时启用/禁用
-- 示例：CameraMgr.Status_Backward(1, { fix_camera = false, lock_zoom = false })
function CameraMgr.Status_Backward(nStep, smoothTimeOrOpt)
    if l_cameraHisPos > 1 then
        if nStep == "all" then
            l_cameraHisPos = 1
        else
            l_cameraHisPos = l_cameraHisPos - (nStep or 1)
        end
        l_cameraHisMode = true
        local backupTick = l_cameraHistory[l_cameraHisPos].tick
        local smoothTime = type(smoothTimeOrOpt) == "number" and smoothTimeOrOpt or nil
        l_cameraHistory[l_cameraHisPos].tick = smoothTime or backupTick
        CameraMgr.Status_Set(l_cameraHistory[l_cameraHisPos])
        l_cameraHistory[l_cameraHisPos].tick = backupTick
        if type(smoothTimeOrOpt) == "table" then
            local opt = smoothTimeOrOpt
            if opt.fix_camera ~= nil then
                rlcmd(("enable fix camera %d"):format((opt.fix_camera == true or opt.fix_camera == 1) and 1 or 0))
            end
            if opt.lock_zoom ~= nil then
                rlcmd(("disable camera zoom %d"):format((opt.lock_zoom == true or opt.lock_zoom == 1) and 1 or 0))
            end
        end
    end
end

function CameraMgr.Status_Forward(nStep)
    if l_cameraHisPos < #l_cameraHistory then
        if nStep == "all" then
            l_cameraHisPos = #l_cameraHistory
        else
            l_cameraHisPos = l_cameraHisPos + (nStep or 1)
        end
        l_cameraHisMode = true
        CameraMgr.Status_Set(l_cameraHistory[l_cameraHisPos])
    end
end

--CameraStatus_Set
function CameraMgr.Status_Set(opt)
    -- check arguments
    assert(type(opt) == "table" and (
    opt.mode == "god camera" or opt.mode == "remote camera" or
    opt.mode == "local camera" or opt.mode == "delay camera"
    ))
    if opt.mode == "remote camera" then
        assert(type(opt.remoteid) == "number", "[remote camera] remoteid expected numeric, got " .. tostring(opt.remoteid))
        if opt.remoteid == UI_GetClientPlayerID() then
            opt.mode = "local camera"
        end
    end
    -- fix arguments
    if opt.pitch then
        opt.pitch = math.max(-math.pi, math.min(opt.pitch, math.pi))
    end
    opt.tick = opt.tick or 0
    -- calculate temporary variables
    opt._oriscale  	, opt._oriyaw    , opt._oripitch   = Camera_GetRTParams()
    opt._orioffsetx	, opt._orioffsety, opt._orioffsetz, opt._orioffsetangle = CameraMgr.TranslationOffset()
    opt._starttick 	= GetTickCount()
    opt._x         	= opt.x           or 0
    opt._y         	= opt.y           or 0
    opt._z         	= opt.z           or 0
    opt._scale     	= opt.scale       or opt._oriscale
    opt._yaw       	= opt.yaw         or opt._oriyaw
    opt._pitch     	= opt.pitch       or opt._oripitch
    opt._offsetx   	= opt.offsetx     or opt._orioffsetx
    opt._offsety   	= opt.offsety     or opt._orioffsety
    opt._offsetz   	= opt.offsetz     or opt._orioffsetz
    opt._offsetangle= opt.offsetangle or opt._orioffsetangle
    if opt.dis_ctrl == 1 then
        opt.dis_ctrl = true
    elseif opt.dis_ctrl == 0 then
        opt.dis_ctrl = false
    end
    opt._dis_ctrl  	= opt.dis_ctrl == nil and (opt.mode == "local camera" and 0 or 1) or (opt.dis_ctrl and 1 or 0)
    opt._maxheight 	= opt.maxheight or 5000
    opt._movespeed 	= opt.movespeed or 15
    opt._Limit		= opt.Limit   	or 0
    opt._limitx 	= opt.limitx 	or 0
    opt._limity 	= opt.limity 	or 0
    opt._limitz		= opt.limitz 	or 0
    opt._lock		= opt.lock 		or 0
    opt._height 	= opt.height  	or 0
    if opt.fix_camera ~= nil then
        opt._fix_camera = (opt.fix_camera == true or opt.fix_camera == 1) and 1 or 0
    end
    if opt.lock_zoom ~= nil then
        opt._lock_zoom = (opt.lock_zoom == true or opt.lock_zoom == 1) and 1 or 0
    end

    -- calculate the shortest path to animate to the destination
    if opt.shortpath ~= false then
        opt._yaw = opt._yaw % (2 * math.pi)
        if opt._yaw - opt._oriyaw > math.pi then
            opt._yaw = opt._yaw - 2 * math.pi
        elseif opt._oriyaw - opt._yaw > math.pi then
            opt._oriyaw = opt._oriyaw - 2 * math.pi
        end
    end
    -- animate scale
    --Camera_SetRTParams(opt._scale, opt._yaw, opt._pitch, opt.tick)
    rlcmd(string.format("ob -camera params %f %f %f %f",opt._scale, opt._yaw, opt._pitch, opt.tick))
    -- set camera mode
    if opt.mode == "local camera" then
        rlcmd(string.format("set local camera mode %d",opt.tick))
        rlcmd(string.format("disable camera zoom %d",opt._lock))
        rlcmd(string.format("set camera delat height %d",opt._height))
    elseif opt.mode == "remote camera" then
        rlcmd(string.format("set remote camera mode %d %d %d %d",opt.remoteid, opt._dis_ctrl, opt.tick, opt.__serendipity and 1 or 0))
        rlcmd(string.format("set camera delat height %d",opt._height))
    elseif opt.mode == "god camera" then
        rlcmd(string.format("set god camera mode %d %f %d %d %d %f %f %d %f %f %f",opt._dis_ctrl, opt._movespeed, opt._x, opt._y, opt._z, opt.tick, opt._maxheight, opt._Limit, opt._limitx, opt._limity, opt._limitz))
    elseif opt.mode == "delay camera" then
    end

    -- apply fix camera lock
    if opt._fix_camera ~= nil then
        rlcmd(("enable fix camera %d"):format(opt._fix_camera))
    end

    -- apply zoom lock
    if opt._lock_zoom ~= nil then
        rlcmd(("disable camera zoom %d"):format(opt._lock_zoom))
    end

    -- apply camera translation offset
    if opt.offsetx or opt.offsety or opt.offsetz or opt.offsetangle then
        CameraMgr.TranslationOffset(opt._offsetx, opt._offsety, opt._offsetz, opt._offsetangle)
    end

    -- call next animation
    if not l_cameraHisMode then
        local nextopt = l_cameraHistory[l_cameraHisPos + 1]
        if nextopt then
            l_cameraHisPos = l_cameraHisPos + 1
            Timer.Add(this ,opt.tick * 0.001 , function ()
                CameraMgr.Status_Set(nextopt)
            end)
        end
    end
    -- set status mark
    l_dis_ctrl = opt._dis_ctrl == 1
    SetFreeViewEnableState(opt.mode == "god camera")
end

----------------------------------------------------------------------------------------------------
-- 镜头重置
----------------------------------------------------------------------------------------------------
function CameraMgr.CamaraReset()
    CameraMgr.Status_Set({
        mode    = "local camera",
        scale   = 1,
        yaw     = (2 * math.pi - (GetClientPlayer().nFaceDirection / 255 * math.pi * 2 + math.pi / 2)) + 180 / 180 * math.pi,
        pitch   = -0.2,
        tick    = 700,
    })

end

function CameraMgr.GetUIModeDistance()
    return kUIModeDistance
end

function CameraMgr.GetCameraParam()
    local _, yaw, pitch, x, y, z, xLookAt, yLookAt, zLookAt = Camera_GetRTParams()
    x, y, z = Scene_ScenePositionToGameWorldPosition(x, y, z)
    xLookAt, yLookAt, zLookAt = Scene_ScenePositionToGameWorldPosition(xLookAt, yLookAt, zLookAt)
    yaw = ConvertYawToDirection(yaw)
    pitch = ConvertPitchToDirection(pitch)

    return {
        yaw = yaw,
        pitch = pitch,

        from = {
            x = x,
            y = y,
            z = z
        },

        to = {
            x = xLookAt,
            y = yLookAt,
            z = zLookAt
        }
    }
end


function CameraMgr.BindKeyboard()
    if not Platform.IsMac() then return end

    local fnUpdate = function()
        local nNormalX, nNormalY = 0, 0
        if (not this.bKUADown and not this.bKDADown) or (this.bKUADown and this.bKDADown) then
            nNormalY = 0
        else
            nNormalY = this.bKUADown and -0.35 or 0.35
        end

        if (not this.bKLADown and not this.bKRADown) or (this.bKLADown and this.bKRADown) then
            nNormalX = 0
        else
            nNormalX = this.bKLADown and -0.45 or 0.45
        end

        if nNormalX ~= 0 or nNormalY ~= 0 then
            Timer.DelTimer(this, this.nKeyboardTimerID)
            this.nKeyboardTimerID = Timer.AddFrameCycle(this, 1, function()
                --LOG.INFO("CameraMgr, OnKeyboardDown nNormalX = %s, nNormalY = %s", tostring(nNormalX), tostring(nNormalY))
                GamepadData.Update_R_Thumb(nNormalX, nNormalY, true, 3)
            end)
        else
            Timer.DelTimer(this, this.nKeyboardTimerID)
            GamepadData.Update_R_Thumb(0, 0, true, 3)
        end
    end

    Event.Reg(this, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_UP_ARROW then
            this.bKUADown = true
            fnUpdate()
        elseif nKeyCode == cc.KeyCode.KEY_DOWN_ARROW then
            this.bKDADown = true
            fnUpdate()
        elseif nKeyCode == cc.KeyCode.KEY_LEFT_ARROW then
            this.bKLADown = true
            fnUpdate()
        elseif nKeyCode == cc.KeyCode.KEY_RIGHT_ARROW then
            this.bKRADown = true
            fnUpdate()
        end
    end)

    Event.Reg(this, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_UP_ARROW then
            this.bKUADown = false
            fnUpdate()
        elseif nKeyCode == cc.KeyCode.KEY_DOWN_ARROW then
            this.bKDADown = false
            fnUpdate()
        elseif nKeyCode == cc.KeyCode.KEY_LEFT_ARROW then
            this.bKLADown = false
            fnUpdate()
        elseif nKeyCode == cc.KeyCode.KEY_RIGHT_ARROW then
            this.bKRADown = false
            fnUpdate()
        end
    end)
end

function CameraMgr.SetLockCHAndGJ(bLock, nMaxCameraDistance, nCameraAngle)
    this.bLockCHAndGJ = bLock

    if bLock then
        this.fLastMaxDistanceBeforeLock = GameSettingData.GetNewValue(UISettingKey.CameraMaxDistance)
        this.fLastWideAngleBeforeLock = GameSettingData.GetNewValue(UISettingKey.WideAngle)

        local nMaxDistance = nMaxCameraDistance * 100 * 2000 / 2400
        local nWideAngle = nCameraAngle--nCameraAngle / 180 * math.pi

        local nMaxDistance_Min = 167
        local nMaxDistance_Max = 2000
        if nMaxDistance > nMaxDistance_Max then nMaxDistance = nMaxDistance_Max end
        if nMaxDistance < nMaxDistance_Min then nMaxDistance = nMaxDistance_Min end

        local nWideAngle_Min = math.ceil(VideoData.Get3DEngineOptionCaps().fMinCameraAngle * 180 / math.pi)
        local nWideAngle_Max = 60
        if nWideAngle > nWideAngle_Max then nWideAngle = nWideAngle_Max end
        if nWideAngle < nWideAngle_Min then nWideAngle = nWideAngle_Min end

        GameSettingData.ApplyNewValue(UISettingKey.CameraMaxDistance, nMaxDistance)
        GameSettingData.ApplyNewValue(UISettingKey.WideAngle, nWideAngle)

        LOG.INFO("CameraMgr.SetLockCHAndGJ, lock camera distance to %s, angle to %s, last distance: %s, last angle: %s", tostring(nMaxCameraDistance), tostring(nCameraAngle), tostring(this.fLastMaxDistanceBeforeLock), tostring(this.fLastWideAngleBeforeLock))
    else
        if this.fLastMaxDistanceBeforeLock then
            GameSettingData.ApplyNewValue(UISettingKey.CameraMaxDistance, this.fLastMaxDistanceBeforeLock)
        end

        if this.fLastWideAngleBeforeLock then
            GameSettingData.ApplyNewValue(UISettingKey.WideAngle, this.fLastWideAngleBeforeLock)
        end

        LOG.INFO("CameraMgr.SetLockCHAndGJ, unlock camera distance and angle, restored distance: %s, restored angle: %s", tostring(this.fLastMaxDistanceBeforeLock), tostring(this.fLastWideAngleBeforeLock))
    end
end

function CameraMgr.IsLockCHAndGJ()
    return this.bLockCHAndGJ
end

