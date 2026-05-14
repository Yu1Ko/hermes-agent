---@class NpcModelView
NpcModelView = class("NpcModelView")

local FRAME_NUM = 25

local function InitCamera(nWidth, nHeight, tFrame, tCamera, tCenterPos)
    if not tCenterPos and tCamera[9] then
        tCenterPos = {tCamera[8], tCamera[9], tCamera[10]}
    end
    tFrame.camera:init(tFrame.hNpcModelView.m_scene, tCamera[1], tCamera[2], tCamera[3] , tCamera[4], tCamera[5], tCamera[6], math.pi / 4, nWidth / nHeight, nil, nil, true, tCenterPos)
end

local function InitCameraWithType(nWidth, nHeight, tFrame, szType, nIndex, nZoomIndex, nZoomValue)
    tFrame.camera:init(tFrame.hNpcModelView.m_scene, 0, 0, 0, 0, 0, 0, 0.3, nWidth / nHeight, nil, 40000, true)
    tFrame.camera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
end

local _play_ref
local _tPlaying = {}
local _play_count = 0

local function play_onfinished()
    local model = argu
    local id = KG3DEngine.ModelToID(model)
    local modelview = _tPlaying[id]
    if not modelview then
        return
    end
    modelview:OnAniFinished(model)
end

local function playing_add(modelview)
    if not modelview:IsRegisterEventHandler() then
        return
    end

    local id = KG3DEngine.ModelToID( modelview:Mdl() )
    if not _tPlaying[id] then
        _play_count = _play_count + 1
    end

    _tPlaying[id] = modelview

    if _play_count > 0 and not _play_ref then
        -- _play_ref = RegisterEvent("KG3D_PLAY_ANIMAION_FINISHED", play_onfinished)
        _play_ref = Event.Reg(NpcModelView, "KG3D_PLAY_ANIMAION_FINISHED", play_onfinished)
    end
end

local function playing_delete(modelview)
    if not modelview:IsRegisterEventHandler() then
        return
    end

    local id = KG3DEngine.ModelToID( modelview:Mdl() )
    if _tPlaying[id] then
        modelview:UnRegisterEventHandler()
        _tPlaying[id] = nil
        _play_count = _play_count - 1
    end

    if _play_count == 0 and _play_ref then
        -- UnRegisterEvent("KG3D_PLAY_ANIMAION_FINISHED", _play_ref)
        Event.UnReg(NpcModelView, "KG3D_PLAY_ANIMAION_FINISHED")
        _play_ref = nil
    end
end

-- function DrawNpcModelImage(dwNpcID, aCameraParams, image, bPortraitOnly)
-- 	local modelView = NpcModelView.new()

-- 	modelView:init()
-- 	modelView:SetCamera(aCameraParams)

-- 	modelView:UnloadModel()
-- 	modelView:LoadNpcRes(dwNpcID, bPortraitOnly)
-- 	modelView:LoadModel()
-- 	modelView:PlayAnimation("Idle", "last")

-- 	image:FromScene(modelView.m_scene)

-- 	MaskModelImage(image)
-- 	image:ToManagedImage()

-- 	modelView:release()
-- end

function NpcModelView:ctor()
	self.bMgrScene = true
	self.m_modelMgr = nil
	self.m_NpcMDL = nil
    self.m_NpcMDLSFX = nil
    self.m_ResourceSFX = nil
	self.bModelInScene = nil
	self.m_aEquipRes = {}
	self.m_aAnimationRes = { Idle = {} }
	self.m_aRoleAnimation = { Idle = 30 }
    LastModelView = self
end;

function NpcModelView:release()
	self:UnloadModel()

    if self.bMgrScene then
        SceneHelper.Delete(self.m_scene)
    end
	self.m_scene=nil
    self.reg_handler = nil
    LastModelView = nil
end;

function NpcModelView:Mdl()
    return self.m_NpcMDL["MDL"];
end

function NpcModelView:init(scene, bNotMgrScene, bLight, szSceneFilePath, szName)
	self.bMgrScene = not bNotMgrScene

	if not scene then
        scene = SceneHelper.Create(szSceneFilePath, true, true, true)
		self.bMgrScene = true
	end
	self.m_scene = scene
    self.bLight	 = bLight
	self.m_modelMgr = KG3DEngine.GetModelMgr()

    if self.bMgrScene then
        self:SetCamera({ 0, 150, -200, 0, 50, 150 })
    end
end

function NpcModelView:SetCamera(aParams)
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
end;

function NpcModelView:SetCameraPosition(tCameraPosion)
	local xp = tCameraPosion[1]
	local yp = tCameraPosion[2]
	local zp = tCameraPosion[3]
	local xl = tCameraPosion[4]
	local yl = tCameraPosion[5]
	local zl = tCameraPosion[6]

    self:SetCameraLookPos(xl, yl, zl)
	self:SetCameraPos(xp, yp, zp)
end;

function NpcModelView:GetCameraPos()
    return self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ
end

function NpcModelView:SetCameraPos(x, y, z)
    self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ = x, y, z
	self.m_scene:SetCameraPosition(x, y, z)
end

function NpcModelView:GetCameraLookPos()
    return self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ
end

function NpcModelView:SetCameraLookPos(x, y, z)
    self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ = x, y, z
	self.m_scene:SetCameraLookAtPosition(x, y, z)
end

function NpcModelView:GetCameraPerspective()
    return self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar
end

function NpcModelView:SetCameraPerspective(fovY, aspect, near, far)
    self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar = fovY, aspect, near, far
	self.m_scene:SetCameraPerspective(fovY, aspect, near, far)
end

function NpcModelView:GetCameraOrthogonal()
    return self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar
end

function NpcModelView:SetCameraOrthogonal(w, h, near, far)
    self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar = w, h, near, far
	self.m_scene:SetCameraOrthogonal(w, h, near, far)
end

function NpcModelView:LoadModelSFXByName(model, equipType, aNewEquipRes, szName)
    if aNewEquipRes[equipType][szName] then
        local mdl = self.m_NpcMDL["MDL"]
        local modelsfx = self.m_modelMgr:NewModel(aNewEquipRes[equipType][szName], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
        self.m_NpcMDLSFX[equipType .. szName] = modelsfx
        if modelsfx then
            if aNewEquipRes[equipType]["SFXSocketName"] then
                modelsfx:BindToSocket(mdl, aNewEquipRes[equipType]["SFXSocketName"])
            else
                modelsfx:BindToBone(model)
            end
        end
    end
end

function NpcModelView:LoadModelSFX(model, equipType, aNewEquipRes)
    --Load SFX1
    self:LoadModelSFXByName(model, equipType, aNewEquipRes, "SFX1")

    --Load SFX2
    self:LoadModelSFXByName(model, equipType, aNewEquipRes, "SFX2")
end;

function NpcModelView:UnloadModelSFX(equipType)
    --Unload SFX2
    if self.m_NpcMDLSFX[equipType.."SFX2"] then
        self.m_NpcMDLSFX[equipType.."SFX2"]:UnbindFromOther()
        self.m_NpcMDLSFX[equipType.."SFX2"]:Release()
        self.m_NpcMDLSFX[equipType.."SFX2"] = nil
        --
    end
    --Unload SFX1
    if self.m_NpcMDLSFX[equipType.."SFX1"] then
        self.m_NpcMDLSFX[equipType.."SFX1"]:UnbindFromOther()
        self.m_NpcMDLSFX[equipType.."SFX1"]:Release()
        self.m_NpcMDLSFX[equipType.."SFX1"] = nil
    end
end;

function NpcModelView:LoadSocket(equipType, aEquipRes, socketScale)
    local socketName = aEquipRes[equipType]["Socket"] or aEquipRes[equipType]["Equip"]
    local meshFile = aEquipRes[equipType]["Mesh"]

    if socketName and meshFile then
        local mdl =  self.m_NpcMDL["MDL"]
        self:UnloadSocket(equipType)

        local model = self.m_modelMgr:NewModel(meshFile, false, false, false, false, APIHelper.GetNpcLODLvl(), mdl)

        if model then
            self.m_NpcMDL[equipType] = model

            local szAni = aEquipRes[equipType]["SocketAni"]
            if szAni and szAni ~= "" and model then
                model:PlayAnimation("loop", szAni, 1.0, 0)
            end

            local mtlFile = aEquipRes[equipType]["Mtl"]
            if mtlFile then
                model:LoadMaterialFromFile(mtlFile)
            end

            if equipType ~= "S_Face" then
                local scale = aEquipRes[equipType]["MeshScale"]
                if scale and scale ~= 0 then
                     model:SetScaling(scale, scale, scale)
                else
                    model:SetScaling(socketScale, socketScale, socketScale)
                end
            end
            if aEquipRes[equipType]["ColorChannel"] then
                model:SetDetail(self.nRoleType, aEquipRes[equipType]["ColorChannel"])
            end
            model:BindToSocket(mdl, socketName)
            self:UnloadModelSFX(equipType)
            self:LoadModelSFX(model, equipType, aEquipRes)
        end
    end
end

function NpcModelView:LoadPart(equipType, aNewEquipRes)
    if aNewEquipRes[equipType]["Mesh"] then
        local mdl = self.m_NpcMDL["MDL"]
        self:UnloadSocket(equipType)

        local model = self.m_modelMgr:NewModel(aNewEquipRes[equipType]["Mesh"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
        if not model then
            return
        end

        self.m_NpcMDL[equipType] = model

        mdl:Attach(model)

        if aNewEquipRes[equipType]["ColorChannel"] then
            model:SetDetail(self.nRoleType, aNewEquipRes[equipType]["ColorChannel"])
        end
        local scale = aNewEquipRes[equipType]["MeshScale"]

        --model:SetScaling(scale, scale, scale)
        self:UnloadModelSFX(equipType)
        self:LoadModelSFX(model, equipType, aNewEquipRes)

        if aNewEquipRes[equipType]["Ani"] and aNewEquipRes[equipType]["Ani"]  ~= "" then
            model:PlayAnimation("loop", aNewEquipRes[equipType]["Ani"] , 1.0, 0)
        end
    end
end

function NpcModelView:UnloadPart(equipType)
    local model = self.m_NpcMDL[equipType]
    if not model then
        return
    end

    self:UnloadModelSFX(equipType)
    self:UnloadResourceSFX(equipType)
    self.m_NpcMDL["MDL"]:Detach(model)
    model:Release()
    model = nil
    self.m_NpcMDL[equipType] = nil
end

function NpcModelView:UnloadResourceSFX(equipType)
    local tModels = self.m_ResourceSFX[equipType] or {}
    for szSocketName, model in pairs(tModels) do
        model:UnbindFromOther()
        model:Release()
        tModels[szSocketName] = nil
    end
    self.m_ResourceSFX[equipType] = nil
end

function NpcModelView:LoadModel()
	if self.m_NpcMDL then
		return
	end

	local aEquipRes = self.m_aEquipRes
	if aEquipRes["Main"] and aEquipRes["Main"]["MDL"] then

		local modelScale = aEquipRes["Main"]["ModelScale"]
		local socketScale = aEquipRes["Main"]["SocketScale"]
		local nColorChannelTable = aEquipRes["Main"]["ColorChannelTable"]
		local nColorChannel = aEquipRes["Main"]["ColorChannel"]
		self.m_NpcMDL = {}
        self.m_NpcMDLSFX = {}
        self.m_ResourceSFX = {}

        --self.m_modelMgr:NewModel(aNewEquipRes[equipType]["Mesh"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
		local mdl = self.m_modelMgr:NewModel(aEquipRes["Main"]["MDL"], false, true, false, true, APIHelper.GetNpcLODLvl())
        self.m_NpcMDL["MDL"] = mdl
		mdl:SetScaling(modelScale, modelScale, modelScale)
		mdl:SetTranslation(0, 0, 0)
		mdl:SetDetail(nColorChannelTable, nColorChannel)
        mdl:SetMainFlag(true)

        -- if IsNumber(nModelLodLevel) then
        --     mdl:SetModelLodLevel(nModelLodLevel)
        -- end

		if self.bLight then
			self.m_scene:AddRenderEntity(mdl, true)
		else
			self.m_scene:AddRenderEntity(mdl)
		end
		self.bModelInScene = true
        -- load Equip
        local tResourceSFX = {}
        for equipType, equipRes in pairs(aEquipRes) do
            if aEquipRes[equipType]["Equip"] then
                if aEquipRes[equipType]["Mesh"] then
                    local tSFXList = Global_GetResourceSfx(aEquipRes[equipType]["Mesh"], aEquipRes[equipType]["ColorChannel"])
                    tResourceSFX[equipType] = tSFXList
                end
                self:LoadPart(equipType, aEquipRes)
            end
        end

        -- load socket
		for equipType, equipRes in pairs(aEquipRes) do
            if aEquipRes[equipType]["Socket"] then
			    self:LoadSocket(equipType, aEquipRes, socketScale)
            end
		end

        for equipType, tSFXList in pairs(tResourceSFX) do
            self:LoadResourceSFX(equipType, tSFXList)
        end

		self.m_NpcMDL["MDL"] = mdl
        if self.reg_handler then
            self:RegisterEventHandler()
        end
	end
end

function NpcModelView:LoadResourceSFX(equipType, tSFXList)
    self.m_ResourceSFX[equipType] = self.m_ResourceSFX[equipType] or {}
    local tModels = self.m_ResourceSFX[equipType]
    for szSocketName, tSFX in pairs(tSFXList) do
        if not tModels[szSocketName] and tSFX.SfxPath and tSFX.SfxPath ~= "" then
            self:BindSFX(szSocketName, tSFX, tModels)
        end
    end
end

function NpcModelView:UnloadResourceSFX(equipType)
    local tModels = self.m_ResourceSFX[equipType] or {}
    for szSocketName, model in pairs(tModels) do
        model:UnbindFromOther()
        model:Release()
        tModels[szSocketName] = nil
    end
    self.m_ResourceSFX[equipType] = nil
end

function NpcModelView:UnloadModel()
	if not self.m_NpcMDL then
		return
	end
    playing_delete(self)

    for equipType, model in pairs(self.m_NpcMDL) do
        if model and self.m_aEquipRes[equipType] and self.m_aEquipRes[equipType]["Socket"] and equipType ~= "MDL"then
            self:UnloadSocket(equipType)
        end
    end

    for equipType, model in pairs(self.m_NpcMDL) do
        if model and self.m_aEquipRes[equipType] and self.m_aEquipRes[equipType]["Equip"] and equipType ~= "MDL" then
            self:UnloadPart(equipType)
        end
    end

	local mdl = self.m_NpcMDL["MDL"]
	if self.bModelInScene then
		self.m_scene:RemoveRenderEntity(mdl)
	end

	mdl:Release()
	self.m_NpcMDL["MDL"] = nil
    self.m_ResourceSFX = nil
    self.m_NpcMDLSFX = nil
	self.bModelInScene   = nil

	self.m_NpcMDL = nil
end;

function NpcModelView:UnloadSocket(equipType)
    local model = self.m_NpcMDL[equipType]
    if not model then
        return
    end

    self:UnloadModelSFX(equipType)
    model:UnbindFromOther()
    model:Release()

    model = nil
    self.m_NpcMDL[equipType] = nil
end

function NpcModelView:PlayAnimationByPath(szAni, szLoopType)
    if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
		return
	end
    if not szAni then
        return
    end
	self.m_NpcMDL["MDL"]:PlayAnimation(szLoopType, szAni, 1, 0)
end;

function NpcModelView:PlayAnimation(szAniName, szLoopType)
	if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
		return
	end
	if not szAniName or not self.m_aAnimationRes[szAniName].Ani then
		return
	end
	self.m_NpcMDL["MDL"]:PlayAnimation(szLoopType, self.m_aAnimationRes[szAniName].Ani, 1, 0)
end;

function NpcModelView:LoadNpcRes(dwModelID, bPortraitOnly, nRoleType, bFace, bSheath, tRepresentID)
    self.m_aEquipRes = self:GetModuleRes(dwModelID, nRoleType, bFace, bSheath, tRepresentID)
	local res = self.m_aEquipRes
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
	for szAniName, v in pairs(self.m_aAnimationRes) do
		self.m_aAnimationRes[szAniName] = {
			Ani = "", AniSound = "", AniPlayType = "loop", AniPlaySpeed = 1, AniSoundRange = 0,
			SFX = "", SFXBone = "", SFXPlayType = "loop", SFXPlaySpeed = 1, SFXScale = 1
		}

		local aAniRes = self.m_aAnimationRes[szAniName]

		aAniRes["Ani"], aAniRes["AniSound"], aAniRes["AniPlayType"], aAniRes["AniPlaySpeed"], aAniRes["AniSoundRange"],
		aAniRes["SFX"], aAniRes["SFXBone"], aAniRes["SFXPlayType"], aAniRes["SFXPlaySpeed"], aAniRes["SFXScale"]
		= NPC_GetAnimationResource(dwModelID, self.m_aRoleAnimation[szAniName])
	end
end;

function NpcModelView:GetMdl()
    if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
		return
	end

    return self.m_NpcMDL["MDL"]
end

function NpcModelView:LoadFaceDefinitionINI(szFileName)
    local model = self.m_NpcMDL["S_Face"]
    if not model then
        Log("NpcModelView LoadFaceDefinitionINI model is not exist")
        return
    end
    model:LoadFaceDefinitionINI(szFileName)
end

function NpcModelView:GetFaceModel()
    local model = self.m_NpcMDL["S_Face"]
    return model
end

function NpcModelView:SetFaceDecals(nRoleType, tDecalDefinition)
    local model = self.m_NpcMDL["S_Face"]
    if not model then
        Log("NpcModelView SetFaceDecals model is not exist")
        return
    end

    model:SetFaceDecals(nRoleType, tDecalDefinition)
end

function NpcModelView:SetTranslation(fX, fY, fZ)
	if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
		return
	end
	self.m_NpcMDL["MDL"]:SetTranslation(fX, fY, fZ)
    self.nTransX, self.nTransY, self.nTransZ = fX, fY, fZ
end

function NpcModelView:GetTranslation()
	return self.nTransX, self.nTransY, self.nTransZ
end

function NpcModelView:SetDetail(nColorChannelTable, nColorChannel)
	if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
		return
	end
	self.m_NpcMDL["MDL"]:SetDetail(nColorChannelTable, nColorChannel)
end

function NpcModelView:SetScaling(fScale)
	if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
		return
	end
	self.m_NpcMDL["MDL"]:SetScaling(fScale, fScale, fScale)
end

function NpcModelView:SetAlpha(fAlpha)
	if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] then
		return
	end
	self.m_NpcMDL["MDL"]:SetAlpha(fAlpha)
end

function NpcModelView:SetYaw(yaw)
    local mdl = self.m_NpcMDL and self.m_NpcMDL["MDL"]
    if mdl then
        self._yaw = yaw
        mdl:SetYaw(yaw)
    end
end

function NpcModelView:GetYaw()
    return (self._yaw or 0)
end

function NpcModelView:Show(bShow)
    self:ShowModel(bShow)
end

function NpcModelView:ShowModel(bShow)
	if not self.m_NpcMDL or not self.m_NpcMDL["MDL"] or not self.m_scene then
		return
	end

	local mdl = self.m_NpcMDL["MDL"]
	if bShow then
		if not self.bModelInScene then
			self.m_scene:AddRenderEntity(mdl)
			self.bModelInScene = true
		end
	else
		if self.bModelInScene then
			self.m_scene:RemoveRenderEntity(mdl)
			self.bModelInScene = nil
		end
	end
end

local function fnComplementTable(tRepresentID)
    local nMax = 0
    for i, v in pairs(tRepresentID) do
        if i > nMax then
            nMax = i
        end
    end

    for i = 0, nMax do
        if not tRepresentID[i] then
            tRepresentID[i] = 0
        end
    end
end

function NpcModelView:GetModuleRes(dwModelID, nRoleType, bFace, bSheath, tRepresentID)
    local tRes
    if tRepresentID and not IsTableEmpty(tRepresentID) then
        fnComplementTable(tRepresentID)
        if bSheath == nil then --默认值
            bSheath = true
        end
        tRes = NPC_GetEquipResource(dwModelID, nRoleType, bFace, bSheath, EQUIPMENT_REPRESENT.TOTAL, tRepresentID)
    elseif nRoleType then
	    tRes = NPC_GetEquipResource(dwModelID, nRoleType)
    else
        tRes = NPC_GetEquipResource(dwModelID)
    end

    return tRes
end

function NpcModelView:IsRegisterEventHandler()
    return self.reg_handler
end

function NpcModelView:RegisterEventHandler()
    if self.reg_handler then
        return
    end
    self.reg_handler = true
    self.m_NpcMDL["MDL"]:RegisterEventHandler()
end

function NpcModelView:UnRegisterEventHandler()
    self.reg_handler = nil
    self.m_NpcMDL["MDL"]:UnregisterEventHandler()
end

function NpcModelView:OnAniFinished(mdl, ani_id)
    if not self.aAnis or mdl ~= self.m_NpcMDL["MDL"] then
        return
    end

    if self.aAnisStandby then
        self:PlayAnimationByPath(self.aAnisStandby.szAni, self.aAnisStandby.szLoopType)
    end

    playing_delete(self)

    local end_func = self.aAnis[ani_id]
    if not end_func then
        return
    end

    end_func(self, ani_id)
    self.aAnis[ani_id] = nil
end

NpcModelPreview = {className = "NpcModelPreview"}
NpcModelPreview.tResisterFrame = {}
NpcModelPreview.tEventFrame = {}

local STEP = 1

function NpcModelPreview.CreateOnLButtonDown(szFrame)
    NpcModelPreview.tEventFrame[szFrame].fnOldOnLButtonDown = _G[szFrame].OnLButtonDown
    _G[szFrame].OnLButtonDown = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = NpcModelPreview.tResisterFrame[szFrameName]
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

            local tEvent = NpcModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnLButtonDown then
                return tEvent.fnOldOnLButtonDown()
            end
        end
    end
    NpcModelPreview.tEventFrame[szFrame].fnNewOnLButtonDown = _G[szFrame].OnLButtonDown
end

function NpcModelPreview.CreateOnLButtonUp(szFrame)
     NpcModelPreview.tEventFrame[szFrame].fnOldOnLButtonUp = _G[szFrame].OnLButtonUp
     _G[szFrame].OnLButtonUp = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = NpcModelPreview.tResisterFrame[szFrameName]
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

            local tEvent = NpcModelPreview.tEventFrame[szFrameName]
            if tEvent.fnOldOnLButtonUp then
                return tEvent.fnOldOnLButtonUp()
            end
        end

    end

    NpcModelPreview.tEventFrame[szFrame].fnNewOnLButtonUp = _G[szFrame].OnLButtonUp
end

function NpcModelPreview.CreateOnRButtonDown(szFrame)
    NpcModelPreview.tEventFrame[szFrame].fnOldOnRButtonDown = _G[szFrame].OnRButtonDown
    _G[szFrame].OnRButtonDown = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = NpcModelPreview.tResisterFrame[szFrameName]
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

            local tEvent = NpcModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnRButtonDown then
                return tEvent.fnOldOnRButtonDown()
            end
        end
    end
    NpcModelPreview.tEventFrame[szFrame].fnNewOnRButtonDown = _G[szFrame].OnRButtonDown
end

function NpcModelPreview.CreateOnRButtonUp(szFrame)
     NpcModelPreview.tEventFrame[szFrame].fnOldOnRButtonUp = _G[szFrame].OnRButtonUp
     _G[szFrame].OnRButtonUp = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = NpcModelPreview.tResisterFrame[szFrameName]
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

            local tEvent = NpcModelPreview.tEventFrame[szFrameName]
            if tEvent.fnOldOnRButtonUp then
                return tEvent.fnOldOnRButtonUp()
            end
        end
    end

    NpcModelPreview.tEventFrame[szFrame].fnNewOnRButtonUp = _G[szFrame].OnRButtonUp
end

function NpcModelPreview.CreateOnFrameBreathe(szFrame)
     NpcModelPreview.tEventFrame[szFrame].fnOldOnFrameBreathe = _G[szFrame].OnFrameBreathe
     _G[szFrame].OnFrameBreathe = function()
        local szFrameName = this:GetName()
        local tFrameList = NpcModelPreview.tResisterFrame[szFrameName]
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hScene = GetUIObjectByPath(this, tFrame.szScene)
                if hScene.hNpcModelView and hScene.hNpcModelView.m_NpcMDL then
                    if hScene.bTurnRight then
                        hScene.fNpcYaw = (hScene.fNpcYaw - CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
                        hScene.hNpcModelView.m_NpcMDL["MDL"]:SetYaw(hScene.fNpcYaw)
                        break
                    elseif hScene.bTurnLeft then
                        hScene.fNpcYaw = (hScene.fNpcYaw + CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
                        hScene.hNpcModelView.m_NpcMDL["MDL"]:SetYaw(hScene.fNpcYaw)
                        break
                    end
                end
            end

            local tEvent = NpcModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnFrameBreathe then
                return tEvent.fnOldOnFrameBreathe()
            end
          end
    end

    NpcModelPreview.tEventFrame[szFrame].fnNewOnFrameBreathe = _G[szFrame].OnFrameBreathe
end

function NpcModelPreview.CreateOnFrameDestroy(szFrame)
     NpcModelPreview.tEventFrame[szFrame].fnOldOnFrameDestroy = _G[szFrame].OnFrameDestroy
     _G[szFrame].OnFrameDestroy = function()
        local szFrameName = this:GetName()
        local tFrameList = NpcModelPreview.tResisterFrame[szFrameName]
        if tFrameList then
            for _, tFrame in pairs(tFrameList) do
                local hNpcModelView = tFrame.hNpcModelView
                if hNpcModelView then
                    hNpcModelView:UnloadModel()
                    hNpcModelView:release()
                    tFrame.hNpcModelView = nil
                end
            end

            local tEvent = NpcModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnFrameDestroy then
                local nResult = tEvent.fnOldOnFrameDestroy()
                NpcModelPreview.tResisterFrame[szFrameName] = {}
                return nResult
            end

            NpcModelPreview.tResisterFrame[szFrameName] = {}
        end
    end
    NpcModelPreview.tEventFrame[szFrame].fnNewOnFrameDestroy = _G[szFrame].OnFrameDestroy
end

function NpcModelPreview.CreateOnMouseWheel(szFrame)
     NpcModelPreview.tEventFrame[szFrame].fnOldOnMouseWheel = _G[szFrame].OnMouseWheel
     _G[szFrame].OnMouseWheel = function()
        local hFrame = this:GetRoot()
        local szFrameName = hFrame:GetName()
        local tFrameList = NpcModelPreview.tResisterFrame[szFrameName]
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
                        FireUIEvent("ON_NPC_CAMERA_UPDATE", szFrameName, tFrame.szName)
                    end
                end
            end

            local tEvent = NpcModelPreview.tEventFrame[szFrameName]
            if tEvent and tEvent.fnOldOnMouseWheel then
                local nResult = tEvent.fnOldOnMouseWheel()
                return nResult
            end
        end
    end

    NpcModelPreview.tEventFrame[szFrame].fnNewOnMouseWheel = _G[szFrame].OnMouseWheel
end

local function CameraRotate(szFrameName, szNpcName, tFrame)
    if tFrame.bLDown then
        local x, y = Cursor.GetPos(false)
        local nCX, nCY = hScene.nCX, hScene.nCY
        if x ~= nCX or y ~= nCY then
            local cx, cy = Station.GetClientSize(false)
            local dx = -(x - nCX) / cx * math.pi
            local dy = (y - nCY) / cy * math.pi
            if tFrame.bDisableCamera then
                hScene.fNpcYaw = (hScene.fNpcYaw + dx) % (2 * math.pi)
                hScene.hNpcModelView.m_NpcMDL["MDL"]:SetYaw(hScene.fNpcYaw)
            else
                --hScene.camera:rotate(dy * STEP, dx * STEP, -math.pi / 2, 0.3)
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
                FireUIEvent("ON_NPC_CAMERA_UPDATE", szFrameName, szNpcName)
            end
            Cursor.SetPos(nCX, nCY, false)
        end
    end
end
local CHARACTER_ROLE_TURN_YAW = math.pi / 54

local function RoleYawTurn(tFrame)
    local fTurnYaw = tFrame.hNpcModelView.fTurnYaw or CHARACTER_ROLE_TURN_YAW
    if tFrame.bTurnRight then
        tFrame.fNpcYaw = (tFrame.fNpcYaw - fTurnYaw) % (2 * math.pi)
        tFrame.hNpcModelView.m_NpcMDL["MDL"]:SetYaw(tFrame.fNpcYaw)
    elseif tFrame.bTurnLeft then
        tFrame.fNpcYaw = (tFrame.fNpcYaw + fTurnYaw) % (2 * math.pi)
        tFrame.hNpcModelView.m_NpcMDL["MDL"]:SetYaw(tFrame.fNpcYaw)
    end
end

function NpcModelPreview.CreateOnEvent(szFrame)
    -- if not NpcModelPreview.tEventFrame[szFrame].nTimerID then
    --     NpcModelPreview.tEventFrame[szFrame].nTimerID = Timer.AddFrameCycle(NpcModelPreview, 1, function ()
    --         local tFrameList = NpcModelPreview.tResisterFrame[szFrame]
    --         if not tFrameList then return end
    --         for szNpcName, tFrame in pairs(tFrameList) do
    --             CameraRotate(szFrame, szNpcName, tFrame)
    --             RoleYawTurn(tFrame)
    --         end
    --     end)
    -- end
end

function NpcModelPreview.Init(szFrame, szName)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]

    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- assert(hFrame)
    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    local hNpcModelView = NpcModelView.CreateInstance(NpcModelView)
    hNpcModelView:ctor()
    -- hScene.hNpcModelView = hNpcModelView
	hNpcModelView:init(tFrame.scene, tFrame.bNotMgrScene, nil, tFrame.szSceneFilePath, szFrame .. "_" .. szName)
    tFrame.hNpcModelView = hNpcModelView
    -- hScene:SetScene(hNpcModelView.m_scene)
    tFrame.Viewer:SetScene(hNpcModelView.m_scene)
    if tFrame.tRadius then
        tFrame.tWheelRadius = tFrame.tRadius
    end

    -- local fWidth, fHeight = hScene:GetSize()
    -- hScene.camera = camera_plus:new()
    -- hScene.fNpcYaw = 0
    tFrame.camera = MiniSceneCamera.CreateInstance(MiniSceneCamera)
    tFrame.camera:ctor()
    tFrame.fNpcYaw = 0.8
    local nWidth, nHeight = UIHelper.GetContentSize(tFrame.Viewer)
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

    if tFrame.tPos then
        tFrame.camera:set_mainplayer_pos(tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
    end

    if hNpcModelView.m_NpcMDL then
        hNpcModelView.m_NpcMDL["MDL"]:SetYaw(tFrame.fNpcYaw)
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

function NpcModelPreview.ShowNpc(szFrame, szName, dwModelID, nColorChannelTable, nColorChannel, fScale, tCamera, szFaceIni, nRoleType, bSheath, tRepresentID)
    local tFrameList = NpcModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    local hNpcModelView = tFrame.hNpcModelView
    if
        hNpcModelView.dwModelID and
        hNpcModelView.dwModelID == dwModelID and
        hNpcModelView.nColorChannelTable == nColorChannelTable and
        hNpcModelView.nColorChannel == nColorChannel
    then
        local bSameScale, bSameFaceIni, bSameCamera, bSameRepresentID
        bSameScale = false
        if hNpcModelView.fScale and hNpcModelView.fScale == fScale then
            bSameScale = true
        end
        bSameFaceIni = false
        if (not hNpcModelView.szFaceIni and not szFaceIni) or
        hNpcModelView.szFaceIni and szFaceIni and hNpcModelView.szFaceIni == szFaceIni then
            bSameFaceIni = true
        end
        bSameCamera = true
        if hNpcModelView.tCamera and #hNpcModelView.tCamera == #tCamera then
            for i = 1, #hNpcModelView.tCamera do
                if not tCamera[i] or hNpcModelView.tCamera[i] ~= tCamera[i] then
                    bSameCamera = false
                end
            end
        else
            bSameCamera = false
        end

        bSameRepresentID = (not hNpcModelView.tRepresentID and not tRepresentID) or IsTableEqual(hNpcModelView.tRepresentID, tRepresentID)

        if bSameScale and bSameFaceIni and bSameCamera and bSameRepresentID then
            return
        end
    end
    local bSameModel = hNpcModelView.dwModelID == dwModelID
    hNpcModelView.dwModelID = dwModelID
    hNpcModelView.nColorChannelTable = nColorChannelTable
    hNpcModelView.nColorChannel = nColorChannel
    hNpcModelView.tRepresentID = clone(tRepresentID)
    hNpcModelView.fScale = fScale
    hNpcModelView.szFaceIni = szFaceIni
    hNpcModelView.tCamera = tCamera
    hNpcModelView.bSheath = bSheath

    -- tFrame.fNpcYaw = 0
    -- if tCamera then
    --     local c = tCamera
    --     if c[7] then
    --         hScene.fNpcYaw = c[7]
    --     end
    --     local fWidth, fHeight = hScene:GetSize()
    --     InitCamera(hScene, c)
        --hScene.camera:init(hNpcModelView.m_scene, c[1], c[2], c[3], c[4], c[5], c[6], math.pi / 4, fWidth / fHeight, nil, nil, true)
    -- end

    hNpcModelView:UnloadModel()
    if dwModelID > 0 then
        local bFace = false
        if szFaceIni and szFaceIni ~= "" then
            bFace = true
        end
        nRoleType = nRoleType or Npc_GetRoleType(szFaceIni)
        hNpcModelView.nRoleType = nRoleType
    	hNpcModelView:LoadNpcRes(dwModelID, false, nRoleType, bFace, bSheath, tRepresentID)
        hNpcModelView:LoadModel()
        if nColorChannel then
            hNpcModelView:SetDetail(nColorChannelTable, nColorChannel)
        end
        hNpcModelView:SetScaling(fScale)

        if bSameModel and hNpcModelView.aAnisStandby then
            if not hNpcModelView.aAnisStandby.szAni then
                UILog(string.format("喊老毕加一下%d模型 %d对应的动作。", dwModelID, hNpcModelView.aAnisStandby.dwAniID))
            end
            hNpcModelView:PlayAnimationByPath(hNpcModelView.aAnisStandby.szAni, hNpcModelView.aAnisStandby.szLoopType)
        else
            --hNpcModelView:PlayAnimation("Idle", "loop")
            NpcModelPreview.PlayAni(szFrame, szName, 30, "loop")
        end

        if hNpcModelView.m_NpcMDL then
            hNpcModelView.m_NpcMDL["MDL"]:SetYaw(tFrame.fNpcYaw)
        end
        if tFrame.tPos then
            hNpcModelView:SetTranslation(tFrame.tPos[1], tFrame.tPos[2], tFrame.tPos[3])
        end
        if bFace then
            hNpcModelView:LoadFaceDefinitionINI(szFaceIni)
        end
    end
    FireUIEvent("ON_NPC_CAMERA_UPDATE", szFrame, szName)
end

function NpcModelPreview.RepresentUpdate(szFrame, szName, bSheath, tRepresentID)
    local tFrameList = NpcModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    local hNpcModelView = tFrame.hNpcModelView

    local dwModelID = hNpcModelView.dwModelID
    local nColorChannelTable = hNpcModelView.nColorChannelTable
    local nColorChannel = hNpcModelView.nColorChannel
    local fScale = hNpcModelView.fScale
    local tCamera = hNpcModelView.tCamera
    local szFaceIni = hNpcModelView.szFaceIni
    local nRoleType = hNpcModelView.nRoleType
    if not dwModelID then
        return
    end
    NpcModelPreview.ShowNpc(szFrame, szName, dwModelID, nColorChannelTable, nColorChannel, fScale, tCamera, szFaceIni, nRoleType, bSheath, tRepresentID)
end

function NpcModelPreview.PlayAni(szFrame, szName, dwAniID, szLoopType, fnEnd)
    local tFrameList = NpcModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end

    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    local hNpcModelView = tFrame.hNpcModelView
    if not hNpcModelView then
        return
    end
    if hNpcModelView.dwModelID then
        local szAni = NPC_GetAnimationResource(hNpcModelView.dwModelID, dwAniID)
        if szLoopType == "loop" then
            hNpcModelView.aAnisStandby = {
                dwAniID = dwAniID,
                szAni = szAni,
                szLoopType = szLoopType,
            }
            playing_delete(hNpcModelView)
        elseif szLoopType == "once" then
            hNpcModelView.aAnis = hNpcModelView.aAnis or {}
            hNpcModelView.aAnis[dwAniID] = fnEnd
            hNpcModelView:RegisterEventHandler()
            playing_add(hNpcModelView)
        else
            playing_delete(hNpcModelView)
        end
        hNpcModelView:PlayAnimationByPath(szAni, szLoopType)
    end
end

function NpcModelPreview_GetCameraRadius(szFrame, szName)
    if not NpcModelPreview.tResisterFrame[szFrame] then
        return
    end
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    return hScene.camera:get_radius()
end

function NpcModelPreview_SetCameraRadius(szFrame, szName, szRadius, nFrameNum)
    nFrameNum = nFrameNum or FRAME_NUM
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
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

function NpcModelPreview_SetCameraZoom(szFrame, szName, szRadius)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
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

function NpcModelPreview_GetRoleYaw(szFrame, szName)
    if not NpcModelPreview.tResisterFrame[szFrame] then
        return
    end
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    local hFrame = Station.Lookup(tFrame.szFramePath)
    local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    return hScene.fNpcYaw
end

function NpcModelPreview_GetCameraPosition(szFrame, szName)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
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

function NpcModelPreview_GetPosition(szFrame, szName)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    return tFrame.tPos
end

function NpcModelPreview_SetCameraPosition(szFrame, szName, tCamera)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    -- local hFrame = Station.Lookup(tFrame.szFramePath)
    -- local hScene = GetUIObjectByPath(hFrame, tFrame.szScene)
    local c = tCamera
    -- local fWidth, fHeight = hScene:GetSize()
    local hNpcModelView = tFrame.hNpcModelView
    local tCenterPos = {c[7], c[8], c[9]}
    local nWidth, nHeight = UIHelper.GetContentSize(tFrame.Viewer)
    InitCamera(nWidth, nHeight, tFrame, c)
    --hScene.camera:init(hNpcModelView.m_scene, c[1], c[2], c[3], c[4], c[5], c[6], math.pi / 4, fWidth / fHeight, nil, nil, true)
    if hNpcModelView.m_NpcMDL then
        hNpcModelView.m_NpcMDL["MDL"]:SetYaw(tFrame.fNpcYaw)
    end
end

function NpcModelPreview_SetCameraCenterR(szFrame, szName, nCenterR, nFrameNum)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    tFrame.camera:set_center_r(nCenterR, nFrameNum)
end

function NpcModelPreview_GetCameraCenterR(szFrame, szName)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:get_center_r()
end

function NpcModelPreview_SetCameraOffset(szFrame, szName, fAngleX, fAngleY, fAngleZ, fModelX, fModelY, fModelZ, bNotUpdate)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:SetOffsetAngle(fAngleX, fAngleY, fAngleZ, fModelX, fModelY, fModelZ, bNotUpdate)
end

function NpcModelPreview_GetCameraOffset(szFrame, szName)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end
    return tFrame.camera:GetOffsetAngle()
end

function NpcModelPreview_GetRegisterFrame(szFrame, szName)
    local tFrameList = NpcModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end

    local tFrame = tFrameList[szName]
    return tFrame
end

function NpcModelPreview_TouchUpdate(szFrame, szName, bTouch, x, y)
    print(szFrame, szName, bTouch, x, y)
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if not tFrame then
        return
    end

    if not tFrame.bTouch and bTouch then
        tFrame.nCX = x
    end
    tFrame.bTouch = bTouch

    tFrame.bTurnRight = bTouch and x > tFrame.nCX
    tFrame.bTurnLeft = bTouch and x < tFrame.nCX
end

local function RestoreMsgFunction(szFrame, szFunctionName)
    if _G[szFrame] and NpcModelPreview.tEventFrame[szFrame] and
       _G[szFrame][szFunctionName] == NpcModelPreview.tEventFrame[szFrame]["fnNew" .. szFunctionName] then

       _G[szFrame][szFunctionName] = NpcModelPreview.tEventFrame[szFrame]["fnOld" .. szFunctionName]
    end
end

function RegisterNpcModelPreview(tNpcParam)
    local szFrame = tNpcParam.szFrameName
    local szName = tNpcParam.szName
    NpcModelPreview.tResisterFrame[szFrame] = NpcModelPreview.tResisterFrame[szFrame] or {}
    local tFrame = NpcModelPreview.tResisterFrame[szFrame][szName]
    if tFrame then
        local hNpcModelView = tFrame.hNpcModelView
        if hNpcModelView then
            hNpcModelView:UnloadModel()
            hNpcModelView:release()
            tFrame.hNpcModelView = nil
        end

        NpcModelPreview.tResisterFrame[szFrame][szName] = nil
    end

    NpcModelPreview.tResisterFrame[szFrame][szName] = tNpcParam
    NpcModelPreview.Init(szFrame, szName)
end

function UnRegisterNpcModel(szFrame, szName)
    local tFrameList = NpcModelPreview.tResisterFrame[szFrame]
    if not tFrameList then
        return
    end
    local tFrame = tFrameList[szName]
    if not tFrame then
        return
    end
    local hNpcModelView = tFrame.hNpcModelView
    if hNpcModelView then
        hNpcModelView:UnloadModel()
        hNpcModelView:release()
        tFrame.hNpcModelView = nil
    end

    NpcModelPreview.tResisterFrame[szFrame][szName] = nil
end

function RegisterNpcModelEvent(szFrame)
    -- if NpcModelPreview.tEventFrame[szFrame] then
    --     RestoreMsgFunction(szName, "OnLButtonDown")
    --     RestoreMsgFunction(szName, "OnLButtonUp")
    --     RestoreMsgFunction(szName, "OnRButtonDown")
    --     RestoreMsgFunction(szName, "OnRButtonUp")
    --     --RestoreMsgFunction(szName, "OnFrameBreathe")
    --     RestoreMsgFunction(szName, "OnFrameDestroy")
    --     RestoreMsgFunction(szName, "OnMouseWheel")
    --     RestoreMsgFunction(szName, "OnEvent")
    -- end

    NpcModelPreview.tResisterFrame[szFrame] = {}
    NpcModelPreview.tEventFrame[szFrame] = {}
    -- NpcModelPreview.CreateOnLButtonDown(szFrame)
    -- NpcModelPreview.CreateOnLButtonUp(szFrame)
    -- NpcModelPreview.CreateOnRButtonDown(szFrame)
    -- NpcModelPreview.CreateOnRButtonUp(szFrame)
    --handlescene不要弄拖动，一堆问题
    --NpcModelPreview.CreateOnFrameBreathe(szFrame)
    -- NpcModelPreview.CreateOnFrameDestroy(szFrame)
    -- NpcModelPreview.CreateOnMouseWheel(szFrame)
    NpcModelPreview.CreateOnEvent(szFrame)
end

-- local function OnNpcModelPreviewEvent(szEvent)
--     if szEvent == "NPC_MODEL_PREVIEW_UPDATE" then
--         NpcModelPreview.ShowNpc(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
--     elseif szEvent == "NPC_MODEL_SET_CAMERA_CENTER_R" then
--         NpcModelPreview_SetCameraCenterR(arg0, arg1, arg2, arg3)
--     elseif szEvent == "NPC_MODEL_PLAY_ANI" then
--         NpcModelPreview.PlayAni(arg0, arg1, arg2, arg3, arg4)
--     end
-- end

Event.Reg(NpcModelPreview, "NPC_MODEL_PREVIEW_UPDATE", function()
    NpcModelPreview.ShowNpc(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
end)

Event.Reg(NpcModelPreview, "NPC_MODEL_TOUCH_UPDATE", function(szFrame, szName, bTouch, x, y)
    NpcModelPreview_TouchUpdate(szFrame, szName, bTouch, x, y)
end)

Event.Reg(NpcModelPreview, "NPC_MODEL_SET_CAMERA_RADIUS", function (szFrame, szName, szRadius, nFrameNum)
    NpcModelPreview_SetCameraRadius(szFrame, szName, szRadius, nFrameNum)
end)

Event.Reg(NpcModelPreview, "NPC_MODEL_SET_CAMERA_ZOOM", function (szFrame, szName, szRadius)
    NpcModelPreview_SetCameraZoom(szFrame, szName, szRadius)
end)

Event.Reg(NpcModelPreview, "NPC_MODEL_SET_CAMERA_CENTER_R", function()
    NpcModelPreview_SetCameraCenterR(arg0, arg1, arg2, arg3)
end)

Event.Reg(NpcModelPreview, "NPC_REPRESENT_UPDATE", function()
    NpcModelPreview.RepresentUpdate(arg0, arg1, arg2, arg3)
end)

-- RegisterEvent("NPC_MODEL_PREVIEW_UPDATE", function(szEvent) OnNpcModelPreviewEvent(szEvent) end)
-- RegisterEvent("NPC_MODEL_SET_CAMERA_CENTER_R", function(szEvent) OnNpcModelPreviewEvent(szEvent) end)
-- RegisterEvent("NPC_MODEL_PLAY_ANI", function(szEvent) OnNpcModelPreviewEvent(szEvent) end)
-- RegisterEvent("NPC_REPRESENT_UPDATE", function(szEvent) OnNpcModelPreviewEvent(szEvent) end)
