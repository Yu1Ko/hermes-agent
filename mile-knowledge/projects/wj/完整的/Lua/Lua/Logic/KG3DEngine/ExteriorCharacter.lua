ExteriorCharacter = {className = "ExteriorCharacter"}

ExteriorCharacter.tResisterFrame = {}
ExteriorCharacter.tEventFrame = {}

ExteriorCharacter.tCameraInfo =
{
    [ROLE_TYPE.STANDARD_MALE]   = { 0, 70, -277, 0, 120, 150 , 0, 0}, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = { 0, 78, -277, 0, 120, 150 , 0, 0}, --rtStandardFemale,   // 标准女
    [ROLE_TYPE.STRONG_MALE]     = { -30, 160, -25, 0, 150, 0 , 0, 0}, --rtStrongMale,       // 魁梧男
    [ROLE_TYPE.SEXY_FEMALE]     = { -30, 160, -25, 0, 150, 0 , 0, 0}, --rtSexyFemale,       // 性感女
    [ROLE_TYPE.LITTLE_BOY]      = { 0, 70, -278, 0, 100, 150 , 0, 0}, --rtLittleBoy,        //  小男孩
    [ROLE_TYPE.LITTLE_GIRL]     = { 0, 70, -278, 0, 100, 150 , 0, 0}  --rtLittleGirl,       // 小孩女
}

ExteriorCharacter.tMinCameraInfo =
{
    [ROLE_TYPE.STANDARD_MALE]   = { 0, 141, -98, 0, 170, 150 , 0, 0}, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = { 0, 146, -99, 0, 170, 150 ,  0, 0}, --rtStandardFemale,   //标准女
    [ROLE_TYPE.STRONG_MALE]     = { -30, 160, -25, 0, 150, 0 , 0, 0}, --rtStrongMale,       // 魁梧男
    [ROLE_TYPE.SEXY_FEMALE]     = { -30, 160, -25, 0, 150, 0 , 0, 0}, --rtSexyFemale,       // 性感女
    [ROLE_TYPE.LITTLE_BOY]      = { 0, 103, -99, 0, 120, 150 , 0, 0}, --rtLittleBoy,        //  小男孩
    [ROLE_TYPE.LITTLE_GIRL]     = { 0, 103, -99, 0, 120, 150 , 0, 0}  --rtLittleGirl,       // 小孩女
}

local FRAME_NUM = 25
local MAX_SCALE = 1.3
local MIN_SCALE = 0.1
local SCALE_CHANGE_LEN = 160

local m_bCanHideChest = false
local m_bCanHideHair = false

local ExteriorCharacterCameraMode = {
    ["Normal"] = "Normal",
    ["New"] = "New",
    ["Wardrobe"] = "Wardrobe",
    ["BuildFace"] = "BuildFace",
    ["BuildBody"] = "BuildBody",
}

local fnYawSmooth = function(nValueExpect, nValue)
    local nDelta = nValueExpect - nValue
    local nDelta1 = 2 * math.pi - math.abs(nDelta)
    local bFinish = false
    if math.abs(nDelta) > nDelta1 then
        local nSign = (nValue - nValueExpect) / math.abs(nValue - nValueExpect)
        nDelta = nSign * nDelta1
    end
    nValue = (nValue + nDelta / 5) % (2 * math.pi)
    bFinish = math.abs(nDelta) < 0.01

    return nValue, bFinish
end

local function InitCamera(nWidth, nHeight, tFrame, szType, nIndex, nZoomIndex, nZoomValue)
    tFrame.hCamera:init(tFrame.scene, 0, 0, 0, 0, 0, 0, 0.3, nWidth / nHeight, nil, 40000, true)
    tFrame.hCamera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
end

local tExpectList =
{
    {"fRoleYaw", "fRoleYawExpect", fnYawSmooth},
}

local fnCameraOperate = function(hScene)
    for _, tExpect in ipairs(tExpectList) do
        local szParamExpect = tExpect[2]
        if hScene[szParamExpect] then
            return false
        end
    end

    return true
end

local STEP = 1

local fnNewValue = function(hScene, szParam, szParamExpect, fnGetValue)
    if not hScene[szParamExpect] then
        return
    end

    local nValue = hScene[szParam]
    local nValueExpect = hScene[szParamExpect]
    local bFinish = false
    if fnGetValue then
        nValue, bFinish = fnGetValue(nValueExpect, nValue)
    else
        local nDelta = nValueExpect - nValue
        nValue = nValue + nDelta / 5
        bFinish = math.abs(nValue - nValueExpect) < 0.01
    end

    if bFinish then
        nValue = nValueExpect
        hScene[szParamExpect] = nil
    end
    hScene[szParam] = nValue
end

local function CameraSmooth(tFrame, szFrame, szName)
    for _, tExpect in ipairs(tExpectList) do
        local szParam = tExpect[1]
        local szParamExpect = tExpect[2]
        local fnGetValue = tExpect[3]
        fnNewValue(tFrame, szParam, szParamExpect, fnGetValue)
    end

    if tFrame.fRoleYawExpect then
        ExteriorCharacter.ReloadModelYaw(szFrame, szName)
    end
end

local function CameraRotate(tFrame)
    local bCanOperate =  fnCameraOperate(tFrame)
    if tFrame.bLDown and bCanOperate then
       -- print(tFrame.nX, tFrame.nY, tFrame.nCX, tFrame.nCY)
        local x, y = tFrame.nX, tFrame.nY
        local nCX, nCY = tFrame.nCX, tFrame.nCY
        if x ~= nCX or y ~= nCY then
            local tbScreenSize = UIHelper.GetScreenSize()-- UIHelper.GetCurResolutionSize() -- UIHelper.GetDesignResolutionSize()
            local cx, _cy = tbScreenSize.width, tbScreenSize.height
            local dx = -(x - nCX) / cx * math.pi
            local dy = 0 -- -(y - nCY) / cy * math.pi -- 上下 不转，锁了
            if tFrame.bDisableCamera then
                tFrame.fRoleYaw = (tFrame.fRoleYaw + dx) % (2 * math.pi)
                tFrame.hModelView:SetYaw(tFrame.fRoleYaw)
            else
                local fMinVerAngle = -math.pi / 2
                local fMaxVerAngle = 0.3
                local fMinHorAngle, fMaxHorAngle
                if tFrame.tCameraVerAngle then
                    fMinVerAngle = tFrame.tCameraVerAngle[1]
                    fMaxVerAngle = tFrame.tCameraVerAngle[2]
                end
                if tFrame.tHorAngle then
                    fMinHorAngle = tFrame.tHorAngle[1]
                    fMaxHorAngle = tFrame.tHorAngle[2]
                end
                tFrame.hCamera:rotate(dy * STEP, dx * STEP, fMinVerAngle, fMaxVerAngle, fMinHorAngle, fMaxHorAngle)
                ExteriorCharacter.UpdateParams(tFrame)
            end
        end
    end
end
local CHARACTER_ROLE_TURN_YAW = math.pi / 54

local function RoleYawTurn(tFrame)
    if tFrame.bTurnRight then
        tFrame.fRoleYaw = (tFrame.fRoleYaw - CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.hModelView:SetYaw(tFrame.fRoleYaw)
    elseif tFrame.bTurnLeft then
        tFrame.fRoleYaw = (tFrame.fRoleYaw + CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.hModelView:SetYaw(tFrame.fRoleYaw)
    end
end

function ExteriorCharacter.CreateOnEvent(szFrame)
    if not ExteriorCharacter.tEventFrame[szFrame].nTimerID then
        ExteriorCharacter.tEventFrame[szFrame].nTimerID = Timer.AddFrameCycle(ExteriorCharacter, 1, function ()
            local tFrameList = ExteriorCharacter.tResisterFrame[szFrame]
            if not tFrameList then return end
            for szName, tFrame in pairs(tFrameList) do
                CameraSmooth(tFrame, szFrame, szName)
                CameraRotate(tFrame)
                RoleYawTurn(tFrame)
            end
        end)
    end
end

function ExteriorCharacter.Init(szFrame, szName)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]

    local hPlayer = GetPlayer(tFrame.dwPlayerID)
    if not hPlayer then
        return
    end

    if tFrame.tRadius then
        tFrame.tWheelRadius = tFrame.tRadius
    end

    if tFrame.tVerAngle then
        tFrame.tCameraVerAngle = tFrame.tVerAngle
    end

    local hModelView = PlayerModelView.CreateInstance(PlayerModelView)
    hModelView:ctor()
    local tParam =
    {
       szName = szFrame .. "_" .. szName,
       szEnvFile = tFrame.szEnvFile,
       bExScene = tFrame.bExScene,
       scene = tFrame.scene,
       szExSceneFile = tFrame.szExSceneFile,
       bAPEX = tFrame.bAPEX,
       nModelType = tFrame.nModelType,
    }
    hModelView:InitBy(tParam)

    if tFrame.bAdjustByAnimation then
        hModelView:SetAdjustByAnimation(true)
    end
    tFrame.hModelView = hModelView
    tFrame.Viewer:SetScene(hModelView.m_scene)

    tFrame.hCamera = MiniSceneCamera.CreateInstance(MiniSceneCamera)
    tFrame.hCamera:ctor()

    local nRoleType = Player_GetRoleType(hPlayer)
    ExteriorCharacter.szCameraMode = ExteriorCharacter.szCameraMode or ExteriorCharacterCameraMode.Normal

    local tbCameraInfo = ExteriorCharacter.GetCameraInfo()
    local nCameraIndex = tbCameraInfo.tbIDs[nRoleType]

    tFrame.fRoleYaw = tbCameraInfo.fRoleYaw

    local nWidth, nHeight = UIHelper.GetContentSize(tFrame.Viewer)
    InitCamera(nWidth, nHeight, tFrame, tbCameraInfo.szType, nCameraIndex, tbCameraInfo.nDefaultZoomIndex, tbCameraInfo.nDefaultZoomValue)

    local tOffset = tFrame.tbCameraOffset or {}
    local xOffset = tOffset[1] or 0
    local yOffset = tOffset[2] or 0
    local zOffset = tOffset[3] or 0

    tFrame.hCamera:SetOffsetAngle(tbCameraInfo.tbOffset[1] + xOffset, tbCameraInfo.tbOffset[2] + yOffset, tbCameraInfo.tbOffset[3] + zOffset
    , tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])

    ExteriorCharacter.ReloadModelYaw(szFrame, szName)
end

function ExteriorCharacter.ReloadModelYaw(szFrame, szName)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    if tFrame.hModelView.m_modelRole then
        tFrame.hModelView:SetYaw(tFrame.fRoleYaw)
        -- tFrame.hCamera:UpdateYaw(tFrame.hModelView)
    end
end

function ExteriorCharacter.ReloadModelYawByCamera(szFrame, szName)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    if tFrame.hModelView.m_modelRole then
        tFrame.hCamera:UpdateYaw(tFrame.hModelView)
    end
end

function ExteriorCharacter.SDefaultCameraInfo(szFrame, szName)
    ExteriorCharacter.SetCameraInfo(szFrame, szName, ExteriorCharacter.tCameraInfo)
end

function ExteriorCharacter.SetCameraInfo(szFrame, szName, tbCameraInfo)
    if not g_pClientPlayer then
        return
    end
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    tFrame.tCameraInfo = tbCameraInfo

    local nRoleType = Player_GetRoleType(g_pClientPlayer)
    local nCameraIndex = tbCameraInfo.tbIDs[nRoleType]
    tFrame.hCamera:UpdateConfig(tbCameraInfo.szType, nCameraIndex)

    local tOffset = tFrame.tbCameraOffset or {}
    local xOffset = tOffset[1] or 0
    local yOffset = tOffset[2] or 0
    local zOffset = tOffset[3] or 0

    tFrame.hCamera:SetOffsetAngle(tbCameraInfo.tbOffset[1] + xOffset, tbCameraInfo.tbOffset[2] + yOffset, tbCameraInfo.tbOffset[3] + zOffset
    , tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])

    if tbCameraInfo.nDefaultZoomIndex and tbCameraInfo.nDefaultZoomValue then
        tFrame.hCamera:UpdateZoom(tbCameraInfo.nDefaultZoomIndex, tbCameraInfo.nDefaultZoomValue, 0, 0.2)
    end

    local fScale = ExteriorCharacter.m_nScale or 1
    tFrame.hCamera:SetModelScale(fScale)

    tFrame.fRoleYaw = tbCameraInfo.fRoleYaw
    ExteriorCharacter.ReloadModelYaw(szFrame, szName)
end

function ExteriorCharacter.OnUpdateMDLScale(szFrame, szName, OnGetMdlScale)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    if tFrame.hModelView then
        tFrame.hModelView:GetMdlScale(OnGetMdlScale)
    end
end

function ExteriorCharacter.SetCameraRadius(szFrame, szName, szRadius, nFrameNum)
    nFrameNum = nFrameNum or FRAME_NUM
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hPlayer = GetPlayer(tFrame.dwPlayerID)
    if not hPlayer then
        return
    end

    local fnAction = function()
        FireUIEvent("ON_EXTERIOR_CAMERA_UPDATE", szFrame, szName)
    end

    local tbZoomConfigs = tFrame.hCamera:GetConfig()
    if szRadius == "Min" then
        tFrame.hCamera:UpdateZoom(1, 0, 0, 0.2)
    elseif szRadius == "BuildFaceMin" then
        tFrame.hCamera:UpdateZoom(1, 10, 0, 0.2)
    elseif szRadius == "Max" then
        tFrame.hCamera:UpdateZoom(#tbZoomConfigs - 1, 100, 0, 0.2)
    end

    FireUIEvent("ON_EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", szFrame, szName, szRadius)
end

function ExteriorCharacter_SetCameraCenterR(szFrame, szName, nCenterR, nFrameNum)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    tFrame.hCamera:set_center_r(nCenterR, nFrameNum)
end

function ExteriorCharacter_SetCameraOffsetX(szFrame, szName, fOffsetX)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    tFrame.hCamera:SetOffsetAngle(fOffsetX)
end

function ExteriorCharacter_SetModelScale(szFrame, szName, fModelScale)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    tFrame.hCamera:SetModelScale(fModelScale)
    tFrame.hCamera:UpdatePosition()
end

function ExteriorCharacter_TouchUpdate(szFrame, szName, bTouch, x, y)
    print(szFrame, szName, bTouch, x, y)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    --[[ 转镜头改成转角色
    if tFrame.bLDown ~= bTouch then
        tFrame.nCX = x
        tFrame.nCY = y
    end

    tFrame.nX = x
    tFrame.nY = y
    tFrame.bLDown = bTouch
    --]]


    if not tFrame.bTouch and bTouch then
        tFrame.nCX = x
    end
    tFrame.bTouch = bTouch

    tFrame.bTurnRight = bTouch and x > tFrame.nCX
    tFrame.bTurnLeft = bTouch and x < tFrame.nCX
end

function ExteriorCharacter_GetCameraCenterR(szFrame, szName)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.hCamera:get_center_r()
end

function ExteriorCharacter_GetCameraOffsetX(szFrame, szName)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    local x = tFrame.hCamera:GetOffsetAngle()
    return x
end

function ExteriorCharacter_GetRegisterFrame(szFrame, szName)
    local tFrameList = ExteriorCharacter.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    return tFrame
end

function ExteriorCharacter.GetModel(szFrame, szName)
    local tFrameList = ExteriorCharacter.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    local hModelView = tFrame.hModelView

    return hModelView
end

function ExteriorCharacter.ShowPlayer(szFrame, szName, tRepresentID, bIngoreReplace, dwLogicID, szDefaultAni)
    local tFrameList = ExteriorCharacter.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    local hPlayer = GetPlayer(tFrame.dwPlayerID)
    if not hPlayer then
        return
    end

    local hModelView = tFrame.hModelView
    tFrame.fRoleYaw = hModelView:GetYaw() -- fRoleYaw理论上应该和GetYaw()的数值一致，现在旋转没有给fRoleYaw赋值，这里先强设一下
    hModelView:UnloadModel()
    hModelView:LoadRes(hPlayer.dwID, tRepresentID, bIngoreReplace)
    if tFrame.tPos then
        hModelView:SetTranslation(tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])

        if tFrame.hCamera then
            tFrame.hCamera:set_mainplayer_pos(tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
        end
    end

    if tFrame.bRegisterEvent and not hModelView:IsRegisterEventHandler() then
        hModelView:RegisterEventHandler()
    end

    if dwLogicID and szDefaultAni then
        hModelView:PlayAnimationByLogicID(dwLogicID, szDefaultAni)
    elseif tFrame.szAnimation and tFrame.szLoopType then
        hModelView:PlayAnimation(tFrame.szAnimation, tFrame.szLoopType)
    else
        hModelView:PlayAnimation("Standard", "loop")
    end

    if hModelView then
        hModelView:SetYaw(tFrame.fRoleYaw)
    end
    ExteriorCharacter.UpdateMDLScale()
end

function ExteriorCharacter.PlayLogicAni(szFrame, szName, dwLogicID, szDefaultAni)
    local tFrameList = ExteriorCharacter.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    local hModelView = tFrame.hModelView
    hModelView:PlayAnimationByLogicID(dwLogicID, szDefaultAni)
end

function ExteriorCharacter.PlayRoleAnimation(szFrame, szName, szLoopType, szAnimationPath)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    local hModelView = tFrame.hModelView
    if hModelView then
        hModelView:PlayRoleAnimation(szLoopType, szAnimationPath)
    end
end

function ExteriorCharacter.UpdateWeaponPos(szFrame, szName, bSheath, nWeaponType)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    local hModelView = tFrame.hModelView
    if hModelView then
        hModelView:UpdateWeaponPos(bSheath, nWeaponType)
    end
end

function ExteriorCharacter.PlayAnimationFinished(hMDL)
    for szFrame, tFrameList in pairs(ExteriorCharacter.tResisterFrame) do
        for szName, tFrame in pairs(tFrameList) do
            local hModelView = tFrame.hModelView
            if hModelView and hModelView.m_modelRole and hModelView.m_modelRole["MDL"] == hMDL then
                if tFrame.szAnimation and tFrame.szLoopType then
                    hModelView:PlayAnimation(tFrame.szAnimation, tFrame.szLoopType)
                else
                    hModelView:PlayAnimation("Standard", "loop")
                end
                hModelView:UpdateWeaponPos(false)
                break
            end
        end
    end
end

function ExteriorCharacter.OnResize(szFrame, szName)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    ExteriorCharacter.ReloadModelYaw(tFrame, szName)
end

function ExteriorCharacter.GetFaceModel(szFrame, szName)
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = hFrame:Lookup(tFrame.szScene)
    local hModelView = hScene.hModelView

    return hModelView:GetFaceModel()
end

function ExteriorCharacter.SetSubsetVisiable(szFrame, szName, nType, nFlag)
    local tFrameList = ExteriorCharacter.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    local hModelView = tFrame.hModelView
    hModelView:SetSubsetVisiable(nType, nFlag)
end

function ExteriorCharacter.SetHairDyeing(szFrame, szName, tData)
    local tFrameList = ExteriorCharacter.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    local hModelView = tFrame.hModelView
    hModelView:SetHairDyeingData(tData)
end

--[[
local tCharacterParam =
{
    dwPlayerID = nPlayerID,
    szName = "PlayerView",
    szFrameName = "PlayerView",
    szFramePath = "Normal/PlayerView",
    szScene = "Page_Main/Page_Exterior/Scene_ERole",
    szTurnLeft = "Btn_TurnLeft_Ex",
    szTurnRight = "Btn_TurnRight_Ex",
    szTurnUp = "Btn_TurnUp",
    szTurnDown =  = "Btn_TurnDown",
    szZoomIn = "Btn_ZoomIn",
    szZoomOut =  = "Btn_ZoomOut",
    szAnimation = "Idle",
    szLoopType = "loop",
    tCameraInfo = PlayerView.m_aCameraInfo,
}
--]]

function RegisterExteriorCharacter(tCharacterParam)
    local szFrame = tCharacterParam.szFrameName
    local szName = tCharacterParam.szName
    ExteriorCharacter.tResisterFrame[szFrame] = ExteriorCharacter.tResisterFrame[szFrame] or {}
    local tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    if tFrame then
        local hModelView = tFrame.hModelView
        if hModelView then
            hModelView:UnloadModel()
            hModelView:release()
            tFrame.hModelView = nil
        end
        ExteriorCharacter.tResisterFrame[szFrame][szName] = nil
    end

    ExteriorCharacter.tResisterFrame[szFrame][szName] = tCharacterParam
    ExteriorCharacter.Init(szFrame, szName)
end

function ExteriorCharacter.UnRegisterExteriorCharacter(szFrameName, szName)
    local tFrameList = ExteriorCharacter.tResisterFrame[szFrameName]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    local hModelView = tFrame.hModelView
    if hModelView then
        if tFrame.bRegisterEvent and hModelView.m_modelRole then
            hModelView:UnRegisterEventHandler()
        end
        hModelView:UnloadModel()
        hModelView:release()
        tFrame.hModelView = nil
    end

    local hCamera = tFrame.hCamera
    if hCamera then
        hCamera:set_mainplayer_pos()
    end

    ExteriorCharacter.tResisterFrame[szFrameName][szName] = nil
end

function RegisterExteriorCharacterEvent(szFrame)
    ExteriorCharacter.tResisterFrame[szFrame] = {}
    ExteriorCharacter.tEventFrame[szFrame] = {}
    ExteriorCharacter.CreateOnEvent(szFrame)
end

Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_UPDATE", function() ExteriorCharacter.ShowPlayer(arg0, arg1, arg2, arg3, arg4, arg5) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_PLAY_ANIMATION", function() ExteriorCharacter.PlayRoleAnimation(arg0, arg1, arg2, arg3) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_UPDATE_WEAPON_POS", function() ExteriorCharacter.UpdateWeaponPos(arg0, arg1, arg2, arg3) end)
Event.Reg(ExteriorCharacter, "KG3D_PLAY_ANIMAION_FINISHED", function() ExteriorCharacter.PlayAnimationFinished(argu) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_SET_CAMERA_INFO", function() ExteriorCharacter.SetCameraInfo(arg0, arg1, arg2, arg3, arg4, arg5) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", function() ExteriorCharacter.SetCameraRadius(arg0, arg1, arg2, arg3) end)
-- Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_DEFAULT_CAMERA_INFO", function() ExteriorCharacter.SDefaultCameraInfo(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_RESIZE", function() ExteriorCharacter.OnResize(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_SET_CAMERA_CENTER_R", function() ExteriorCharacter_SetCameraCenterR(arg0, arg1, arg2, arg3) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_SET_CAMERA_OFFSET_X", function() ExteriorCharacter_SetCameraOffsetX(arg0, arg1, arg2) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_SET_MODEL_SCALE", function() ExteriorCharacter_SetModelScale(arg0, arg1, arg2) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_PLAY_LOGIC_ANI", function() ExteriorCharacter.PlayLogicAni(arg0, arg1, arg2, arg3) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_PLAY_SUBSET_VISIABLE", function() ExteriorCharacter.SetSubsetVisiable(arg0, arg1, arg2, arg3) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_SET_HAIR_DYEING_DATA", function() ExteriorCharacter.SetHairDyeing(arg0, arg1, arg2, arg3) end)

-- Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_UPDATE_BODY", function() ExteriorCharacter.UpdatePlayerBody(arg0, arg1, arg2) end)
-- Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_PLAY_FACE_ANI", function()  ExteriorCharacter.UpdateFaceAni(arg0, arg1, arg2) end)
-- Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_SET_YAW", function() ExteriorCharacter.SetYaw(arg0, arg1, arg2) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_GET_SCALE", function() ExteriorCharacter.OnUpdateMDLScale(arg0, arg1, arg2) end)
Event.Reg(ExteriorCharacter, "EXTERIOR_CHARACTER_TOUCH_UPDATE", function(szFrame, szName, bTouch, x, y) ExteriorCharacter_TouchUpdate(szFrame, szName, bTouch, x, y) end)
--------------------CoinShop_View--------------------------------------
ExteriorCharacter.m_nCameraRadius = nil

local tCameraInfo = --常规
{
    [ROLE_TYPE.STANDARD_MALE]   = {0, 150, -446, -48, 90, 0, 0, 0, 90, 0, 0.50}, --标男常规镜头参数 1
    [ROLE_TYPE.STANDARD_FEMALE] = {0, 150, -428, -48, 84, 0, 0, 0, 84, 0, 0.50},--标女常规镜头参数 1
    [ROLE_TYPE.STRONG_MALE]     = {-30, 83, -227, 0, 86, 0, 0, 0},
    [ROLE_TYPE.SEXY_FEMALE]     = {-28, 99, -227, 0, 86, 0, 0, 0},
    [ROLE_TYPE.LITTLE_BOY]      = {0, 134, -338, -38, 65, 0, 0, 0, 65, 0, 0.50},--小男孩常规镜头参数 1
    [ROLE_TYPE.LITTLE_GIRL]     = {0, 134, -338, -38, 65, 0, 0, 0, 65, 0, 0.50},--小女孩常规镜头参数 1
}

local tMinCameraInfo = --加号
{
    [ROLE_TYPE.STANDARD_MALE]   = {0, 148, -188, -20, 153, 0, 0, 0, 153, 0, 0.5}, --rtStandardMale, 1
    [ROLE_TYPE.STANDARD_FEMALE] = {0, 148, -140, -14, 150, 0, 0, 0, 150, 0, 0.5}, --rtStandardFemale, 1
    [ROLE_TYPE.STRONG_MALE]     = {-41, 162, -35, 0, 167, 0, 1.29}, --rtStrongMale,
    [ROLE_TYPE.SEXY_FEMALE]     = {-41, 162, -35, 0, 167, 0, 1.29}, --rtSexyFemale,
    [ROLE_TYPE.LITTLE_BOY]      = {0, 108, -140, -20, 108, 0, 0, 0, 108, 0, 0.5}, --rtLittleBoy,  1
    [ROLE_TYPE.LITTLE_GIRL]     = {0, 108, -140, -14, 108, 0, 0, 0, 108, 0, 0.5}  --rtLittleGirl, 1
}

-- 商城捏体型
local tBuildFaceCameraInfo =
{
    [ROLE_TYPE.STANDARD_MALE]   = {0, 150, -428, 28, 90, 0, 0, 0, 90, 0, 0.50}, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = {0, 150, -428, 30, 85, 0, 0, 0, 85, 0, 0.50},--rtStandardFemale,   // 标准女
    [ROLE_TYPE.STRONG_MALE]     = {-30, 83, -227, 0, 86, 0, 0, 0}, --rtStrongMale,       // 魁梧男
    [ROLE_TYPE.SEXY_FEMALE]     = {-28, 99, -227, 0, 86, 0, 0, 0},--rtSexyFemale,       // 性感女
    [ROLE_TYPE.LITTLE_BOY]      = {0, 134, -350, 25, 65, 0, 0, 0, 65, 0, 0.50}, --rtLittleBoy,        //  小男孩
    [ROLE_TYPE.LITTLE_GIRL]     = {0, 134, -350, 25, 65, 0, 0, 0, 65, 0, 0.50},--rtLittleGirl,       // 小孩女
}
-- 商城捏脸、发型
local tBuildFaceMinCameraInfo =
{
    [ROLE_TYPE.STANDARD_MALE]   = {0, 171, -80, 3, 170, 0, 0, 0, 170, 0, 0.50}, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = {0, 152, -100, 5, 152, 0, 0, 0, 152, 0, 0.50},--rtStandardFemale,   //标准女
    [ROLE_TYPE.STRONG_MALE]     = {-30, 83, -227, 0, 86, 0, 0, 0},--rtStrongMale,       // 魁梧男
    [ROLE_TYPE.SEXY_FEMALE]     = {-28, 99, -227, 0, 86, 0, 0, 0},--rtSexyFemale,       // 性感女
    [ROLE_TYPE.LITTLE_BOY]      = {0, 114, -80, 0, 114, 0, 0, 0, 114, 0, 0.50},--rtLittleBoy,        //  小男孩
    [ROLE_TYPE.LITTLE_GIRL]     = {0, 108, -80, 5, 113, 0, 0.12, 0, 113, 0, 0.50},--rtLittleGirl,       // 小孩女
}

local tRadius = --常规
{
    [ROLE_TYPE.STANDARD_MALE]   = { 380, 500}, --rtStandardMale, --标男常规镜头最近最远限制
    [ROLE_TYPE.STANDARD_FEMALE] = { 395, 500}, --rtStandardFemale,
    [ROLE_TYPE.STRONG_MALE]     = { 50, 160}, --rtStrongMale,
    [ROLE_TYPE.SEXY_FEMALE]     = { 50, 100}, --rtSexyFemale,
    [ROLE_TYPE.LITTLE_BOY]      = { 300, 390}, --rtLittleBoy,
    [ROLE_TYPE.LITTLE_GIRL]     = { 300, 390},  --rtLittleGirl,
}

local tMinRadius = --加号
{
    [ROLE_TYPE.STANDARD_MALE]   = { 150, 220}, --rtStandardMale,
    [ROLE_TYPE.STANDARD_FEMALE] = { 110, 180}, --rtStandardFemale,
    [ROLE_TYPE.STRONG_MALE]     = { 50, 180}, --rtStrongMale,
    [ROLE_TYPE.SEXY_FEMALE]     = { 50, 180}, --rtSexyFemale,
    [ROLE_TYPE.LITTLE_BOY]      = { 105, 200}, --rtLittleBoy,
    [ROLE_TYPE.LITTLE_GIRL]     = { 105, 200},  --rtLittleGirl,
}

local tBuildFaceRadius = -- 商城捏体型
{
    [ROLE_TYPE.STANDARD_MALE]   = { 380, 500}, --rtStandardMale, --标男常规镜头最近最远限制
    [ROLE_TYPE.STANDARD_FEMALE] = { 370, 500}, --rtStandardFemale,
    [ROLE_TYPE.STRONG_MALE]     = { 50, 160}, --rtStrongMale,
    [ROLE_TYPE.SEXY_FEMALE]     = { 50, 100}, --rtSexyFemale,
    [ROLE_TYPE.LITTLE_BOY]      = { 280, 390}, --rtLittleBoy,
    [ROLE_TYPE.LITTLE_GIRL]     = { 280, 390},  --rtLittleGirl,
}

local tBuildFaceMinRadius = -- 商城捏脸、发型
{
    [ROLE_TYPE.STANDARD_MALE]   = {60, 120}, --rtStandardMale,
    [ROLE_TYPE.STANDARD_FEMALE] = { 80, 120}, --rtStandardFemale,
    [ROLE_TYPE.STRONG_MALE]     = { 50, 180}, --rtStrongMale,
    [ROLE_TYPE.SEXY_FEMALE]     = { 50, 180}, --rtSexyFemale,
    [ROLE_TYPE.LITTLE_BOY]      = { 70, 100}, --rtLittleBoy,
    [ROLE_TYPE.LITTLE_GIRL]     = { 70, 100}, --rtLittleGirl,
}

local tNpcCamera = {-486, 75, -304, -34, 77, 44, 1.72, 0, 77, 0}
local tNpcRadius = {280, 700}
local tRideCamera = {-643, 169, -249, -37, 101, 71, 2.37, 0, 101, 0}
local tRideRadius = {380, 700}
local tVerAngle = {-1, 0.1}-- 取值范围-pi~pi
local tMinVerAngle = {-1, 0.3}-- 取值范围-pi~pi
local tHorAngle = {5.9, 1.1}

local tFurnitureCamera = {-1600, 980, -645, -120, 160, 153, 1.72, 0, 160, 0}
local tFVerAngle = {-1, 0}-- 取值范围-pi~pi
local tFHorAngle = {5.9, 1.1}-- 取值范围-pi~pi
local tFRadius = {380, 2000}

local tPos = {0, 0, 0}--基准角色模型位置（主角和NPC等都是这个点）

function ExteriorCharacter.RegisterRole(UIViewer3D, scene)
    if not g_pClientPlayer then
        return
    end
    --local szFramePath = GetFramePath()
    local tCameraInfo = ExteriorCharacter.GetCameraInfo()

    local tCharacterParam =
    {
        dwPlayerID = g_pClientPlayer.dwID,
        szName = "CoinShop",
        szFrameName = "CoinShop_View",
        szFramePath = "CoinShop_View_Path",
        -- szScene = "WndCoinShop/Scene_CoinShop",
        Viewer = UIViewer3D,
        szTurnLeft = "Btn_RoleTurnLeft",
        szTurnRight = "Btn_RoleTurnRight",
        szZoomIn = "Btn_RoleZoomIn",
        szZoomOut = "Btn_RoleZoomOut",
        szSceneName = "Scene_CoinShop",
        tCameraInfo = tCameraInfo,
        bRegisterEvent = true,
        bExScene = true,
        scene = scene,
        szAnimation = "StandardNew",
        szLoopType = "loop",
        bAdjustByAnimation = true,
        tPos = tPos,
        tHorAngle = tHorAngle,
        tVerAngle = tVerAngle,
        tMinVerAngle = tMinVerAngle,
        bAPEX = false,--TODO: CoinShop_Main.GetFabric(), --布料开关一定要重新reload
        nModelType = UI_MODEL_TYPE.COINSHOP,
    }
    RegisterExteriorCharacter(tCharacterParam)
end

function ExteriorCharacter.RegisterNpc(UIViewer3D, scene)
    local tCamera = clone(tNpcCamera)
    ExteriorCharacter.AddCameraPos(tCamera, tPos)
    local tNpcParam =
    {
        szName = "CoinShop",
        szFrameName = "CoinShop_View",
        szFramePath = "CoinShop_View_Path",
        Viewer = UIViewer3D,
        scene = scene,
        bNotMgrScene = true,
        szTurnLeft = "Btn_RoleTurnLeft",
        szTurnRight = "Btn_RoleTurnRight",
        --bDisableCamera = true,
        tPos = tPos,
        tCamera = tCamera,
        tRadius = tNpcRadius,
        tHorAngle = tHorAngle,
        tVerAngle = tVerAngle,
        szCameraType = "ShopNpc",
        nCameraIndex = 1,
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
        tbCameraOffset = {4.0, 0, 0}
    }
    RegisterNpcModelPreview(tNpcParam)
end

function ExteriorCharacter.UpdatePetModel()
    local tData = ExteriorCharacter.GetPetData()
    local tItem = tData.tItem
    if tItem then
        local tPet = Table_GetFellowPet(tItem.nPetIndex)
        --local tCamera = {tPet.nX, tPet.nY, tPet.nZ, tPet.nLookAtX, tPet.nLookAtY, tPet.nLookAtZ}
        local tCamera = clone(tNpcCamera)
        local tNpcPos = clone(tPos)
        -- if tPet.nCoinShopPosY > 0 then
        --     tNpcPos[2] = tPet.nCoinShopPosY
        -- end
        -- ExteriorCharacter.AddCameraPos(tCamera, tNpcPos)

        NpcModelPreview.tResisterFrame["CoinShop_View"] = NpcModelPreview.tResisterFrame["CoinShop_View"] or {}
        local tFrame = NpcModelPreview.tResisterFrame["CoinShop_View"]["CoinShop"]

        if tPet.dwPetIndex == 546 then -- pet：花楹 坐标特殊处理
            tNpcPos[2] = tNpcPos[2] - 20
        elseif tPet.nY > 180 then
            tNpcPos[2] = tNpcPos[2] - 130
        end
        tFrame.tPos = tNpcPos

        local fScale = tPet.fMobileCoinShopScale > 0.001 and tPet.fMobileCoinShopScale or tPet.fCoinShopScale

        FireUIEvent(
            "NPC_MODEL_PREVIEW_UPDATE",
            "CoinShop_View",
            "CoinShop",
            tPet.dwModelID,
            tPet.nColorChannelTable,
            tPet.nColorChannel,
            fScale,
            tCamera
        )
    else
        FireUIEvent(
            "NPC_MODEL_PREVIEW_UPDATE",
            "CoinShop_View",
            "CoinShop",
            0,
            nil,
            nil,
            nil,
            nil
        )
    end
end

function ExteriorCharacter.RegisterRide(UIViewer3D, scene)
    -- local szFramePath = GetFramePath()
    -- local scene = GetScene(szExSceneFile)
    local tCamera = clone(tRideCamera)
    ExteriorCharacter.AddCameraPos(tCamera, tPos)
    local tRideParam =
    {
        szName = "CoinShop",
        szFrameName = "CoinShop_View",
        szFramePath = "CoinShop_View_Path",
        szTurnLeft = "Btn_RoleTurnLeft",
        szTurnRight = "Btn_RoleTurnRight",
        Viewer = UIViewer3D,
        --bDisableCamera = true,
        scene = scene,
        fScale = 0.4,
        tPos = tPos,
        tCamera = tCamera,
        tRadius = tRideRadius,
        tHorAngle = tHorAngle,
        tVerAngle = tVerAngle,
        szCameraType = "ShopRide",
        nCameraIndex = 1,
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
        tbCameraOffset = {4.0, 0, 0}
    }
    RegisterRidesModelPreview(tRideParam)
end

function ExteriorCharacter.RegisteFurniture(UIViewer3D, scene)
    -- local szFramePath = GetFramePath()
    local tCamera = clone(tFurnitureCamera)
    ExteriorCharacter.AddCameraPos(tCamera, tPos)
    local tNpcParam =
    {
        szName = "CoinShop",
        szFrameName = "CoinShop_View",
        szFramePath = "CoinShop_View_Path",
        -- szScene = "WndCoinShop/Scene_CoinShop",
        -- szSceneName = "Scene_CoinShop",
        Viewer = UIViewer3D,
        scene = scene,
        bNotMgrScene = true,
        szTurnLeft = "Btn_RoleTurnLeft",
        szTurnRight = "Btn_RoleTurnRight",
        --bDisableCamera = true,
        tPos = tPos,
        tCamera = tCamera,
        tRadius = tFRadius,
        tHorAngle = tFHorAngle,
        tVerAngle = tFVerAngle,
        szCameraType = "ShopFurniture",
        nCameraIndex = 1,
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
        tbCameraOffset = {4.0, 0, 0}
    }
    RegisterFurnitureModelView(tNpcParam)
end

function ExteriorCharacter.UpdateFurnitureModel()
    local tData = ExteriorCharacter.GetFurnitureData()
    local tItem = tData.tItem

    local nYaw, fScale, fScaleScale
    if tItem.nYaw then
        nYaw = tItem.nYaw - 1.16
    else
        nYaw = -2.65
    end
    if tItem.fScale then
        fScale = tItem.fScale * 0.8
    else
        fScaleScale = 0.35
    end
    if tItem then
        local tCamera = clone(tNpcCamera)
        local tNpcPos = clone(tPos)
        tCamera[7] = -math.pi/2
        ExteriorCharacter.AddCameraPos(tCamera, tNpcPos)

        local tItemPos = clone(tItem.tPos)
        tItemPos[2] = tItemPos[2] + 10
        FireUIEvent(
            "FURNITURE_MODEL_PREVIEW_UPDATE",
            "CoinShop_View",
            "CoinShop",
            tItem.dwRepresentID,
            tCamera,
            tItemPos,
            tItem.nPutType,
            tItem.nDetails,
            nYaw,
            fScale,
            fScaleScale
        )
    else
        FireUIEvent(
            "FURNITURE_MODEL_PREVIEW_UPDATE",
            "CoinShop_View",
            "CoinShop",
            0
        )
    end
end

local ExteriorCharacterCameraModeConfig = {
    ["Normal"] = {
        szType = "Shop",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0.05,
        tbOffset = {3.2, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
    },
    ["New"] = {
        szType = "Shop",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0.05,
        tbOffset = {3.2, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
    },
    ["Wardrobe"] = {
        szType = "Shop",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0.05,
        tbOffset = {4.2, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
    },
    ["BuildFace"] = {
        szType = "ShopFace",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0,
        tbOffset = {-1.8, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 0,
    },
    ["ShareStation"] = {
        szType = "ShopFace",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0,
        tbOffset = {0.5, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 0,
    },
    ["ShareStation_Face"] = {
        szType = "ShopFace",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0,
        tbOffset = {-0.5, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 0,
    },
    ["ShareStation_Body"] = {
        szType = "Shop",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0,
        tbOffset = {-0.5, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 0,
    },
    ["BuildHair"] = {
        szType = "ShopFace",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0,
        tbOffset = {3.2, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 0,
    },
    ["BuildBody"] = {
        szType = "Shop",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0,
        tbOffset = {-1.8, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
    },
    ["Center"] = {
        szType = "Shop",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0,
        tbOffset = {0, 0, 0},
    },
    ["CustomPendant"] = {
        szType = "Shop",
        tbIDs = {
            [ROLE_TYPE.STANDARD_MALE]   = 1, --rtStandardMale,     // 标准男
            [ROLE_TYPE.STANDARD_FEMALE] = 2, --rtStandardFemale,   //标准女
            [ROLE_TYPE.LITTLE_BOY]      = 3, --rtLittleBoy,        //  小男孩
            [ROLE_TYPE.LITTLE_GIRL]     = 4  --rtLittleGirl,       // 小孩女
        },
        fRoleYaw = 0.05,
        tbOffset = {1.2, 0, 0},
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
    },
}
function ExteriorCharacter.SetCameraMode(szCameraMode)
    ExteriorCharacter.szCameraMode = szCameraMode
end

function ExteriorCharacter.GetCameraInfo()
    local tInfo = ExteriorCharacterCameraModeConfig[ExteriorCharacter.szCameraMode] or ExteriorCharacterCameraModeConfig.Normal
    return tInfo
end

function ExteriorCharacter.GetBasePos()
    return tPos
end

function ExteriorCharacter.DelCameraInfo(tCameraInfo)
    local tCameraInfo1 = clone(tCameraInfo)
    for _, tCamera in pairs(tCameraInfo1) do
        ExteriorCharacter.AddCameraPos(tCamera, tPos)
    end
    return tCameraInfo1
end

function ExteriorCharacter.DelMinCameraInfo(tCameraInfo)
    local tCameraInfo1 = clone(tCameraInfo)
    for _, tCamera in pairs(tCameraInfo1) do
        local nScale = ExteriorCharacter.m_nScale or 1
        tCamera[2] = tCamera[2] + SCALE_CHANGE_LEN * (nScale - 1)
        tCamera[5] = tCamera[5] + SCALE_CHANGE_LEN * (nScale - 1)
        tCamera[9] = tCamera[5]
        ExteriorCharacter.AddCameraPos(tCamera, tPos)
    end
    return tCameraInfo1
end

function ExteriorCharacter.AddCameraPos(tCamera, tPos)
    tCamera[1] = tCamera[1] + tPos[1]
    tCamera[2] = tCamera[2] + tPos[2]
    tCamera[3] = tCamera[3] + tPos[3]

    tCamera[4] = tCamera[4] + tPos[1]
    tCamera[5] = tCamera[5] + tPos[2]
    tCamera[6] = tCamera[6] + tPos[3]

    if tCamera[8] and tCamera[9] and tCamera[10] then
        tCamera[8] = tCamera[8] + tPos[1]
        tCamera[9] = tCamera[9] + tPos[2]
        tCamera[10] = tCamera[10] + tPos[3]
    end
end

function ExteriorCharacter.ScaleToCamera(szCameraRadius)
    local tCameraInfo = ExteriorCharacter.GetCameraInfo()
    FireUIEvent(
        "EXTERIOR_CHARACTER_SET_CAMERA_INFO",
        "CoinShop_View",
        "CoinShop",
        tCameraInfo
    )

    ExteriorCharacter.m_szCameraRadius = szCameraRadius
    FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", szCameraRadius, FRAME_NUM)
    ExteriorCharacter.m_nCameraRadius = nil
end

function ExteriorCharacter.ScaleToPos(tItem)
    if not tItem.tCameraInfo then
        return
    end
    local tCameraInfo = tItem.tCameraInfo

    FireUIEvent(
        "EXTERIOR_CHARACTER_SET_CAMERA_INFO",
        "CoinShop_View",
        "CoinShop",
        tCameraInfo
    )
    FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", tItem.szInitPosition, FRAME_NUM)
    ExteriorCharacter.m_nCameraRadius = nil
end

function ExteriorCharacter.OnGetMdlScale(model, UserData, fScale)
    ExteriorCharacter.m_nScale = fScale
    ExteriorCharacter.m_nScale = math.max(ExteriorCharacter.m_nScale, MIN_SCALE)
    ExteriorCharacter.m_nScale = math.min(ExteriorCharacter.m_nScale, MAX_SCALE)

    FireUIEvent(
        "EXTERIOR_CHARACTER_SET_MODEL_SCALE",
        "CoinShop_View",
        "CoinShop",
        ExteriorCharacter.m_nScale
    )
end

function ExteriorCharacter.ResetMDLScale()
    ExteriorCharacter.m_nScale = 1
    local tCameraInfo = ExteriorCharacter.GetCameraInfo()

    FireUIEvent(
        "EXTERIOR_CHARACTER_SET_CAMERA_INFO",
        "CoinShop_View",
        "CoinShop",
        tCameraInfo
    )
end

function ExteriorCharacter.UpdateMDLScale()
    FireUIEvent("EXTERIOR_CHARACTER_GET_SCALE", "CoinShop_View", "CoinShop", ExteriorCharacter.OnGetMdlScale)
end

function ExteriorCharacter.CameraToCenter()
    if ExteriorCharacter.tbCenterCacheOffsetParams or ExteriorCharacter.szCenterCacheCameraMode then
        return
    end

    if ExteriorCharacter.m_szViewPage == "Ride" then
        ExteriorCharacter.tbCenterCacheOffsetParams = {RidesModelPreview_GetCameraOffset("CoinShop_View", "CoinShop")}
        RidesModelPreview_SetCameraOffset("CoinShop_View", "CoinShop", 0, 0, 0,
            ExteriorCharacter.tbCenterCacheOffsetParams[4],
            ExteriorCharacter.tbCenterCacheOffsetParams[5],
            ExteriorCharacter.tbCenterCacheOffsetParams[6],
            false
        )
    elseif ExteriorCharacter.m_szViewPage == "Pet" then
        ExteriorCharacter.tbCenterCacheOffsetParams = {NpcModelPreview_GetCameraOffset("CoinShop_View", "CoinShop")}
        NpcModelPreview_SetCameraOffset("CoinShop_View", "CoinShop", 0, 0, 0,
            ExteriorCharacter.tbCenterCacheOffsetParams[4],
            ExteriorCharacter.tbCenterCacheOffsetParams[5],
            ExteriorCharacter.tbCenterCacheOffsetParams[6],
            false
        )
    elseif ExteriorCharacter.m_szViewPage == "Furniture" then
        ExteriorCharacter.tbCenterCacheOffsetParams = {FurnitureModelPreview_GetCameraOffset("CoinShop_View", "CoinShop")}
        FurnitureModelPreview_SetCameraOffset("CoinShop_View", "CoinShop", 0, 0, 0,
            ExteriorCharacter.tbCenterCacheOffsetParams[4],
            ExteriorCharacter.tbCenterCacheOffsetParams[5],
            ExteriorCharacter.tbCenterCacheOffsetParams[6],
            false
        )
    else
        ExteriorCharacter.szCenterCacheCameraMode = ExteriorCharacter.szCameraMode
        ExteriorCharacter.SetCameraMode("Center")
        local tCameraInfo = ExteriorCharacter.GetCameraInfo()
        FireUIEvent(
            "EXTERIOR_CHARACTER_SET_CAMERA_INFO",
            "CoinShop_View",
            "CoinShop",
            tCameraInfo
        )
    end
end

function ExteriorCharacter.RestoreCameraCenter()
    if not ExteriorCharacter.tbCenterCacheOffsetParams and not ExteriorCharacter.szCenterCacheCameraMode then
        return
    end
    if ExteriorCharacter.m_szViewPage == "Ride" then
        RidesModelPreview_SetCameraOffset("CoinShop_View", "CoinShop",
            ExteriorCharacter.tbCenterCacheOffsetParams[1],
            ExteriorCharacter.tbCenterCacheOffsetParams[2],
            ExteriorCharacter.tbCenterCacheOffsetParams[3],
            ExteriorCharacter.tbCenterCacheOffsetParams[4],
            ExteriorCharacter.tbCenterCacheOffsetParams[5],
            ExteriorCharacter.tbCenterCacheOffsetParams[6],
            false
        )
    elseif ExteriorCharacter.m_szViewPage == "Pet" then
        NpcModelPreview_SetCameraOffset("CoinShop_View", "CoinShop",
            ExteriorCharacter.tbCenterCacheOffsetParams[1],
            ExteriorCharacter.tbCenterCacheOffsetParams[2],
            ExteriorCharacter.tbCenterCacheOffsetParams[3],
            ExteriorCharacter.tbCenterCacheOffsetParams[4],
            ExteriorCharacter.tbCenterCacheOffsetParams[5],
            ExteriorCharacter.tbCenterCacheOffsetParams[6],
            false
        )
    elseif ExteriorCharacter.m_szViewPage == "Furniture" then
        FurnitureModelPreview_SetCameraOffset("CoinShop_View", "CoinShop",
            ExteriorCharacter.tbCenterCacheOffsetParams[1],
            ExteriorCharacter.tbCenterCacheOffsetParams[2],
            ExteriorCharacter.tbCenterCacheOffsetParams[3],
            ExteriorCharacter.tbCenterCacheOffsetParams[4],
            ExteriorCharacter.tbCenterCacheOffsetParams[5],
            ExteriorCharacter.tbCenterCacheOffsetParams[6],
            false
        )
    else
        ExteriorCharacter.SetCameraMode(ExteriorCharacter.szCenterCacheCameraMode)
        local tCameraInfo = ExteriorCharacter.GetCameraInfo()
        FireUIEvent(
            "EXTERIOR_CHARACTER_SET_CAMERA_INFO",
            "CoinShop_View",
            "CoinShop",
            tCameraInfo
        )
    end
    ExteriorCharacter.tbCenterCacheOffsetParams = nil
    ExteriorCharacter.szCenterCacheCameraMode = nil
end

function ExteriorCharacter.SetViewPage(szViewPage)
    ExteriorCharacter.m_szViewPage = szViewPage
end

function ExteriorCharacter.GetViewPage()
    return ExteriorCharacter.m_szViewPage
end

function ExteriorCharacter.SetLogicPage(szLogicPage)
    ExteriorCharacter.m_szLogicPage = szLogicPage
end

function ExteriorCharacter.GetLogicPage()
    return ExteriorCharacter.m_szLogicPage
end

RegisterExteriorCharacterEvent("CoinShop_View")
RegisterRidesModelEvent("CoinShop_View")
RegisterNpcModelEvent("CoinShop_View")
RegisterFurnitureModelEvent("CoinShop_View")

--------------------CoinShop_View-end----------------------------------


--------------------CoinShopView-------------------------------
ExteriorCharacter.m_tRoleInitData = {}
ExteriorCharacter.m_tRoleViewData = {}
ExteriorCharacter.m_tRoleViewMultiData = {}
ExteriorCharacter.m_tPetViewData = {}
ExteriorCharacter.m_tRideViewData = {}
ExteriorCharacter.m_tRideViewMultiData = {}
ExteriorCharacter.m_tFurnitureViewData = {}
ExteriorCharacter.m_tRepresentID = {}
ExteriorCharacter.m_bClearRole = false
ExteriorCharacter.m_bInitRole = false
ExteriorCharacter.m_nWeaponType = nil
ExteriorCharacter.m_bWeaponShow = false
ExteriorCharacter.FURNITURE_POS = "0;0;0"
ExteriorCharacter.m_Replace = true

function ExteriorCharacter.InitView()
    FireUIEvent("COINSHOP_INIT_ROLE", true, true)
    FireUIEvent("COINSHOP_INIT_RIDE", false)
    FireUIEvent("COINSHOP_INIT_PET", false)
    FireUIEvent("COINSHOP_INIT_FURNITURE", false)
end

function ExteriorCharacter.GetRoleData()
    return ExteriorCharacter.m_tRoleViewData
end

function ExteriorCharacter.GetCurrentOutfit()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tOutfit = {}
    local tOuftifData = {}

    local tRoleData = ExteriorCharacter.GetRoleData()
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    for nIndex, tData in pairs(tRoleData) do
        local nSub = Exterior_BoxIndexToExteriorSub(nIndex)
        if nSub then
            if tData.dwID > 0 then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID})
            end
        --elseif nIndex == COINSHOP_BOX_INDEX.ITEM then -- item did not save
        elseif nIndex == COINSHOP_BOX_INDEX.HAIR then
            local nHairID = ExteriorCharacter.m_tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
            local nDyeIndex = GetEquippedHairCustomDyeingIndex(nHairID)
            local tColorID = {nDyeIndex}
            table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.nHairID, tColorID = tColorID})
        elseif nIndex == COINSHOP_BOX_INDEX.FACE and not tRoleData.bNewFace then
            if tData.bUseLiftedFace then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.UserData.nIndex, bUseLiftedFace = true})
            else
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.nFaceID, bUseLiftedFace = false})
            end
        elseif nIndex == COINSHOP_BOX_INDEX.NEW_FACE and tRoleData.bNewFace then
            table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.nFaceID})
        elseif nIndex == COINSHOP_BOX_INDEX.PENDANT_PET then
            if tData.tItem.dwIndex > 0 then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.tItem.dwIndex})
            end
        elseif CoinShop_BoxIndexToPendantType(nIndex) then
            if tData.tItem.dwIndex > 0 then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.tItem.dwIndex, tColorID = tData.tItem.tColorID})
            end
        elseif tWeaponBox[nIndex] then
            if tData.dwID > 0 then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.dwID})
            end
        elseif nIndex == COINSHOP_BOX_INDEX.BODY then
            if tData.nBody > 0 then
                table.insert(tOuftifData, {nIndex = nIndex, dwID = tData.nBody})
            end
        end
    end

    local fnSortByIndex = function(tLeft, tRight)
        return tLeft.nIndex < tRight.nIndex
    end

    table.sort(tOuftifData, fnSortByIndex)
    tOutfit.tData = tOuftifData
    tOutfit.bHideHat = hPlayer.bHideHat

    return tOutfit
end

function ExteriorCharacter.GetHatStyle()
    if not g_pClientPlayer then
        return
    end

    return Role_GetHatStyle(g_pClientPlayer.bHideHair)
end

function ExteriorCharacter.GetRoleRes()
    if not g_pClientPlayer then
        return
    end

    ExteriorCharacter.m_tRepresentID.nHatStyle = ExteriorCharacter.GetHatStyle()
    ExteriorCharacter.m_tRepresentID.bHideFacePendent = g_pClientPlayer.bHideFacePendent
    return ExteriorCharacter.m_tRepresentID
end

function ExteriorCharacter.SetWeaponShow(bShow, bUpdate)
    if ExteriorCharacter.m_bWeaponShow == bShow then
        return
    end
    ExteriorCharacter.m_bWeaponShow = bShow
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.GetWeaponType()
    return ExteriorCharacter.m_nWeaponType
end

function ExteriorCharacter.IsWeaponShow()
    return ExteriorCharacter.m_bWeaponShow
end

local function GetAllBit1(nCount)
    local nNum = 0
    for i = 1, nCount do
        nNum = kmath.add_bit(nNum, i)
    end
    return nNum
end

function ExteriorCharacter.GetChestHideFlag(dwID, hPlayer, hExterior)
    if not hExterior then
        hExterior = GetExterior()
    end
    local nFlag = 0
    local nCanHideCount 		= hExterior.GetSubsetCanHideCount(dwID)
    if nCanHideCount > 0 then
        local nHideFlag         = hPlayer.GetExteriorSubsetHideFlag(dwID)
        nFlag = nHideFlag
        return true, nFlag
    end
    return false, nFlag
end

function ExteriorCharacter.GetHairHideFlag(dwID, hPlayer)
    local hHairShop = GetHairShop()
    if not hHairShop then
        return
    end
    local nFlag = 0
    local nRoleType = Player_GetRoleType(hPlayer)
    local nCount = hHairShop.GetSubsetCanHideCount(nRoleType, dwID)
    if nCount > 0 then
        nFlag = hPlayer.GetHairSubsetHideFlag(dwID)
        return true, nFlag
    end
    return false, nFlag
end

function ExteriorCharacter.GetExteriorSubsetHideFlag(dwExteriorID, nSubSetType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if dwExteriorID == 0 then
        ExteriorCharacter.m_tRepresentID[nSubSetType] = 0
        if nSubSetType == EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK then
            m_bCanHideChest = false
        elseif nSubSetType == EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK then
            m_bCanHideHair = false
        end
    else
        local nFlag
        if nSubSetType == EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK then
            m_bCanHideChest, nFlag = ExteriorCharacter.GetChestHideFlag(dwExteriorID, hPlayer)
        elseif nSubSetType == EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK then
            m_bCanHideHair, nFlag = ExteriorCharacter.GetHairHideFlag(dwExteriorID, hPlayer)
        end

        ExteriorCharacter.m_tRepresentID[nSubSetType] = nFlag
    end
end

--获取是否可以隐藏
function ExteriorCharacter.GetCanHideSubsetFlag()
    return m_bCanHideChest, m_bCanHideHair
end

--设置隐藏与否
function ExteriorCharacter.SetExteriorSubsetHideFlag(nSubSetTpye, nFlag)
    -- if bHide then
        ExteriorCharacter.m_tRepresentID[nSubSetTpye] = nFlag or 0
    -- else
    --     ExteriorCharacter.m_tRepresentID[nSubSetTpye] = 0
    -- end

    -- if nSubSetTpye == EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK then
    --     ExteriorCharacter.m_tRoleViewData[COINSHOP_BOX_INDEX.CHEST].bSubsetHide = bHide
    --     ExteriorCharacter.m_tRoleViewMultiData[COINSHOP_BOX_INDEX.CHEST].bSubsetHide = bHide
    -- elseif nSubSetTpye ==EQUIPMENT_REPRESENT.Hair_SUBSET_HIDE_MASK then
    --     ExteriorCharacter.m_tRoleViewData[COINSHOP_BOX_INDEX.HAIR].bSubsetHide = bHide
    --     ExteriorCharacter.m_tRoleViewMultiData[COINSHOP_BOX_INDEX.HAIR].bSubsetHide = bHide
    -- end

    --FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    FireUIEvent("EXTERIOR_CHARACTER_PLAY_SUBSET_VISIABLE", "CoinShop_View", "CoinShop", nSubSetTpye, ExteriorCharacter.m_tRepresentID[nSubSetTpye])
end

function ExteriorCharacter.ResetHairDyeingData()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nHair = ExteriorCharacter.m_tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
    local nHairDyeingIndex = hPlayer.GetEquippedHairCustomDyeingIndex(nHair)
    ExteriorCharacter.GetHairDyeingData(nHair, nHairDyeingIndex)
    FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
end

--获得头发的染色
function ExteriorCharacter.GetHairDyeingData(nHairID, nHairDyeingIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if nHairDyeingIndex then
        ExteriorCharacter.m_tRepresentID.tHairDyeingData = ExteriorCharacter.GetHairDyeingIndexData(nHairID, nHairDyeingIndex)
    else
        ExteriorCharacter.m_tRepresentID.tHairDyeingData = hPlayer.GetEquippedHairCustomDyeingData(nHairID)
    end
    ExteriorCharacter.m_tRoleViewData.nHairDyeingIndex = nHairDyeingIndex
    FireUIEvent("ON_HAIRDYEING_CHANGED")
end

--获得头发的某个Index的data
function ExteriorCharacter.GetHairDyeingIndexData(nHairID, nIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tList = hPlayer.GetHairCustomDyeingList(nHairID)
    if not tList or not tList[nIndex] then
        return
    end
    return tList[nIndex]
end

--设置头发的染色
function ExteriorCharacter.SetHairDyeingData(nHairID, tHairDyeingData)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    if tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] ~= nHairID then
        return
    end
    ExteriorCharacter.m_tRepresentID.tHairDyeingData = tHairDyeingData

    FireUIEvent("EXTERIOR_CHARACTER_SET_HAIR_DYEING_DATA", "CoinShop_View", "CoinShop", tHairDyeingData)
end

function ExteriorCharacter.GetHairDyeingIndex()
    return ExteriorCharacter.m_tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE], ExteriorCharacter.m_tRoleViewData.nHairDyeingIndex
end

function ExteriorCharacter.PreviewRewards(dwID, tViewItems)
    local tItem = Table_GetRewardsItem(dwID)
    ExteriorCharacter.PreviewRewardsItem(tItem, tViewItems)
end

function ExteriorCharacter.IsRewardsPreview(tItem)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local bPreview = false
    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE
    then
        bPreview = ExteriorCharacter.IsHorsePreview(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP
    then
        bPreview = ExteriorCharacter.IsHAdornmentPreview(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.PET
    then
        bPreview = ExteriorCharacter.IsPetPreview(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(hItemInfo) then
        bPreview = ExteriorCharacter.IsPendantPreview(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(hItemInfo) then
        bPreview = ExteriorCharacter.IsPendantPetPreview(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
        bPreview = ExteriorCharacter.IsViewLimitItemPreview(hItemInfo, tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.HOMELAND then
        bPreview = ExteriorCharacter.IsFurniturePreview(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.DESIGNATION and IsDesignationEffectSfxItem(tItem) then
        bPreview = ExteriorCharacter.IsEffectPreviewItem(tItem)
    else
        bPreview = ExteriorCharacter.IsViewItemPreview(tItem)
    end

    return bPreview
end

function ExteriorCharacter.PreviewRewardsItem(tItem, tViewItems)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE
    then
        FireUIEvent("PREVIEW_HORSE", tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP
    then
        FireUIEvent("PREVIEW_HORSE_ADORNMENT", tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.PET
    then
        FireUIEvent("PREVIEW_PET", tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(hItemInfo) then
        ExteriorCharacter.PreviewRewardsPendant(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(hItemInfo) then
        ExteriorCharacter.PreviewRewardsPendantPet(tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
        ExteriorCharacter.PreviewLimitItem(hItemInfo, tItem, tViewItems)
    elseif hItemInfo.nGenre == ITEM_GENRE.HOMELAND then
        FireUIEvent("PREVIEW_FURNITURE", tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.DESIGNATION and IsDesignationEffectSfxItem(tItem) then
        ExteriorCharacter.PreviewRewardsEffectSfx(tItem)
    else
        ExteriorCharacter.PreviewViewItem(tItem)
    end

    FireUIEvent("ON_PREVIEW_REWARDS_ITEM")
end


function ExteriorCharacter.PreviewLimitItem(hItemInfo, tItem, tViewItems)
    local szViewType = "Role"
    if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
        ExteriorCharacter.PreviewRewardsPendant(tItem, true)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
        ExteriorCharacter.PreviewRewardsPendantPet(tItem, true)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
        ExteriorCharacter.PreviewLimitExterior(hItemInfo.nDetail, tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
        ExteriorCharacter.PreviewLimitHair(hItemInfo.nDetail, tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PACK then
        ExteriorCharacter.PreviewMultiItem(hItemInfo.nDetail, tItem, tViewItems)
        szViewType = nil
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE then
        ExteriorCharacter.PreviewHorse(tItem, true, true, false)
        szViewType = "Ride"
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE_EQUIP then
        ExteriorCharacter.PreviewHorseAdornment(tItem, true, true, false)
        szViewType = "Ride"
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FELLOW_PET then
        ExteriorCharacter.PreviewPet(tItem, true)
        szViewType = "Pet"
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FURNITURE then
        ExteriorCharacter.PreviewFurniture(tItem, true)
        szViewType = "Furniture"
    else
        ExteriorCharacter.PreviewViewItem(tItem)
    end

    if szViewType then
        FireUIEvent("COINSHOP_SHOW_VIEW", szViewType, false)
    end
end

function ExteriorCharacter.PreviewMultiItem(nID, tItem, tCustomMultiItem)
    local tMultiItem
    if tCustomMultiItem then
        tMultiItem = tCustomMultiItem
    else
        tMultiItem =  CoinShop_GetLimitView(nID)
        ExteriorCharacter.SetRepresentReplace(true)
    end
    local szViewType = "Role"
    for _, tViewItem in ipairs(tMultiItem) do
        if tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID}
            ExteriorCharacter.PreviewRewardsPendant(tNewItem, true, true)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID}
            ExteriorCharacter.PreviewRewardsPendantPet(tNewItem, true, true)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
            if tCustomMultiItem then
                ExteriorCharacter.PreviewLimitExterior(tViewItem.dwLogicID, tItem, true, tViewItem)
            else
                ExteriorCharacter.PreviewLimitExterior(tViewItem.dwLogicID, tItem, true)
            end
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
            ExteriorCharacter.PreviewLimitHair(tViewItem.dwLogicID, tItem, true)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE then
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID}
            ExteriorCharacter.PreviewHorse(tNewItem, true, true, true)
            szViewType = "Ride"
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE_EQUIP then
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID}
            ExteriorCharacter.PreviewHorseAdornment(tNewItem, true, true, true)
            szViewType = "Ride"
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FELLOW_PET then
            local tLine = Table_GetRewardsItem(tViewItem.dwLogicID)
            if not tLine then
                return
            end
            -- local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID, nPetIndex = tLine.nPetIndex, dwLogicID = tItem.dwLogicID}
            local tNewItem = {dwTabType = tLine.dwTabType, dwIndex = tLine.dwIndex, nPetIndex = tLine.nPetIndex, dwLogicID = tItem.dwLogicID, tPetItem = tItem}
            ExteriorCharacter.PreviewPet(tNewItem, true)
            szViewType = "Pet"
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FURNITURE then
            local hItemInfo = GetItemInfo(tViewItem.dwItemType, tViewItem.dwItemID)
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID, dwFurnitureID = hItemInfo.dwFurnitureID, dwLogicID = tItem.dwLogicID}
            ExteriorCharacter.PreviewFurniture(tNewItem, true)
            szViewType = "Furniture"
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.IDLE_ACTION then
            ExteriorCharacter.PreviewAniID(tViewItem.dwLogicID, nil, true)
        end
    end

    if szViewType == "Role" then
        ExteriorCharacter.PreviewViewItem(tItem)
    elseif szViewType == "Ride" then
        FireUIEvent("PREVIEW_HORSE_ITEM", tItem, true)
    end
    FireUIEvent("COINSHOP_SHOW_VIEW", szViewType, false)
end

function ExteriorCharacter.CancalPreviewRewardsByID(dwID, tCustomMultiItem)
    local tItem = Table_GetRewardsItem(dwID)
    ExteriorCharacter.CancelPreviewRewards(tItem, tCustomMultiItem)
end

function ExteriorCharacter.CancelPreviewRewards(tItem, tCustomMultiItem, bMaybeMulti)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE
    then
        FireUIEvent("CANCEL_PREVIEW_HORSE")
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP
    then
        FireUIEvent("CANCEL_PREVIEW_HORSE_ADORNMENT", tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
        hItemInfo.nSub == EQUIPMENT_SUB.PET
    then
        --pet does not need cancle preview
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantItem(hItemInfo) then
        FireUIEvent("CANCEL_PREVIEW_PENDANT", tItem, nil, nil, true, bMaybeMulti)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and IsPendantPetItem(hItemInfo) then
        FireUIEvent("CANCEL_PREVIEW_PENDANT_PET", tItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
        ExteriorCharacter.CancelPreviewLimitItem(hItemInfo, tItem, tCustomMultiItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.HOMELAND then
        --furniture does not need cancle preview
    elseif hItemInfo.nGenre == ITEM_GENRE.DESIGNATION and IsDesignationEffectSfxItem(tItem) then
        local nType, nEffectID = ExteriorCharacter.GetRewardsEffectSfxType(tItem)
        FireUIEvent("RESET_ONE_EFFECT_SFX", nType)
    else
        ExteriorCharacter.CancelPreviewItem(true)
    end

    FireUIEvent("ON_CANCEL_PREVIEW_REWARDS")
end

function ExteriorCharacter.CancelPreviewLimitItem(hItemInfo, tItem, tCustomMultiItem)
    if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
        FireUIEvent("CANCEL_PREVIEW_PENDANT", tItem, true, false)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
        FireUIEvent("CANCEL_PREVIEW_PENDANT_PET", tItem, true, false)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
        ExteriorCharacter.CancelLimitExterior(hItemInfo.nDetail, tItem, false)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
        ExteriorCharacter.CancelLimitHair()
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PACK then
        ExteriorCharacter.CancelPreviewMultiItem(hItemInfo.nDetail, tItem, tCustomMultiItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE then
        ExteriorCharacter.CancelPreviewHorse()
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE_EQUIP then
        ExteriorCharacter.CancelPreviewAdornment(tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FELLOW_PET then
        -- 宠物无法取消预览
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FURNITURE then
        -- 家具无法取消预览
    else
        ExteriorCharacter.CancelPreviewItem(true)
    end
end

function ExteriorCharacter.CancelPreviewMultiItem(nID, tItem, tCustomMultiItem)
    local tMultiItem
    if tCustomMultiItem then
        tMultiItem = tCustomMultiItem
    else
        tMultiItem = CoinShop_GetLimitView(nID)
    end
    local szViewType = "Role"
    for _, tViewItem in ipairs(tMultiItem) do
        if tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID}
            FireUIEvent("CANCEL_PREVIEW_PENDANT", tNewItem, true, true)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENTP_PET then
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID}
            FireUIEvent("CANCEL_PREVIEW_PENDANT_PET", tNewItem, true, true)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
            ExteriorCharacter.CancelLimitExterior(tViewItem.dwLogicID, tItem, true)
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
            ExteriorCharacter.CancelLimitHair()
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE then
            ExteriorCharacter.CancelPreviewHorse()
            szViewType = "Ride"
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE_EQUIP then
            local tNewItem = {dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = tViewItem.dwLogicID}
            ExteriorCharacter.CancelPreviewAdornment(tNewItem)
            szViewType = "Ride"
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FELLOW_PET then
            szViewType = "Pet"
            -- 宠物无法取消预览
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FURNITURE then
            szViewType = "Furniture"
            -- 家具无法取消预览
        elseif tViewItem.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.IDLE_ACTION then
            ExteriorCharacter.InitPosture()
        end
    end
    if szViewType == "Role" then
        if not tCustomMultiItem then
            ExteriorCharacter.CancelPreviewItem(true)
        end
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    elseif szViewType == "Ride" then
        if not tCustomMultiItem then
            ExteriorCharacter.CancelPreviewHorseItem(true)
        end
    end
end

function ExteriorCharacter.IsViewLimitItemPreview(hItemInfo, tItem)
    if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
        return ExteriorCharacter.IsPendantPreview(tItem, true)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
        return ExteriorCharacter.IsPendantPetPreview(tItem, true)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
        return ExteriorCharacter.IsLimitExteriorPreview(hItemInfo, tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
        return ExteriorCharacter.IsLImitHairPreview(hItemInfo, tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE then
        return ExteriorCharacter.IsHorsePreview(tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE_EQUIP then
        return ExteriorCharacter.IsHAdornmentPreview(tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FELLOW_PET then
        return ExteriorCharacter.IsPetPreview(tItem)
    elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.FURNITURE then
        return ExteriorCharacter.IsFurniturePreview(tItem)
    else
        local bPreview = ExteriorCharacter.IsViewItemPreview(tItem)
        if not bPreview then
            bPreview = ExteriorCharacter.IsHorseItemPreview(tItem)

        end
        return bPreview
    end

    return false
end

function ExteriorCharacter.PreviewLimitExterior(dwExteriorID, tItem, bMultiPreview, tReplaceRepresent)
    if not g_pClientPlayer then
        return
    end

    ExteriorCharacter.ScaleToPos(tItem)

    if bMultiPreview then
        FireUIEvent("PREVIEW_SUB", dwExteriorID, tItem, false, bMultiPreview, tReplaceRepresent)
    else
        local tNewItem = {}
        tNewItem.dwTabType = tItem.dwTabType
        tNewItem.dwIndex = tItem.dwIndex
        tNewItem.dwLogicID = tItem.dwLogicID
        FireUIEvent("PREVIEW_SUB", dwExteriorID, tNewItem, true, bMultiPreview)
    end
end

function ExteriorCharacter.CancelLimitExterior(dwExteriorID, tItem, bMultiPreview)

    local tNewItem = {}
    tNewItem.dwTabType = tItem.dwTabType
    tNewItem.dwIndex = tItem.dwIndex
    tNewItem.dwLogicID = tItem.dwLogicID

    FireUIEvent("CANCEL_PREVIEW_SUB", dwExteriorID, not bMultiPreview, tNewItem, bMultiPreview)
end

function ExteriorCharacter.IsLimitExteriorPreview(hItemInfo, tItem)
    local dwExteriorID = hItemInfo.nDetail
    local tNewItem = {}
    tNewItem.dwTabType = tItem.dwTabType
    tNewItem.dwIndex = tItem.dwIndex
    tNewItem.dwLogicID = tItem.dwLogicID

    return ExteriorCharacter.IsSubPreview(dwExteriorID, tNewItem)
end

function ExteriorCharacter.PreviewLimitHair(nHairID, tItem, bMultiPreview)
    local tNewItem = {}
    tNewItem.dwTabType = tItem.dwTabType
    tNewItem.dwIndex = tItem.dwIndex
    tNewItem.dwLogicID = tItem.dwLogicID

    FireUIEvent("PREVIEW_HAIR", nHairID, tNewItem, not bMultiPreview, true, bMultiPreview)

    ExteriorCharacter.ScaleToPos(tItem)
end

function ExteriorCharacter.CancelLimitHair()
    FireUIEvent("RESET_HAIR")
end

function ExteriorCharacter.IsLImitHairPreview(hItemInfo, tItem)
    local nHairID = hItemInfo.nDetail
    return ExteriorCharacter.IsHairPreview(nHairID, tItem)

end
function ExteriorCharacter.PreviewRewardsPendant(tItem, bLimitItem, bMultiPreview)
    FireUIEvent("PREVIEW_PENDANT", tItem, bLimitItem, bMultiPreview)
    ExteriorCharacter.ScaleToPos(tItem)
end

function ExteriorCharacter.PreviewRewardsPendantPet(tItem, bLimitItem, bMultiPreview)
    FireUIEvent("PREVIEW_PENDANT_PET", tItem, bLimitItem, bMultiPreview)
    ExteriorCharacter.ScaleToPos(tItem)
end

function ExteriorCharacter.PreviewViewItem(tItem)
    FireUIEvent("PREVIEW_ITEM", tItem, true)
    ExteriorCharacter.ScaleToPos(tItem)
end

function ExteriorCharacter.ResUpdate_Body(tBody, nBody)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.tBody = tBody
    if nBody then
        tRepresentID.nBody = nBody
    end
end

function ExteriorCharacter.PreviewBody(nBody, tBody, bRefresh)
    ExteriorCharacter.ClearPreviewAniIDInShop()

    local nIndex = COINSHOP_BOX_INDEX.BODY

    tBody.nBody = nBody or ExteriorCharacter.m_tRoleViewData[nIndex].nBody
    ExteriorCharacter.m_tRoleViewData[nIndex] = tBody

    ExteriorCharacter.ResUpdate_Body(tBody, nBody)
    if bRefresh then
        FireUIEvent("ON_PREVIEW_BODY")
    end
    FireUIEvent("EXTERIOR_CHARACTER_UPDATE_BODY", "CoinShop_View", "CoinShop", tBody)
    FireUIEvent("ON_BODY_CHANGED")
end

function ExteriorCharacter.SetNewFaceData(nFaceID, tData)
    local nIndex = COINSHOP_BOX_INDEX.NEW_FACE
    if not ExteriorCharacter.m_tRoleViewData[nIndex] then
        ExteriorCharacter.m_tRoleViewData[nIndex] = {}
    end
    tData.nFaceID = nFaceID or ExteriorCharacter.m_tRoleViewData[nIndex].nFaceID
    ExteriorCharacter.m_tRoleViewData[nIndex] = clone(tData)
    ExteriorCharacter.ChangeFaceType(true)
end

function ExteriorCharacter.SetEmptyNewFaceData()
    local nIndex = COINSHOP_BOX_INDEX.NEW_FACE

    ExteriorCharacter.m_tRoleViewData[nIndex] = {}
end

function ExteriorCharacter.PreviewNewFace(nFaceID, tNewFace, bRefresh)
    ExteriorCharacter.ClearPreviewAniIDInShop()

    local bOriginIsNewFace = ExteriorCharacter.IsNewFace()

    ExteriorCharacter.SetNewFaceData(nFaceID, tNewFace)
    ExteriorCharacter.ResUpdate_NewFace(tNewFace)

    FireUIEvent("ON_NEW_FACE_LIFT_CHANGED")
    if bRefresh then
        if bOriginIsNewFace then
            local hModel = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
            local hPlayer = GetClientPlayer()
            if not hPlayer then
                return
            end
            local nRoleType = hPlayer.nRoleType
            hModel:SetFaceDefinition(tNewFace.tBone, nRoleType, tNewFace.tDecal, tNewFace.tDecoration, true)
        else
            FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
        end
    end

    FireUIEvent("ON_PREVIEW_NEW_FACE")
end

function ExteriorCharacter.UpdateNewFace(nFaceID, tNewFace)
    local bOriginIsNewFace = ExteriorCharacter.IsNewFace()
    ExteriorCharacter.SetNewFaceData(nFaceID, tNewFace)
    ExteriorCharacter.ResUpdate_NewFace(tNewFace)
end

function ExteriorCharacter.UpdateNewFaceDecal(tDecal)
    local nIndex = COINSHOP_BOX_INDEX.NEW_FACE
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    tData.tDecal = clone(tDecal)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.tFaceData = tData
end

function ExteriorCharacter.UpdateNewFaceBoneParams(tBone)
    local nIndex = COINSHOP_BOX_INDEX.NEW_FACE
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    tData.tBone = clone(tBone)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.tFaceData = tData
end

function ExteriorCharacter.UpdateNewFaceDecoration(tDecoration)
    local nIndex = COINSHOP_BOX_INDEX.NEW_FACE
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    tData.tDecoration = clone(tDecoration)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.tFaceData = tData
end

function ExteriorCharacter.InitRole(bIncludeFacelift, bUpdate)
    if not g_pClientPlayer then
        return
    end

    local bFaceModify
    ExteriorCharacter.m_bInitRole = true
    local tRepresentID = g_pClientPlayer.GetRepresentID()

    tRepresentID.tBody = g_pClientPlayer.GetEquippedBodyBoneData()
    tRepresentID.nBody = g_pClientPlayer.GetEquippedBodyBoneIndex()
    tRepresentID.bUseLiftedFace = g_pClientPlayer.bEquipLiftedFace
    ExteriorCharacter.m_tRepresentID = tRepresentID
    ExteriorCharacter.m_tRoleViewData = {}

    local tExteriorData = SelfieTemplateBase.GetPlayerExteriorData(GetClientPlayer())
    if tExteriorData then
        ExteriorCharacter.m_tRoleInitData = tExteriorData.tExteriorID
    end

    ExteriorCharacter.InitExterior()
    ExteriorCharacter.InitWeapon()
    ExteriorCharacter.InitPendant()
    ExteriorCharacter.InitPendantPet()
    ExteriorCharacter.InitItem()
    ExteriorCharacter.InitHair()
    ExteriorCharacter.InitBody()
    ExteriorCharacter.InitFace(bIncludeFacelift)
    ExteriorCharacter.InitPosture()
    -- ExteriorCharacter.InitEffectSfx()

    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
    ExteriorCharacter.m_bInitRole = false
end

function ExteriorCharacter.IsInitRole()
    return ExteriorCharacter.m_bInitRole
end

function ExteriorCharacter.ClearRole(bUpdate)
    if not g_pClientPlayer then
        return
    end

    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end

    local tRepresentID = ExteriorCharacter.m_tRepresentID

    tRepresentID.bUseLiftedFace = g_pClientPlayer.bEquipLiftedFace

    ExteriorCharacter.m_tRepresentID = tRepresentID
    ExteriorCharacter.m_tRoleViewData = {}
    ExteriorCharacter.m_tRoleViewMultiData = {}

    local tFaceData = g_pClientPlayer.GetEquipLiftedFaceData()
    local nIndex = hManager.GetEquipedIndex()
    if tFaceData and tFaceData.bNewFace then
        ExteriorCharacter.InitNewFace(nIndex, tFaceData)
    else
        tRepresentID.tFaceData = tFaceData
        tRepresentID.nEquipIndex = nIndex
        ExteriorCharacter.InitOldFace(tRepresentID.bUseLiftedFace)
    end

    ExteriorCharacter.m_bClearRole = true
    ExteriorCharacter.ClearExterior()
    ExteriorCharacter.ClearAllWeapon()
    ExteriorCharacter.ClearAllPendant()
    ExteriorCharacter.ClearAllPendantPet()
    ExteriorCharacter.InitItem()
    ExteriorCharacter.InitHair()
    ExteriorCharacter.InitPosture()
    ExteriorCharacter.m_bClearRole = false
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.InitExterior()
    if not g_pClientPlayer then
        return
    end

    local nCurrentSetID = g_pClientPlayer.GetCurrentSetID()
    local tExteriorSet = g_pClientPlayer.GetExteriorSet(nCurrentSetID)
    for i = 1, EXTERIOR_SUB_NUMBER do
        local nExteriorSub  = Exterior_BoxIndexToExteriorSub(i)
        local dwExteriorID = tExteriorSet[nExteriorSub]
        if dwExteriorID <= 0 then
            ExteriorCharacter.ClearSub(i, false)
        else
            ExteriorCharacter.PreviewSub(dwExteriorID, nil, false)
        end
    end
end

function ExteriorCharacter.ClearExterior()
    for i = 1, EXTERIOR_SUB_NUMBER do
        ExteriorCharacter.ClearSub(i, false)
    end
end

function ExteriorCharacter.InitWeapon()
    if not g_pClientPlayer then
        return
    end

    local nCurrentSetID = g_pClientPlayer.GetCurrentSetID()
    local tWeaponExterior = g_pClientPlayer.GetWeaponExteriorSet(nCurrentSetID)
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    for i, nWeaponSub in pairs(tWeaponBox) do
        local dwWeaponID = tWeaponExterior[nWeaponSub]
        if dwWeaponID <= 0 then
            ExteriorCharacter.ClearWeapon(i, false)
        else
            ExteriorCharacter.PreviewWeapon(dwWeaponID, false)
        end
    end
end

function ExteriorCharacter.ClearAllWeapon()
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    for i, nWeaponSub in pairs(tWeaponBox) do
        ExteriorCharacter.ClearWeapon(i, false)
    end
end

function ExteriorCharacter.InitPendant()
    if not g_pClientPlayer then
        return
    end

    for nPendantPos = 0, PENDENT_SELECTED_POS.TOTAL - 1 do
        local nBoxIndex = CoinShop_PendantTypeToBoxIndex(nPendantPos)
        if nBoxIndex then
            local dwIndex = g_pClientPlayer.GetSelectPendent(nPendantPos)
            local tItem = {}
            tItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
            tItem.dwIndex = dwIndex
            if dwIndex <= 0 then
                local nRepresentSub = Exterior_BoxIndexToRepresentSub(nBoxIndex)
                ExteriorCharacter.ClearPendant(nRepresentSub, false)
            else
                local tColorID = GetPendantColor(tItem.dwTabType, tItem.dwIndex)
                tItem.tColorID = tColorID
                ExteriorCharacter.PreviewPendant(tItem, nil, nil, false, nPendantPos)
            end
        end
    end
end

function ExteriorCharacter.ClearAllPendant()
   for nPendantType = 0, PENDENT_SELECTED_POS.TOTAL - 1 do
        local nRepresentSub = CoinShop_PendantTypeToRepresentSub(nPendantType)
        if nRepresentSub then
            ExteriorCharacter.ClearPendant(nRepresentSub, false)
        end
    end
end

function ExteriorCharacter.InitPendantPet()
    if not g_pClientPlayer then
        return
    end

    local nBoxIndex = COINSHOP_BOX_INDEX.PENDANT_PET
    local dwIndex, dwCurrentPos = g_pClientPlayer.GetEquippedPendentPet()
    local tItem = {}
    tItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    tItem.dwIndex = dwIndex
    tItem.nPos = dwCurrentPos

    if dwIndex <= 0 then
        ExteriorCharacter.ClearPendantPet(false)
    else
        ExteriorCharacter.PreviewPendantPet(tItem, nil, nil, false)
    end
end

function ExteriorCharacter.ClearAllPendantPet()
    ExteriorCharacter.ClearPendantPet(false)
end

function ExteriorCharacter.InitHair()
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]

    ExteriorCharacter.PreviewHair(nHairID, nil, false)
end

function ExteriorCharacter.InitOldFace(bModify)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    local nFaceID = tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
    local UserData = nil
    if tRepresentID.bUseLiftedFace and tRepresentID.tFaceData then
        UserData = {}
        UserData.tFaceData = tRepresentID.tFaceData
        UserData.nIndex = tRepresentID.nEquipIndex
    end
    ExteriorCharacter.PreviewFace(nFaceID, tRepresentID.bUseLiftedFace, UserData, bModify, false)
end

function ExteriorCharacter.InitFace(bIncludeFacelift)
    if not g_pClientPlayer then
        return
    end

    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end

    local nIndex = COINSHOP_BOX_INDEX.FACE
    local tFaceData = ExteriorCharacter.m_tRoleViewData[nIndex]
    local tOldRepresentID = ExteriorCharacter.m_tRepresentID
    local tRepresentID = ExteriorCharacter.m_tRepresentID

    local tPlayerFaceData = g_pClientPlayer.GetEquipLiftedFaceData()
    local nEquipIndex = hManager.GetEquipedIndex()
    if tPlayerFaceData and tPlayerFaceData.bNewFace then
        ExteriorCharacter.InitNewFace(nEquipIndex, tPlayerFaceData)
    else
         if bIncludeFacelift then
            tRepresentID.bUseLiftedFace = g_pClientPlayer.bEquipLiftedFace
            tRepresentID.tFaceData = tPlayerFaceData
            tRepresentID.nEquipIndex = nEquipIndex
            ExteriorCharacter.InitOldFace(true)
        elseif tOldRepresentID then
            ExteriorCharacter.ResUpdate_Face(tFaceData.nFaceID, tFaceData.bUseLiftedFace, tFaceData.UserData, tFaceData.bModify)
            ExteriorCharacter.m_tRoleViewData[nIndex] = tFaceData
        else
            ExteriorCharacter.m_tRoleViewData[nIndex] = tPlayerFaceData
        end
    end
end

function ExteriorCharacter.InitPosture()
    if not CoinShopData.IsInCoinShopWardrobe() then
        ExteriorCharacter.PreviewAniID(0)
    else
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local nPosture = hPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
        ExteriorCharacter.PreviewAniID(nPosture)
    end
end

function ExteriorCharacter.InitBody()
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    local tBody = tRepresentID.tBody
    ExteriorCharacter.PreviewBody(tRepresentID.nBody, tBody, true)

    FireUIEvent("ON_INIT_BODY", tBody)
end

function ExteriorCharacter.InitEffectSfx()
    local EFFECT_TYPE = CharacterEffectData.CoinShop_GetEffectTypeTable()
    for nType, _ in pairs(EFFECT_TYPE) do
        ExteriorCharacter.InitOneEffectSfx(nType)
    end
end

function ExteriorCharacter.InitOneEffectSfx(nType)
    local nEffectID = CharacterEffectData.GetEffectEquipByTypeLogic(nType)
    if nEffectID > 0 then
        ExteriorCharacter.PreviewEffect(nType, nEffectID)
    else
        ExteriorCharacter.ClearPreviewEffect(nType)
    end
end

function ExteriorCharacter.CancelEffectSfx()
    local EFFECT_TYPE = CharacterEffectData.CoinShop_GetEffectTypeTable()
    for nType, _ in pairs(EFFECT_TYPE) do
        ExteriorCharacter.CancelOneEffectSfx(nType)
    end
end

function ExteriorCharacter.CancelOneEffectSfx(nType)
    local nEffectID         = CharacterEffectData.GetEffectEquipByTypeLogic(nType)
    local tPreviewEffect    = ExteriorCharacter.GetPreviewEffect(nType)
    local nNowEffectID      = 0
    if tPreviewEffect then
        nNowEffectID        = tPreviewEffect.nEffectID
    end

    if nNowEffectID == 0 then
        return
    end

    local nPreviewID        = 0
    if nEffectID ~= nNowEffectID then
        nPreviewID          = nEffectID
    end

    if nPreviewID > 0 then
        ExteriorCharacter.PreviewEffect(nType, nPreviewID, nil, true)
    else
        ExteriorCharacter.ClearPreviewEffect(nType, true)
    end
end


function ExteriorCharacter.InitNewFace(nIndex, tNewFace)
    ExteriorCharacter.PreviewNewFace(nIndex, tNewFace)

    FireUIEvent("ON_INIT_NEW_FACE", tNewFace)
end

function ExteriorCharacter.InitItem()
    ExteriorCharacter.m_tRoleViewData[COINSHOP_BOX_INDEX.ITEM] = {}
end

function ExteriorCharacter.ResUpdate_Face(nFaceID, bUseLiftedFace, UserData, bModify)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    if bUseLiftedFace then
        tRepresentID.bUseLiftedFace = bUseLiftedFace
        tRepresentID.tFaceData = UserData.tFaceData
        tRepresentID.nEquipIndex = UserData.nIndex
    else
        tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE] = nFaceID
        tRepresentID.bUseLiftedFace = false
        tRepresentID.tFaceData = nil
        tRepresentID.nEquipIndex = nil
    end
end

function ExteriorCharacter.ResUpdate_NewFace(UserData)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.bUseLiftedFace = true
    tRepresentID.tFaceData = clone(UserData)
    tRepresentID.nEquipIndex = UserData.nIndex
    tRepresentID.bNewFace = true
end

function ExteriorCharacter.PreviewFace(nFaceID, bUseLiftedFace, UserData, bModify, bUpdate)
    ExteriorCharacter.ClearPreviewAniIDInShop()

    local nIndex = COINSHOP_BOX_INDEX.FACE

    local tData = {}
    tData.nFaceID = nFaceID
    tData.bUseLiftedFace = bUseLiftedFace
    if UserData then
        tData.UserData = clone(UserData)
    end
    tData.bModify = bModify

    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.ChangeFaceType(false)
    ExteriorCharacter.ResUpdate_Face(nFaceID, bUseLiftedFace, tData.UserData, bModify)

    FireUIEvent("ON_PREVIEW_FACE", nFaceID, bUseLiftedFace, UserData, bModify)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.InitHorseAdornment()
    if not g_pClientPlayer then
        return
    end
    for i = 1, HORSE_ADORNMENT_COUNT do
        local nRepresentID = EQUIPMENT_REPRESENT["HORSE_ADORNMENT" .. i]
        local nIndex = CoinShop_GetRideIndex(nRepresentID)
        local dwX = CoinShop_GetRideEquipIndex(nIndex)
        local hItem = g_pClientPlayer.GetEquippedHorseEquip(dwX)
        if hItem then
            local tItem = {}
            tItem.dwTabType = hItem.dwTabType
            tItem.dwIndex = hItem.dwIndex
            ExteriorCharacter.PreviewHorseAdornment(tItem, false)
        else
            local tRepresentID = ExteriorCharacter.m_tRepresentID
            ExteriorCharacter.m_tRideViewData[nIndex] = {}
            tRepresentID[nRepresentID] = 0
        end
    end
end

function ExteriorCharacter.PreviewHorseAdornment(tItem, bUpdate, bLimitItem, bMultiPreview)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hAdornment = hItemInfo

    local nHorseIndex = CoinShop_GetRideIndex(EQUIPMENT_REPRESENT.HORSE_STYLE)
    local tData = ExteriorCharacter.m_tRideViewData[nHorseIndex]
    if bMultiPreview then
        tData = ExteriorCharacter.m_tRideViewMultiData[nHorseIndex]
    end
    local tHorse = nil
    if tData then
        tHorse = tData.tItem
    end

    local bHaveHorse = tHorse ~= nil
    local tRepresentID = ExteriorCharacter.GetRoleRes()
    if tHorse then
        if tData.bHaveSpecialHorse then
            bHaveHorse = false
        end
    end

    if not bHaveHorse then
        local hItem = hPlayer.GetEquippedHorse()
        if not hItem or hItem.nDetail ~= 0 then
            ExteriorCharacter.ClearHorse(false)
        else
            ExteriorCharacter.InitHorse()
        end
    end
    local nRepresentSub = ExteriorView_GetRepresentSub(hAdornment.nSub, hAdornment.nDetail)
    tRepresentID[nRepresentSub] = hAdornment.nRepresentID
    local nIndex = CoinShop_GetRideIndex(nRepresentSub)
    if not tItem.dwLogicID  then
        local dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        tItem.dwLogicID = dwLogicID
    end

    local tData = {}
    local tNewItem = {}

    local tMultiData = {}
    local tNewMultiItem = {}

    if bMultiPreview then
        tNewItem.dwIndex = 0

        tNewMultiItem.dwTabType = tItem.dwTabType
        tNewMultiItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end

        tNewMultiItem.dwLogicID = dwLogicID
        tNewMultiItem.bLimitItem = bLimitItem
    else
        tNewItem.dwTabType = tItem.dwTabType
        tNewItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end

        tNewItem.dwLogicID = dwLogicID
        tNewItem.bLimitItem = bLimitItem

        tNewMultiItem.dwIndex = 0
    end
    tData.tItem = tNewItem
    tMultiData.tItem = tNewMultiItem

    ExteriorCharacter.m_tRideViewData[nIndex] = tData
    ExteriorCharacter.m_tRideViewMultiData[nIndex] = tMultiData
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPreviewAdornment(tItem)
    if not g_pClientPlayer then
        return
    end
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local tRepresentID = ExteriorCharacter.GetRoleRes()
    local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
    local nIndex = CoinShop_GetRideIndex(nRepresentSub)
    local dwX = CoinShop_GetRideEquipIndex(nIndex)
    local hCurrent = g_pClientPlayer.GetEquippedHorseEquip(dwX)
    local bClear = not hCurrent or hCurrent.dwIndex == tItem.dwIndex
    if bClear then
        tRepresentID[nRepresentSub] = 0
        ExteriorCharacter.m_tRideViewData[nIndex] = {}
        ExteriorCharacter.m_tRideViewMultiData[nIndex] = {}
    else
        local tItem = {}
        tItem.dwTabType = hCurrent.dwTabType
        tItem.dwIndex = hCurrent.dwIndex
        ExteriorCharacter.PreviewHorseAdornment(tItem, true)
    end
    FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
end

function ExteriorCharacter.IsHAdornmentPreview(tItem)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hAdornment = hItemInfo
    local nRepresentSub = ExteriorView_GetRepresentSub(hAdornment.nSub, hAdornment.nDetail)
    local nIndex = CoinShop_GetRideIndex(nRepresentSub)

    local tData = ExteriorCharacter.m_tRideViewData[nIndex]
    local tAdornment = tData.tItem
    if tAdornment and tAdornment.dwIndex == tItem.dwIndex then
        return true
    end

    return false
end

function ExteriorCharacter.ClearHorseAdornment(bUpdate)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    for i = 1, HORSE_ADORNMENT_COUNT do
        local nRepresentID = EQUIPMENT_REPRESENT["HORSE_ADORNMENT" .. i]
        local nIndex = CoinShop_GetRideIndex(nRepresentID)
        ExteriorCharacter.m_tRideViewData[nIndex] = {}
        tRepresentID[nRepresentID] = 0
    end
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
    end
end

function ExteriorCharacter.PreviewHorseAdornmentSet(tSub)
    for i, tItem in ipairs(tSub) do
        local bUpdate = i == #tSub
        ExteriorCharacter.PreviewHorseAdornment(tItem, bUpdate)
    end
end

function ExteriorCharacter.CancelPreviewHorseAdornmentSet(tSub)
    for i, tItem in ipairs(tSub) do
        ExteriorCharacter.CancelPreviewAdornment(tItem)
    end
end

function ExteriorCharacter.IsHorseAdornmentSetPreview(tSub)
    for _, tItem in ipairs(tSub) do
        if not ExteriorCharacter.IsHAdornmentPreview(tItem) then
            return false
        end
    end
    return true
end

function ExteriorCharacter.GetRideData()
    return ExteriorCharacter.m_tRideViewData
end

function ExteriorCharacter.PreviewHorseItem(tItem, bUpdate)
    local nIndex = COINSHOP_RIDE_BOX_INDEX.ITEM
    local tData = {}
    tData.tItem = tItem
    ExteriorCharacter.m_tRideViewData[nIndex] = tData
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPreviewHorseItem(bUpdate)
    ExteriorCharacter.PreviewHorseItem(nil, bUpdate)
end

function ExteriorCharacter.IsHorseItemPreview(tItem)
    local nIndex = COINSHOP_RIDE_BOX_INDEX.ITEM
    local tData = ExteriorCharacter.m_tRideViewData[nIndex]
    local tViewItem = tData.tItem

    if tViewItem and tViewItem.dwLogicID == tItem.dwLogicID then
        return true
    end

    return false
end

function ExteriorCharacter.IsHorsePreview(tItem)
    local nIndex = CoinShop_GetRideIndex(EQUIPMENT_REPRESENT.HORSE_STYLE)
    local tData = ExteriorCharacter.m_tRideViewData[nIndex]
    local tHorse = tData.tItem
    if tHorse and tHorse.dwTabType == tItem.dwTabType and tHorse.dwIndex == tItem.dwIndex then
        return true
    end

    return false
end

function ExteriorCharacter.PreviewHorse(tItem, bUpdate, bLimitItem, bMultiPreview)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hHorse = hItemInfo
    if bLimitItem and not bMultiPreview then
        hHorse = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    tRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = hHorse.nRepresentID
    local bHaveSpecialHorse = hHorse.nDetail ~= 0
    if bHaveSpecialHorse then
        ExteriorCharacter.ClearHorseAdornment(false)
        ExteriorCharacter.ClearHorseItem(false)
    end

    local nIndex = CoinShop_GetRideIndex(EQUIPMENT_REPRESENT.HORSE_STYLE)
    local tData = {}
    tData.bHaveSpecialHorse = bHaveSpecialHorse
    local tNewItem = {}

    local tMultiData = {}
    tMultiData.bHaveSpecialHorse = bHaveSpecialHorse
    local tNewMultiItem = {}

    if bMultiPreview then
        tNewItem.dwIndex = 0

        tNewMultiItem.dwTabType = tItem.dwTabType
        tNewMultiItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end

        tNewMultiItem.dwLogicID = dwLogicID
        tNewMultiItem.bLimitItem = bLimitItem
    else
        tNewItem.dwTabType = tItem.dwTabType
        tNewItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end

        tNewItem.dwLogicID = dwLogicID
        tNewItem.bLimitItem = bLimitItem

        tNewMultiItem.dwIndex = 0
    end

    tData.tItem = tNewItem
    tMultiData.tItem = tNewMultiItem

    ExteriorCharacter.m_tRideViewData[nIndex] = tData
    ExteriorCharacter.m_tRideViewMultiData[nIndex] = tMultiData
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPreviewHorse()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hItem = hPlayer.GetEquippedHorse()
    if hItem then
        local tItem = {}
        tItem.dwTabType = hItem.dwTabType
        tItem.dwIndex = hItem.dwIndex
        ExteriorCharacter.PreviewHorse(tItem, true)
    else
        ExteriorCharacter.ClearHorse(true)
    end
end

function ExteriorCharacter.ClearHorse(bUpdate)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    local nIndex = CoinShop_GetRideIndex(EQUIPMENT_REPRESENT.HORSE_STYLE)
    ExteriorCharacter.m_tRideViewData[nIndex] = {}
    ExteriorCharacter.m_tRideViewMultiData[nIndex] = {}
    tRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = 25
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
    end
end

function ExteriorCharacter.ClearHorseItem(bUpdate)
    ExteriorCharacter.m_tRideViewData[COINSHOP_RIDE_BOX_INDEX.ITEM] = {}
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
    end
end

function ExteriorCharacter.InitHorse()
    if not g_pClientPlayer then
        return
    end
    local hItem = g_pClientPlayer.GetEquippedHorse()
    if hItem then
        local tItem = {}
        tItem.dwTabType = hItem.dwTabType
        tItem.dwIndex = hItem.dwIndex
        ExteriorCharacter.PreviewHorse(tItem, false)
    else
        ExteriorCharacter.ClearHorse(false)
    end
end

function ExteriorCharacter.InitRide(bUpdate)
    ExteriorCharacter.InitHorseAdornment()
    ExteriorCharacter.InitHorse()
    ExteriorCharacter.ClearHorseItem(false)

    if bUpdate then
        FireUIEvent("COINSHOPVIEW_RIDE_DATA_UPDATE")
    end
end

function ExteriorCharacter.IsFurniturePreview(tItem)
    local tFurniture = ExteriorCharacter.m_tFurnitureViewData.tItem
    if tFurniture and tFurniture.dwTabType and tFurniture.dwIndex
        and tFurniture.dwTabType == tItem.dwTabType
        and tFurniture.dwIndex == tItem.dwIndex then
        return true
    end

    return false
end

function ExteriorCharacter.GetPetData()
    return ExteriorCharacter.m_tPetViewData
end

function ExteriorCharacter.PreviewPet(tItem, bUpdate)
    local tData = {}
    tData.tItem = tItem
    ExteriorCharacter.m_tPetViewData = tData
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_PET_DATA_UPDATE")
    end
end

function ExteriorCharacter.IsPetPreview(tItem)
    local tPet = ExteriorCharacter.m_tPetViewData.tItem
    if tPet and tPet.dwLogicID and tPet.dwLogicID == tItem.dwLogicID then
        return true
    end

    if tPet and tPet.nPetIndex and tPet.nPetIndex == tItem.nPetIndex then
        return true
    end

    return false
end

function ExteriorCharacter.IsPetMultiPreview(nPetIndex, tItem)
    local tPet = ExteriorCharacter.m_tPetViewData.tItem

    if tPet and tPet.dwLogicID and tPet.dwLogicID == tItem.dwLogicID and tPet.nPetIndex == nPetIndex then
        return true
    end

    return false
end

function ExteriorCharacter.InitPet(bUpdate)
    ExteriorCharacter.PreviewPet(nil, bUpdate)
end

function ExteriorCharacter.InitFurniture(bUpdate)
    ExteriorCharacter.PreviewFurniture(nil, bUpdate)
end

function ExteriorCharacter.GetFurnitureData()
    return ExteriorCharacter.m_tFurnitureViewData
end

function ExteriorCharacter.PreviewFurniture(tItem, bUpdate)
    if not tItem or IsTableEmpty(tItem) then
        local tData = {}
        tData.tItem = tItem
        ExteriorCharacter.m_tFurnitureViewData = tData
        if bUpdate then
            FireUIEvent("COINSHOPVIEW_FURNITURE_DATA_UPDATE")
        end
        return
    end

    if not g_pClientPlayer then
        return
    end

    local dwFurnitureID = tItem.dwFurnitureID
    local nFurnitureType = tItem.nFurnitureType
    if not dwFurnitureID then
        local tItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
        nFurnitureType = tItemInfo.nFurnitureType
        dwFurnitureID = tItemInfo.dwFurnitureID
    end

    local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
    local dwRepresentID = tUIInfo and tUIInfo.dwModelID

    local tNewItem      = {}
    tNewItem.dwTabType  = tItem.dwTabType
    tNewItem.dwIndex    = tItem.dwIndex
    local dwLogicID     = tItem.dwLogicID
    if not dwLogicID then
        dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
    end

    tNewItem.dwRepresentID  = dwRepresentID
    tNewItem.dwLogicID      = dwLogicID
    tNewItem.dwFurnitureID  = dwFurnitureID

    local tLine         = CoinShop_GetFurnitureShopInfo(dwFurnitureID) or {}
    local szPos         = tLine.szMobilePos or ExteriorCharacter.FURNITURE_POS
    tNewItem.nPutType   = tLine.nPutType or 0
    tNewItem.tPos       = SplitString(szPos, ";")
    tNewItem.nYaw       = tLine.nYaw
    tNewItem.fScale     = tLine.fScale
    tNewItem.nDetails   = tLine.nDetails
    local tData         = {}
    tData.tItem         = tNewItem
    ExteriorCharacter.m_tFurnitureViewData = tData
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_FURNITURE_DATA_UPDATE")
    end
end

function ExteriorCharacter.ResUpdate_Exterior(dwExteriorID, nIndex, tReplaceRepresent)
    local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)

    local tRepresentID = ExteriorCharacter.m_tRepresentID
    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    local nSubType = Exterior_BoxIndexToSub(nIndex)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
    local nRepresentDyeing = Exterior_RepresentSubToDyeing(nRepresentSub)

    local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
    local hItem = ExteriorCharacter.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)

    if not hItem or dwExteriorID > 0 then
        if not g_pClientPlayer.bHideHat or nSubType ~= EQUIPMENT_SUB.HELM then
            if tReplaceRepresent and tReplaceRepresent.nRepresentID and tReplaceRepresent.nColorID and tReplaceRepresent.nRepresentID ~= 0 then
                tRepresentID[nRepresentSub] = tReplaceRepresent.nRepresentID
                tRepresentID[nRepresentColor] = tReplaceRepresent.nColorID
            else
                tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
                tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
            end
            if nRepresentDyeing then
                local nDyeingID = g_pClientPlayer.GetExteriorDyeingID(dwExteriorID)
                tRepresentID[nRepresentDyeing] = nDyeingID
            end
        end
    else
        if not g_pClientPlayer.bHideHat or nSubType ~= EQUIPMENT_SUB.HELM then
            tRepresentID[nRepresentSub] = hItem.nRepresentID
            tRepresentID[nRepresentColor] = hItem.nColorID
            if nRepresentDyeing then
                tRepresentID[nRepresentDyeing] = 0
            end
        end
    end
    if nSubType == EQUIPMENT_SUB.CHEST then
        ExteriorCharacter.GetExteriorSubsetHideFlag(dwExteriorID, EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK)
    end
end

function ExteriorCharacter.PreviewSub(dwID, tItem, bUpdate, bMultiPreview, tReplaceRepresent)
    ExteriorCharacter.ClearPreviewAniIDInShop()

    local nSubsetHideCount = 0
    local bSubsetHide = false
    if g_pClientPlayer then
        nSubsetHideCount = GetExterior().GetSubsetCanHideCount(dwID)
        if nSubsetHideCount > 0 then
            bSubsetHide = g_pClientPlayer.GetExteriorSubsetHideFlag(dwID) ~= 0
        end
    end

    local nIndex = Exterior_GetSubIndex(dwID)
    local tData = {}
    local tMultiData = {}
    if bMultiPreview then
        tData.dwID = 0
        tMultiData.dwID = dwID
        tMultiData.tItem = tItem
        tMultiData.bReplace = tReplaceRepresent and tReplaceRepresent.nRepresentID ~= nil
        tMultiData.nSubsetHideCount = nSubsetHideCount
        tMultiData.bSubsetHide = bSubsetHide
        tData.nExterior = dwID
    else
        tData.dwID = dwID
        tData.tItem = tItem
        tData.nSubsetHideCount = nSubsetHideCount
        tData.bSubsetHide = bSubsetHide
        tData.nExterior = dwID
        tMultiData.dwID = 0
    end
    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.m_tRoleViewMultiData[nIndex] = tMultiData

    FireUIEvent("ON_PREVIEW_SUB", dwID)
    ExteriorCharacter.ResUpdate_Exterior(dwID, nIndex, tReplaceRepresent)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.ClearSub(nIndex, bUpdate)
    local tData = {}
    local tMultiData = {}

    tData.dwID = 0
    tData.bInit = false
    tMultiData.dwID = 0

    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    tData.nExterior = ExteriorCharacter.m_tRoleInitData[nRepresentSub]  --没穿外观的情况下，存一下本身装备的外观ID
    tData.bInit = true

    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.m_tRoleViewMultiData[nIndex] = tMultiData
    ExteriorCharacter.ResUpdate_Exterior(0, nIndex)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPreviewSub(dwID, bUpdate, tItem, bMultiPreview)
    if not g_pClientPlayer then
        return
    end

    local bPreview = ExteriorCharacter.IsSubPreview(dwID, tItem)
    if not bPreview and not bMultiPreview then
        return
    end

    local tInfo = GetExterior().GetExteriorInfo(dwID)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)

    local nCurrentSetID = g_pClientPlayer.GetCurrentSetID()
    local tExteriorSet = g_pClientPlayer.GetExteriorSet(nCurrentSetID)
    local nExteriorSub  = Exterior_BoxIndexToExteriorSub(nIndex)
    local dwExteriorID = tExteriorSet[nExteriorSub]
    if dwID == dwExteriorID and not tItem then
        dwExteriorID = 0
    end

    if dwExteriorID == 0 then
        ExteriorCharacter.ClearSub(nIndex, bUpdate)
    else
        ExteriorCharacter.PreviewSub(dwExteriorID, nil, bUpdate)
    end
end

function ExteriorCharacter.IsSubPreview(dwExteriorID, tItem)
    if dwExteriorID <= 0 then
        return false
    end

    local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]

    if tData.dwID == dwExteriorID and not tItem and not tData.tItem
    then
        return true
    end

    if tData.dwID == dwExteriorID and tItem and tData.tItem and
        tItem.dwLogicID == tData.tItem.dwLogicID
    then
        return true
    end

    return false
end

function ExteriorCharacter.IsSubSubsetHide(dwExteriorID, tItem)
    if not ExteriorCharacter.IsSubPreview(dwExteriorID, tItem) then
        return 0, false
    end
    if dwExteriorID <= 0 then
        return 0, false
    end
    local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    return tData.nSubsetHideCount, tData.bSubsetHide
end

function ExteriorCharacter.PreviewSet(tSub)
    for i, dwID in ipairs(tSub) do
        local bUpdate = i == #tSub
        ExteriorCharacter.PreviewSub(dwID, nil, bUpdate)
    end
end

function ExteriorCharacter.CancelPreviewSet(tSub)
    for i, dwID in ipairs(tSub) do
        local bUpdate = i == #tSub
        ExteriorCharacter.CancelPreviewSub(dwID, bUpdate)
    end
end

function ExteriorCharacter.IsSetPreview(tSub)
    for _, dwID in ipairs(tSub) do
        if not ExteriorCharacter.IsSubPreview(dwID) then
            return false
        end
    end
    return true
end

function ExteriorCharacter.GetPlayerItem(player, dwBox, dwX, szPackageType, dwASPSource)
    if szPackageType == UI_BOX_TYPE.SHAREPACKAGE then
        return player.GetItemInAccountSharedPackage(dwASPSource, dwBox, dwX)
    elseif dwBox == INVENTORY_GUILD_BANK then
        return GetTongClient().GetRepertoryItem(GetGuildBankPagePos(dwBox, dwX))
    else
        return player.GetItem(dwBox, dwX)
    end
end

function ExteriorCharacter.ResUpdate_Weapon(dwWeaponID, nIndex)
    local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID)
    local tRepresentID = ExteriorCharacter.m_tRepresentID

    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    local nSubType = Exterior_BoxIndexToSub(nIndex)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
    local tWeaponEnchant = CoinShop_GetWeaponEnchantArray()

    local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
    local nEnchant1, nEnchant2 = unpack(tWeaponEnchant[nIndex])
    local hItem = ExteriorCharacter.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)
    local bHideBigSword = nRepresentSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE and
            g_pClientPlayer.dwForceID ~= FORCE_TYPE.CANG_JIAN and g_pClientPlayer.dwForceID ~= 0
    if not hItem or dwWeaponID > 0 or bHideBigSword then
        tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
        tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
        tRepresentID[nEnchant1] = tExteriorInfo.nEnchantRepresentID1
        tRepresentID[nEnchant2] = tExteriorInfo.nEnchantRepresentID2
        if nRepresentSub ~= EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then
            ExteriorCharacter.m_nWeaponType = tExteriorInfo.nDetailType
        end
        return
    end

    local tEnchant = hItem.GetEnchantRepresentID()
    tRepresentID[nRepresentSub] = hItem.nRepresentID
    tRepresentID[nRepresentColor] = hItem.nColorID
    tRepresentID[nEnchant1] = tEnchant[1]
    tRepresentID[nEnchant2] = tEnchant[2]
    if nRepresentSub ~= EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then
        ExteriorCharacter.m_nWeaponType = hItem.nDetail
    end
end

function ExteriorCharacter.PreviewWeapon(dwID, bUpdate)
    local nIndex = CoinShop_GetWeaponIndex(dwID)
    local tData = {}
    tData.dwID = dwID
    tData.nExterior = dwID --仅做记录外观ID用，不参与结算购买

    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.ResUpdate_Weapon(dwID, nIndex)

    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.ClearWeapon(nIndex, bUpdate)
    local dwID = 0
    local tData = {}
    tData.dwID = dwID

    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    tData.nExterior = ExteriorCharacter.m_tRoleInitData[nRepresentSub]  --没穿武器外观的情况下，存一下本身装备的外观ID

    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.ResUpdate_Weapon(dwID, nIndex)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPreviewWeapon(dwID)
    if not g_pClientPlayer then
        return
    end

    local bPreview = ExteriorCharacter.IsWeaponPreview(dwID)
    if not bPreview then
        return
    end

    local nIndex = CoinShop_GetWeaponIndex(dwID)
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local nCurrentSetID = g_pClientPlayer.GetCurrentSetID()
    local tWeaponExterior = g_pClientPlayer.GetWeaponExteriorSet(nCurrentSetID)
    local nExteriorSub  = tWeaponBox[nIndex]
    local dwWeaponID = tWeaponExterior[nExteriorSub]
    if dwID == dwWeaponID or dwWeaponID == 0 then
        ExteriorCharacter.ClearWeapon(nIndex, true)
    else
        ExteriorCharacter.PreviewWeapon(dwWeaponID, true)
    end
end

function ExteriorCharacter.IsWeaponPreview(dwWeaponID)
    if dwWeaponID <= 0 then
        return false
    end

    local nIndex = CoinShop_GetWeaponIndex(dwWeaponID)
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]

    if tData.dwID == dwWeaponID then
        return true
    end

    return false
end

function ExteriorCharacter.ResUpdate_Pendant(tItem, dwPerdentIndex, bLimitItem, bMultiPreview, hPendant, nRepresentSub)
    if not g_pClientPlayer then
        return
    end

    local tColorID = hPendant.GetColorID()
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    -- local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    tRepresentID[nRepresentSub] = hPendant.nRepresentID
    if nRepresentSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
        local bHide = g_pClientPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL)
        tRepresentID.bHideBackCloakModel = bHide
        -- if bHide then
        --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = 0
        --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = 0
        --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = 0
        --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = 0
        -- else
            if tItem and tItem.tColorID then
                tColorID = tItem.tColorID
            end
            tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = tColorID[1]
            tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = tColorID[2]
            tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = tColorID[3]
        --end
    end
end

function ExteriorCharacter.GetHeadPendentCoinShopIndex(nGetIndex)
    nGetIndex = nGetIndex or 0
    local tList = CoinShop_PendentHeadType()
    for _, nIndex in ipairs(tList) do
        local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
        if tData and tData.tItem and tData.tItem.dwIndex == nGetIndex then
            return nIndex
        end
    end
end

function ExteriorCharacter.GetFreeHeadPendentCoinShopIndex()
    local tList = CoinShop_PendentHeadType()
    for _, nIndex in ipairs(tList) do
        local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
        if not tData or not tData.tItem or tData.tItem.dwIndex == 0 then
            return nIndex
        end
    end
end


function ExteriorCharacter.IsColorSame(tColorID1, tColorID2)
    if not tColorID1 then
        tColorID1 = {0, 0, 0}
    end

    if not tColorID2 then
        tColorID2 = {0, 0, 0}
    end

    for i, nColor in ipairs(tColorID1) do
        if nColor ~= tColorID2[i]then
            return false
        end
    end

    return true
end

local function IsPendantRoleViewPreview(nIndex, tItem)
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    if not tData then
        return false
    end
    local tCurrent = tData.tItem
    if tCurrent.dwIndex ~= tItem.dwIndex then
        return false
    end

    if tCurrent.dwIndex == 0 and tItem.dwIndex == 0 then
        return true
    end

    local bSame = ExteriorCharacter.IsColorSame(tCurrent.tColorID, tItem.tColorID)

    return bSame
end

function ExteriorCharacter.IsPendantPreview(tItem, bLimitItem)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo
    if bLimitItem then
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)

    if EQUIPMENT_REPRESENT.HEAD_EXTEND == nRepresentSub then
        local tList = CoinShop_PendentHeadType()
        for _, nIndex in ipairs(tList) do
            local bSame = IsPendantRoleViewPreview(nIndex, tItem)
            if bSame then
                return true
            end
        end
    else
        return IsPendantRoleViewPreview(nIndex, tItem)
    end
    return false
end

function ExteriorCharacter.PreviewItem(tItem, bUpdate)
    local nIndex = COINSHOP_BOX_INDEX.ITEM
    local tData = {}
    tData.tItem = tItem
    ExteriorCharacter.m_tRoleViewData[nIndex] = tData

    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPreviewItem(bUpdate)
    ExteriorCharacter.PreviewItem(nil, bUpdate)
end

function ExteriorCharacter.IsViewItemPreview(tItem)
    local nIndex = COINSHOP_BOX_INDEX.ITEM
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    local tViewItem = tData and tData.tItem
    if tViewItem and tViewItem.dwLogicID == tItem.dwLogicID then
        return true
    end
    -- 宠物盒子
    local tPetData = ExteriorCharacter.GetPetData()
    if tPetData and tPetData.tItem and tPetData.tItem.dwLogicID == tItem.dwLogicID then
        return true
    end

    return false
end

function ExteriorCharacter.GetViewItemPreview()
    local nIndex = COINSHOP_BOX_INDEX.ITEM
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    if tData then
        return tData.tItem
    end
end

function ExteriorCharacter.UpdateFaceDecal(tDecal)
    local tData = ExteriorCharacter.GetPreviewFace()
    if not tData.UserData then
        UserData = {}
        UserData.tFaceData = {}
        tData.UserData = UserData
    end
    local tFaceData = tData.UserData.tFaceData
    tFaceData.tDecal = tDecal
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.tFaceData = tFaceData
end

function ExteriorCharacter.UpdateFaceBoneParams(tBone)
    local tData = ExteriorCharacter.GetPreviewFace()
    if not tData.UserData then
        UserData = {}
        UserData.tFaceData = {}
        tData.UserData = UserData
    end
    local tFaceData = tData.UserData.tFaceData
    tFaceData.tBone = tBone
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.tFaceData = tFaceData
end

function ExteriorCharacter.UpdateFaceDecorationID(nDecorationID)
    local tData = ExteriorCharacter.GetPreviewFace()
    if not tData.UserData then
        UserData = {}
        UserData.tFaceData = {}
        tData.UserData = UserData
    end
    local tFaceData = tData.UserData.tFaceData
    tFaceData.nDecorationID = nDecorationID
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID.tFaceData = tFaceData
end

function ExteriorCharacter.IsFacePreview(nFaceID, nEquipIndex)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    if nEquipIndex then
        if tRepresentID.bUseLiftedFace and tRepresentID.nEquipIndex == nEquipIndex then
            return true
        end
    else
        if not tRepresentID.bUseLiftedFace and
            tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE] == nFaceID
        then
            return true
        end
    end

    return false
end

function ExteriorCharacter.GetPreviewFace()
    local nIndex = CoinShop_GetHairBoxIndex(HAIR_STYLE.FACE)
    local tFace = ExteriorCharacter.m_tRoleViewData[nIndex]

    local nIndex = nil

    if tFace and tFace.UserData then
        nIndex = tFace.UserData.nIndex
    end

    return tFace, nIndex
end

function ExteriorCharacter.GetPreviewHair()
    local nIndex = CoinShop_GetHairBoxIndex(HAIR_STYLE.HAIR)
    local tHair = ExteriorCharacter.m_tRoleViewData[nIndex]

    return tHair
end

-- function ExteriorCharacter.GetPreviewPendantIndexByItem(nItemIndex)
--     for _, nPos in ipairs(PENDENT_HEAD_TYPE) do
--         local nIndex = CoinShop_PendantTypeToBoxIndex(nPos)
--         local tPendant = ExteriorCharacter.m_tRoleViewData[nIndex]
--         if tPendant and tPendant.tItem and tPendant.tItem.dwIndex == nItemIndex then
--             return nIndex
--         end
--     end
-- end

function ExteriorCharacter.GetPreviewPendant(nIndex)
    local tPendant = ExteriorCharacter.m_tRoleViewData[nIndex]
    if not tPendant then
        return
    end
    return tPendant.tItem
end

function ExteriorCharacter.GetPreviewPendantPet()
    local nIndex = COINSHOP_BOX_INDEX.PENDANT_PET
    local tPendantPet = ExteriorCharacter.m_tRoleViewData[nIndex]
    if not tPendantPet then
        return
    end

    return tPendantPet.tItem
end

function ExteriorCharacter.GetTakeUpHeadPreviewPendant()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tList = CoinShop_PendentHeadType()
    for _, nIndex in ipairs(tList) do
        local tPendant = ExteriorCharacter.GetPreviewPendant(nIndex)
        if tPendant and tPendant.dwIndex ~= 0 and hPlayer.IsPendentExist(tPendant.dwIndex) then
            return nIndex
        end
    end
end

function ExteriorCharacter.GetPreviewBody()
    local nIndex = COINSHOP_BOX_INDEX.BODY
    local tBody = ExteriorCharacter.m_tRoleViewData[nIndex]
    if tBody then
        return tBody, tBody.nBody
    end

    return
end

function ExteriorCharacter.PreviewAniID(dwID, dwRepresentID, bMultiPreview)
    local bUpdate = not ExteriorCharacter.IsInitRole()
    if (not ExteriorCharacter.m_tRoleViewData.nLogicAniID) or (dwID ~= ExteriorCharacter.m_tRoleViewData.nLogicAniID) then
        ExteriorCharacter.m_tRoleViewData.nLogicAniID = dwID
    end
    ExteriorCharacter.m_tRoleViewData.bLogicMultiPreview = bMultiPreview
    ExteriorCharacter.m_bOnPreviewAni = true
    FireUIEvent("ON_ACTION_CHANGED", bMultiPreview)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
    ExteriorCharacter.m_bOnPreviewAni = false
end

function ExteriorCharacter.OnPreviewAni()
    return ExteriorCharacter.m_bOnPreviewAni
end

function ExteriorCharacter.GetPreviewAniID()
    return ExteriorCharacter.m_tRoleViewData.nLogicAniID, ExteriorCharacter.m_tRoleViewData.bLogicMultiPreview
end

function ExteriorCharacter.IsAlreadyHavePosture()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nPosture = ExteriorCharacter.m_tRoleViewData.nLogicAniID
    local bHave = nPosture == 0 or hPlayer.IsHaveIdleAction(nPosture)
	return bHave
end

function ExteriorCharacter.ClearPreviewAniIDInShop()
    if not ExteriorCharacter.IsInitRole() and not CoinShopData.IsInCoinShopWardrobe() then
        FireUIEvent("PREVIEW_IDLE_ACTION", 0)
    end
end

function ExteriorCharacter.IsAlreadyHaveBody()
    local hManager = GetBodyReshapingManager()
    if not hManager then
        return
    end
    local nIndex = COINSHOP_BOX_INDEX.BODY
    local tBody = ExteriorCharacter.m_tRoleViewData[nIndex]
    local bHave, nIndex = hManager.IsAlreadyHave(tBody)
    return bHave, nIndex
end

function ExteriorCharacter.GetPreviewNewFace()
    local nIndex = COINSHOP_BOX_INDEX.NEW_FACE
    local tFace = ExteriorCharacter.m_tRoleViewData[nIndex]
    local nFaceID = nil
    if tFace then
        nFaceID = tFace.nFaceID
    end
    return tFace, nFaceID
end

function ExteriorCharacter.IsAlreadyHaveNewFace()
    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end
    local nIndex = COINSHOP_BOX_INDEX.NEW_FACE
    local tNewHair = ExteriorCharacter.m_tRoleViewData[nIndex]
    local bHave, nIndex = hManager.IsAlreadyHave(tNewHair)
    return bHave, nIndex
end

function ExteriorCharacter.IsNewFace()
    return ExteriorCharacter.m_tRoleViewData.bNewFace
end

function ExteriorCharacter.IsUseLiftedFace()
    return ExteriorCharacter.m_tRepresentID.bUseLiftedFace
end

function ExteriorCharacter.IsAlreadyHaveFace()
    local hManager = GetFaceLiftManager()
    if not hManager then
        return
    end
    local nIndex = COINSHOP_BOX_INDEX.FACE
    local tNewHair = ExteriorCharacter.m_tRoleViewData[nIndex]
    if not tNewHair or not tNewHair.UserData then
        return
    end
    local bHave, nIndex = hManager.IsAlreadyHave(tNewHair.UserData.tFaceData)
    return bHave, nIndex
end

function ExteriorCharacter.ChangeFaceType(bNew)
    local bOld = ExteriorCharacter.m_tRoleViewData.bNewFace
    ExteriorCharacter.m_tRoleViewData.bNewFace = bNew
    if bNew ~= bOld then
        FireUIEvent("ON_CHANGE_FACE_TYPE")
        if bNew then
            ExteriorCharacter.ClearFaceData()
        else
            ExteriorCharacter.ClearNewFaceData()
        end
    end
end

function ExteriorCharacter.ClearFaceData()
    local nIndex = CoinShop_GetHairBoxIndex(HAIR_STYLE.FACE)
    ExteriorCharacter.m_tRoleViewData[nIndex] = {}
end

function ExteriorCharacter.ClearNewFaceData()
    ExteriorCharacter.m_tRoleViewData[COINSHOP_BOX_INDEX.NEW_FACE] = {}

    return tFace
end

function ExteriorCharacter.PreviewPendant(tItem, bLimitItem, bMultiPreview, bUpdate, nPos)
    ExteriorCharacter.ClearPreviewAniIDInShop()

    if not g_pClientPlayer then
        return
    end
    local dwPerdentIndex = tItem.dwIndex
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo

    if bLimitItem and not bMultiPreview then
        dwPerdentIndex = hItemInfo.nDetail
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)

    local tData = {}
    local tNewItem = {}

    local tMultiData = {}
    local tNewMultiItem = {}

    tNewItem.dwPendantIndex = dwPerdentIndex
    if bMultiPreview then
        bUpdate = false
        tNewItem.dwIndex = 0

        tNewMultiItem.dwTabType = tItem.dwTabType
        tNewMultiItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end
        tNewMultiItem.dwLogicID = dwLogicID
        tNewMultiItem.bLimitItem = bLimitItem
        tNewMultiItem.nClass = tItem.nClass
        tNewMultiItem.tColorID = tItem.tColorID
    else
        tNewItem.dwTabType = tItem.dwTabType
        tNewItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end
        tNewItem.dwLogicID = dwLogicID
        tNewItem.bLimitItem = bLimitItem
        tNewItem.nClass = tItem.nClass
        tNewItem.tColorID = tItem.tColorID

        tNewMultiItem.dwIndex = 0
        if nPos and nIndex == COINSHOP_BOX_INDEX.HEAD_EXTEND then
            if type(nPos) == "number" then
                nIndex = CoinShop_PendantTypeToBoxIndex(nPos)
            else
                nIndex = ExteriorCharacter.GetFreeHeadPendentCoinShopIndex() or nIndex
            end
            nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
        end
    end
    tNewItem.nRepresentID = hPendant.nRepresentID
    tData.tItem = tNewItem
    tMultiData.tItem = tNewMultiItem
    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.m_tRoleViewMultiData[nIndex] = tMultiData
    ExteriorCharacter.ResUpdate_Pendant(tData.tItem, dwPerdentIndex, bLimitItem, bMultiPreview, hPendant, nRepresentSub)

    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.ClearPendant(nRepresentSub, bUpdate)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)

    local tNewItem = {}
    tNewItem.dwIndex = 0
    tNewItem.dwPendantIndex = 0

    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID[nRepresentSub] = 0

    ExteriorCharacter.m_tRoleViewData[nIndex] = { tItem = tNewItem}
    ExteriorCharacter.m_tRoleViewMultiData[nIndex] = { tItem = tNewItem }

    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPendentPreview(tItem, bLimitItem, bMultiPreview, bUpdate, bMaybeMulti)
    if not g_pClientPlayer then
        return
    end
    if bMultiPreview then
        bUpdate = false
    end
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo
    local dwIndex = tItem.dwIndex
    if bLimitItem and not bMultiPreview then
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
        dwIndex = hItemInfo.nDetail
    end
    local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]

    local nPendantType = CoinShop_BoxIndexToPendantType(nIndex)
    local nPendantPos = GetPendentPos(nPendantType)
    local dwCurrentIndex = g_pClientPlayer.GetSelectPendent(nPendantPos)
    local dwPerdentIndex = dwCurrentIndex

    if not tItem.bLimitItem then
        if bMaybeMulti and nPendantType == KPENDENT_TYPE.HEAD then
            local nCoinShopIndex = ExteriorCharacter.GetHeadPendentCoinShopIndex(tItem.dwIndex)
            local nPendantPos = CoinShop_BoxIndexToPendantType(nCoinShopIndex)
            nRepresentSub = Exterior_BoxIndexToRepresentSub(nCoinShopIndex)
            dwPerdentIndex = 0 --头饰可以装备3个的话取消就不恢复到player原来那个了
        end
        if dwCurrentIndex == tItem.dwIndex then
            dwPerdentIndex = 0
        end
    end

    if dwCurrentIndex == tItem.dwIndex and not tItem.bLimitItem then
        dwPerdentIndex = 0
    end

    if dwPerdentIndex > 0 then
        local tNewItem = {}
        tNewItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
        tNewItem.dwIndex = dwPerdentIndex
        local hNewPendant = GetItemInfo(tNewItem.dwTabType, tNewItem.dwIndex)
        local tColorID = GetPendantColor(tNewItem.dwTabType, tNewItem.dwIndex)
        tNewItem.tColorID = tColorID
        ExteriorCharacter.PreviewPendant(tNewItem, nil, nil, bUpdate, bMaybeMulti)
    else
        ExteriorCharacter.ClearPendant(nRepresentSub, bUpdate)
    end
end

function ExteriorCharacter.IsPendantSelected(tItem)
    if not g_pClientPlayer then
        return
    end
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo
    if hPendant.nSub == EQUIPMENT_SUB.HEAD_EXTEND then
        local nSelectedPos = g_pClientPlayer.GetHeadPendentSelectedPos(tItem.dwIndex)
        if nSelectedPos then
            return true
        else
            return false
        end
    end
    local nPendantType = GetPendantTypeByEquipSub(hPendant.nSub)
    local dwIndex = g_pClientPlayer.GetSelectPendent(nPendantType)
    if dwIndex == 0 or dwIndex ~= tItem.dwIndex then
        return false
    end
    local tColorID = GetPendantColor(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
    local bSame = ExteriorCharacter.IsColorSame(tColorID, tItem.tColorID)
    return bSame
end

function ExteriorCharacter.IsPendantPetPreview(tItem, bLimitItem)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo
    if bLimitItem then
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    local tCurrent = tData.tItem

    return tCurrent.dwIndex == tItem.dwIndex
end

function ExteriorCharacter.ResUpdate_PendantPet(tItem, hPendant)
    if not g_pClientPlayer then
        return
    end

    local tRepresentID = ExteriorCharacter.m_tRepresentID
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    tRepresentID[nRepresentSub] = hPendant.nRepresentID

    tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_POS] = tItem.nPos or 0
end

function ExteriorCharacter.PreviewPendantPet(tItem, bLimitItem, bMultiPreview, bUpdate)
    ExteriorCharacter.ClearPreviewAniIDInShop()

    if not g_pClientPlayer then
        return
    end
    local dwPendantPetIndex = tItem.dwIndex
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo

    if bLimitItem and not bMultiPreview then
        dwPendantPetIndex = hItemInfo.nDetail
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)

    local tData = {}
    local tNewItem = {}

    local tMultiData = {}
    local tNewMultiItem = {}

    tNewItem.dwPendantIndex = dwPendantPetIndex
    if bMultiPreview then
        tNewItem.dwIndex = 0
        tNewItem.nPos = tItem.nPos or 0

        tNewMultiItem.dwTabType = tItem.dwTabType
        tNewMultiItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end

        tNewMultiItem.dwLogicID = dwLogicID
        tNewMultiItem.bLimitItem = bLimitItem
        tNewMultiItem.nClass = tItem.nClass
        tNewMultiItem.nPos = tItem.nPos or 0
    else
        tNewItem.dwTabType = tItem.dwTabType
        tNewItem.dwIndex = tItem.dwIndex
        local dwLogicID = tItem.dwLogicID
        if not dwLogicID then
            dwLogicID = Table_GetRewardsGoodID(tItem.dwTabType, tItem.dwIndex)
        end

        tNewItem.dwLogicID = dwLogicID
        tNewItem.bLimitItem = bLimitItem
        tNewItem.nClass = tItem.nClass
        tNewItem.nPos = tItem.nPos or 0

        tNewMultiItem.dwIndex = 0
    end

    tData.tItem = tNewItem
    tMultiData.tItem = tNewMultiItem

    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.m_tRoleViewMultiData[nIndex] = tMultiData

    ExteriorCharacter.ResUpdate_PendantPet(tData.tItem, hPendant)
    FireUIEvent("ON_PREVIEW_PENDANT_PET")
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.PreviewPendantPetPos(nPos)
    local nIndex = COINSHOP_BOX_INDEX.PENDANT_PET
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    tData.tItem.nPos = nPos
    ExteriorCharacter.m_tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_POS] = nPos or 0
    FireUIEvent("ON_PREVIEW_PENDANT_PET_POS")
    FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
end

function ExteriorCharacter.ClearPendantPet(bUpdate)
    local nIndex = COINSHOP_BOX_INDEX.PENDANT_PET

    local tNewItem = {}
    tNewItem.dwIndex = 0
    tNewItem.dwPendantIndex = 0
    tNewItem.nPos = 0

    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_STYLE] = 0
    tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_POS] = 0

    ExteriorCharacter.m_tRoleViewData[nIndex] = {tItem = tNewItem}
    ExteriorCharacter.m_tRoleViewMultiData[nIndex] = {tItem = tNewItem}

    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.CancelPendentPetPreview(tItem, bLimitItem, bMultiPreview, bUpdate)
    if not g_pClientPlayer then
        return
    end
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo
    if bLimitItem and not bMultiPreview then
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local dwCurrentIndex, dwCurrentPos = g_pClientPlayer.GetEquippedPendentPet()
    local dwPerdentPetIndex = dwCurrentIndex
    if dwCurrentIndex == tItem.dwIndex and not tItem.bLimitItem then
        dwPerdentPetIndex = 0
    end

    if dwPerdentPetIndex > 0 then
        local tNewItem = {}
        tNewItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
        tNewItem.dwIndex = dwPerdentPetIndex
        tNewItem.nPos = dwCurrentPos
        ExteriorCharacter.PreviewPendantPet(tNewItem, nil, nil, bUpdate)
    else
        ExteriorCharacter.ClearPendantPet(nRepresentSub, bUpdate)
    end
end

function ExteriorCharacter.IsPendantPetSelected(tbItem)
    if not g_pClientPlayer then
        return
    end
    local dwIndex, dwCurrentPos = g_pClientPlayer.GetEquippedPendentPet()
    if dwIndex ~= tbItem.dwIndex then
        return false
    end
end

function ExteriorCharacter.ResUpdate_Hair(nHairID, tItem, nHairDyeingIndex)
    local tRepresentID = ExteriorCharacter.m_tRepresentID
    tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = nHairID
    ExteriorCharacter.GetExteriorSubsetHideFlag(nHairID, EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK)
    ExteriorCharacter.GetHairDyeingData(nHairID, nHairDyeingIndex)
    -- CoinShop_DyeingHair.Close()
end

function ExteriorCharacter.ResetHairFlag()
    local nHairID = ExteriorCharacter.m_tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
    if nHairID and nHairID ~= 0 then
        ExteriorCharacter.GetExteriorSubsetHideFlag(nHairID, EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK)
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.PreviewHair(nHairID, tItem, bUpdate, bHideHat, bMultiPreview, nHairDyeingIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    ExteriorCharacter.ClearPreviewAniIDInShop()

    local nIndex = COINSHOP_BOX_INDEX.HAIR
    local tData = {}
    local tMultiData = {}

    local nSubsetHideCount = false
    local bSubsetHide = false
    if g_pClientPlayer then
        nSubsetHideCount = GetHairShop().GetSubsetCanHideCount(g_pClientPlayer.nRoleType, nHairID)
        if nSubsetHideCount > 0 then
            bSubsetHide = g_pClientPlayer.GetHairSubsetHideFlag(nHairID) ~= 0
        end
    end

    if bMultiPreview then
        local tRepresentID = GetClientPlayer().GetRepresentID()
        tData.nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
        tMultiData.nHairID = nHairID
        tMultiData.tItem = tItem
        tMultiData.nSubsetHideCount = nSubsetHideCount
        tMultiData.bSubsetHide = bSubsetHide
        tData.nExterior = nHairID   --只给显示用，不做购买等处理
        nHairDyeingIndex = ExteriorCharacter.m_tRoleViewData.nHairDyeingIndex
    else
        tData.nHairID = nHairID
        tData.tItem = tItem
        tData.nSubsetHideCount = nSubsetHideCount
        tData.bSubsetHide = bSubsetHide
        tMultiData.nHairID = 0
        tData.nExterior = nHairID
        nHairDyeingIndex = nHairDyeingIndex or hPlayer.GetEquippedHairCustomDyeingIndex(nHairID)
    end
    tData.bMultiPreview = bMultiPreview
    ExteriorCharacter.m_tRoleViewData[nIndex] = tData
    ExteriorCharacter.m_tRoleViewMultiData[nIndex] = tMultiData
    ExteriorCharacter.ResUpdate_Hair(nHairID, tItem, nHairDyeingIndex)
    FireUIEvent("ON_PREVIEW_HAIR", nHairID, tItem, bHideHat)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.ResetHair()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tRepresentID = hPlayer.GetRepresentID()
    local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
    FireUIEvent("PREVIEW_HAIR", nHairID, nil, true, true, false)
end

function ExteriorCharacter.IsHairPreview(nHair, tItem)
    local nIndex = COINSHOP_BOX_INDEX.HAIR
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]

    if tData.nHairID == nHair and not tItem and not tData.tItem
    then
        return true
    end

    if tData.nHairID == nHair and tItem and tData.tItem and
        tItem.dwLogicID == tData.tItem.dwLogicID
    then
        return true
    end

    return false
end

function ExteriorCharacter.IsHairSubsetHide(nHair, tItem)
    if not ExteriorCharacter.IsHairPreview(nHair, tItem) then
        return 0, false
    end
    local nIndex = COINSHOP_BOX_INDEX.HAIR
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]
    return tData.nSubsetHideCount, tData.bSubsetHide
end

function ExteriorCharacter.GetSubPreviewData(nIndex)
    local tData = ExteriorCharacter.m_tRoleViewData[nIndex]

    if not tData then
        return
    end
    return tData
end

function ExteriorCharacter.IsSubMultiPreview(dwExteriorID, tItem)
    if dwExteriorID <= 0 then
        return false
    end

    local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
    local tData = ExteriorCharacter.m_tRoleViewMultiData[nIndex]

    if tData.dwID == dwExteriorID and not tItem and not tData.tItem then
        return true
    end

    if tData.dwID == dwExteriorID and tItem and tData.tItem and tItem.dwLogicID == tData.tItem.dwLogicID then
        return true
    end

    return false
end

function ExteriorCharacter.IsSubMultiReplace(dwExteriorID, tItem)
    if dwExteriorID <= 0 then
        return false
    end

    local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
    local tData = ExteriorCharacter.m_tRoleViewMultiData[nIndex]

    return tData.bReplace
end

function ExteriorCharacter.IsSubMultiSubsetHide(dwExteriorID, tItem)
    if not ExteriorCharacter.IsSubMultiPreview(dwExteriorID, tItem) then
        return 0, false
    end
    if dwExteriorID <= 0 then
        return 0, false
    end
    local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
    local tData = ExteriorCharacter.m_tRoleViewMultiData[nIndex]
    return tData.nSubsetHideCount, tData.bSubsetHide
end

function ExteriorCharacter.IsPendantMultiPreview(tItem, bLimitItem)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo
    if bLimitItem then
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)
    local tData = ExteriorCharacter.m_tRoleViewMultiData[nIndex]
    local tCurrent = tData.tItem
    if tCurrent.dwIndex ~= tItem.dwIndex then
        return false
    end

    if tCurrent.dwIndex == 0 and tItem.dwIndex == 0 then
        return true
    end

    local bSame = ExteriorCharacter.IsColorSame(tCurrent.tColorID, tItem.tColorID)

    return bSame
end

function ExteriorCharacter.IsHairMultiPreview(nHair, tItem)
    local nIndex = COINSHOP_BOX_INDEX.HAIR
    local tData = ExteriorCharacter.m_tRoleViewMultiData[nIndex]

    if tData.nHairID == nHair and not tItem and not tData.tItem
    then
        return true
    end

    if tData.nHairID == nHair and tItem and tData.tItem and
        tItem.dwLogicID == tItem.dwLogicID
    then
        return true
    end

    return false
end

function ExteriorCharacter.IsHairMultiSubsetHide(nHair, tItem)
    if not ExteriorCharacter.IsHairMultiPreview(nHair, tItem) then
        return 0, false
    end

    local nIndex = COINSHOP_BOX_INDEX.HAIR
    local tData = ExteriorCharacter.m_tRoleViewMultiData[nIndex]
    return tData.nSubsetHideCount, tData.bSubsetHide
end

function ExteriorCharacter.IsHAdornmentMultiPreview(tItem)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hAdornment = hItemInfo
    local nRepresentSub = ExteriorView_GetRepresentSub(hAdornment.nSub, hAdornment.nDetail)
    local nIndex = CoinShop_GetRideIndex(nRepresentSub)

    local tData = ExteriorCharacter.m_tRideViewMultiData[nIndex]
    local tAdornment = tData.tItem
    if tAdornment and tAdornment.dwIndex == tItem.dwIndex then
        return true
    end

    return false
end

function ExteriorCharacter.IsHorseMultiPreview(tItem)
    local nIndex = CoinShop_GetRideIndex(EQUIPMENT_REPRESENT.HORSE_STYLE)
    local tData = ExteriorCharacter.m_tRideViewMultiData[nIndex]
    local tHorse = tData.tItem
    if tHorse and tHorse.dwTabType == tItem.dwTabType and tHorse.dwIndex == tItem.dwIndex then
        return true
    end

    return false
end

function ExteriorCharacter.IsPendantPetMultiPreview(tItem, bLimitItem)
    local hItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local hPendant = hItemInfo
    if bLimitItem then
        hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
    end
    local nRepresentSub = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
    local nIndex = Exterior_RepresentToBoxIndex(nRepresentSub)
    local tData = ExteriorCharacter.m_tRoleViewMultiData[nIndex]
    local tCurrent = tData.tItem

    return tCurrent.dwIndex == tItem.dwIndex
end

function ExteriorCharacter.SetRepresentReplace(bReplace)
    if bReplace ~= ExteriorCharacter.m_bReplace then
        ExteriorCharacter.m_bReplace = bReplace
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.GetRepresentReplace()
    return ExteriorCharacter.m_bReplace
end

-- 解决center_pos中的角色无法缩放的问题
function ExteriorCharacter.RoleCameraCenter(szRadius, bCenter)
    ExteriorCharacter.bRoleCameraCenter = bCenter
    FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", szRadius, nil)
end

Event.Reg(ExteriorCharacter, "PREVIEW_SUB", function() ExteriorCharacter.PreviewSub(arg0, arg1, arg2, arg3, arg4) end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_SUB", function() ExteriorCharacter.CancelPreviewSub(arg0, arg1, arg2, arg3) end)
Event.Reg(ExteriorCharacter, "PREVIEW_SET", function() ExteriorCharacter.PreviewSet(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_SET", function() ExteriorCharacter.CancelPreviewSet(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "PREVIEW_WEAPON", function() ExteriorCharacter.PreviewWeapon(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_WEAPON", function() ExteriorCharacter.CancelPreviewWeapon(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "PREVIEW_PENDANT", function()
    ExteriorCharacter.PreviewPendant(arg0, arg1, arg2, true, arg3)
    FireUIEvent("COINSHOP_HIDE_CLOAK", false)
end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_PENDANT", function() ExteriorCharacter.CancelPendentPreview(arg0, arg1, arg2, true, arg3) end)
Event.Reg(ExteriorCharacter, "PREVIEW_PENDANT_PET", function() ExteriorCharacter.PreviewPendantPet(arg0, arg1, arg2, true) end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_PENDANT_PET", function() ExteriorCharacter.CancelPendentPetPreview(arg0, arg1, arg2, true) end)
Event.Reg(ExteriorCharacter, "PREVIEW_PENDANT_PET_POS", function() ExteriorCharacter.PreviewPendantPetPos(arg0) end)
Event.Reg(ExteriorCharacter, "PREVIEW_ITEM", function() ExteriorCharacter.PreviewItem(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "PREVIEW_HAIR", function() ExteriorCharacter.PreviewHair(arg0, arg1, arg2, arg3, arg4, arg5) end)
Event.Reg(ExteriorCharacter, "RESET_HAIR", function() ExteriorCharacter.ResetHair() end)
Event.Reg(ExteriorCharacter, "PREVIEW_FACE", function() ExteriorCharacter.PreviewFace(arg0, arg1, arg2, arg3, arg4) end)
Event.Reg(ExteriorCharacter, "COINSHOP_INIT_ROLE", function() ExteriorCharacter.InitRole(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "COINSHOP_CLEAR_ROLE_PREVIEW", function() ExteriorCharacter.ClearRole(arg0) end)
Event.Reg(ExteriorCharacter, "PREVIEW_PET", function() ExteriorCharacter.PreviewPet(arg0, true) end)
Event.Reg(ExteriorCharacter, "PREVIEW_FURNITURE", function() ExteriorCharacter.PreviewFurniture(arg0, true) end)
Event.Reg(ExteriorCharacter, "COINSHOP_INIT_PET", function() ExteriorCharacter.InitPet(arg0) end)
Event.Reg(ExteriorCharacter, "COINSHOP_INIT_FURNITURE", function() ExteriorCharacter.InitFurniture(arg0) end)
Event.Reg(ExteriorCharacter, "PREVIEW_HORSE", function() ExteriorCharacter.PreviewHorse(arg0, true) end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_HORSE", function() ExteriorCharacter.CancelPreviewHorse() end)
Event.Reg(ExteriorCharacter, "PREVIEW_HORSE_ADORNMENT", function() ExteriorCharacter.PreviewHorseAdornment(arg0, true) end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_HORSE_ADORNMENT", function() ExteriorCharacter.CancelPreviewAdornment(arg0) end)
Event.Reg(ExteriorCharacter, "COINSHOP_INIT_RIDE", function() ExteriorCharacter.InitRide(arg0) end)
Event.Reg(ExteriorCharacter, "PREVIEW_REWARDS", function() ExteriorCharacter.PreviewRewards(arg0) end)
Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_REWARDS", function() ExteriorCharacter.CancalPreviewRewardsByID(arg0) end)
Event.Reg(ExteriorCharacter, "PREVIEW_HORSE_ITEM", function() ExteriorCharacter.PreviewHorseItem(arg0, arg1) end)
--Event.Reg(ExteriorCharacter, "CANCEL_PREVIEW_FURNITURE", function() ExteriorCharacter.OnEvent(szEvent) end)
Event.Reg(ExteriorCharacter, "PREVIEW_BODY", function() ExteriorCharacter.PreviewBody(arg0, arg1, arg2) end)
Event.Reg(ExteriorCharacter, "PREVIEW_NEW_FACE", function() ExteriorCharacter.PreviewNewFace(arg0, arg1, arg2) end)

Event.Reg(ExteriorCharacter, "COINSHOP_SHOW_VIEW", function (szViewPage) ExteriorCharacter.SetLogicPage(szViewPage) end)
Event.Reg(ExteriorCharacter, "COINSHOPVIEW_ROLE_DATA_UPDATE", function () ExteriorCharacter.SetLogicPage("Role") end)
Event.Reg(ExteriorCharacter, "COINSHOPVIEW_RIDE_DATA_UPDATE", function () ExteriorCharacter.SetLogicPage("Ride") end)
Event.Reg(ExteriorCharacter, "COINSHOPVIEW_PET_DATA_UPDATE", function () ExteriorCharacter.SetLogicPage("Pet") end)
Event.Reg(ExteriorCharacter, "COINSHOPVIEW_FURNITURE_DATA_UPDATE", function () ExteriorCharacter.SetLogicPage("Furniture") end)
Event.Reg(ExteriorCharacter, "PREVIEW_IDLE_ACTION", function() ExteriorCharacter.PreviewAniID(arg0, arg1, arg2) end)
Event.Reg(ExteriorCharacter, "RESET_ACTION", function() ExteriorCharacter.InitPosture() end)
Event.Reg(ExteriorCharacter, "SET_SUBSET_HIDE_FLAG", function() ExteriorCharacter.SetExteriorSubsetHideFlag(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "SET_HAIR_DYEING_DATA", function() ExteriorCharacter.SetHairDyeingData(arg0, arg1) end)
Event.Reg(ExteriorCharacter, "PREVIEW_PENDANT_EFFECT_SFX", function() ExteriorCharacter.PreviewEffect(arg0, arg1, arg2, true) end)
Event.Reg(ExteriorCharacter, "RESET_EFFECT_SFX", function() ExteriorCharacter.CancelEffectSfx() end)
Event.Reg(ExteriorCharacter, "RESET_ONE_EFFECT_SFX", function() ExteriorCharacter.CancelOneEffectSfx(arg0) end)
Event.Reg(ExteriorCharacter, "ON_CUSTOM_SFX_DATA_CHANGE", function()
    if arg0 == PLAYER_SFX_REPRESENT.SURROUND_BODY then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end)

--------------------CoinShopView-end---------------------------

--------------------ExteriorView-------------------------------
local tItemSubToRepresentSub =
{
    [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
    [EQUIPMENT_SUB.CHEST] = EQUIPMENT_REPRESENT.CHEST_STYLE,
    [EQUIPMENT_SUB.HELM]  = EQUIPMENT_REPRESENT.HELM_STYLE,
    [EQUIPMENT_SUB.WAIST] = EQUIPMENT_REPRESENT.WAIST_STYLE,
    [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_REPRESENT.BOOTS_STYLE,
    [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_REPRESENT.BANGLE_STYLE,
    [EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    [EQUIPMENT_SUB.BAG_EXTEND] = EQUIPMENT_REPRESENT.BAG_EXTEND,
    [EQUIPMENT_SUB.PENDENT_PET] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    [EQUIPMENT_SUB.GLASSES_EXTEND] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    --[EQUIPMENT_SUB.HORSE_EQUIP] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,

    [EQUIPMENT_SUB.L_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    [EQUIPMENT_SUB.R_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
    [EQUIPMENT_SUB.HEAD_EXTEND] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
}

local tItemSubToRepresentColor =
{
    [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_REPRESENT.WEAPON_COLOR,
    [EQUIPMENT_SUB.CHEST] = EQUIPMENT_REPRESENT.CHEST_COLOR,
    [EQUIPMENT_SUB.HELM]  = EQUIPMENT_REPRESENT.HELM_COLOR,
    [EQUIPMENT_SUB.WAIST] = EQUIPMENT_REPRESENT.WAIST_COLOR,
    [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_REPRESENT.BOOTS_COLOR,
    [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_REPRESENT.BANGLE_COLOR,
}

local tRepresentSubToIndex =
{
    [EQUIPMENT_REPRESENT.HELM_STYLE] = 1,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 2,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 3,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 4,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 5,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = 12,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 13,
}

local tHorseEquipToRe =
{
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT4,
}

function ExteriorView_GetRepresentSub(nSubType, nDetailType)
    if nSubType == EQUIPMENT_SUB.HORSE_EQUIP then
        return tHorseEquipToRe[nDetailType]
    end
    local nRepresentSub = tItemSubToRepresentSub[nSubType]
    local nRepresentColor = tItemSubToRepresentColor[nSubType]
    if not nRepresentSub then
        return
    end
    local nEnchantSub1 = nil
    local nEnchantSub2 = nil
    if nSubType == EQUIPMENT_SUB.MELEE_WEAPON then
        if nDetailType  == WEAPON_DETAIL.BIG_SWORD then
            nRepresentSub = EQUIPMENT_REPRESENT.BIG_SWORD_STYLE
            nRepresentColor = EQUIPMENT_REPRESENT.BIG_SWORD_COLOR
            nEnchantSub1 = EQUIPMENT_REPRESENT.BIG_SWORD_ENCHANT1
            nEnchantSub2 = EQUIPMENT_REPRESENT.BIG_SWORD_ENCHANT2
        else
            nEnchantSub1 = EQUIPMENT_REPRESENT.WEAPON_ENCHANT1
            nEnchantSub2 = EQUIPMENT_REPRESENT.WEAPON_ENCHANT2
        end
    end

    return nRepresentSub, nRepresentColor, nEnchantSub1, nEnchantSub2
end

--------------------ExteriorView-end---------------------------

--只在设计站内预览模型，不影响结算流程
function ExteriorCharacter.PreviewExteriorInShareStation(tExterior)
    local pPlayer = GetClientPlayer()
    if not pPlayer or not tExterior then
        return
    end

    local tID = tExterior.tExteriorID
    local tDetail = tExterior.tDetail or {}
    --先把身上所有外观清掉
    ExteriorCharacter.ClearExterior()
    ExteriorCharacter.ClearAllWeapon()
    ExteriorCharacter.ClearAllPendant()
    ExteriorCharacter.ClearAllPendantPet()
    ExteriorCharacter.CancelEffectSfx()
    FireUIEvent("RESET_HAIR")

    --预览对应的外观ID（不包含Detail设置）
    local bShowWeapon = false
    for nSub, nID in pairs(tID) do
        local tSubDetail = tDetail[nSub]
        local nEffectType = CharacterEffectData.GetLogicTypeByEffectType(nSub)
        if nID > 0 then
            if nEffectType then -- 称号特效
                ExteriorCharacter.PreviewEffect(nEffectType, nID, nil, true)
            elseif nSub == EQUIPMENT_REPRESENT.HAIR_STYLE then -- 发型
                ExteriorCharacter.PreviewHair(nID, nil, true)
            elseif nSub == EQUIPMENT_REPRESENT.CHEST_STYLE then -- 【成衣】或【外装收集-上衣】
                ExteriorCharacter.PreviewSub(nID, nil, true)
            elseif nSub == EQUIPMENT_REPRESENT.HELM_STYLE -- 外装收集-帽子
            or nSub == EQUIPMENT_REPRESENT.WAIST_STYLE -- 外装收集-腰带
            or nSub == EQUIPMENT_REPRESENT.BANGLE_STYLE -- 外装收集-护腕
            or nSub == EQUIPMENT_REPRESENT.BOOTS_STYLE -- 外装收集-鞋子
            then
                -- 外装收集-帽子需要特殊处理，如果对应部位有外观的情况需要把开关打开
                if nSub == EQUIPMENT_REPRESENT.HELM_STYLE then
                    if nID and nID > 0 then
                        --需要显示帽子
                        if pPlayer.bHideHat then
                            pPlayer.HideHat(false)
                        end
                    end
                end
                ExteriorCharacter.PreviewSub(nID, nil, true)
            elseif nSub == EQUIPMENT_REPRESENT.WEAPON_STYLE or nSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then -- 武器
                bShowWeapon = true --需要预览武器
                ExteriorCharacter.PreviewWeapon(nID)
            elseif nSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then -- 挂宠
                local tItem = {
                    dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET,
                    dwIndex = nID,
                    nPos = tSubDetail and tSubDetail["nPetPos"] or 0
                }
                ExteriorCharacter.PreviewPendantPet(tItem, false, false, true)
            elseif nSub == EQUIPMENT_REPRESENT.BACK_EXTEND -- 背部挂件
            or nSub == EQUIPMENT_REPRESENT.WAIST_EXTEND -- 腰部挂件
            or nSub == EQUIPMENT_REPRESENT.FACE_EXTEND -- 面部挂件
            or nSub == EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND -- 左肩饰
            or nSub == EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND -- 右肩饰
            or nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND -- 披风
            or nSub == EQUIPMENT_REPRESENT.BAG_EXTEND -- 佩囊
            or nSub == EQUIPMENT_REPRESENT.GLASSES_EXTEND -- 眼饰
            or nSub == EQUIPMENT_REPRESENT.L_GLOVE_EXTEND -- 左手饰
            or nSub == EQUIPMENT_REPRESENT.R_GLOVE_EXTEND -- 右手饰
            or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND -- 1号头饰
            or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND1 -- 2号头饰
            or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND2 -- 3号头饰
            then
                -- 面挂需要特殊处理，如果对应部位有外观的情况需要把开关打开
                if nSub == EQUIPMENT_REPRESENT.FACE_EXTEND then
                    --需要显示面挂
                    if pPlayer.bHideFacePendent then
                        pPlayer.SetFacePendentHideFlag(false)
                    end
                end

                local tItem = {
                    dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET,
                    dwIndex = nID,
                    tColorID = tSubDetail and tSubDetail["tColorID"]
                }
                local nPos = CoinShop_RepresentSubToPendantPos(nSub)
                ExteriorCharacter.PreviewPendant(tItem, false, false, true, nPos)
            end
        end
    end

    -- 全部外观都换上了，补充包身状态（商城本来就无法保存包身和散件状态）
    local nChestSub = EQUIPMENT_REPRESENT.CHEST_STYLE
    local bViewReplace = tDetail[nChestSub] and tDetail[nChestSub]["bViewReplace"]
    ExteriorCharacter.SetRepresentReplace(bViewReplace)

    -- 是否需要预览武器
    ExteriorCharacter.SetWeaponShow(bShowWeapon, true)

    -- 头饰在三个一起预览+设置自定义位置时，会出现后设置的覆盖掉前面设置的情况。暂时不确定其他部位有没有类似的问题，所以统一改成先预览ID后，再挨个应用Detail
    -- 应用Detail细节
    local hModel = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
    if hModel then
        for nSub, nID in pairs(tID) do
            local tSubDetail = tDetail[nSub] or {}
            local nEffectType = CharacterEffectData.GetLogicTypeByEffectType(nSub)
            if nID > 0 then
                if nEffectType then -- 称号特效
                    -- 自定义位置
                    local tCustomData = tSubDetail["tCustomData"] or ShareExteriorData.GetDefaultSFXCustomData(nID)
                    if tCustomData then
                        if not ExteriorCharacter.m_tRepresentID.tEffect then
                            ExteriorCharacter.m_tRepresentID.tEffect = {}
                        end

                        if not ExteriorCharacter.m_tRepresentID.tEffect[nEffectType] then
                            ExteriorCharacter.m_tRepresentID.tEffect[nEffectType] = {}
                        end

                        ExteriorCharacter.m_tRepresentID.tEffect[nEffectType].tCustomPos = tCustomData
                        hModel:UpdateEffectCustom(nEffectType, tCustomData)
                    end
                elseif nSub == EQUIPMENT_REPRESENT.HAIR_STYLE then -- 发型
                    -- 染色数据
                    local tDyeingData = tSubDetail["tDyeingData"]
                    if tDyeingData then
                        ExteriorCharacter.SetHairDyeingData(nID, tDyeingData) --playermodelview中设置染色时会先把发型裁剪重置回改外观原本的设置，所以需要先设置染色再设置裁剪
                    end

                    -- 发饰隐藏
                    local _, bCanHideHair = ExteriorCharacter.GetCanHideSubsetFlag()
                    local nHairHideFlag = tSubDetail and tSubDetail["nFlag"]
                    local nSubSetType = EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK
                    if bCanHideHair then
                        ExteriorCharacter.SetExteriorSubsetHideFlag(nSubSetType, nHairHideFlag)
                    end
                elseif nSub == EQUIPMENT_REPRESENT.HELM_STYLE then -- 外装收集-帽子
                    -- 帽子染色
                    local nDyeingID = tSubDetail["nNowDyeingID"]
                    if nDyeingID then
                        ExteriorCharacter.m_tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] = nDyeingID
                        FireUIEvent("COINSHOP_UPDATE_ROLE")
                    end
                elseif nSub == EQUIPMENT_REPRESENT.CHEST_STYLE then -- 【成衣】或【外装收集-上衣】
                    -- 外装裁剪
                    local bCanHideChest = ExteriorCharacter.GetCanHideSubsetFlag()
                    local nChestHideFlag = tSubDetail and tSubDetail["nFlag"]
                    local nSubSetType = EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK
                    if bCanHideChest then
                        ExteriorCharacter.SetExteriorSubsetHideFlag(nSubSetType, nChestHideFlag)
                    end
                elseif IsCustomPendantType(nSub) then
                    -- 自定义位置
                    local tCustomData = tSubDetail["tCustomData"] or ShareExteriorData.GetDefaultPendantCustomData(nSub, nID)
                    if tCustomData then
                        if not ExteriorCharacter.m_tRepresentID.tCustomRepresentData then
                            ExteriorCharacter.m_tRepresentID.tCustomRepresentData = {}
                        end
                        ExteriorCharacter.m_tRepresentID.tCustomRepresentData[nSub] = tCustomData
                        hModel:UpdatePendantCustom(nSub, tCustomData)
                    end

                    if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
                        -- 披风显示开关
                        if tSubDetail["bVisible"] then
                            pPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, false)
                        else
                            pPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, true)
                        end
                    end
                end
            end
        end
    end
end

function ExteriorCharacter.ResetExterior()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    --重置除了捏脸和体型以外的预览
    local tRes = ExteriorCharacter.GetRoleRes()
    tRes.tCustomRepresentData = GetEquipCustomRepresentData(pPlayer)

    ExteriorCharacter.InitExterior()
    FireUIEvent("RESET_HAIR")

    ExteriorCharacter.InitWeapon()
    ExteriorCharacter.InitPendant()
    ExteriorCharacter.InitPendantPet()
    -- ExteriorCharacter.InitEffectSfx()

    ExteriorCharacter.CancelPreviewItem(true)
    FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
end

function ExteriorCharacter.UpdeteModelVisable(szFrame, szName, bShow)
    local tFrame = ExteriorCharacter_GetRegisterFrame(szFrame, szName)
    local hModel = tFrame and tFrame.hModelView
    if hModel and hModel.m_modelRole then
        if bShow then
            hModel:ShowMDL(hModel.m_modelRole["MDL"])
        else
            hModel:HideMDL(hModel.m_modelRole["MDL"])
        end
    end
end

function ExteriorCharacter.PreviewEffect(nType, nEffectID, tItem, bUpdate)
    -- return -- 商城特效预览功能暂时关闭，等后续需求明确了再完善
    local nIndex = COINSHOP_BOX_INDEX.EFFECT_SFX
    local nState = 1
    ExteriorCharacter.m_tRoleViewData[nIndex] = ExteriorCharacter.m_tRoleViewData[nIndex] or {}
    ExteriorCharacter.m_tRoleViewData[nIndex][nType] = {nEffectID = nEffectID, tItem = tItem, nState = nState}

    ExteriorCharacter.ResUpdate_EffectSfx(nType, nEffectID, nState)

    ExteriorCharacter.GetSfxStateCount(nType, nEffectID)

    FireUIEvent("ON_EFFECT_CHANGED", nType)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.ResUpdate_EffectSfx(nType, nEffectID, nState)
    ExteriorCharacter.m_tRepresentID.tEffect = ExteriorCharacter.m_tRepresentID.tEffect or {}
    ExteriorCharacter.m_tRepresentID.tEffect[nType] = {nEffectID = nEffectID, nState = nState}
    ExteriorCharacter.SetPreviewEffectCustomPos(nType)
end

function ExteriorCharacter.SetPreviewEffectCustomPos(nType)
    if not ExteriorCharacter.m_tRepresentID.tEffect or not ExteriorCharacter.m_tRepresentID.tEffect[nType] then
        return
    end
    local nEffectID = ExteriorCharacter.m_tRepresentID.tEffect[nType].nEffectID
    if nEffectID and nEffectID ~= 0 then
        ExteriorCharacter.m_tRepresentID.tEffect[nType].tCustomPos = CoinShopEffectCustom.GetData(nType) or CharacterEffectData.GetLocalCustomEffectDataEx(nType, nEffectID)
    end
end

function ExteriorCharacter.GetSfxStateCount(nType, nEffectID)
    local nIndex = COINSHOP_BOX_INDEX.EFFECT_SFX
    local tInfo = ExteriorCharacter.m_tRoleViewData[nIndex][nType]
    if not tInfo then
        return
    end

    if not tInfo.nEffectID then
        return
    end

    local nRoleType = Player_GetRoleType(GetClientPlayer())
    local nRepresentID = Table_GetPendantEffectRepresentID(tInfo.nEffectID)
    if nType == PLAYER_SFX_REPRESENT.FOOTPRINT then
        local tSFXRes = Player_GetFootprintResource(nRepresentID, nRoleType)
        if tSFXRes.Idle and tSFXRes.Idle.Enable then
            ExteriorCharacter.m_tRoleViewData[nIndex][nType].bHaveIdle = true
        end

        if tSFXRes.Left then
            ExteriorCharacter.m_tRoleViewData[nIndex][nType].nStateCount = GetTableCount(tSFXRes.Left.tResource)
        end
    else
        local  tCustomPos = ExteriorCharacter.m_tRepresentID.tEffect[nType].tCustomPos
        local bDefaultCustomData = CharacterEffectData.IsDefaultCustomData(tCustomPos)
        local tSFXRes = Player_GetEquipSfxResource(nRepresentID, nRoleType, bDefaultCustomData)
        for _, tModelInfo in pairs(tSFXRes) do
            if tModelInfo.SubType == RL_PLAYER_EQUIP_SFX_SUB_TYPE.MDL and tModelInfo.IdleAni then
                ExteriorCharacter.m_tRoleViewData[nIndex][nType].bHaveIdle = true
            elseif tModelInfo.SubType == RL_PLAYER_EQUIP_SFX_SUB_TYPE.DOUBLE_SFX then
                ExteriorCharacter.m_tRoleViewData[nIndex][nType].bHaveIdle = true
            end
        end
        ExteriorCharacter.m_tRoleViewData[nIndex][nType].nStateCount = 1
    end
end

function ExteriorCharacter.IsEffectPreviewItem(tItem)
    -- local nIndex = COINSHOP_BOX_INDEX.EFFECT_SFX
    -- local tEffect = ExteriorCharacter.m_tRoleViewData[nIndex]
    -- if not tEffect then
    --     return
    -- end
    -- for nType, tInfo in pairs(tEffect) do
    --     if tInfo.tItem and tInfo.tItem.dwTabType and tInfo.tItem.dwIndex
    --         and tInfo.tItem.dwTabType == tItem.dwTabType
    --         and tInfo.tItem.dwIndex == tItem.dwIndex then
    --         return true
    --     end
    -- end

    return false
end

function ExteriorCharacter.GetRewardsEffectSfxType(tItem)
    local tItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    return ExteriorCharacter.GetRewardsEffectSfxTypeItemInfo(tItemInfo)
end

function ExteriorCharacter.GetRewardsEffectSfxTypeItemInfo(tItemInfo)
    if not tItemInfo then
        return
    end

    local nEffectID
    if tItemInfo.nPrefix ~= 0 then
        nEffectID = GetDesignationPrefixInfo(tItemInfo.nPrefix).dwSFXID
    elseif tItemInfo.nPostfix ~= 0 then
        nEffectID = GetDesignationPostfixInfo(tItemInfo.nPostfix).dwSFXID
    end
    if not nEffectID then
        return
    end

    local tInfo = Table_GetPendantEffectInfo(nEffectID)
    if not tInfo then
        return
    end

    local nType = CharacterEffectData.GetLogicTypeByEffectType(tInfo.szType)
    return nType, nEffectID
end

function ExteriorCharacter.PreviewRewardsEffectSfx(tItem)
    local nType, nEffectID = ExteriorCharacter.GetRewardsEffectSfxType(tItem)
    if not nType then
        return
    end

    if not nEffectID then
        return
    end

    FireUIEvent("PREVIEW_PENDANT_EFFECT_SFX", nType, nEffectID, tItem)
end

function ExteriorCharacter.SetEffectSfxState(nType, nState, bUpdate)
    local nIndex = COINSHOP_BOX_INDEX.EFFECT_SFX
    if not ExteriorCharacter.m_tRoleViewData[nIndex][nType] then
        return
    end
    ExteriorCharacter.m_tRoleViewData[nIndex][nType].nState = nState

    ExteriorCharacter.ResUpdate_EffectSfx(nType,  ExteriorCharacter.m_tRoleViewData[nIndex][nType].nEffectID, nState)
    if bUpdate then
        local hModel    = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
        local tInfo     = ExteriorCharacter.GetPreviewEffectRepresent(nType)
        hModel:SetAEffectSfx(nType, tInfo)
    end
end

function ExteriorCharacter.GetPreviewEffectRepresent(nType)
    if ExteriorCharacter.m_tRepresentID.tEffect then
        return ExteriorCharacter.m_tRepresentID.tEffect[nType]
    end
end

function ExteriorCharacter.ClearPreviewEffect(nType, bUpdate)
    local nIndex = COINSHOP_BOX_INDEX.EFFECT_SFX

    ExteriorCharacter.m_tRoleViewData[nIndex] = ExteriorCharacter.m_tRoleViewData[nIndex] or {}
    ExteriorCharacter.m_tRoleViewData[nIndex][nType] = nil

    ExteriorCharacter.m_tRepresentID.tEffect = ExteriorCharacter.m_tRepresentID.tEffect or {}
    ExteriorCharacter.m_tRepresentID.tEffect[nType] = nil

    FireUIEvent("ON_EFFECT_CHANGED", nType)
    if bUpdate then
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end
end

function ExteriorCharacter.GetPreviewEffect(nType)
    local nIndex = COINSHOP_BOX_INDEX.EFFECT_SFX
    if ExteriorCharacter.m_tRoleViewData[nIndex] then
        return ExteriorCharacter.m_tRoleViewData[nIndex][nType]
    end
end

function ExteriorCharacter.IsPreviewEffect(nType, nEffectID)
    local nIndex = COINSHOP_BOX_INDEX.EFFECT_SFX
    if not ExteriorCharacter.m_tRoleViewData[nIndex] or not ExteriorCharacter.m_tRoleViewData[nIndex][nType] then
        return
    end

    local tInfo = ExteriorCharacter.m_tRoleViewData[nIndex][nType]
    if not tInfo then
        return
    end

    return tInfo.nEffectID == nEffectID
end

function ExteriorCharacter.SetAllPreviewEffectCustomPos()
    if not ExteriorCharacter.m_tRepresentID.tEffect then
        return
    end
    for nType, tInfo in pairs(ExteriorCharacter.m_tRepresentID.tEffect) do
        ExteriorCharacter.SetPreviewEffectCustomPos(nType)
    end
    return ExteriorCharacter.m_tRepresentID.tEffect
end

function ExteriorCharacter.UpdateEffectPos(nType)
    ExteriorCharacter.SetPreviewEffectCustomPos(nType)
    local hModel = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
    if hModel and ExteriorCharacter.m_tRepresentID.tEffect[nType] then
        if ExteriorCharacter.m_tRepresentID.tEffect[nType].tCustomPos then
            hModel:UpdateEffectCustom(nType, ExteriorCharacter.m_tRepresentID.tEffect[nType].tCustomPos)
        end
    end
end

function ExteriorCharacter.GetScene(szFrame, szName)
    local szFrame = szFrame or "CoinShop_View"
    local szName = szName or "CoinShop"
    local tFrame = nil

    if ExteriorCharacter.tResisterFrame[szFrame] then
        tFrame = ExteriorCharacter.tResisterFrame[szFrame][szName]
    end

    return tFrame and tFrame.scene
end

-- 开启镜头光
function ExteriorCharacter.OpenCameraLight(szFrame, szStore)
    local scene = ExteriorCharacter.GetScene(szFrame, szStore)
    if scene and not QualityMgr.bDisableCameraLight then
        scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
    end
end

-- 恢复镜头光
function ExteriorCharacter.RestoreCameraLight(szFrame, szStore)
    local scene = ExteriorCharacter.GetScene(szFrame, szStore)
    if scene then
        scene:RestoreCameraLight()
    end
end

