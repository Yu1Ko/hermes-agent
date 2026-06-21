MiniSceneCamera = class(camera_plus, "MiniSceneCamera")

local FrameStep = 1
local MAX_SCALE = 1.5
local MIN_SCALE = 0.5

local ZoomFactor = Const.MiniSceneZoomFactor
if Platform.IsMobile() then
    ZoomFactor = Const.MiniSceneMobileZoomFactor
end

function MiniSceneCamera:ctor()
    camera_plus.ctor(self)

    self.tbConfigs = nil
    self.fCameraPosX = nil
    self.fCameraPosY = nil
    self.fCameraPosZ = nil
    self.fAngleX = 0
    self.fAngleY = 0
    self.fAngleZ = 0
    self.fModelX = nil
    self.fModelY = nil
    self.fModelZ = nil
    self.fModelScale = 1
    self.nDefaultModelHight = 160
    self.fRotationX = 0
    self.fRotationY = 0
    self.fRotationZ = 0
    self.nCurZoomValue = 0
    self.nCurZoomIndex = 1
end

function MiniSceneCamera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
    self:UpdateConfig(szType, nIndex)
    self:UpdateZoom(nZoomIndex, nZoomValue)
end

function MiniSceneCamera:InitModelConfig(modelView)
    if not self.tbConfigs then
        LOG.ERROR("MiniSceneCamera:InitModelConfig Error! not tbConfigs!")
        return
    end

    if not modelView then
        LOG.ERROR("MiniSceneCamera:InitModelConfig Error! not modelView!")
        return
    end

    local tbCurParams = self.tbConfigs[self.nCurZoomIndex]
    modelView:SetYaw(tbCurParams.nModelYaw)
    modelView:SetTranslation(tbCurParams.tbModelTranslation[1], tbCurParams.tbModelTranslation[2], tbCurParams.tbModelTranslation[3])
end

function MiniSceneCamera:UpdateConfig(szType, nIndex)
    self.tbConfigs = TabHelper.GetUICameraConfigTab(szType, nIndex)
end

function MiniSceneCamera:UpdateYaw(modelView)
    if not self.tbConfigs then
        LOG.ERROR("MiniSceneCamera:UpdateYaw Error! not tbConfigs!")
        return
    end

    if not modelView then
        LOG.ERROR("MiniSceneCamera:UpdateYaw Error! not modelView!")
        return
    end

    local tbCurParams = self.tbConfigs[self.nCurZoomIndex]
    modelView:SetYaw(tbCurParams.nModelYaw)
end

function MiniSceneCamera:GetConfig()
    return self.tbConfigs
end

function MiniSceneCamera:SetPosition(x, y, z)
    self:setpos(x, y, z)
    self:UpdateLookAtPosition()
end

function MiniSceneCamera:GetPosition()
    return self:getpos()
end

function MiniSceneCamera:SetBasePosition(x, y, z)
    self.fCameraPosX = x
    self.fCameraPosY = y
    self.fCameraPosZ = z
    self:UpdatePosition()
end

function MiniSceneCamera:GetBasePosition()
    return self.fCameraPosX, self.fCameraPosY, self.fCameraPosZ
end

function MiniSceneCamera:SetRotation(fRX, fRY, fRZ, bNotUpdate)
    self.fRotationX = fRX
    self.fRotationY = fRY
    self.fRotationZ = fRZ
    if not bNotUpdate then
        self:UpdateLookAtPosition()
    end
end

function MiniSceneCamera:GetRotation()
    return self.fRotationX, self.fRotationY, self.fRotationZ
end

function MiniSceneCamera:SetOffsetAngle(fAngleX, fAngleY, fAngleZ, fModelX, fModelY, fModelZ, bNotUpdate)
    self.fAngleX = fAngleX or self.fAngleX
    self.fAngleY = fAngleY or self.fAngleY
    self.fAngleZ = fAngleZ or self.fAngleZ
    self.fModelX = fModelX or self.fModelX
    self.fModelY = fModelY or self.fModelY
    self.fModelZ = fModelZ or self.fModelZ
    if not bNotUpdate then
        self:UpdatePosition()
    end
end

function MiniSceneCamera:GetOffsetAngle()
    return self.fAngleX, self.fAngleY, self.fAngleZ, self.fModelX, self.fModelY, self.fModelZ
end

function MiniSceneCamera:SetModelScale(fModelScale, nDefaultModelHight)
    fModelScale = math.max(fModelScale, MIN_SCALE)
    fModelScale = math.min(fModelScale, MAX_SCALE)

    self.fModelScale = fModelScale
    self.nDefaultModelHight = nDefaultModelHight or 160
end

function MiniSceneCamera:GetModelScale()
    return self.fModelScale
end

function MiniSceneCamera:DoSetCameraParams(tbParams)
    if tbParams["tbCameraRot"] then
        self:SetRotation(tbParams["tbCameraRot"][1], tbParams["tbCameraRot"][2], tbParams["tbCameraRot"][3], true)
    end

    if tbParams["tbCameraPos"] then
        self:SetBasePosition(tbParams["tbCameraPos"][1], tbParams["tbCameraPos"][2], tbParams["tbCameraPos"][3])
    end
end

function MiniSceneCamera:SetCameraParams(tbParams, nTweenStartTime, nTweenTotalTime, funcOnAction)
    if self.nSetCameraParamsTimer then
        Timer.DelTimer(self, self.nSetCameraParamsTimer)
        self.nSetCameraParamsTimer = nil
    end

    if not nTweenStartTime or not nTweenTotalTime or nTweenStartTime >= nTweenTotalTime then
        self:DoSetCameraParams(tbParams)
    else
        local tbDeltaParams = self:GetDeltaCameraParams(tbParams, nTweenStartTime, nTweenTotalTime)
        self:DoSetCameraParams(tbDeltaParams)

        local nLastTime = GetTickCount()
        self.nSetCameraParamsTimer = Timer.AddFrame(self, 1, function ()
            local nFrameTime = (GetTickCount() - nLastTime) / 1000.0 / FrameStep
            self:SetCameraParams(tbParams, nTweenStartTime + nFrameTime, nTweenTotalTime, funcOnAction)
            if funcOnAction then
                funcOnAction()
            end
        end)
    end
end

function MiniSceneCamera:GetDeltaCameraParams(tbEndParams, nTweenStartTime, nTweenTotalTime)
    local fPerc = nTweenStartTime / nTweenTotalTime
    local tbParams = {}
    for key, value in pairs(tbEndParams) do
        local nowValue

        if key == "tbCameraRot" then
            nowValue = {self:GetRotation()}
        elseif key == "tbCameraPos" then
            nowValue = {self:GetBasePosition()}
        end

        if nowValue then
            if IsTable(value) then
                tbParams[key] = self:GetDeltaTableValue(nowValue, value, fPerc)
            else
                tbParams[key] = self:GetDeltaValue(nowValue, value, fPerc)
            end
        end
    end

    return tbParams
end

function MiniSceneCamera:UpdateLookAtPosition()
    local x, y, z = self:GetPosition()
    local fRadianX = math.pi * self.fRotationX / 180.0
    self:setlook(x, y + 300 * math.sin(fRadianX), z + 300 * math.cos(fRadianX))
end

function MiniSceneCamera:UpdatePosition()
    local x, y, z = self.fCameraPosX, self.fCameraPosY, self.fCameraPosZ
    if self.fAngleX and self.fModelZ then
        x = x + (self.fCameraPosZ - self.fModelZ) * math.tan(self.fAngleX * math.pi / 180)
    end

    y = y + self.nDefaultModelHight * (self.fModelScale - 1)

    self:SetPosition(x, y, z)
end

function MiniSceneCamera:OnTouchsBegan(nX1, nY1, nX2, nY2)
    self.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)
    self.nLastPinchZoomValue = self.nCurZoomValue

    if not self.nSceneWidth then
        local size = UIHelper.GetCurResolutionSize()
        self.nSceneWidth = size.width
    end
end

function MiniSceneCamera:OnTouchsMoved(nX1, nY1, nX2, nY2)
    if not self.nLastPinchDist or not self.nLastPinchZoomValue then
        self.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)
        self.nLastPinchZoomValue = self.nCurZoomValue
    end

    if not self.nSceneWidth then
        local size = UIHelper.GetCurResolutionSize()
        self.nSceneWidth = size.width
    end

    -- local nZoomCount = math.max(0, #(self.tbConfigs or {}) - 1)
    local nZoomCount = math.max(0, #(self.tbConfigs or {}) - 1) / 2
    local nDist = kmath.len2(nX1, nY1, nX2, nY2)
    local nDelta = nDist - self.nLastPinchDist
    local fPerc = ZoomFactor * nZoomCount * 3 * -100 * nDelta / self.nSceneWidth

    local nZoomIndex, nZoomValue = self.nCurZoomIndex, self.nLastPinchZoomValue
    nZoomValue = nZoomValue + fPerc

    while nZoomValue < 0 or nZoomValue > 100 do
        if nZoomValue < 0 then
            if self.tbConfigs[nZoomIndex - 1] then
                nZoomValue = nZoomValue + 100
                nZoomIndex = nZoomIndex - 1

                self.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)
                self.nLastPinchZoomValue = nZoomValue
            else
                nZoomValue = 0
            end
        elseif nZoomValue > 100 then
            if self.tbConfigs[nZoomIndex + 2] then
                nZoomValue = nZoomValue - 100
                nZoomIndex = nZoomIndex + 1

                self.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)
                self.nLastPinchZoomValue = nZoomValue
            else
                nZoomValue = 100
            end
        end
    end

    self:UpdateZoom(nZoomIndex, nZoomValue)
end

function MiniSceneCamera:OnTouchsEnded(nX1, nY1, nX2, nY2)
    self.nLastPinchDist = nil
    self.nLastPinchZoomValue = nil
    self:Zoom(0, 0)
end

function MiniSceneCamera:OnTouchsCancelled(nX1, nY1, nX2, nY2)
    self.nLastPinchDist = nil
    self.nLastPinchZoomValue = nil
    self:Zoom(0, 0)
end

function MiniSceneCamera:Zoom(nDelta, nTweenTotalTime)
    if not self.tbConfigs then
        return false
    end

    nTweenTotalTime = nTweenTotalTime or 0.2

    local nZoomIndex, nZoomValue = self.nCurZoomIndex, self.nCurZoomValue
    nZoomValue = nZoomValue + nDelta

    if nZoomValue <= 0 then
        nZoomValue = 0
        if self.tbConfigs[nZoomIndex - 1] then
            nZoomValue = 100
            nZoomIndex = nZoomIndex - 1
        end
    elseif nZoomValue >= 100 then
        nZoomValue = 100
        if self.tbConfigs[nZoomIndex + 2] then
            nZoomValue = 0
            nZoomIndex = nZoomIndex + 1
        end
    end

    self:UpdateZoom(nZoomIndex, nZoomValue, 0, nTweenTotalTime)

    return true
end

function MiniSceneCamera:UpdateZoom(nZoomIndex, nZoomValue, nTweenStartTime, nTweenTotalTime)
    self.nCurZoomIndex = nZoomIndex
    self.nCurZoomValue = nZoomValue

    local tbCurParams = self.tbConfigs[self.nCurZoomIndex]
    local tbNextParams = self.tbConfigs[self.nCurZoomIndex + 1]

    if not tbCurParams then
        return
    end

    if not tbNextParams then
        return
    end

    local tbParams = {
        ["tbCameraPos"]= self:GetDeltaTableValue(tbCurParams["tbCameraPos"], tbNextParams["tbCameraPos"], self.nCurZoomValue / 100.0),
        ["tbCameraRot"]= self:GetDeltaTableValue(tbCurParams["tbCameraRot"], tbNextParams["tbCameraRot"], self.nCurZoomValue / 100.0),
    }

    self:SetCameraParams(tbParams, nTweenStartTime, nTweenTotalTime)
end

function MiniSceneCamera:GetDeltaTableValue(tb1, tb2, fPerc)
    if not tb1 or not tb2 then
        return
    end

    local tb = {}
    for key, value1 in pairs(tb1) do
        local value2 = tb2[key]
        if value2 then
            tb[key] = self:GetDeltaValue(value1, value2, fPerc)
        end
    end

    return tb
end

function MiniSceneCamera:GetDeltaValue(value1, value2, fPerc)
    local total = value2 - value1
    local value = value1 + total * fPerc

    return value
end

function MiniSceneCamera:RefreshRender()
    Timer.AddFrame(self, 1, function ()
        local x, y, z = self:getpos()
        self:setpos(x, y, z + 1)
    end)
end