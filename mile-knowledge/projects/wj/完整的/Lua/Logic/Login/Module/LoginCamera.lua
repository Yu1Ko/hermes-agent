local LoginCamera = {className = "LoginCamera"}
local self = LoginCamera


local m_szCameraAniPath = nil
if Const.USE_NEW_LOGIN_SCENE then
    m_szCameraAniPath = Table_GetPath("CAMERA_ANI_LOGIN_NEW")
else
    m_szCameraAniPath = UTF8ToGBK("data\\source\\maps\\HD登陆界面_刀宗001\\HD登陆界面_刀宗001.CameraAni")
end

local DragFactorX = Const.MiniSceneDragFactorX
if Platform.IsMobile() then
    DragFactorX = Const.MiniSceneMobileDragFactorX
end

--角色位置
local m_tbRolePos =
{
    x =	133335,-- 133173,
    y = 4120,
    z = 35921,
    yaw = -0.5,--选门派的ca_look值，注意Y值会加120
}

--原始相机数据
local m_tbOriginCamData =
{
    szType = "Login",
	tbIDs = {
		[ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
		[ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
		[ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
		[ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
	},
    fFovy   = 0.3,
    fFar    = 9000,
	fRoleYaw = 0,
	tbOffset = {0, 0, 0},
	nDefaultZoomIndex = 1,
	nDefaultZoomValue = 100,
}

local m_rotate_step = 3 --旋转步长
local m_zoom_step = 0.2 --缩放步长

local m_scene --场景
local m_camera --相机
local m_tbCurCamData = {} --当前相机数据

local m_bIsPlayingCameraAnim = false --是否正在播放相机动画
local m_nCameraStatus --相机状态LoginCameraStatus
local m_bIsCameraFixed = false --相机是否固定

local m_nLastTouchX = 0
local m_nLastTouchY = 0
local m_bCanDrag = true
local m_nTouchCount = 0

function LoginCamera.RegisterEvent()

end

function LoginCamera.OnEnter(szPrevStep)

end

function LoginCamera.OnExit(szNextStep)

end

function LoginCamera.OnClear()
    self._setTouchEventReg(false)
end

-------------------------------- Public --------------------------------

function LoginCamera.InitSceneCamera(scene)
    if not scene then
        return
    end

    m_bIsPlayingCameraAnim = false
    m_scene = scene
    m_camera = MiniSceneCamera.CreateInstance(MiniSceneCamera)
    --旧版class自动调用ctor，新版需class手动调一次
    m_camera:ctor()

    m_tbCurCamData = clone(m_tbOriginCamData)

    local c = m_tbCurCamData
    m_camera:init(m_scene, 0, 0, 0, 0, 0, 0, m_tbCurCamData.fFovy, nil, nil, m_tbCurCamData.fFar)
    m_camera:InitCameraConfig("Login", 1, 1, 100)
end

function LoginCamera.SetCameraStatus(nCameraType, nRoleType)
    m_nCameraStatus = nCameraType

    if nCameraType == LoginCameraStatus.ROLE_LIST then
        self.UpdateCamera(g_tRoleListCamera, nRoleType) --相机参数
        self._setTouchEventReg(true) --注册拖动事件
    elseif nCameraType == LoginCameraStatus.BUILD_FACE_STEP1 then
        self.UpdateCamera(g_tBuildFaceCameraStep1, nRoleType)
        self._setTouchEventReg(true)
    elseif nCameraType == LoginCameraStatus.BUILD_FACE_STEP2_FACE then
        self.UpdateCamera(g_tBuildFaceCameraStep2Face, nRoleType)
        self._setTouchEventReg(true)
    elseif nCameraType == LoginCameraStatus.BUILD_FACE_STEP2_HAIR then
        self.UpdateCamera(g_tBuildFaceCameraStep2Hair, nRoleType)
        self._setTouchEventReg(true)
    elseif nCameraType == LoginCameraStatus.BUILD_FACE_STEP2_BODY then
        self.UpdateCamera(g_tBuildFaceCameraStep2Body, nRoleType)
        self._setTouchEventReg(true)
    elseif nCameraType == LoginCameraStatus.BUILD_FACE_STEP2_SHARE then
        self.UpdateCamera(g_tBuildFaceCameraStepShare, nRoleType)
        self._setTouchEventReg(true)
    elseif nCameraType == LoginCameraStatus.BUILD_FACE_STEP2_BUILDALL then
        self.UpdateCamera(g_tBuildFaceCameraStepBuildAll, nRoleType)
        self._setTouchEventReg(true)
    elseif nCameraType == LoginCameraStatus.BUILD_FACE_STEP_INPUTNAME then
        self.UpdateCamera(g_tBuildFaceCameraStepInputName, nRoleType)
        self._setTouchEventReg(true)
    elseif nCameraType == LoginCameraStatus.ROLE_CHOOSE_SHOW then
        self.UpdateCamera(g_tRoleChooseShowCamera, nRoleType)
        self._setTouchEventReg(true)
    end

    if m_camera then
        m_camera:RefreshRender()
    end
end

function LoginCamera.Zoom(radius, frame_num)
    if not m_camera then return end
    m_camera:set_radius(radius, frame_num)
end

function LoginCamera.ZoomMax(frame_num)
    if not m_camera then return end
    m_camera:set_radius(m_tbCurCamData.MAX_RADIUS, frame_num)
end

function LoginCamera.ZoomMin(frame_num)
    if not m_camera then return end
    m_camera:set_radius(m_tbCurCamData.MIN_RADIUS, frame_num)
end

function LoginCamera.GetCurCamData()
    return m_tbCurCamData
end

function LoginCamera.SetCameraFixed(bIsFixed)
    if not m_camera then return end

    m_bIsCameraFixed = bIsFixed
    if bIsFixed then
        --self._playCameraAnim() --现在的场景先不转，避免显示到后面的东西

        local c = m_tbCurCamData
        m_camera:setpos(c.fix_x, c.fix_y, c.fix_z)
        m_camera:setlook(c.fix_look_x, c.fix_look_y, c.fix_look_z)
    else
        self._stopCameraAnim()

        local c = m_tbCurCamData
        m_camera:init(m_scene,
                      c.pos_x,  c.pos_y,  c.pos_z,
                      c.look_x, c.look_y, c.look_z,
                      c.fovy,   c.aspect, c.z_near,
                      c.z_far,  c.perspective)
        m_camera:InitCameraConfig("Login", 1, 1, 100)
    end
end

function LoginCamera.UpdateCamera(tbCamData, nRoleType)
    if not m_camera then return end

    self.UpdateCameraData(tbCamData)
    local c = m_tbCurCamData

    m_camera:InitCameraConfig(tbCamData.szType, tbCamData.tbIDs[nRoleType], tbCamData.nDefaultZoomIndex, tbCamData.nDefaultZoomValue)
    m_camera:SetOffsetAngle(tbCamData.tbOffset[1], tbCamData.tbOffset[2], tbCamData.tbOffset[3], g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)
end

function LoginCamera.UpdateCameraData(tbCamData)
    for k, v in pairs(tbCamData) do
        m_tbCurCamData[k] = v
    end
end

local tbDefaultHeight =
{
    [ROLE_TYPE.STANDARD_MALE]   = 180, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = 160, --rtStandardFemale,   //标准女
    [ROLE_TYPE.LITTLE_BOY]      = 130, --rtLittleBoy,        //  小男孩
    [ROLE_TYPE.LITTLE_GIRL]     = 120  --rtLittleGirl,       // 小孩女
}
function LoginCamera.SetModelScale(fScale, nRoleType)
    if not m_camera then return end

    local nDefaultHeight = tbDefaultHeight[nRoleType or 1]
    m_camera:SetModelScale(fScale, nDefaultHeight)
    m_camera:UpdatePosition()
end

-------------------------------- Protocol --------------------------------


----------------------------------- Private --------------------------------

function LoginCamera._setTouchEventReg(bIsReg)
    if bIsReg == nil then bIsReg = true end

    self._clearDragParams()
    if bIsReg then
        Event.Reg(self, EventType.OnSceneTouchBegan, self._onDragBegan)
        Event.Reg(self, EventType.OnSceneTouchMoved, self._onDragMoved)
        Event.Reg(self, EventType.OnSceneTouchEnded, self._onDragEnded)
        Event.Reg(self, EventType.OnSceneTouchCancelled, self._onDragEnded)
        Event.Reg(self, EventType.OnSceneTouchsBegan, self._onMultiTouchsBegan)
        Event.Reg(self, EventType.OnSceneTouchsMoved, self._onMultiTouchsMoved)
        Event.Reg(self, EventType.OnSceneTouchsEnded, self._onMultiTouchsEnded)
        Event.Reg(self, EventType.OnSceneTouchsCancelled, self._onMultiTouchsEnded)
        Event.Reg(self, EventType.OnWindowsMouseWheel, function(nDelta, bHandled)
            if bHandled then return end
            self._cameraZoom(nDelta)
        end)
    else
        Event.UnReg(self, EventType.OnSceneTouchBegan)
        Event.UnReg(self, EventType.OnSceneTouchMoved)
        Event.UnReg(self, EventType.OnSceneTouchEnded)
        Event.UnReg(self, EventType.OnSceneTouchCancelled)
        Event.UnReg(self, EventType.OnSceneTouchsBegan)
        Event.UnReg(self, EventType.OnSceneTouchsMoved)
        Event.UnReg(self, EventType.OnSceneTouchsEnded)
        Event.UnReg(self, EventType.OnSceneTouchsCancelled)
        Event.UnReg(self, EventType.OnWindowsMouseWheel)
    end
end

function LoginCamera._clearDragParams()
    m_nLastTouchX = 0
    m_nLastTouchY = 0
end


--镜头旋转
function LoginCamera._onDragBegan(nX, nY)
    m_nLastTouchX = nX
    m_nLastTouchY = nY
end

function LoginCamera._onDragMoved(nX, nY)
    if SceneMgr.GetTouchingCount() > 1 then
        return
    end

    if nX ~= m_nLastTouchX or nY ~= m_nLastTouchY then
        local size = UIHelper.GetScreenSize()
        local cx, cy = size.width, size.height
        local dx = -(nX - m_nLastTouchX) / cx * math.pi
        local dy = -(nY - m_nLastTouchY) / cy * math.pi
        local nRealDeltaY = math.abs(nY - m_nLastTouchY)

        dx = math.max(dx, -0.35)
        dx = math.min(dx, 0.35)
        dy = math.max(dy, -0.2)
        dy = math.min(dy, 0.2)

        local model
        local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
        if UIMgr.GetView(VIEW_ID.PanelSchoolSelect) then
            model = moduleScene and moduleScene.GetModel(LoginModel.FORCE_ROLE)
        elseif UIMgr.GetView(VIEW_ID.PanelRoleChoices) then
            model = moduleScene and moduleScene.GetModel(LoginModel.ROLE)
        elseif UIMgr.GetView(VIEW_ID.PanelModelVideo) then
            model = moduleScene and moduleScene.GetModel(LoginModel.FORCE_ROLE)
        end

        if model then
            local nYaw = model:GetYaw()
            model:SetYaw(nYaw + dx * 2 * DragFactorX)

            -- 特殊处理转动角色模式时oit表现不正常的问题
            local scene = moduleScene.GetScene()
            if scene then
                scene:OnRotatePlayer(dx * 2 * DragFactorX)
            end
        end
    end

    m_nLastTouchX = nX
    m_nLastTouchY = nY
end

function LoginCamera._onDragEnded(nX, nY)
    if SceneMgr.GetTouchingCount() == 1 then
        local pos = SceneMgr.GetTouchPos()
        if pos then
            self._onDragBegan(pos.nX, pos.nY)
        end
        return
    end
end

--镜头缩放
function LoginCamera._cameraZoom(nDelta)
    if m_camera then
        if Platform.IsWindows() or Platform.IsMac() or KeyBoard.MobileSupportKeyboard() then
            m_camera:Zoom(-nDelta * m_zoom_step * Const.MiniSceneZoomFactor)
        end
    end
end

function LoginCamera._onMultiTouchsBegan(nX1, nY1, nX2, nY2)
    m_bCanDrag = false

    if m_camera then
        m_camera:OnTouchsBegan(nX1, nY1, nX2, nY2)
    end
end

function LoginCamera._onMultiTouchsMoved(nX1, nY1, nX2, nY2)
    m_bCanDrag = false

    if m_camera then
        m_camera:OnTouchsMoved(nX1, nY1, nX2, nY2)
    end
end

function LoginCamera._onMultiTouchsEnded(nX1, nY1, nX2, nY2)
    m_bCanDrag = true

    if m_camera then
        m_camera:OnTouchsEnded(nX1, nY1, nX2, nY2)
    end
end

--播放相机动画
function LoginCamera._playCameraAnim()
    if not m_bIsPlayingCameraAnim then
        if m_szCameraAniPath then
            m_scene:PlayCameraAni(m_szCameraAniPath, true)
        end
        m_bIsPlayingCameraAnim = true
    end
end

    --停止相机动画
function LoginCamera._stopCameraAnim()
    if m_bIsPlayingCameraAnim then
        m_scene:StopCameraAni()
        m_bIsPlayingCameraAnim = false
    end
end

function LoginCamera.GetCamera()
    return m_camera
end

return LoginCamera