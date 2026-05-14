RidesModelView = class("RidesModelView")

local FRAME_NUM = 25

local function InitCamera(nWidth, nHeight, tFrame, tCamera, tCenterPos)
    if not tCenterPos and tCamera[9] then
        tCenterPos = {tCamera[8], tCamera[9], tCamera[10]}
    end
    tFrame.camera:init(tFrame.hRidesModelView.m_scene, tCamera[1], tCamera[2], tCamera[3] , tCamera[4], tCamera[5], tCamera[6], math.pi / 4, nWidth / nHeight, nil, nil, true, tCenterPos)
end

local function InitCameraWithType(nWidth, nHeight, tFrame, szType, nIndex, nZoomIndex, nZoomValue)
    tFrame.camera:init(tFrame.hRidesModelView.m_scene, 0, 0, 0, 0, 0, 0, 0.3, nWidth / nHeight, nil, 40000, true)
    tFrame.camera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
end

local function InitRidesAnimation()
    local tRes, tAnimation = {}, {}
    local nCount = g_tTable.RideModelAnimation:GetRowCount()
    for i = 1, nCount do
        local tLine = g_tTable.RideModelAnimation:GetRow(i)
        tAnimation[tLine.szAnimationName] = tLine.dwAnimationID
        tRes[tLine.szAnimationName] = {}
    end
    return tRes, tAnimation
end

function RidesModelView:ctor()
    self.m_modelMgr = nil

    self.m_RidesMDL = nil
    self.m_aRidesEquipRes = {}
    self.m_ResourceSFX = nil
    self.m_ResourceMdlSFX = nil
    self.m_PartSFX = nil
    -- self.m_aRidesAnimationRes = { Idle = {}, EatGrass = {}  }
    -- self.m_aRidesAnimation = { Idle = 10000, EatGrass = 99999 }
    self.m_aRidesAnimationRes, self.m_aRidesAnimation = InitRidesAnimation()

    self.m_NpcMDL = nil
    self.m_aNpcEquipRes = {}
    self.m_aNpcAnimationRes = { Idle = {} }
    self.m_aNpcAnimation = { Idle = 30 }
end;

function RidesModelView:init(scene, szSceneFilePath, szName)
    self:Init3D(scene, szSceneFilePath, szName)
end;

function RidesModelView:release()
    self:Free3D()
end;

function RidesModelView:Init3D(scene, szSceneFilePath, szName)
    if scene then
        self.m_scene = scene
        self.bMgrScene = false
    else
        self.m_scene = SceneHelper.Create(szSceneFilePath, true, true, true)
        self.bMgrScene = true
    end
    self.m_modelMgr = KG3DEngine.GetModelMgr()

    self:SetCamera({ 0, 150, -200, 0, 50, 150 })
end;

function RidesModelView:Free3D()
    self:UnloadRidesModel()
    self:UnloadNpcModel()

    if self.bMgrScene then
        SceneHelper.Delete(self.m_scene)
        self.m_scene = nil
    else
        self.m_scene = nil
    end
end

function RidesModelView:SetCamera(aParams)
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

    if bPerspective then
        self:SetCameraPerspective(p1, p2, p3, p4)
    else
        self:SetCameraOrthogonal(p1, p2, p3, p4)
    end
end;

function RidesModelView:GetCameraPos()
    return self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ
end

function RidesModelView:SetCameraPos(x, y, z)
    self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ = x, y, z
    self.m_scene:SetCameraPosition(x, y, z)
end

function RidesModelView:GetCameraLookPos()
    return self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ
end

function RidesModelView:SetCameraLookPos(x, y, z)
    self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ = x, y, z
    self.m_scene:SetCameraLookAtPosition(x, y, z)
end

function RidesModelView:GetCameraPerspective()
    return self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar
end

function RidesModelView:SetCameraPerspective(fovY, aspect, near, far)
    self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar = fovY, aspect, near, far
    self.m_scene:SetCameraPerspective(fovY, aspect, near, far)
end

function RidesModelView:GetCameraOrthogonal()
    return self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar
end

function RidesModelView:SetCameraOrthogonal(w, h, near, far)
    self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar = w, h, near, far
    self.m_scene:SetCameraOrthogonal(w, h, near, far)
end

function RidesModelView:LoadRidesRes(dwPlayerID, bPortraitOnly)
    -- load model and mesh
    local player=GetPlayer(dwPlayerID)
    if not player then
        return
    end

    local aRepresentID = RideExteriorData.GetPlayerRideRepresentID(player)
    self:LoadResByRepresent(aRepresentID, bPortraitOnly)
end

function RidesModelView:LoadResByRepresent(aRepresentID, bPortraitOnly)
    local dwRideResID = aRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE]
    self.fScale = nil
    self.m_aRidesEquipRes = Player_GetRidesEquipResource(
        dwRideResID,
        dwRideResID,
        dwRideResID,
        aRepresentID[EQUIPMENT_REPRESENT.HORSE_ADORNMENT1],
        aRepresentID[EQUIPMENT_REPRESENT.HORSE_ADORNMENT2],
        aRepresentID[EQUIPMENT_REPRESENT.HORSE_ADORNMENT3],
        aRepresentID[EQUIPMENT_REPRESENT.HORSE_ADORNMENT4])
    local res = self.m_aRidesEquipRes
    if bPortraitOnly then
        res["EquipMain"]["Socket"], res["EquipMain"]["Mesh"], res["EquipMain"]["Mtl"], res["EquipMain"]["MeshScale"] = nil, nil, nil, nil
        res["SocketMain"]["Socket"], res["SocketMain"]["Mesh"], res["SocketMain"]["Mtl"], res["SocketMain"]["MeshScale"] = nil, nil, nil, nil
        res["Socket1"]["Socket"], res["Socket1"]["Mesh"], res["Socket1"]["Mtl"], res["Socket1"]["MeshScale"] = nil, nil, nil, nil
        res["Socket2"]["Socket"], res["Socket2"]["Mesh"], res["Socket2"]["Mtl"], res["Socket2"]["MeshScale"] = nil, nil, nil, nil
        res["Socket3"]["Socket"], res["Socket3"]["Mesh"], res["Socket3"]["Mtl"], res["Socket3"]["MeshScale"] = nil, nil, nil, nil
        res["Socket4"]["Socket"], res["Socket4"]["Mesh"], res["Socket4"]["Mtl"], res["Socket4"]["MeshScale"] = nil, nil, nil, nil
    end

    -- load animation
    for szAniName, v in pairs(self.m_aRidesAnimationRes) do
        self.m_aRidesAnimationRes[szAniName] = {
            Ani = nil, AniSound = nil, AniPlayType = "loop", AniPlaySpeed = 1, AniSoundRange = 0,
            SFX = nil, SFXBone = nil, SFXPlayType = "loop", SFXPlaySpeed = 1, SFXScale = 1
        }

        local aAniRes = self.m_aRidesAnimationRes[szAniName]

        aAniRes["Ani"], aAniRes["AniSound"], aAniRes["AniPlayType"], aAniRes["AniPlaySpeed"], aAniRes["AniSoundRange"],
        aAniRes["SFX"], aAniRes["SFXBone"], aAniRes["SFXPlayType"], aAniRes["SFXPlaySpeed"], aAniRes["SFXScale"]
            = Player_GetRidesAnimationResource(dwRideResID, self.m_aRidesAnimation[szAniName])
    end

    self.fScale, self.fRidesYaw, self.fOffsetY = nil, nil, nil
    if dwRideResID >= 0 then
        local tLine = Table_GetRideModelInfo(dwRideResID);
        if tLine then
            self.fScale, self.fRidesYaw, self.fOffsetY = tLine.fScale, tLine.fYaw, tLine.fOffsetY
        end
    end
end

local function OnSfxFind(model, UserData, bFind)
    if not bFind then
        return
    end
    local szSocketName = UserData.szSocketName
    local tSFX = UserData.tSFX
    local sfx = UserData.sfx
    local sub = string.lower(string.sub(szSocketName, 1, 2))

    local scale = tSFX["Scale"]
    sfx:SetScaling(scale, scale, scale)
    local tPosition = tSFX.Position
    local tRotation = tSFX.Rotation
    sfx:SetRotation(tRotation.x, tRotation.y, tRotation.z, tRotation.w)
    sfx:SetTranslation(tPosition.x, tPosition.y, tPosition.z)

    if sub == "s_" then
        sfx:BindToSocket(model, szSocketName)
    else
        sfx:BindToBone(model, szSocketName)
    end
end

function RidesModelView:LoadResourceSFX(equipType, tSFXList)
    self.m_ResourceSFX[equipType] = self.m_ResourceSFX[equipType] or {}
    local tModels = self.m_ResourceSFX[equipType]
    for szSocketName, tSFX in pairs(tSFXList) do
        if not tModels[szSocketName] then
            self:BindSFX(szSocketName, tSFX, tModels)
        end
    end
end

function RidesModelView:UnloadResourceSFX(equipType)
    local tModels = self.m_ResourceSFX[equipType] or {}
    for szSocketName, model in pairs(tModels) do
        model:UnbindFromOther()
        model:Release()
        tModels[szSocketName] = nil
    end
    self.m_ResourceSFX[equipType] = nil
end

function RidesModelView:LoadResourceMdlSFX(tSFXList)
    self.m_ResourceMdlSFX = self.m_ResourceMdlSFX or {}
    local tModels = self.m_ResourceMdlSFX
    for szSocketName, tSFX in pairs(tSFXList) do
        if not tModels[szSocketName] then
            self:BindSFX(szSocketName, tSFX, tModels)
        end
    end
end

function RidesModelView:UnloadResourceMdlSFX()
    local tModels = self.m_ResourceMdlSFX or {}
    for szSocketName, model in pairs(tModels) do
        model:UnbindFromOther()
        model:Release()
        tModels[szSocketName] = nil
    end
    self.m_ResourceMdlSFX = nil
end

function RidesModelView:BindSFX(szSocketName, tSFX, tModels)
    local sfx = self.m_modelMgr:NewModel(tSFX["SfxPath"])
    for equipType, model in pairs(self.m_RidesMDL) do
        if equipType == "MDL" then
            -- 2023.8.3因一个特效重复绑定会影响缩放，因此改为只对MDL绑定
            local UserData = {}
            UserData.szSocketName = szSocketName
            UserData.tSFX = tSFX
            UserData.tModels = tModels
            UserData.sfx = sfx
            Post3DModelThreadCall(OnSfxFind, UserData, model, "Find", szSocketName)
        end
    end
    tModels[szSocketName] = sfx
end

function RidesModelView:LoadPartSFX(szSFX, szSFXSocket, mdl)
    local sfx = self.m_modelMgr:NewModel(szSFX)
    self.m_PartSFX[szSFXSocket] = sfx
    if sub == "s_" then
        sfx:BindToSocket(mdl, szSFXSocket)
    else
        sfx:BindToBone(mdl, szSFXSocket)
    end
end

function RidesModelView:UnloadPartSFX(equipType)
    local model = self.m_PartSFX[equipType] or {}
    model:UnbindFromOther()
    model:Release()
    self.m_PartSFX[equipType] = nil
end

function RidesModelView:LoadRidesModel()
    if self.m_RidesMDL then
        return
    end

    local aEquipRes = self.m_aRidesEquipRes

    if aEquipRes["MDL"] then
        self.m_RidesMDL = {}

        local mdl = self.m_modelMgr:NewModel(aEquipRes["MDL"], false, false, false, true)
        self.m_RidesMDL["MDL"] = mdl
        if not mdl then
            return
        end

        mdl:SetDetail(aEquipRes["ColorChannelTable"], aEquipRes["ColorChannel"])

        local tResourceSFX = {}
        local tResourceMDLSFX = {}
        self.m_ResourceSFX = self.m_ResourceSFX or {}

        self.m_PartSFX = self.m_PartSFX or {}

        for equipType, equipRes in pairs(aEquipRes) do
            if type(equipRes) == "table" then
                if aEquipRes[equipType]["SFX"] and aEquipRes[equipType]["SFXSocket"] then
                    self:LoadPartSFX(aEquipRes[equipType]["SFX"], aEquipRes[equipType]["SFXSocket"], mdl)
                end

                if aEquipRes[equipType]["SFX2"] and aEquipRes[equipType]["SFXSocket2"] then
                    self:LoadPartSFX(aEquipRes[equipType]["SFX2"], aEquipRes[equipType]["SFXSocket2"], mdl)
                end
            end
        end

        local tSFXList = Global_GetResourceSfx(aEquipRes["MDL"], 0)
        tResourceMDLSFX = tSFXList

        -- load part
        for equipType, equipRes in pairs(aEquipRes) do
            if type(equipRes) == "table" and not aEquipRes[equipType]["Socket"] and aEquipRes[equipType]["Mesh"] then
                local model = self.m_modelMgr:NewModel(aEquipRes[equipType]["Mesh"], false, false, false, true, 0, mdl)
                self.m_RidesMDL[equipType] = model
                if model then
                    if aEquipRes[equipType]["Mtl"] then
                        model:LoadMaterialFromFile(aEquipRes[equipType]["Mtl"])
                    end

                    local scale = aEquipRes[equipType]["MeshScale"]

                    mdl:Attach(model)
                    --model:SetScaling(scale, scale, scale)
                    model:SetDetail(aEquipRes[equipType]["ColorChannelTable"], aEquipRes[equipType]["ColorChannel"])
                    --self:LoadModelSFX(model, equipType)

                    local tSFXList = Global_GetResourceSfx(aEquipRes[equipType]["Mesh"], aEquipRes[equipType]["ColorChannel"])
                    tResourceSFX[equipType] = tSFXList
                end
            end
        end

        -- load socket
        for equipType, equipRes in pairs(aEquipRes) do
            if type(equipRes) == "table" and aEquipRes[equipType]["Socket"] and aEquipRes[equipType]["Mesh"] then
                local model = self.m_modelMgr:NewModel(aEquipRes[equipType]["Mesh"], false, false, false, true, 0, mdl)
                self.m_RidesMDL[equipType] = model
                if model then
                    if aEquipRes[equipType]["Mtl"] then
                        model:LoadMaterialFromFile(aEquipRes[equipType]["Mtl"])
                    end

                    local scale = aEquipRes[equipType]["MeshScale"]

                    model:BindToSocket(mdl, aEquipRes[equipType]["Socket"])
                    model:SetScaling(scale, scale, scale)
                    model:SetDetail(aEquipRes[equipType]["ColorChannelTable"], aEquipRes[equipType]["ColorChannel"])
                    --self:LoadModelSFX(model, equipType)

                    local tSFXList = Global_GetResourceSfx(aEquipRes[equipType]["Mesh"], aEquipRes[equipType]["ColorChannel"])
                    tResourceSFX[equipType] = tSFXList

                    local szAni = aEquipRes[equipType]["Ani"]
                    if szAni and szAni ~= "" then
                        model:PlayAnimation("loop", szAni, 1.0, 0)
                    end
                end
            end
        end

        mdl:SetTranslation(0, (self.fOffsetY or 0), 0)
        self.m_scene:AddRenderEntity(mdl)
        if self.fScale then
            mdl:SetScaling(self.fScale, self.fScale, self.fScale)
        end

        -- load sfx
        for equipType, tSFXList in pairs(tResourceSFX) do
            self:LoadResourceSFX(equipType, tSFXList)
        end

        if tResourceMDLSFX then
            self:LoadResourceMdlSFX(tResourceMDLSFX)
        end
    end
end

function RidesModelView:SetScaling(fScale, fScale, fScale)
    if self.m_RidesMDL["MDL"] then
        if self.fScale then
            fScale = self.fScale * fScale
        end
        self.m_RidesMDL["MDL"]:SetScaling(fScale, fScale, fScale)
    end
end

function RidesModelView:SetTranslation(fX, fY, fZ)
    if not self.m_RidesMDL or not self.m_RidesMDL["MDL"] then
        return
    end
    self.m_RidesMDL["MDL"]:SetTranslation(fX, fY, fZ)
    self.nTransX, self.nTransY, self.nTransZ = fX, fY, fZ
end

function RidesModelView:GetTranslation()
    return self.nTransX, self.nTransY, self.nTransZ
end

function RidesModelView:SetMainFlag(bFlag)
    local mdl = self.m_RidesMDL and self.m_RidesMDL["MDL"]
    if mdl then
        mdl:SetMainFlag(bFlag)
    end
end

function RidesModelView:SetYaw(yaw)
    if not self.m_RidesMDL then return end
    local mdl = self.m_RidesMDL["MDL"]
    if mdl then
        self._yaw = yaw
        mdl:SetYaw(yaw)
    end
end

local CHARACTER_ROLE_TURN_YAW = math.pi / 54
function RidesModelView:TouchModel(bTouch, x, y)
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

function RidesModelView:GetYaw()
    return (self._yaw or 0)
end

function RidesModelView:Show(bShow)
    local mdl = self.m_RidesMDL["MDL"]
    if mdl then
        local fAlpha = 0
        if bShow then
            fAlpha = 1
        end
        mdl:SetAlpha(fAlpha)
    end
end

function RidesModelView:UnloadRidesModel()
    if not self.m_RidesMDL or not self.m_RidesMDL["MDL"] then
        return
    end

    self:UnloadResourceMdlSFX()

    for equipType, model in pairs(self.m_RidesMDL) do
        if model and self.m_ResourceSFX[equipType] then
            self:UnloadResourceSFX(equipType)
        end
    end

    for equipType, model in pairs(self.m_PartSFX) do
        self:UnloadPartSFX(equipType)
    end

    for equipType, model in pairs(self.m_RidesMDL) do
        if model and self.m_aRidesEquipRes[equipType]["Socket"] then
            --self:UnloadResourceSFX(equipType)
            model:UnbindFromOther()
            model:Release()
            model = nil
        end
    end

    for equipType, model in pairs(self.m_RidesMDL) do
        if model and not self.m_aRidesEquipRes[equipType]["Socket"] and equipType ~= "MDL" then
            --self:UnloadResourceSFX(equipType)
            self.m_RidesMDL["MDL"]:Detach(model)
            model:Release()
            model = nil
        end
    end

    self.m_scene:RemoveRenderEntity(self.m_RidesMDL["MDL"])
    self.m_RidesMDL["MDL"]:Release()
    self.m_RidesMDL["MDL"] = nil
    self.m_RidesMDL = nil
    self.m_ResourceSFX = nil
    self.m_ResourceMdlSFX = nil
    self.m_PartSFX = nil
end

function RidesModelView:PlayRidesAnimation(szAniName, szLoopType)
    if not self.m_RidesMDL or not self.m_RidesMDL["MDL"] then
        return
    end
    if not szAniName or not self.m_aRidesAnimationRes[szAniName].Ani then
        return
    end
    self.m_RidesMDL["MDL"]:PlayAnimation(szLoopType, self.m_aRidesAnimationRes[szAniName].Ani, 1, 0)
end

function RidesModelView:LoadNpcResByModelID(dwModelID, bPortraitOnly)
    self.m_aNpcEquipRes = NPC_GetEquipResource(dwModelID)
    local res = self.m_aNpcEquipRes
    if bPortraitOnly then
        local tNotNeedParts =
        {
            "S_LH",
            "S_LP",
            "S_LC",
            "S_RH",
            "S_RP",
            "S_RC",
            "S_Long",
            "S_Spine",
            "S_Spine2",
            "S_epee",
            "S_HS",
            "S_bow",
        }
        for _, szPart in ipairs(tNotNeedParts) do
            res[szPart]["Mesh"] = nil
            res[szPart]["Mtl"] = nil
        end
    end
    -- load animation
    for szAniName, v in pairs(self.m_aNpcAnimationRes) do
        self.m_aNpcAnimationRes[szAniName] = {
            Ani = "", AniSound = "", AniPlayType = "loop", AniPlaySpeed = 1, AniSoundRange = 0,
            SFX = "", SFXBone = "", SFXPlayType = "loop", SFXPlaySpeed = 1, SFXScale = 1
        }

        local aAniRes = self.m_aNpcAnimationRes[szAniName]

        aAniRes["Ani"], aAniRes["AniSound"], aAniRes["AniPlayType"], aAniRes["AniPlaySpeed"], aAniRes["AniSoundRange"],
        aAniRes["SFX"], aAniRes["SFXBone"], aAniRes["SFXPlayType"], aAniRes["SFXPlaySpeed"], aAniRes["SFXScale"]
        = NPC_GetAnimationResource(dwModelID, self.m_aNpcAnimation[szAniName])
    end
end

function RidesModelView:LoadNpcModel()
    if self.m_NpcMDL then
        return
    end

    local aEquipRes = self.m_aNpcEquipRes
    if aEquipRes["Main"] and aEquipRes["Main"]["MDL"] then

        local modelScale = aEquipRes["Main"]["ModelScale"]
        local socketScale = aEquipRes["Main"]["SocketScale"]
        local nColorChannelTable = aEquipRes["Main"]["ColorChannelTable"]
        local nColorChannel      = aEquipRes["Main"]["ColorChannel"]
        self.m_NpcMDL = {}

        local mdl = self.m_modelMgr:NewModel(aEquipRes["Main"]["MDL"])
        mdl:SetScaling(modelScale, modelScale, modelScale)
        mdl:SetTranslation(0, 0, 0)
        mdl:SetDetail(nColorChannelTable, nColorChannel)

        self.m_scene:AddRenderEntity(mdl)
        self.bNpcModelInScene = true
        -- load socket
        for equipType, equipRes in pairs(aEquipRes) do
            local socketName = aEquipRes[equipType]["Socket"]
            local meshFile = aEquipRes[equipType]["Mesh"]

            if socketName and meshFile then
                local model = self.m_modelMgr:NewModel(meshFile, false, false, false, true, 0, mdl)
                self.m_NpcMDL[equipType] = model
                if model then
                    local mtlFile = aEquipRes[equipType]["Mtl"]
                    if mtlFile then
                        model:LoadMaterialFromFile(mtlFile)
                    end
                    if equipType ~= "S_Face" then
                        model:SetScaling(socketScale, socketScale, socketScale)
                    end
                    model:BindToSocket(mdl, socketName)
                end
            end
        end
        self.m_NpcMDL["MDL"] = mdl
    end
end

function RidesModelView:SetNpcTranslation(fX, fY, fZ)
    if self.m_NpcMDL["MDL"] then
        self.m_NpcMDL["MDL"]:SetTranslation(fX, fY, fZ)
    end
end

function RidesModelView:SetNpcScaling(fScale, fScale, fScale)
    if self.m_NpcMDL["MDL"] then
        self.m_NpcMDL["MDL"]:SetScaling(fScale, fScale, fScale)
    end
end

function RidesModelView:PlayNpcAnimation(szAniName, szLoopType)
    if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
        return
    end
    if not szAniName or not self.m_aNpcAnimationRes[szAniName].Ani then
        return
    end
    self.m_NpcMDL["MDL"]:PlayAnimation(szLoopType, self.m_aNpcAnimationRes[szAniName].Ani, 1, 0)
end

function RidesModelView:UnloadNpcModel()
    if not self.m_NpcMDL then
        return
    end

    for equipType, model in pairs(self.m_NpcMDL) do
        if model and equipType ~= "MDL" then
            model:UnbindFromOther()
            model:Release()
            model = nil
        end
    end
    local mdl = self.m_NpcMDL["MDL"]
    if self.bNpcModelInScene then
        self.m_scene:RemoveRenderEntity(mdl)
    end

    mdl:Release()
    self.m_NpcMDL["MDL"] = nil
    self.bNpcModelInScene = nil

    self.m_NpcMDL = nil
end

RidesModelPreview = {className = "RidesModelPreview"}
RidesModelPreview.tResisterFrame = {}
RidesModelPreview.tEventFrame = {}

local STEP = 1

function RidesModelPreview.CreateOnLButtonDown(szFrame)
    RidesModelPreview.tEventFrame[szFrame].fnOldOnLButtonDown = _G[szFrame].OnLButtonDown
    _G[szFrame].OnLButtonDown = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local szName = this:GetName()
        local tFrameList = RidesModelPreview.tResisterFrame[szFrameName]
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = hFrame:Lookup(tFrame.szScene)
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
                    local hScene = hFrame:Lookup(tFrame.szScene)
                    Station.SetCapture(hScene)
                    break
                end
            end

            local tEvent = RidesModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnLButtonDown then
                return tEvent.fnOldOnLButtonDown()
            end
        end

    end
    RidesModelPreview.tEventFrame[szFrame].fnNewOnLButtonDown = _G[szFrame].OnLButtonDown
end

function RidesModelPreview.CreateOnLButtonUp(szFrame)
    RidesModelPreview.tEventFrame[szFrame].fnOldOnLButtonUp = _G[szFrame].OnLButtonUp
    _G[szFrame].OnLButtonUp = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = RidesModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = hFrame:Lookup(tFrame.szScene)
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

            local tEvent = RidesModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnLButtonUp then
                return tEvent.fnOldOnLButtonUp()
            end
        end


    end

    RidesModelPreview.tEventFrame[szFrame].fnNewOnLButtonUp = _G[szFrame].OnLButtonUp
end

function RidesModelPreview.CreateOnRButtonDown(szFrame)
    RidesModelPreview.tEventFrame[szFrame].fnOldOnRButtonDown = _G[szFrame].OnRButtonDown
    _G[szFrame].OnRButtonDown = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local szName = this:GetName()
        local tFrameList = RidesModelPreview.tResisterFrame[szFrameName]
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = hFrame:Lookup(tFrame.szScene)
                if szName == tFrame.szSceneName then
                    hScene.bLDown = true
                    local x, y = Station.GetMessagePos(false)
                    Cursor.Show(false)
                    hScene.nCX = x
                    hScene.nCY = y
                    local hScene = hFrame:Lookup(tFrame.szScene)
                    Station.SetCapture(hScene)
                    break
                end
            end

            local tEvent = RidesModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnRButtonDown then
                return tEvent.fnOldOnRButtonDown()
            end
        end

    end
    RidesModelPreview.tEventFrame[szFrame].fnNewOnRButtonDown = _G[szFrame].OnRButtonDown
end

function RidesModelPreview.CreateOnRButtonUp(szFrame)
    RidesModelPreview.tEventFrame[szFrame].fnOldOnRButtonUp = _G[szFrame].OnRButtonUp
    _G[szFrame].OnRButtonUp = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = RidesModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = hFrame:Lookup(tFrame.szScene)
                if szName == tFrame.szSceneName then
                    hScene.bLDown = false
                    Cursor.SetPos(hScene.nCX, hScene.nCY, false)
                    Cursor.Show(true)
                    Station.SetCapture(nil)
                    break
                end
            end

            local tEvent = RidesModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnRButtonUp then
                return tEvent.fnOldOnRButtonUp()
            end
        end
    end

    RidesModelPreview.tEventFrame[szFrame].fnNewOnRButtonUp = _G[szFrame].OnRButtonUp
end

function RidesModelPreview.CreateOnFrameBreathe(szFrame)
    RidesModelPreview.tEventFrame[szFrame].fnOldOnFrameBreathe = _G[szFrame].OnFrameBreathe
    _G[szFrame].OnFrameBreathe = function()
        local szFrameName = this:GetName()
        local tFrameList = RidesModelPreview.tResisterFrame[szFrameName]
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = this:Lookup(tFrame.szScene)
                if hScene.hRidesModelView and hScene.hRidesModelView.m_RidesMDL then
                    if hScene.bTurnRight then
                        hScene.fRidesYaw = hScene.fRidesYaw - CHARACTER_ROLE_TURN_YAW
                        hScene.hRidesModelView.m_RidesMDL["MDL"]:SetYaw(hScene.fRidesYaw)
                        break
                    elseif hScene.bTurnLeft then
                        hScene.fRidesYaw = hScene.fRidesYaw + CHARACTER_ROLE_TURN_YAW
                        hScene.hRidesModelView.m_RidesMDL["MDL"]:SetYaw(hScene.fRidesYaw)
                        break
                    end
                end
            end

            local tEvent = RidesModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnFrameBreathe then
                return tEvent.fnOldOnFrameBreathe()
            end
        end
    end

    RidesModelPreview.tEventFrame[szFrame].fnNewOnFrameBreathe = _G[szFrame].OnFrameBreathe
end

function RidesModelPreview.CreateOnMouseWheel(szFrame)
    RidesModelPreview.tEventFrame[szFrame].fnOldOnMouseWheel = _G[szFrame].OnMouseWheel
    _G[szFrame].OnMouseWheel = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = RidesModelPreview.tResisterFrame[szFrameName]
        local szName = this:GetName()
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                if tFrame.szSceneName and  szName == tFrame.szSceneName then
                    local hScene = hFrame:Lookup(tFrame.szScene)
                    local nDelta = Station.GetMessageWheelDelta()
                    if hScene.camera then
                        local tRadius = tFrame.tRadius
                        local fMinRadius
                        local fMaxRadius
                        if tRadius then
                            fMinRadius = tRadius[1]
                            fMaxRadius = tRadius[2]
                        end
                        hScene.camera:zoom(nDelta * 10, fMinRadius, fMaxRadius)
                        FireUIEvent("ON_RIDE_CAMERA_UPDATE", szFrameName, tFrame.szName)
                    end
                end
            end

            local tEvent = RidesModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnMouseWheel then
                local nResult = tEvent.fnOldOnMouseWheel()
                return nResult
            end
        end
    end

    RidesModelPreview.tEventFrame[szFrame].fnNewOnMouseWheel = _G[szFrame].OnMouseWheel
end

function RidesModelPreview.CreateOnFrameDestroy(szFrame)
    RidesModelPreview.tEventFrame[szFrame].fnOldOnFrameDestroy = _G[szFrame].OnFrameDestroy
    _G[szFrame].OnFrameDestroy = function()
        local szFrameName = this:GetName()
        local tFrameList = RidesModelPreview.tResisterFrame[szFrameName]
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hRidesModelView = tFrame.hRidesModelView
                if hRidesModelView then
                    hRidesModelView:UnloadRidesModel()
                    hRidesModelView:UnloadNpcModel()
                    hRidesModelView:release()
                    tFrame.hRidesModelView = nil
                end
            end

            local tEvent = RidesModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnFrameDestroy then
                local nResult = tEvent.fnOldOnFrameDestroy()
                RidesModelPreview.tResisterFrame[szFrameName] = {}
                return nResult
            end
            RidesModelPreview.tResisterFrame[szFrameName] = {}
        end
    end
    RidesModelPreview.tEventFrame[szFrame].fnNewOnFrameDestroy = _G[szFrame].OnFrameDestroy
end

local function CameraRotate(hScene, szFrameName, szName, tFrame)
    if hScene.bLDown then
        local x, y = Cursor.GetPos(false)
        local nCX, nCY = hScene.nCX, hScene.nCY
        if x ~= nCX or y ~= nCY then
            local cx, cy = Station.GetClientSize(false)
            local dx = -(x - nCX) / cx * math.pi
            local dy = (y - nCY) / cy * math.pi
            if tFrame.bDisableCamera then
                hScene.fRidesYaw = (hScene.fRidesYaw + dx) % (2 * math.pi)
                hScene.hRidesModelView.m_RidesMDL["MDL"]:SetYaw(hScene.fRidesYaw)
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
                hScene.camera:rotate(dy * STEP, dx * STEP,fMinVerAngle , fMaxVerAngle, fMinHorAngle, fMaxHorAngle)
                --hScene.camera:rotate(dy * STEP, dx * STEP, -math.pi / 2, 0.3)
                FireUIEvent("ON_RIDE_CAMERA_UPDATE", szFrameName, szName)
            end
            Cursor.SetPos(nCX, nCY, false)
        end
    end
end
local CHARACTER_ROLE_TURN_YAW = math.pi / 54

local function RoleYawTurn(tFrame)
    if tFrame.bTurnRight then
        tFrame.fRidesYaw = (tFrame.fRidesYaw - CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.hRidesModelView.m_RidesMDL["MDL"]:SetYaw(tFrame.fRidesYaw)
    elseif tFrame.bTurnLeft then
        tFrame.fRidesYaw = (tFrame.fRidesYaw + CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.hRidesModelView.m_RidesMDL["MDL"]:SetYaw(tFrame.fRidesYaw)
    end
end

function RidesModelPreview.CreateOnEvent(szFrame)
    -- if not RidesModelPreview.tEventFrame[szFrame].nTimerID then
    --     RidesModelPreview.tEventFrame[szFrame].nTimerID = Timer.AddFrameCycle(RidesModelPreview, 1, function ()
    --         local tFrameList = RidesModelPreview.tResisterFrame[szFrame]
    --         if not tFrameList then return end
    --         for szName, tFrame in pairs(tFrameList) do
    --             RoleYawTurn(tFrame)
    --         end
    --     end)
    -- end
end

function RidesModelPreview.Init(szFrame, szName)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]

    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- assert(hFrame)
    -- local hScene = hFrame:Lookup(tFrame.szScene)
    -- local nWidth, nHeight = hScene:GetSize()

    -- local hRidesModelView = RidesModelView.new()
    -- hScene.hRidesModelView = hRidesModelView
    local hRidesModelView = RidesModelView.CreateInstance(RidesModelView)
    hRidesModelView:ctor()
    hRidesModelView:init(tFrame.scene, szFrame .. "_" .. szName)
    tFrame.hRidesModelView = hRidesModelView
    tFrame.Viewer:SetScene(hRidesModelView.m_scene)
    local nWidth, nHeight = UIHelper.GetContentSize(tFrame.Viewer)
    -- hScene:SetScene(hRidesModelView.m_scene)
    -- local fWidth, fHeight = hScene:GetSize()
    -- hScene.camera = camera_plus:new()
    -- hScene.fRidesYaw = math.pi / 2
    tFrame.camera = MiniSceneCamera.CreateInstance(MiniSceneCamera)
    tFrame.camera:ctor()
    tFrame.fRidesYaw = 0.75
    if tFrame.szCameraType then
        InitCameraWithType(nWidth, nHeight, tFrame, tFrame.szCameraType, tFrame.nCameraIndex, tFrame.nDefaultZoomIndex, tFrame.nDefaultZoomValue)
        if tFrame.tbCameraOffset then
            tFrame.camera:SetOffsetAngle(tFrame.tbCameraOffset[1], tFrame.tbCameraOffset[2], tFrame.tbCameraOffset[3],
                                            tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
        end
    elseif tFrame.tCamera then
        local c = tFrame.tCamera
        if c[7] then
            tFrame.fOrgRidesYaw = c[7]
        end

        InitCamera(nWidth, nHeight, tFrame, c)
    else
        InitCamera(nWidth, nHeight, tFrame, {0, 120, -410, 0, 150, 150})
    end

    if tFrame.tPos then
        tFrame.camera:set_mainplayer_pos(tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
    end
end

function RidesModelPreview.ShowRides(szFrame, szName, tRepresentID, tNpc)
    local tFrameList = RidesModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- local hScene = hFrame:Lookup(tFrame.szScene)
    local hRidesModelView = tFrame.hRidesModelView

    if tRepresentID then
        hRidesModelView:UnloadRidesModel()
        if tRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] == 0 then
            return
        end

        hRidesModelView:LoadResByRepresent(tRepresentID, false)
        hRidesModelView:LoadRidesModel()
        if tFrame.fScale then
            hRidesModelView:SetScaling(tFrame.fScale, tFrame.fScale, tFrame.fScale)
        end
        hRidesModelView:SetMainFlag(true)

        hRidesModelView:PlayRidesAnimation("Idle", "loop")
        if hRidesModelView.m_RidesMDL then
            if tFrame.fOrgRidesYaw then
                tFrame.fRidesYaw = tFrame.fOrgRidesYaw
            elseif hRidesModelView.fRidesYaw then
                tFrame.fOrgRidesYaw = tFrame.fRidesYaw
                tFrame.fRidesYaw = hRidesModelView.fRidesYaw
            end
            hRidesModelView:SetYaw( tFrame.fRidesYaw )
            if tFrame.tPos then
                hRidesModelView:SetTranslation(tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
            end
        end
    end

    if tNpc then
        hRidesModelView:UnloadNpcModel()
        hRidesModelView:LoadNpcResByModelID(tNpc.dwModelID, false)
        hRidesModelView:LoadNpcModel()
        if tNpc.fScale then
            hRidesModelView:SetNpcScaling(tNpc.fScale, tNpc.fScale, tNpc.fScale)
        end
        hRidesModelView:PlayNpcAnimation("Idle", "loop")
        if tNpc.tPos then
            hRidesModelView:SetNpcTranslation(tNpc.tPos[1], tNpc.tPos[2], tNpc.tPos[3])
        end
    end
    FireUIEvent("ON_RIDE_CAMERA_UPDATE", szFrame, szName)
end

function RidesModelPreview.PlayRidesAnimation(szFrame, szName, szAniName, szLoopType)
    local tFrameList = RidesModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = hFrame:Lookup(tFrame.szScene)
    local hRidesModelView = hScene.hRidesModelView
    if not hRidesModelView then
        return
    end
    hRidesModelView:PlayRidesAnimation(szAniName, szLoopType)
end

function RidesModelPreview.RegisterHorse(UIViewer3D, hModelView, szFrameName, szName)
    local tRideParam =
    {
        dwPlayerID = g_pClientPlayer.dwID,
        szName = szName,
        szFrameName = szFrameName,
        Viewer = UIViewer3D,
        hRidesModelView = hModelView,
    }
    local szFrame = tRideParam.szFrameName
    local szName = tRideParam.szName
    tRideParam.fRidesYaw = 0.7
    RidesModelPreview.tResisterFrame[szFrame] = RidesModelPreview.tResisterFrame[szFrame] or {}
    RidesModelPreview.tResisterFrame[szFrame][szName] = tRideParam
end

function RidesModelPreview_SetCameraRadius(szFrame, szName, szRadius, nFrameNum)
    nFrameNum = nFrameNum or FRAME_NUM
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
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

function RidesModelPreview_SetCameraZoom(szFrame, szName, szRadius)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
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

function RidesModelPreview_GetCameraRadius(szFrame, szName)
    if not RidesModelPreview.tResisterFrame[szFrame] then
        return
    end
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:get_radius()
end

function RidesModelPreview_GetRoleYaw(szFrame, szName)
    if not RidesModelPreview.tResisterFrame[szFrame] then
        return
    end
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = hFrame:Lookup(tFrame.szScene)
    return hScene.fRidesYaw
end

function RidesModelPreview_GetCameraPosition(szFrame, szName)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = hFrame:Lookup(tFrame.szScene)
    local camera = hScene.camera
    local pos = hScene.camera:getpos(true)
    local look = hScene.camera:getlook(true)
    local center_pos = hScene.camera:get_center_pos(true)

    local tCamera = {pos.x, pos.y, pos.z, look.x, look.y, look.z, center_pos.x, center_pos.y, center_pos.z}
    return tCamera
end

function RidesModelPreview_GetPosition(szFrame, szName)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    return tFrame.tPos
end

function RidesModelPreview_SetCameraPosition(szFrame, szName, tCamera)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = hFrame:Lookup(tFrame.szScene)
    local c = tCamera
    local fWidth, fHeight = hScene:GetSize()
    local hRidesModelView = hScene.hRidesModelView
    InitCamera(hScene, c, {c[7], c[8],c[9]})
    --hScene.camera:init(hRidesModelView.m_scene, c[1], c[2], c[3], c[4], c[5], c[6], math.pi / 4, fWidth / fHeight, nil, nil, true)
    if hRidesModelView.m_RidesMDL then
        hRidesModelView.m_RidesMDL["MDL"]:SetYaw(hScene.fRidesYaw)
    end
end

function RidesModelPreview_SetCameraCenterR(szFrame, szName, nCenterR, nFrameNum)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    tFrame.camera:set_center_r(nCenterR, nFrameNum)
end

function RidesModelPreview_GetCameraCenterR(szFrame, szName)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:get_center_r()
end

function RidesModelPreview_SetCameraOffset(szFrame, szName, fAngleX, fAngleY, fAngleZ, fModelX, fModelY, fModelZ, bNotUpdate)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:SetOffsetAngle(fAngleX, fAngleY, fAngleZ, fModelX, fModelY, fModelZ, bNotUpdate)
end

function RidesModelPreview_GetCameraOffset(szFrame, szName)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:GetOffsetAngle()
end


function RidesModelPreview_GetRegisterFrame(szFrame, szName)
    local tFrameList = RidesModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    return tFrame
end

local function RestoreMsgFunction(szFrame, szFunctionName)
    if _G[szFrame] and
        RidesModelPreview.tEventFrame[szFrame] and
    _G[szFrame][szFunctionName] == RidesModelPreview.tEventFrame[szFrame]["fnNew" .. szFunctionName] then
        _G[szFrame][szFunctionName] = RidesModelPreview.tEventFrame[szFrame]["fnOld" .. szFunctionName]
    end
end

function RegisterRidesModelEvent(szFrame)
    if RidesModelPreview.tEventFrame[szFrame] then
        -- RestoreMsgFunction(szFrame, "OnLButtonDown")
        -- RestoreMsgFunction(szFrame, "OnLButtonUp")
        -- RestoreMsgFunction(szFrame, "OnRButtonDown")
        -- RestoreMsgFunction(szFrame, "OnRButtonUp")
        -- --RestoreMsgFunction(szFrame, "OnFrameBreathe")
        -- RestoreMsgFunction(szFrame, "OnMouseWheel")
        -- RestoreMsgFunction(szFrame , "OnFrameDestroy")
        -- RestoreMsgFunction(szName, "OnEvent")
    end
    RidesModelPreview.tResisterFrame[szFrame] = {}
    RidesModelPreview.tEventFrame[szFrame] = {}
    -- RidesModelPreview.CreateOnLButtonDown(szFrame)
    -- RidesModelPreview.CreateOnLButtonUp(szFrame)
    -- RidesModelPreview.CreateOnRButtonDown(szFrame)
    -- RidesModelPreview.CreateOnRButtonUp(szFrame)
    -- --RidesModelPreview.CreateOnFrameBreathe(szFrame)
    -- RidesModelPreview.CreateOnMouseWheel(szFrame)
    -- RidesModelPreview.CreateOnFrameDestroy(szFrame)
    RidesModelPreview.CreateOnEvent(szFrame)
end

Event.Reg(RidesModelPreview, "RIDE_TOUCH_UPDATE", function(szFrame, szName, bTouch, x, y) Ride_TouchUpdate(szFrame, szName, bTouch, x, y) end)

--[[
    local tRideParam =
    {
    szName = "HorseStable", 一个界面可能有多个模型，用这个名字来区分同一个界面里的不同模型
    szFrameName = "HorseStable",
    szFramePath = "Normal/HorseStable",
    szScene = "Scene_Rides",
    szTurnLeft = "Btn_TurnLeft",
    szTurnRight = "Btn_TurnRight",
    }
--]]

RegisterRidesModelEvent("SaddleHorse_view")
RegisterRidesModelEvent("Domesticate_view")

function Ride_TouchUpdate(szFrame, szName, bTouch, x, y)
    --print(szFrame, szName, bTouch, x, y)
    local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
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

function RegisterRidesModelPreview(tRideParam)
    local szFrame = tRideParam.szFrameName
    local szName = tRideParam.szName
    RidesModelPreview.tResisterFrame[szFrame] = RidesModelPreview.tResisterFrame[szFrame] or {}
    if RidesModelPreview.tResisterFrame[szFrame][szName] then
        local tFrame = RidesModelPreview.tResisterFrame[szFrame][szName]
        local hRidesModelView = tFrame.hRidesModelView
        if hRidesModelView then
            hRidesModelView:UnloadRidesModel()
            hRidesModelView:UnloadNpcModel()
            hRidesModelView:release()
            tFrame.hRidesModelView = nil
        end

        RidesModelPreview.tResisterFrame[szFrame][szName] = nil
    end
    RidesModelPreview.tResisterFrame[szFrame][szName] = tRideParam
    RidesModelPreview.Init(szFrame, szName)
end

function UnRegisterRidesModel(szFrame, szName)
    local tFrameList = RidesModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    local hRidesModelView = tFrame.hRidesModelView
    if hRidesModelView then
        hRidesModelView:UnloadRidesModel()
        hRidesModelView:UnloadNpcModel()
        hRidesModelView:release()
        tFrame.hRidesModelView = nil
    end

    RidesModelPreview.tResisterFrame[szFrame][szName] = nil
end

-- local function OnRidesModelPreviewEvent(szEvent)
--     if szEvent == "RIDES_MODEL_PREVIEW_UPDATE" then
--         RidesModelPreview.ShowRides(arg0, arg1, arg2, arg3)
--     elseif szEvent == "RIDES_MODEL_SET_CAMERA_CENTER_R" then
--         RidesModelPreview_SetCameraCenterR(arg0, arg1, arg2, arg3)
--     elseif szEvent == "RIDES_MODEL_PLAY_ANIMATION" then
--         RidesModelPreview.PlayRidesAnimation(arg0, arg1, arg2, arg3)
--     end
-- end

Event.Reg(RidesModelPreview, "RIDES_MODEL_PREVIEW_UPDATE", function()
    RidesModelPreview.ShowRides(arg0, arg1, arg2, arg3)
end)

Event.Reg(RidesModelPreview, "RIDES_MODEL_SET_CAMERA_RADIUS", function (szFrame, szName, szRadius, nFrameNum)
    RidesModelPreview_SetCameraRadius(szFrame, szName, szRadius, nFrameNum)
end)

Event.Reg(RidesModelPreview, "RIDES_MODEL_SET_CAMERA_ZOOM", function (szFrame, szName, szRadius)
    RidesModelPreview_SetCameraZoom(szFrame, szName, szRadius)
end)

Event.Reg(RidesModelPreview, "RIDES_MODEL_SET_CAMERA_CENTER_R", function()
    RidesModelPreview_SetCameraCenterR(arg0, arg1, arg2, arg3)
end)

-- RegisterEvent("RIDES_MODEL_PREVIEW_UPDATE", function(szEvent) OnRidesModelPreviewEvent(szEvent) end)
-- RegisterEvent("RIDES_MODEL_SET_CAMERA_CENTER_R", function(szEvent) OnRidesModelPreviewEvent(szEvent) end)
-- RegisterEvent("RIDES_MODEL_PLAY_ANIMATION", function(szEvent) OnRidesModelPreviewEvent(szEvent) end)