PendantModelView = class("PendantModelView")
PendantModelView.tResisterFrame = {}
PendantModelView.IsPendant = true

local function InitCameraWithType(nWidth, nHeight, tFrame, szType, nIndex, nZoomIndex, nZoomValue)
    tFrame.camera:init(tFrame.hPendantModelView.m_scene, 0, 0, 0, 0, 0, 0, 0.3, nWidth / nHeight, nil, 40000, true)
    tFrame.camera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
end

function RegisterPendantPreview(tParam)
    local szFrame = tParam.szFrameName
    local szName = tParam.szName
    PendantModelView.tResisterFrame[szFrame] = PendantModelView.tResisterFrame[szFrame] or {}
    local tFrame = PendantModelView.tResisterFrame[szFrame][szName]
    if tFrame then
        local hPendantModelView = tFrame.hPendantModelView
        if hPendantModelView then
            hPendantModelView:UnloadModel()
            hPendantModelView:release()
            tFrame.hPendantModelView = nil
        end

        PendantModelView.tResisterFrame[szFrame][szName] = nil
    end

    PendantModelView.tResisterFrame[szFrame][szName] = tParam
    PendantModelView.Init(szFrame, szName)
end

local function InitCamera(nWidth, nHeight, tFrame, tCamera, tCenterPos)
    if not tCenterPos and tCamera[9] then
        tCenterPos = {tCamera[8], tCamera[9], tCamera[10]}
    end
    tFrame.camera:init(tFrame.hPendantModelView.m_scene, tCamera[1], tCamera[2], tCamera[3] , tCamera[4], tCamera[5], tCamera[6], math.pi / 4, nWidth / nHeight, nil, nil, true, tCenterPos)
end

local function InitCameraWithType(nWidth, nHeight, tFrame, szType, nIndex, nZoomIndex, nZoomValue)
    tFrame.camera:init(tFrame.hPendantModelView.m_scene, 0, 0, 0, 0, 0, 0, 0.3, nWidth / nHeight, nil, 40000, true)
    tFrame.camera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
end

local function IsEquipType(equipType)
    if equipType ~= "MDL" and equipType ~= "MDLScale" and equipType ~= "nWeaponType" and equipType ~= "nHeadformID" then
        return true
    end
end

local function Replace(tRepresentID, tReplaceList)
    for _, tReplace in ipairs(tReplaceList) do
        tRepresentID[tReplace[1]] = tReplace[2]
    end
end

local function CheckReplace(tRepresentID, tKeyList)
    for _, tKey in ipairs(tKeyList) do
        if tRepresentID[tKey[1]] ~= tKey[2] then
            return false
        end
    end
    return true
end
function PendantModelView:GetReplace(tRepresentID)
	local tViewReplace = Table_ViewReplace()
    for _, tLine in ipairs(tViewReplace) do
        local bReplace = CheckReplace(tRepresentID, tLine.tKey)
        if bReplace then
			return tLine.tReplace
		 end
    end
end

function PendantModelView:RepresentReplace(tRepresentID)
    local tReplace = self:GetReplace(tRepresentID)
    if tReplace then
        Replace(tRepresentID, tReplace)
    end
end
function PendantModelView:ctor()
	self.m_modelMgr = nil;
    self.m_modelRole = nil;
    self.m_aEquipRes = {};
    self.bMainPlayer = true
    self.bForceRealInterpolate = false
end

function PendantModelView:release()
	self:Free3D()
end

function PendantModelView:Mdl()
    return self.m_modelPendant["MDL"];
end


function PendantModelView:init(scene, szSceneFilePath, szName)
    self:Init3D(scene, szSceneFilePath, szName)
end

function PendantModelView:InitBy(tParam)
    self:Init3D(tParam)
end

function PendantModelView:Init3D(tParam)
    local szExSceneFile = tParam.szExSceneFile
    local szEnvPath = tParam.szEnvPath
    if tParam.scene then
        self.m_scene = tParam.scene
        self.bMgrScene = false
        self.bForceRealInterpolate = true
        self.bMainPlayer = true
    elseif tParam.bExScene then
        self.m_scene = SceneHelper.Create(szExSceneFile, false, false, true)
        self.bMgrScene = true
        self.bForceRealInterpolate = true
        self.bMainPlayer = true
    else
        self.m_scene = SceneHelper.NewScene_Old(szEnvPath, tParam.szName)
        self.bMgrScene = true
    end

    self.bModLod = false
    if tParam.bModLod then
        self.bModLod = tParam.bModLod
    end

    self.bExScene = tParam.bExScene
    self.m_modelMgr = KG3DEngine.GetModelMgr()
    if self.bMgrScene then
        self:SetCamera({ 0, 150, -200, 0, 0, 0 })
    end
end

function PendantModelView:Free3D()
    self:UnloadModel()
    if self.bMgrScene then
        if self.bExScene then
            SceneHelper.Delete(self.m_scene)
        else
            SceneHelper.DeleteScene_Old(self.m_scene)
        end
    end
    self.bMgrScene = nil
    self.m_scene=nil
    self._x, self._y, self._z = nil, nil ,nil
    self._yaw = nil
end

function PendantModelView:SwitchScene(tParam)
    if self.bMgrScene then
        if self.bExScene then
            SceneHelper.Delete(self.m_scene)
        else
            SceneHelper.DeleteScene_Old(self.m_scene)
        end
    end
    if tParam.scene then
        self.m_scene = tParam.scene
        self.bMgrScene = false
    elseif tParam.bExScene then
        self.m_scene = SceneHelper.Create(tParam.szExSceneFile, false, false, true)
        self.bMgrScene = true
    else
        self.m_scene = SceneHelper.NewScene_Old(tParam.szEnvPath, tParam.szName)
        self.bMgrScene = true
    end
    self.bExScene = tParam.bExScene
end

function PendantModelView:SetCamera(args)
    if args.camera == nil then
        local xp = args[1]
        local yp = args[2]
        local zp = args[3]
        local xl = args[4]
        local yl = args[5]
        local zl = args[6]
        local p1 = args[7]
        local p2 = args[8]
        local p3 = args[9]
        local p4 = args[10]
        local bPerspective = args[11]

        self:SetCameraLookPos(xl, yl, zl)
        self.m_scene:SetMainPlayerPosition(xl, yl, zl)
        self:SetCameraPos(xp, yp, zp)

        if bPerspective then
            self:SetCameraPerspective(p1, p2, p3, p4)
        else
            self:SetCameraOrthogonal(p1, p2, p3, p4)
        end
    else
        local c = args.camera
        if c ~= nil then
            self:SetCameraPos(c[1], c[2], c[3])
        end

        local l = args.lookat
        if l ~= nil then
            self:SetCameraLookPos(l[1], l[2], l[3])
        end

        local p = args.player
        if p ~= nil then
            self.m_scene:SetMainPlayerPosition(p[1], p[2], p[3])
        else
            self.m_scene:SetMainPlayerPosition(l[1], l[2], l[3])
        end

        local fovy = args.fovy
        if fovy ~= nil then
            local aspect = args.aspect
            local z_near = args.z_near
            local z_far = args.z_far

            self:SetCameraPerspective(fovy, aspect, z_near, z_far)
        end

        local width = args.width
        if width ~= nil then
            local height = args.height
            local z_near = args.z_near
            local z_far = args.z_far

            self:SetCameraOrthogonal(width, height, z_near, z_far)
        end
    end;
end

function PendantModelView:SetCameraPosition(tCameraPosion)
	local xp = tCameraPosion[1]
	local yp = tCameraPosion[2]
	local zp = tCameraPosion[3]
	local xl = tCameraPosion[4]
	local yl = tCameraPosion[5]
	local zl = tCameraPosion[6]

	self:SetCameraLookPos(xl, yl, zl)
	self:SetCameraPos(xp, yp, zp)
end

function PendantModelView:GetCameraPos()
    return self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ
end

function PendantModelView:SetCameraPos(x, y, z)
    self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ = x, y, z
    self.m_scene:SetCameraPosition(x, y, z)
end

function PendantModelView:GetCameraLookPos()
    return self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ
end

function PendantModelView:SetCameraLookPos(x, y, z)
    self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ = x, y, z
    self.m_scene:SetCameraLookAtPosition(x, y, z)
end

function PendantModelView:GetCameraPerspective()
    return self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar
end

function PendantModelView:SetCameraPerspective(fovY, aspect, near, far)
    self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar = fovY, aspect, near, far
    self.m_scene:SetCameraPerspective(fovY, aspect, near, far)
end

function PendantModelView:GetCameraOrthogonal()
    return self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar
end

function PendantModelView:SetCameraOrthogonal(w, h, near, far)
    self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar = w, h, near, far
    self.m_scene:SetCameraOrthogonal(w, h, near, far)
end


function PendantModelView:LoadModelSFXByName(model, equipType, aNewEquipRes, szName, bSocket, fSfxScale)
    if aNewEquipRes[equipType][szName] then
        local mdl = self.m_modelPendant["MDL"]
        local modelsfx = self.m_modelMgr:NewModel(aNewEquipRes[equipType][szName], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
        self.m_modelPendantSFX[equipType .. szName] = modelsfx
        if modelsfx then
            if aNewEquipRes[equipType]["SFXSocketName"] then
                modelsfx:BindToSocket(mdl, aNewEquipRes[equipType]["SFXSocketName"])

                local scale = aNewEquipRes[equipType]["MeshScale"]
                if bSocket and scale then
                    scale = scale * fSfxScale
                    modelsfx:SetScaling(scale, scale, scale)
                else
                    modelsfx:SetScaling(fSfxScale, fSfxScale, fSfxScale)
                end
            else
                modelsfx:BindToBone(model)
            end
        end
    end
end


function PendantModelView:LoadModelSFX(model, equipType, aNewEquipRes, bSocket)
    --Load SFX1
    local fSfx1Scale = aNewEquipRes[equipType]["SFX1Scale"]
    self:LoadModelSFXByName(model, equipType, aNewEquipRes, "SFX1", bSocket, fSfx1Scale)

    --Load SFX2
    local fSfx2Scale = aNewEquipRes[equipType]["SFX2Scale"]
    self:LoadModelSFXByName(model, equipType, aNewEquipRes, "SFX2", bSocket, fSfx2Scale)
end;

function PendantModelView:UnloadModelSFX(equipType)
    --Unload SFX2
    if self.m_modelPendantSFX[equipType.."SFX2"] then
        self.m_modelPendantSFX[equipType.."SFX2"]:UnbindFromOther()
        self.m_modelPendantSFX[equipType.."SFX2"]:Release()
        self.m_modelPendantSFX[equipType.."SFX2"] = nil
        --
    end
    --Unload SFX1
    if self.m_modelPendantSFX[equipType.."SFX1"] then
        self.m_modelPendantSFX[equipType.."SFX1"]:UnbindFromOther()
        self.m_modelPendantSFX[equipType.."SFX1"]:Release()
        self.m_modelPendantSFX[equipType.."SFX1"] = nil
    end
end;

function PendantModelView:LoadModel()
    if not self.m_aEquipRes or not self.m_aEquipRes["MDL"] then
        return
    end
    self.m_modelPendant = self.m_modelPendant or {}
	local aEquipRes = self.m_aEquipRes
    local scale = nil
    local model = nil
    local equipType = self.m_szRepresentType
    if equipType and aEquipRes[equipType] then
        local mesh = aEquipRes[self.m_szRepresentType]["Mesh"]
        if mesh then
            model = self.m_modelMgr:NewModel(mesh, true, false, false, true)

        end
    end
    if model then
        if aEquipRes[equipType]["ColorChannel"] then
            model:SetDetail(self.m_nRoleType, aEquipRes[equipType]["ColorChannel"])
        end
        scale = aEquipRes[equipType]["MeshScale"]
        model:SetScaling(scale , scale , scale)
        self.m_scene:AddRenderEntity(model)
        self.m_modelPendant["MDL"] = model
        self.bModelInScene = true
        if self.reg_handler then
            self:RegisterEventHandler()
        end
    end
end

function PendantModelView:UnloadModel()
	if not self.m_modelPendant then
		return
	end
    local mdl = self.m_modelPendant["MDL"]
    if mdl then
        if self.bModelInScene then
            self.m_scene:RemoveRenderEntity(mdl)
        end

        mdl:Release()
    end

    if self.m_tExModel then
        for k, v in pairs(self.m_tExModel) do
            self:RemoveModel(k)
        end
    end
    self.m_tExModel = nil
	self.m_modelPendant["MDL"] = nil
    self.m_modelPendantSFX = nil
	self.bModelInScene = nil
	self.m_aDecalAttr = nil
	self.m_modelPendant = nil
end

function PendantModelView:AddExModel(szModelPath, scale)
    self.m_tExModel =  self.m_tExModel or {}
    local model = self.m_modelMgr:NewModel(UIHelper.UTF8ToGBK(szModelPath), true, false, false, true)
    self.m_scene:AddRenderEntity(model)
    model:SetScaling(scale, scale, scale)
    self.m_tExModel[szModelPath] = model
end

function PendantModelView:RemoveModel(szModelPath)
    if self.m_tExModel and self.m_tExModel[szModelPath] then
        local mdl = self.m_tExModel[szModelPath]
        if mdl then
            if self.bModelInScene then
                self.m_scene:RemoveRenderEntity(mdl)
            end
            mdl:Release()
        end
        self.m_tExModel[szModelPath] = nil
    end
end

function PendantModelView:UnloadSocket(equipType)
    if not self.m_modelPendant then
		return
	end
    local model = self.m_modelPendant[equipType]
    if not model then
        return
    end

    self:UnloadModelSFX(equipType)
    model:UnbindFromOther()
    model:Release()

    model = nil
    self.m_modelPendant[equipType] = nil
end

function PendantModelView:LoadRes(itemInfo, nRepresentSub)
    local player = PlayerData.GetClientPlayer()
    local tRepresentID = Role_GetRepresentID(player)
    tRepresentID[nRepresentSub] = itemInfo.nRepresentID
    self.m_szRepresentType = GetCustomPendantType(nRepresentSub)
    self.m_nRepresentID = itemInfo.nRepresentID

    local nRoleType = Player_GetRoleType(player)
    local dwSchoolID = player.dwSchoolID
    self.m_aOriginalRepresentID = clone(tRepresentID)
    local aTransformID = self:TransformEquipDefaultResource(tRepresentID, nRoleType, dwSchoolID)
    for i = 0, EQUIPMENT_REPRESENT.TOTAL-1 do
        tRepresentID[i] = aTransformID[i]
    end
    local bModified = false

    if not self.m_aRepresentID or not self.m_modelPendant then
        self.m_aRepresentID = clone(tRepresentID)
        self.m_nRoleType = nRoleType
        self.m_dwSchoolID = dwSchoolID
        bModified = true
    else
        for i, v in pairs(tRepresentID) do
            if v ~= self.m_aRepresentID[i] then
                self.m_aRepresentID[i] = v
                bModified = true
            end
        end

        for i, v in pairs(self.m_aRepresentID) do
            if tRepresentID[i] == nil then
                self.m_aRepresentID[i] = nil
                bModified = true
            end
        end

        if self.m_nRoleType ~= nRoleType then
            bModified = true
        end
    end
    self:UpdateFacePendant()
    if bModified then
        local aNewEquipRes = self:GetModuleRes(nRoleType, dwSchoolID, self.m_aRepresentID, true)
        if aNewEquipRes and aNewEquipRes["MDL"] then
            self.m_aEquipRes = aNewEquipRes
        end
    end
end

function PendantModelView:GetMdl()
    if not self.m_modelPendant then
        return
    end

    return self.m_modelPendant["MDL"]
end


function PendantModelView:SetTranslation(fX, fY, fZ)
	if not self.m_modelPendant or not self.m_modelPendant["MDL"] then
		return
	end

    self._x, self._y, self._z = fX, fY, fZ
	self.m_modelPendant["MDL"]:SetTranslation(fX, fY, fZ)
end

function PendantModelView:GetTranslation()
    return (self._x or 0), (self._y or 0), (self._z or 0)
end

function PendantModelView:SetDetail(nDetails)
	if not self.m_modelPendant or not self.m_modelPendant["MDL"] then
		return
	end
	self.m_modelPendant["MDL"]:SetModelDetails(nDetails)
end

function PendantModelView:SetScaling(fScale)
	if not self.m_modelPendant or not self.m_modelPendant["MDL"] then
		return
	end
	self.m_modelPendant["MDL"]:SetScaling(fScale, fScale, fScale)
end

function PendantModelView:SetAlpha(fAlpha)
	if not self.m_modelPendant or not self.m_modelPendant["MDL"] then
		return
	end
	self.m_modelPendant["MDL"]:SetAlpha(fAlpha)
end


-- 挂件模型特殊处理，因为它本身就是倒着放的
-- 所以SetYaw，其实就是设置SetEulerRotation，然后固定X为0，Z为90，这样旋转Y轴才有用
function PendantModelView:SetYaw(yaw)
    if not self.m_modelPendant or not self.m_modelPendant["MDL"] then
        return
    end

    local mdl = self.m_modelPendant["MDL"]
    if mdl then
        self._yaw = yaw

        mdl:SetEulerRotation(0, self._yaw, 90)
        --mdl:SetYaw(yaw)
    end
end

function PendantModelView:GetYaw()
    return (self._yaw or 0)
end

function PendantModelView:GetModuleRes(nRoleType, dwSchoolID, tRepresentID, bReplace)
    if bReplace then
        self:RepresentReplace(tRepresentID, tRepresentID.bHideHair)
    end

    local bNewFace = false
    if tRepresentID.tFaceData then
        bNewFace = tRepresentID.tFaceData.bNewFace
    else
        bNewFace = tRepresentID.bNewFace
    end

    local tRes = Player_GetEquipResource(
        nRoleType,
        EQUIPMENT_REPRESENT.TOTAL,
        tRepresentID,
        tRepresentID.bUseLiftedFace,
        false,
        tRepresentID.nHatStyle,
        bNewFace
    )
    return tRes
end

function PendantModelView:TransformEquipDefaultResource(aRepresentID, nRoleType, dwSchoolID)
    local aTransformID = Player_TransformEquipDefaultResource(
        nRoleType,
        dwSchoolID,
        aRepresentID.nHatStyle,
        aRepresentID
    )
    if aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] == 0 then
        aTransformID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
    end
    if aRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] == 0 then
        aTransformID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end
    return aTransformID
end

function PendantModelView:UpdateFacePendant()
    if self.m_aRepresentID.bHideFacePendent then
        self.m_aRepresentID[EQUIPMENT_REPRESENT.FACE_EXTEND] = 0
    end
end

function PendantModelView:IsRegisterEventHandler()
    return self.reg_handler
end

function PendantModelView:RegisterEventHandler()
    if self.reg_handler then
        return
    end
    self.reg_handler = true
    self.m_modelPendant["MDL"]:RegisterEventHandler()
end

function PendantModelView:UnRegisterEventHandler()
    self.reg_handler = nil
    self.m_modelPendant["MDL"]:UnregisterEventHandler()
end

function PendantModelView.Init(szFrame, szName)
    local tFrame = PendantModelView.tResisterFrame[szFrame][szName]

    local hPendantModelView = PendantModelView.CreateInstance(PendantModelView)
    hPendantModelView:ctor()
    hPendantModelView:init({
        szName = tFrame.szName,
        scene = tFrame.scene,
    })
    tFrame.hPendantModelView = hPendantModelView
    tFrame.Viewer:SetScene(hPendantModelView.m_scene)

    tFrame.camera = MiniSceneCamera.CreateInstance(MiniSceneCamera)
    tFrame.camera:ctor()

    local nWidth, nHeight = UIHelper.GetContentSize(tFrame.Viewer)
    InitCameraWithType(nWidth, nHeight, tFrame, tFrame.szCameraType, tFrame.nCameraIndex, tFrame.nDefaultZoomIndex, tFrame.nDefaultZoomValue)
    if tFrame.tbCameraOffset then
        tFrame.camera:SetOffsetAngle(tFrame.tbCameraOffset[1], tFrame.tbCameraOffset[2], tFrame.tbCameraOffset[3],
                tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
    end
    if tFrame.tPos then
        tFrame.camera:set_mainplayer_pos(tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
    end
end
