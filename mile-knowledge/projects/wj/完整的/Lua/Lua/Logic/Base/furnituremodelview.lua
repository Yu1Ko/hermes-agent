FurnitureModelView = class("FurnitureModelView")

local FRAME_NUM = 25

local _tSetting
local szSettingFile = "/ui/Scheme/Setting/CoinShopFurnitureSetting.ini"

local function InitCamera(nWidth, nHeight, tFrame, tCamera, tCenterPos)
    if not tCenterPos and tCamera[9] then
        tCenterPos = {tCamera[8], tCamera[9], tCamera[10]}
    end
    tFrame.camera:init(tFrame.hFurnitureModelView.m_scene, tCamera[1], tCamera[2], tCamera[3] , tCamera[4], tCamera[5], tCamera[6], math.pi / 4, nWidth / nHeight, nil, nil, true, tCenterPos)
end

local function InitCameraWithType(nWidth, nHeight, tFrame, szType, nIndex, nZoomIndex, nZoomValue)
    tFrame.camera:init(tFrame.hFurnitureModelView.m_scene, 0, 0, 0, 0, 0, 0, 0.3, nWidth / nHeight, nil, 40000, true)
    tFrame.camera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
end

function FurnitureModelView:ctor()
	self.bMgrScene = true
end

function FurnitureModelView:release()
	self:UnloadModel()

    if self.bMgrScene then
        SceneHelper.DeleteScene_Old(self.m_scene)
    end
	self.m_scene=nil
end;

function FurnitureModelView:init(scene, bNotMgrScene, szSceneFilePath, szName)
	self.bMgrScene = not bNotMgrScene

	if not scene then
        scene = SceneHelper.NewScene_Old(szSceneFilePath, szName)
		self.bMgrScene = true
	end
	self.m_scene = scene

    if self.bMgrScene then
        self:SetCamera({0, 150, -200, 0, 50, 150})
    end
end

function FurnitureModelView:SetCamera(aParams)
	local xp = aParams[1]
	local yp = aParams[2]
	local zp = aParams[3]
	local xl = aParams[4]
	local yl = aParams[5]
	local zl = aParams[6]
	local p1 = aParams[7]
	local p2 = aParams[8]
	local p3 = aParams[9]
	local p4 = aParams[10]
	local bPerspective = aParams[11]

    self:SetCameraLookPos(xl, yl, zl)
	self:SetCameraPos(xp, yp, zp)

	if bPerspective ~= nil then
		self:SetCameraPerspective(p1, p2, p3, p4)
	else
        self:SetCameraOrthogonal(p1, p2, p3, p4)
	end
end

function FurnitureModelView:SetCameraPosition(tCameraPosion)
	local xp = tCameraPosion[1]
	local yp = tCameraPosion[2]
	local zp = tCameraPosion[3]
	local xl = tCameraPosion[4]
	local yl = tCameraPosion[5]
	local zl = tCameraPosion[6]

	self:SetCameraLookPos(xl, yl, zl)
	self:SetCameraPos(xp, yp, zp)
end

function FurnitureModelView:GetCameraPos()
    return self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ
end

function FurnitureModelView:SetCameraPos(x, y, z)
    self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ = x, y, z
	self.m_scene:SetCameraPosition(x, y, z)
end

function FurnitureModelView:GetCameraLookPos()
    return self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ
end

function FurnitureModelView:SetCameraLookPos(x, y, z)
    self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ = x, y, z
	self.m_scene:SetCameraLookAtPosition(x, y, z)
end

function FurnitureModelView:GetCameraPerspective()
    return self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar
end

function FurnitureModelView:SetCameraPerspective(fovY, aspect, near, far)
    self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar = fovY, aspect, near, far
	self.m_scene:SetCameraPerspective(fovY, aspect, near, far)
end

function FurnitureModelView:GetCameraOrthogonal()
    return self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar
end

function FurnitureModelView:SetCameraOrthogonal(w, h, near, far)
    self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar = w, h, near, far
	self.m_scene:SetCameraOrthogonal(w, h, near, far)
end

function FurnitureModelView:LoadModel(dwRepresentID, dwType, nDetails, fScale, fScaleScale)
    self.dwRepresentID = dwRepresentID
    local _, dwID = Homeland_SendMessage(HOMELAND_FURNITURE.CREATE, dwRepresentID, dwType)
    self.dwModelID = dwID
    self.fDefaultScale = fScale
    self.fScaleScale = fScaleScale
    if nDetails then
        self:SetModelDetails(nDetails)
    end
end

function FurnitureModelView:SetScale(x, y, z)
    if not self.dwRepresentID then
        return
    end
    local fScale = self.fDefaultScale
    local fScaleScale = self.fScaleScale
    if not fScale or fScale == 0 then --没有默认的缩放
        if x * y * z == 0 then
            UILog("Error FurnitureModel, dwRepresentID = ", self.dwRepresentID, " x y z = ",  x, y, z, ",fScale=", fScale)
            return
        end
        fScale = math.min(_tSetting.CriterionX / x, _tSetting.CriterionY / y, _tSetting.CriterionZ / z, _tSetting.MaxScale)
        fScale = math.max(fScale, _tSetting.MinScale)
        if fScaleScale then
            fScale = fScale * fScaleScale
        end
    end
    Homeland_SendMessage(HOMELAND_FURNITURE.SET_SCALE, self.dwModelID, fScale)
end

function FurnitureModelView:SetTranslation(fX, fY, fZ)
	Homeland_SendMessage(HOMELAND_FURNITURE.SET_POSITION, self.dwModelID, fX, fY, fZ)
    self.nTransX, self.nTransY, self.nTransZ = fX, fY, fZ
end

function FurnitureModelView:GetTranslation()
	return self.nTransX or 0, self.nTransY or 0, self.nTransZ or 0
end

function FurnitureModelView:SetRotation(fNpcYaw)
    if fNpcYaw then
	    Homeland_SendMessage(HOMELAND_FURNITURE.SET_ROTATION, self.dwModelID, fNpcYaw)
    end
end

function FurnitureModelView:SetModelDetails(nDetails) --偏色
    if nDetails then
        Homeland_SendMessage(HOMELAND_FURNITURE.SET_DETAILS, self.dwModelID, nDetails)
        self.nDetails = nDetails
    end
end

function FurnitureModelView:GetDetails()
    return self.nDetails
end

function FurnitureModelView:UnloadModel()
    if self.dwModelID then
        Homeland_SendMessage(HOMELAND_FURNITURE.DESTROY, self.dwModelID)
        self.dwModelID = nil
    end
end

function FurnitureModelView:SetYaw(yaw)
    if yaw then
        self._yaw = yaw
	    Homeland_SendMessage(HOMELAND_FURNITURE.SET_ROTATION, self.dwModelID, yaw)
    end
end

function FurnitureModelView:GetYaw()
    return (self._yaw or 0)
end

local CHARACTER_ROLE_TURN_YAW = math.pi / 54
function FurnitureModelView:TouchModel(bTouch, x, y)
    if bTouch then
        self.fTouchModelX = x
        self.fTouchModelY = y
        if not self.nTouchModelTimerID then
            self.nTouchModelTimerID = Timer.AddFrameCycle(self, 1, function ()
                self.fTouchModelBaseX = self.fTouchModelBaseX or self.fTouchModelX
                local yaw = self:GetYaw()
                if self.fTouchModelBaseX > self.fTouchModelX then
                    yaw = yaw + CHARACTER_ROLE_TURN_YAW
                else
                    yaw = yaw - CHARACTER_ROLE_TURN_YAW
                end

                self:SetYaw(yaw)
            end)
        end
    else
        if self.nTouchModelTimerID then
            Timer.DelTimer(self, self.nTouchModelTimerID)
            self.nTouchModelTimerID = nil
            self.fTouchModelBaseX = nil
        end
    end
end

FurnitureModelPreview = {className = "FurnitureModelPreview"}
FurnitureModelPreview.tResisterFrame = {}
FurnitureModelPreview.tEventFrame = {}

function FurnitureModelPreview.CreateOnLButtonDown(szFrame)
    FurnitureModelPreview.tEventFrame[szFrame].fnOldOnLButtonDown = _G[szFrame].OnLButtonDown
    _G[szFrame].OnLButtonDown = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = FurnitureModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
                if szName == tFrame.szTurnLeft then
                    hScene.bTurnLeft = true
                    break
                elseif szName == tFrame.szTurnRight then
                    hScene.bTurnRight = true
                    break
                elseif szName == tFrame.szSceneName then
                    hScene.bLDown = true
                    local x, y = Station.GetMessagePos(false)
                    Cursor.Show(false)
                    hScene.nCX = x
                    hScene.nCY = y
                    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
                    Station.SetCapture(hScene)
                    break
                end
            end

            local tEvent = FurnitureModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnLButtonDown then
                return tEvent.fnOldOnLButtonDown()
            end
        end
    end
    FurnitureModelPreview.tEventFrame[szFrame].fnNewOnLButtonDown = _G[szFrame].OnLButtonDown
end

function FurnitureModelPreview.CreateOnLButtonUp(szFrame)
     FurnitureModelPreview.tEventFrame[szFrame].fnOldOnLButtonUp = _G[szFrame].OnLButtonUp
     _G[szFrame].OnLButtonUp = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = FurnitureModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
                if szName == tFrame.szTurnLeft then
                    hScene.bTurnLeft = false
                    break
                elseif szName == tFrame.szTurnRight then
                    hScene.bTurnRight = false
                    break
                elseif szName == tFrame.szSceneName then
                    hScene.bLDown = false
                    Cursor.SetPos(hScene.nCX, hScene.nCY, false)
                    Cursor.Show(true)
                    Station.SetCapture(nil)
                    break
                end
            end

            local tEvent = FurnitureModelPreview.tEventFrame[szFrameName]
            if tEvent.fnOldOnLButtonUp then
                return tEvent.fnOldOnLButtonUp()
            end
        end
    end
    FurnitureModelPreview.tEventFrame[szFrame].fnNewOnLButtonUp = _G[szFrame].OnLButtonUp
end

function FurnitureModelPreview.CreateOnRButtonDown(szFrame)
    FurnitureModelPreview.tEventFrame[szFrame].fnOldOnRButtonDown = _G[szFrame].OnRButtonDown
    _G[szFrame].OnRButtonDown = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = FurnitureModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
                if szName == tFrame.szSceneName then
                    hScene.bLDown = true
                    local x, y = Station.GetMessagePos(false)
                    Cursor.Show(false)
                    hScene.nCX = x
                    hScene.nCY = y
                    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
                    Station.SetCapture(hScene)
                    break
                end
            end

            local tEvent = FurnitureModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnRButtonDown then
                return tEvent.fnOldOnRButtonDown()
            end
        end
    end
    FurnitureModelPreview.tEventFrame[szFrame].fnNewOnRButtonDown = _G[szFrame].OnRButtonDown
end

function FurnitureModelPreview.CreateOnRButtonUp(szFrame)
     FurnitureModelPreview.tEventFrame[szFrame].fnOldOnRButtonUp = _G[szFrame].OnRButtonUp
     _G[szFrame].OnRButtonUp = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = FurnitureModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
                if szName == tFrame.szSceneName then
                    hScene.bLDown = false
                    Cursor.SetPos(hScene.nCX, hScene.nCY, false)
                    Cursor.Show(true)
                    Station.SetCapture(nil)
                    break
                end
            end

            local tEvent = FurnitureModelPreview.tEventFrame[szFrameName]
            if tEvent.fnOldOnRButtonUp then
                return tEvent.fnOldOnRButtonUp()
            end
        end
    end

    FurnitureModelPreview.tEventFrame[szFrame].fnNewOnRButtonUp = _G[szFrame].OnRButtonUp
end

function FurnitureModelPreview.CreateOnFrameDestroy(szFrame)
     FurnitureModelPreview.tEventFrame[szFrame].fnOldOnFrameDestroy = _G[szFrame].OnFrameDestroy
     _G[szFrame].OnFrameDestroy = function()
        local szFrameName = this:GetName()
        local tFrameList = FurnitureModelPreview.tResisterFrame[szFrameName]
        if tFrameList then
            for szName, tFrame in pairs(tFrameList) do
                local hFurnitureModelView = tFrame.hFurnitureModelView
                if hFurnitureModelView then
                    hFurnitureModelView:UnloadModel()
                    hFurnitureModelView:release()
                    UnRegisterFurnitureModel(szFrameName, szName)
                    tFrame.hFurnitureModelView = nil
                end
            end

            local tEvent = FurnitureModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnFrameDestroy then
                local nResult = tEvent.fnOldOnFrameDestroy()
                FurnitureModelPreview.tResisterFrame[szFrameName] = {}
                return nResult
            end
            FurnitureModelPreview.tResisterFrame[szFrameName] = {}
        end
    end
    FurnitureModelPreview.tEventFrame[szFrame].fnNewOnFrameDestroy = _G[szFrame].OnFrameDestroy
end

function FurnitureModelPreview.CreateOnMouseWheel(szFrame)
     FurnitureModelPreview.tEventFrame[szFrame].fnOldOnMouseWheel = _G[szFrame].OnMouseWheel
     _G[szFrame].OnMouseWheel = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = FurnitureModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                if tFrame.szSceneName and  szName == tFrame.szSceneName then
                    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
                    local nDelta = Station.GetMessageWheelDelta()
                    if hScene.camera then
                        local tRadius = tFrame.tRadius
                        local hPlayer = GetPlayer(tFrame.dwPlayerID)
                        local fMinRadius
                        local fMaxRadius
                        if tRadius then
                            fMinRadius = tRadius[1]
                            fMaxRadius = tRadius[2]
                        end
                        hScene.camera:zoom(nDelta * 10, fMinRadius, fMaxRadius)
                        FireUIEvent("ON_FURNITURE_CAMERA_UPDATE", szFrameName, tFrame.szName)
                    end
                end
            end

            local tEvent = FurnitureModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnMouseWheel then
                local nResult = tEvent.fnOldOnMouseWheel()
                return nResult
            end
        end
    end

    FurnitureModelPreview.tEventFrame[szFrame].fnNewOnMouseWheel = _G[szFrame].OnMouseWheel
end

local STEP = 1
local function CameraRotate(hScene, szFrameName, szNpcName, tFrame, dwModelID)
    if hScene.bLDown then
        local x, y = Cursor.GetPos(false)
        local nCX, nCY = hScene.nCX, hScene.nCY
        if x ~= nCX or y ~= nCY then
            local cx, cy = Station.GetClientSize(false)
            local dx = -(x - nCX) / cx * math.pi
            local dy = (y - nCY) / cy * math.pi
            if tFrame.bDisableCamera then
                hScene.fNpcYaw = (hScene.fNpcYaw + dx) % (2 * math.pi)
                hScene.hFurnitureModelView:SetRotation(hScene.fNpcYaw)
            else
                local fMinVerAngle = -math.pi / 2
                local fMaxVerAngle = 0.3
                local fMinHorAngle, fMaxHorAngle
                if tFrame.tVerAngle then
                    fMinVerAngle = tFrame.tVerAngle[1]
                    fMaxVerAngle = tFrame.tVerAngle[2]
                end
                if tFrame.tHorAngle then
                    fMinHorAngle = tFrame.tHorAngle[1]
                    fMaxHorAngle = tFrame.tHorAngle[2]
                end
                hScene.camera:rotate(dy * STEP, dx * STEP, fMinVerAngle , fMaxVerAngle, fMinHorAngle, fMaxHorAngle)
                FireUIEvent("ON_FURNITURE_CAMERA_UPDATE", szFrameName, szNpcName)
            end
            Cursor.SetPos(nCX, nCY, false)
        end
    end
end
local CHARACTER_ROLE_TURN_YAW = math.pi / 54

local function RoleYawTurn(tFrame)
    if not tFrame.hFurnitureModelView then
        return
    end
    if tFrame.bTurnRight then
        tFrame.fNpcYaw = (tFrame.fNpcYaw - CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.hFurnitureModelView:SetRotation(tFrame.fNpcYaw)
    elseif tFrame.bTurnLeft then
        tFrame.fNpcYaw = (tFrame.fNpcYaw + CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.hFurnitureModelView:SetRotation(tFrame.fNpcYaw)
    end
end

local _calllookID
local xx,xy,xz
function FurnitureModelPreview.CreateOnEvent(szFrame)
    -- if not FurnitureModelPreview.tEventFrame[szFrame].nTimerID then
    --     FurnitureModelPreview.tEventFrame[szFrame].nTimerID = Timer.AddFrameCycle(FurnitureModelPreview, 1, function ()
    --         -- local tFrameList = FurnitureModelPreview.tResisterFrame[szFrame]
    --         -- if not tFrameList then return end
    --         -- for szName, tFrame in pairs(tFrameList) do
    --         --     CameraRotate(tFrame)
    --         --     RoleYawTurn(tFrame)
    --         -- end
    --     end)
    -- end
    Event.Reg(FurnitureModelPreview.tEventFrame[szFrame], "HOMELAND_CALL_RESULT", function ()
        if arg0 == HOMELAND_FURNITURE.MODEL_INFO then
            local tFrameList = FurnitureModelPreview.tResisterFrame[szFrame]
            if not tFrameList then return end
            for szNpcName, tFrame in pairs(tFrameList) do
                local x, y, z = arg1, arg2, arg3
                tFrame.hFurnitureModelView:SetScale(x, y, z)
            end
        end
    end)
end

function FurnitureModelPreview.RegisterFurniture(UIViewer3D, hModelView, szFrameName, szName)
    local tFurnitureParam =
    {
        dwPlayerID = g_pClientPlayer.dwID,
        szName = szName,
        szFrameName = szFrameName,
        Viewer = UIViewer3D,
        hFurnitureModelView = hModelView,
    }
    local szFrame = tFurnitureParam.szFrameName
    local szName = tFurnitureParam.szName
    tFurnitureParam.fNpcYaw = 0.7
    FurnitureModelPreview.tResisterFrame[szFrame] = FurnitureModelPreview.tResisterFrame[szFrame] or {}
    FurnitureModelPreview.tResisterFrame[szFrame][szName] = tFurnitureParam
end

function FurnitureModelPreview.Init(szFrame, szName)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- assert(hFrame)

    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    local hFurnitureModelView = FurnitureModelView.CreateInstance(FurnitureModelView)
    hFurnitureModelView:ctor()
    -- hScene.hFurnitureModelView = hFurnitureModelView
    tFrame.hFurnitureModelView = hFurnitureModelView
	hFurnitureModelView:init(tFrame.scene, tFrame.bNotMgrScene, tFrame.szSceneFilePath, szFrame .. "_" .. szName)
    tFrame.Viewer:SetScene(hFurnitureModelView.m_scene)
    -- hScene:SetScene(hFurnitureModelView.m_scene)
    if tFrame.tRadius then
        tFrame.tWheelRadius = tFrame.tRadius
    end

    -- local fWidth, fHeight = hScene:GetSize()
    -- hScene.camera = camera_plus:new()
    -- hScene.fNpcYaw = 0
    local nWidth, nHeight = UIHelper.GetContentSize(tFrame.Viewer)
    tFrame.camera = MiniSceneCamera.CreateInstance(MiniSceneCamera)
    tFrame.camera:ctor()
    tFrame.fNpcYaw = 0
    if tFrame.szCameraType then
        InitCameraWithType(nWidth, nHeight, tFrame, tFrame.szCameraType, tFrame.nCameraIndex, tFrame.nDefaultZoomIndex, tFrame.nDefaultZoomValue)
        if tFrame.tbCameraOffset then
            tFrame.camera:SetOffsetAngle(tFrame.tbCameraOffset[1], tFrame.tbCameraOffset[2], tFrame.tbCameraOffset[3],
                                            tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
        end
    elseif tFrame.tCamera then
        local c = tFrame.tCamera
         if c[7] then
            tFrame.fNpcYaw = c[7]
        end
        InitCamera(nWidth, nHeight, tFrame, c)
    else
        InitCamera(nWidth, nHeight, tFrame, {0, 80, -360, 0, 100, 150})
    end
end

function Npc_GetRoleType(szFaceIni)
    if not szFaceIni or szFaceIni == "" then
        return nil
    end
    local szString = string.lower(szFaceIni)
    if StringFindW(szString, "m2") then
        return 1
    elseif StringFindW(szString, "f2") then
        return 2
    elseif StringFindW(szString, "m1") then
        return 5
    elseif StringFindW(szString, "f1") then
        return 6
    end
end

function FurnitureModelPreview.ShowFurniture(szFrame, szName, dwRepresentID, tCamera, tPos, nPutType, nDetails, nYaw, fScale, fScaleScale)
    local tFrameList = FurnitureModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    local hFurnitureModelView = tFrame.hFurnitureModelView
    if
        hFurnitureModelView.dwRepresentID and
        hFurnitureModelView.dwRepresentID == dwRepresentID
    then
        return
    end

    hFurnitureModelView.dwRepresentID = dwRepresentID
    tFrame.fNpcYaw = 0
    if tCamera then
        local c = tCamera
        if c[7] then
            tFrame.fNpcYaw = c[7]
        end
    end
    if nYaw then
        tFrame.fNpcYaw = nYaw
    end
    hFurnitureModelView:UnloadModel()
    if dwRepresentID > 0 then
        hFurnitureModelView:LoadModel(dwRepresentID, nPutType, nDetails, fScale, fScaleScale)
        hFurnitureModelView:SetTranslation(tPos[1], tPos[2], tPos[3])
        hFurnitureModelView:SetRotation(tFrame.fNpcYaw)
    end


    FireUIEvent("ON_FURNITURE_CAMERA_UPDATE", szFrame, szName)
end

function FurnitureModelPreview.SetFurnitureDetails(szFrame, szName, nDetails)
    local tFrameList = FurnitureModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    -- local hFurnitureModelView = hScene.hFurnitureModelView
    local hFurnitureModelView = tFrame.hFurnitureModelView
    hFurnitureModelView:SetModelDetails(nDetails)
end

function FurnitureModelPreview.SetFurniturePosition(szFrame, szName, tPos)
    local tFrameList = FurnitureModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    -- local hFurnitureModelView = hScene.hFurnitureModelView
    local hFurnitureModelView = tFrame.hFurnitureModelView
    hFurnitureModelView:SetTranslation(tPos[1], tPos[2], tPos[3])
end

function FurnitureModelPreview_GetCameraRadius(szFrame, szName)
    if not FurnitureModelPreview.tResisterFrame[szFrame] then
        return
    end
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    return hScene.camera:get_radius()
end

function FurnitureModelPreview_SetCameraRadius(szFrame, szName, szRadius, nFrameNum)
    nFrameNum = nFrameNum or FRAME_NUM
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local tRadius = tFrame.tRadius
    if szRadius == "Min" then
        tFrame.camera:set_radius(tRadius[1], nFrameNum)
    elseif szRadius == "Max" then
        tFrame.camera:set_radius(tRadius[2], nFrameNum)
    end
end

function FurnitureModelPreview_SetCameraZoom(szFrame, szName, szRadius)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local tbZoomConfigs = tFrame.camera:GetConfig()
    if szRadius == "Min" then
        tFrame.camera:UpdateZoom(1, 0, 0, 0.2)
    elseif szRadius == "Max" then
        tFrame.camera:UpdateZoom(#tbZoomConfigs - 1, 100, 0, 0.2)
    end
end

function FurnitureModelPreview_GetRoleYaw(szFrame, szName)
    if not FurnitureModelPreview.tResisterFrame[szFrame] then
        return
    end
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    return hScene.fNpcYaw
end

function FurnitureModelPreview_GetCameraPosition(szFrame, szName)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    local camera = hScene.camera
    local pos = hScene.camera:getpos(true)
    local look = hScene.camera:getlook(true)
    local center_pos = hScene.camera:get_center_pos(true)

    local tCamera = {pos.x, pos.y, pos.z, look.x, look.y, look.z, center_pos.x, center_pos.y, center_pos.z}
    return tCamera
end

function FurnitureModelPreview_GetPosition(szFrame, szName)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    return tFrame.tPos
end

function FurnitureModelPreview_SetCameraCenterR(szFrame, szName, nCenterR, nFrameNum)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    hScene.camera:set_center_r(nCenterR, nFrameNum)
end

function FurnitureModelPreview_GetCameraCenterR(szFrame, szName)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    return hScene.camera:get_center_r()
end

function FurnitureModelPreview_SetCameraOffset(szFrame, szName, fAngleX, fAngleY, fAngleZ, fModelX, fModelY, fModelZ, bNotUpdate)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:SetOffsetAngle(fAngleX, fAngleY, fAngleZ, fModelX, fModelY, fModelZ, bNotUpdate)
end

function FurnitureModelPreview_GetCameraOffset(szFrame, szName)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:GetOffsetAngle()
end

function FurnitureModelPreview_SetCameraPosition(szFrame, szName, tCamera)
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = hFrame:Lookup(tFrame.szScene)
    local c = tCamera
    local fWidth, fHeight = hScene:GetSize()
    local hFurnitureModelView = hScene.hFurnitureModelView
    InitCamera(hScene, c, {c[7], c[8],c[9]})
    if hFurnitureModelView.m_RidesMDL then
        hFurnitureModelView:SetYaw(hScene.fRidesYaw)
    end
end

function FurnitureModelPreview_GetRegisterFrame(szFrame, szName)
    local tFrameList = FurnitureModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    return tFrame
end

local function RestoreMsgFunction(szFrame, szFunctionName)
    if _G[szFrame] and FurnitureModelPreview.tEventFrame[szFrame] and
       _G[szFrame][szFunctionName] == FurnitureModelPreview.tEventFrame[szFrame]["fnNew" .. szFunctionName] then

       _G[szFrame][szFunctionName] = FurnitureModelPreview.tEventFrame[szFrame]["fnOld" .. szFunctionName]
    end
end

function RegisterFurnitureModelView(tParam)
    local szFrame = tParam.szFrameName
    local szName = tParam.szName
    FurnitureModelPreview.tResisterFrame[szFrame] = FurnitureModelPreview.tResisterFrame[szFrame] or {}
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if tFrame then
        local hFurnitureModelView = tFrame.hFurnitureModelView
        if hFurnitureModelView then
            hFurnitureModelView:UnloadModel()
            hFurnitureModelView:release()
            tFrame.hFurnitureModelView = nil
        end

        FurnitureModelPreview.tResisterFrame[szFrame][szName] = nil
    end

    FurnitureModelPreview.tResisterFrame[szFrame][szName] = tParam
    FurnitureModelPreview.Init(szFrame, szName)

    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if tFrame and _tSetting then
        Homeland_SendMessage(HOMELAND_FURNITURE.ENTER, tFrame.hFurnitureModelView.m_scene, _tSetting.PlatformMesh, _tSetting.PlatformX, _tSetting.PlatformY, _tSetting.PlatformZ, _tSetting.PlatformYaw)
    end
end

function UnRegisterFurnitureModel(szFrame, szName)
    local tFrameList = FurnitureModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = FurnitureModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    local hFurnitureModelView = tFrame.hFurnitureModelView
    if hFurnitureModelView then
        hFurnitureModelView:UnloadModel()
        hFurnitureModelView:release()
        Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)
        tFrame.hFurnitureModelView = nil
    end

    FurnitureModelPreview.tResisterFrame[szFrame][szName] = nil
end

function RegisterFurnitureModelEvent(szFrame)
    if FurnitureModelPreview.tEventFrame[szFrame] then
        -- RestoreMsgFunction(szName, "OnLButtonDown")
        -- RestoreMsgFunction(szName, "OnLButtonUp")
        -- RestoreMsgFunction(szName, "OnRButtonDown")
        -- RestoreMsgFunction(szName, "OnRButtonUp")
        -- --RestoreMsgFunction(szName, "OnFrameBreathe")
        -- RestoreMsgFunction(szName, "OnFrameDestroy")
        -- RestoreMsgFunction(szName, "OnMouseWheel")
        -- RestoreMsgFunction(szName, "OnEvent")
        Event.UnRegAll(FurnitureModelView.tEventFrame[szFrame])
    end

    FurnitureModelPreview.tResisterFrame[szFrame] = {}
    FurnitureModelPreview.tEventFrame[szFrame] = {}
    -- FurnitureModelPreview.CreateOnLButtonDown(szFrame)
    -- FurnitureModelPreview.CreateOnLButtonUp(szFrame)
    -- FurnitureModelPreview.CreateOnRButtonDown(szFrame)
    -- FurnitureModelPreview.CreateOnRButtonUp(szFrame)
    -- FurnitureModelPreview.CreateOnFrameDestroy(szFrame)
    -- FurnitureModelPreview.CreateOnMouseWheel(szFrame)
    FurnitureModelPreview.CreateOnEvent(szFrame)
end

local function LoadSetting()
    Event.UnReg(FurnitureModelPreview, "COINSHOP_ON_OPEN")

    local pFile = Ini.Open(szSettingFile)
    if not pFile then
        return
    end
    local szSection = "FurnitureModelSetting"
    _tSetting = {}
    _tSetting.CriterionX = pFile:ReadInteger(szSection, "CriterionX" , 0)
    _tSetting.CriterionY = pFile:ReadInteger(szSection, "CriterionY" , 0)
    _tSetting.CriterionZ = pFile:ReadInteger(szSection, "CriterionZ" , 0)
    _tSetting.MaxScale = pFile:ReadFloat(szSection, "MaxScale" , 0)
    _tSetting.MinScale = pFile:ReadFloat(szSection, "MinScale" , 0)
    _tSetting.PlatformMesh = pFile:ReadString(szSection, "PlatformMesh" , "")
    _tSetting.PlatformX = pFile:ReadFloat(szSection, "MobilePlatformX" , 0)
    _tSetting.PlatformY = pFile:ReadFloat(szSection, "MobilePlatformY" , 0)
    _tSetting.PlatformZ = pFile:ReadFloat(szSection, "MobilePlatformZ" , 0)
    _tSetting.PlatformYaw = pFile:ReadFloat(szSection, "PlatformYaw" , 0)
    pFile:Close()
end

Event.Reg(FurnitureModelPreview, "COINSHOP_ON_OPEN", LoadSetting)
Event.Reg(FurnitureModelPreview, EventType.OnRenownRewordOpen, LoadSetting)

Event.Reg(FurnitureModelPreview, "FURNITURE_MODEL_PREVIEW_UPDATE", function()
    FurnitureModelPreview.ShowFurniture(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end)

Event.Reg(FurnitureModelPreview, "FURNITURE_MODEL_SET_DETAILS", function ()
    FurnitureModelPreview.SetFurnitureDetails(arg0, arg1, arg2)
end)

Event.Reg(FurnitureModelPreview, "FURNITURE_MODEL_SET_CAMERA_RADIUS", function (szFrame, szName, szRadius, nFrameNum)
    FurnitureModelPreview_SetCameraRadius(szFrame, szName, szRadius, nFrameNum)
end)

Event.Reg(FurnitureModelPreview, "FURNITURE_MODEL_SET_CAMERA_ZOOM", function (szFrame, szName, szRadius)
    FurnitureModelPreview_SetCameraZoom(szFrame, szName, szRadius)
end)

Event.Reg(FurnitureModelPreview, "FURNITURE_MODEL_SET_POSITION", function ()
    FurnitureModelPreview.SetFurniturePosition(arg0, arg1, arg2)
end)

-- local function OnFurnitureModelPreviewEvent(szEvent)
--     if szEvent == "FURNITURE_MODEL_PREVIEW_UPDATE" then
--         FurnitureModelPreview.ShowFurniture(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
--     elseif szEvent == "FURNITURE_MODEL_SET_CAMERA_CENTER_R" then
--         FurnitureModelPreview_SetCameraCenterR(arg0, arg1, arg2, arg3)
--     elseif szEvent == "FURNITURE_MODEL_SET_DETAILS" then
--         FurnitureModelPreview.SetFurnitureDetails(arg0, arg1, arg2)

--     end
-- end
-- RegisterEvent("FURNITURE_MODEL_PREVIEW_UPDATE", function(szEvent) OnFurnitureModelPreviewEvent(szEvent) end)
-- RegisterEvent("FURNITURE_MODEL_SET_CAMERA_CENTER_R", function(szEvent) OnFurnitureModelPreviewEvent(szEvent) end)
-- RegisterEvent("FURNITURE_MODEL_SET_DETAILS", function(szEvent) OnFurnitureModelPreviewEvent(szEvent) end)