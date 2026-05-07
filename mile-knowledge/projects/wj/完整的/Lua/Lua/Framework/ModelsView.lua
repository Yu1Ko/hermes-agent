local _tSocketName = --背上的插槽
{
    [WEAPON_DETAIL.SWORD] = {RH="S_RC"}, --短兵类
    [WEAPON_DETAIL.DOUBLE_WEAPON] = {LH="S_LC", RH="S_RC"},  --双兵类
    [WEAPON_DETAIL.PEN] = {RH="S_RP"}, --笔类
    [WEAPON_DETAIL.BOW] = {RH="S_bow"},--千机匣
    [WEAPON_DETAIL.FLUTE] = {RH="S_flute"},  -- 笛类
    [WEAPON_DETAIL.SPEAR] = {RH="S_Long"}, --长兵类
    [WEAPON_DETAIL.WAND] = {RH="S_Long"},  --棍类
    [WEAPON_DETAIL.BIG_SWORD] = {RH="S_epee"},  --重剑
    [WEAPON_DETAIL.KNIFE] = {LH="S_LTulwar", RH="S_RTulwar"},  --小刀
    [WEAPON_DETAIL.STICK] = {LH="S_rod", RH="S_pot"},  --STICK
    [WEAPON_DETAIL.BLADE_SHIELD] = {LH="s_shield", RH="s_modao"},
    [WEAPON_DETAIL.HEPTA_CHORD] = {LH="s_qin01", RH="s_jian01"},
    [WEAPON_DETAIL.BROAD_SWORD] = {LH="s_bddagger", RH="s_bdknife", DART="s_bdshell", RACK="S_BDshelf"},--
    [WEAPON_DETAIL.UMBRELLA] = {RH="s_epee"},-- 伞
    [WEAPON_DETAIL.CHAIN_BLADE] = {LH="s_Lchain", RH="S_RC"},-- 链刀
    [WEAPON_DETAIL.SOUL_LAMP] = {LH="S_Long"},-- 魂灯
    [WEAPON_DETAIL.SCROLL] = {LH="s_medkit"},
    [WEAPON_DETAIL.MASTER_BLADE] = {LH="S_LH",RH = "S_RH",DART="s_tangdao", RACK=""},
    [WEAPON_DETAIL.LONGBOW] = {RH="S_RC"},
}

ModelsView = class("ModelsView")

local _tInitSFX = {
    SfxPath     = "",
    Scale       = 1.0,
    Position    = {x = 0, y = 0, z = 0,},
    Rotation    = {x = 0, y = 0, z = 0, w = 0},
}

local _tItemDefaultPos = {
    [ROLE_TYPE.STANDARD_MALE] = {
        [0] = { 0, 0, 0},
        [1] = { -180, 60, 0},
        [2] = { 0, 60, 0},
        [3] = { 180, 60, 0},
        [4] = { -180, -210, 0},
        [5] = { 0, -210, 0},
        [6] = { 180, -210, 0},
    },
    [ROLE_TYPE.STANDARD_FEMALE] = {
        [0] = { 0, 0, 0},
        [1] = { -170, 60, 0},
        [2] = { 0, 60, 0},
        [3] = { 170, 60, 0},
        [4] = { -170, -200, 0},
        [5] = { 0, -200, 0},
        [6] = { 170, -200, 0},
    },
    [ROLE_TYPE.LITTLE_BOY] = {
        [0] = { 0, 0, 0},
        [1] = { -113, 30, 0},
        [2] = { 0, 30, 0},
        [3] = { 120, 30, 0},
        [4] = { -113, -150, 0},
        [5] = { 0, -150, 0},
        [6] = { 120, -150, 0},
    },
    [ROLE_TYPE.LITTLE_GIRL] = {
        [0] = { 0, 0, 0},
        [1] = { -120, 30, 0},
        [2] = { 0, 30, 0},
        [3] = { 115, 30, 0},
        [4] = { -120, -150, 0},
        [5] = { 0, -150, 0},
        [6] = { 115, -150, 0},
    }
}

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

local function playing_add(modelview, nIndex)
    nIndex = nIndex or 0

    if not modelview:IsRegisterEventHandler(nIndex) then
        return
    end

    local id = KG3DEngine.ModelToID( modelview:Mdl() )
    if not _tPlaying[id] then
        _play_count = _play_count + 1
    end

    _tPlaying[id] = modelview

    if _play_count > 0 and not _play_ref then
        -- _play_ref = RegisterEvent("KG3D_PLAY_ANIMAION_FINISHED", play_onfinished)
        _play_ref = Event.Reg(ModelsView, "KG3D_PLAY_ANIMAION_FINISHED", play_onfinished)
    end
end

local function playing_delete(modelview, nIndex)
    nIndex = nIndex or 0

    if not modelview:IsRegisterEventHandler(nIndex) then
        return
    end

    local id = KG3DEngine.ModelToID( modelview:Mdl() )
    if _tPlaying[id] then
        _tPlaying[id] = nil
        _play_count = _play_count - 1
    end

    if _play_count == 0 and _play_ref then
        -- UnRegisterEvent("KG3D_PLAY_ANIMAION_FINISHED", _play_ref)
        Event.UnReg(ModelsView, "KG3D_PLAY_ANIMAION_FINISHED")

        _play_ref = nil
    end
end

local function IsHaveCloak(aEquipRes)
    if not aEquipRes then
        return false
    end
    if not aEquipRes["CLOAK"] then
        return false
    end

    if not aEquipRes["CLOAK"]["Mesh"] then
        return false
    end

    return true
end

local function IsHaveExtendCloak(aEquipRes)
    if not aEquipRes then
        return false
    end
    if not aEquipRes["EXTEND_PART"] then
        return false
    end

    if not aEquipRes["EXTEND_PART"]["Mesh"] then
        return false
    end
    return true
end

local m_tRoleAnimations
function GetRoleAnimation(nWeaponType)
    if g_tRoleAnimations then
        return g_tRoleAnimations[nWeaponType]
    end
end;


local function IsEquipType(equipType)
    if equipType ~= "MDL" and equipType ~= "MDLScale" and equipType ~= "nWeaponType" then
        return true
    end
end

function ModelsView:ctor()
    self.m_modelMgr = nil;
    self.m_modelRole = nil;
    self.m_modelRoleSFX = nil;
    self.m_ResourceSFX = nil
    self.m_aEquipRes = {};
    self.m_aAnimationRes = { Idle = {}, Standard = {}, StandardNew = {}};
    self.m_aRoleAnimation = { Idle = 100 , Standard = 30, StandardNew = 60211};
    self.m_aRepresentID = nil;
    self.m_nRoleType = nil;
    self.aAnis = nil
    self.WeaponVisible = nil
    self.bAdjustByAnimation = false
    self.bForceRealInterpolate = false
    self.bMainPlayer = false
end;

function ModelsView:SetNpcAnimation()
    self.m_aAnimationRes = { Idle = {}};
    self.m_aRoleAnimation = { Idle = 30 };
end

function ModelsView:release()
    self:Free3D()
end;

function ModelsView:init(szEnvPath, bExScene, scene, canselect, szExSceneFile, bModLod, bAPEX)
    self:ctor() --旧版class自动调用ctor，新版Class手动调一次
    local tParam = {
        szEnvPath = szEnvPath,
        bExScene = bExScene,
        scene = scene,
        canselect = canselect,
        szExSceneFile = szExSceneFile,
        bModLod = bModLod,
        bAPEX = bAPEX or false,
    }
    self:Init3D(tParam)
end;

function ModelsView:InitBy(tParam)
    self:Init3D(tParam)
end

function ModelsView:SetSceneName(szName)
    if self.m_scene then
        self.m_scene:SetName(szName)
    end
end

function ModelsView:SetAdjustByAnimation(bAdjustByAnimation)
    self.bAdjustByAnimation = bAdjustByAnimation
end

function ModelsView:Init3D(tParam)
    local szExSceneFile = tParam.szExSceneFile
    local szEnvPath = tParam.szEnvPath
    if tParam.scene then
        self.m_scene = tParam.scene
        self.bMgrScene = false
        self.bForceRealInterpolate = true
        self.bMainPlayer = false
    elseif tParam.bExScene then
        self.m_scene = SceneHelper.Create(szExSceneFile, false, false, true)
        self.bMgrScene = true
        self.bForceRealInterpolate = true
        self.bMainPlayer = false
    else
        self.m_scene = SceneHelper.NewScene_Old(szEnvPath, tParam.szName)
        self.bMgrScene = true
    end

    self.bModLod = false
    if tParam.bModLod then
        self.bModLod = tParam.bModLod
    end

    self.bAPEX = tParam.bAPEX or false

    self.bExScene = tParam.bExScene
    self.m_modelMgr = KG3DEngine.GetModelMgr()

    self.m_canselect = tParam.canselect

    if self.bMgrScene then
        self:SetCamera({ 0, 150, -200, 0, 50, 150 })
    end
end;

function ModelsView:Free3D()
    if self.m_modelRole then
        for _, index in ipairs(table.Keys(self.m_modelRole)) do
            self:UnloadModel(index)
        end
    end

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
    self.reg_handler = nil
    self.aAnis = nil
end;

function ModelsView:Mdl(nIndex)
    nIndex = nIndex or 0
    return self:GetModel(nIndex, "MDL");
end

function ModelsView:RoleType()
    return self.m_nRoleType
end

function ModelsView:SetCamera(args)
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
end;

function ModelsView:GetCameraPos()
    return self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ
end

function ModelsView:SetCameraPos(x, y, z)
    self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ = x, y, z
	self.m_scene:SetCameraPosition(x, y, z)
end

function ModelsView:GetCameraLookPos()
    return self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ
end

function ModelsView:SetCameraLookPos(x, y, z)
    self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ = x, y, z
	self.m_scene:SetCameraLookAtPosition(x, y, z)
end

function ModelsView:GetCameraPerspective()
    return self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar
end

function ModelsView:SetCameraPerspective(fovY, aspect, near, far)
    self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar = fovY, aspect, near, far
	self.m_scene:SetCameraPerspective(fovY, aspect, near, far)
end

function ModelsView:GetCameraOrthogonal()
    return self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar
end

function ModelsView:SetCameraOrthogonal(w, h, near, far)
    self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar = w, h, near, far
	self.m_scene:SetCameraOrthogonal(w, h, near, far)
end

function ModelsView:LoadModelSFXByName(nIndex, model, equipType, aNewEquipRes, szName, szSocketName)
    nIndex = nIndex or 0

    if aNewEquipRes[equipType][szName] then
        local mdl = self:GetModel(nIndex, "MDL")
        local modelsfx = self.m_modelMgr:NewModel(aNewEquipRes[equipType][szName], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
        self.m_modelRoleSFX[nIndex] = self.m_modelRoleSFX[nIndex] or {}
        self.m_modelRoleSFX[nIndex][equipType .. szName] = modelsfx
        if modelsfx then
            if aNewEquipRes[equipType][szSocketName] then
                modelsfx:BindToSocket(mdl, aNewEquipRes[equipType][szSocketName])
            else
                modelsfx:BindToBone(model)
            end
        end
    end
end

function ModelsView:LoadModelSFX(nIndex, model, equipType, aNewEquipRes)
    --Load SFX1
    self:LoadModelSFXByName(nIndex, model, equipType, aNewEquipRes, "SFX1", "SFX1Socket")

    --Load SFX2
    self:LoadModelSFXByName(nIndex, model, equipType, aNewEquipRes, "SFX2", "SFX2Socket")
end;

function ModelsView:UnloadModelSFX(nIndex, equipType)
    nIndex = nIndex or 0

    --Unload SFX2
    if self.m_modelRoleSFX[nIndex] and self.m_modelRoleSFX[nIndex][equipType.."SFX2"] then
        self.m_modelRoleSFX[nIndex][equipType.."SFX2"]:UnbindFromOther()
        self.m_modelRoleSFX[nIndex][equipType.."SFX2"]:Release()
        self.m_modelRoleSFX[nIndex][equipType.."SFX2"] = nil
        --
    end
    --Unload SFX1
    if self.m_modelRoleSFX[nIndex] and self.m_modelRoleSFX[nIndex][equipType.."SFX1"] then
        self.m_modelRoleSFX[nIndex][equipType.."SFX1"]:UnbindFromOther()
        self.m_modelRoleSFX[nIndex][equipType.."SFX1"]:Release()
        self.m_modelRoleSFX[nIndex][equipType.."SFX1"] = nil
    end
end;

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

function ModelsView:BindSFX(nIndex, szSocketName, tSFX, tModels)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "MDL")
    local sfx = self.m_modelMgr:NewModel(tSFX["SfxPath"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
    for equipType, model in pairs(self.m_modelRole[nIndex] or {}) do
        local UserData = {}
        UserData.szSocketName = szSocketName
        UserData.tSFX = tSFX
        UserData.tModels = tModels
        UserData.sfx = sfx

        Post3DModelThreadCall(OnSfxFind, UserData, model, "Find", szSocketName)
    end
    tModels[szSocketName] = sfx
end

local function OnFind(model, UserData, bFind)
    if not bFind then
        return
    end
    local szSocketName = UserData.szSocketName
    local mdl = UserData.mdl
    local sub = string.lower(string.sub(szSocketName, 1, 2))

    if sub == "s_" then
        mdl:BindToSocket(model, szSocketName)
    else
        mdl:BindToBone(model, szSocketName)
    end
end

function ModelsView:BindToSpecialSocket(mdl, szSocketName)
    nIndex = nIndex or 0

    for equipType, model in pairs(self.m_modelRole[nIndex] or {}) do
        local UserData = {}
        UserData.mdl = mdl
        UserData.szSocketName = szSocketName

        Post3DModelThreadCall(OnFind, UserData, model, "Find", szSocketName)
    end
end

function ModelsView:LoadResourceSFX(nIndex, equipType, tSFXList)
    self.m_ResourceSFX[nIndex] = self.m_ResourceSFX[nIndex] or {}
    self.m_ResourceSFX[nIndex][equipType] = self.m_ResourceSFX[nIndex][equipType] or {}
    local tModels = self.m_ResourceSFX[nIndex][equipType]
    for szSocketName, tSFX in pairs(tSFXList) do
        if not tModels[szSocketName] and tSFX.SfxPath and tSFX.SfxPath ~= "" then
            self:BindSFX(szSocketName, tSFX, tModels)
        end
    end
end

function ModelsView:UnloadResourceSFX(nIndex, equipType)
    local tModels = self.m_ResourceSFX[nIndex] and self.m_ResourceSFX[nIndex][equipType] or {}
    for szSocketName, model in pairs(tModels) do
        model:UnbindFromOther()
        model:Release()
        tModels[szSocketName] = nil
    end
    if self.m_ResourceSFX[nIndex] then
        self.m_ResourceSFX[nIndex][equipType] = nil
    end
end

function ModelsView:LoadPart(nIndex, equipType, aNewEquipRes, aEquipRes)
    nIndex = nIndex or 0

    if aNewEquipRes[equipType]["Mesh"] then
        local mdl = self:GetModel(nIndex, "MDL")
        local model = self:GetModel(nIndex, equipType)
        local new_model = false
        if not aEquipRes or not model or aNewEquipRes[equipType]["Mesh"] ~= aEquipRes[equipType]["Mesh"] then
            self:UnloadPart(equipType)
            model = self.m_modelMgr:NewModel(aNewEquipRes[equipType]["Mesh"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
            self:SetModel(nIndex, equipType, model)

            if model then
                mdl:Attach(model)
            end
            new_model = true
        end

        if model then
            -- if aNewEquipRes[equipType]["Mtl"] and
            -- 	(new_model or not aEquipRes or (aNewEquipRes[equipType]["Mtl"] ~= aEquipRes[equipType]["Mtl"]) ) then
            --     model:LoadMaterialFromFile(aNewEquipRes[equipType]["Mtl"])
            -- end

            -- LOG.ERROR("[UI] LoadPart("..equipType..", "..self.m_nRoleType..", "..aNewEquipRes[equipType]["ColorChannel"]..", "..aNewEquipRes[equipType]["Mesh"]..")")

            model:SetDetail(self.m_nRoleType, aNewEquipRes[equipType]["ColorChannel"])

            local scale = aNewEquipRes[equipType]["MeshScale"]

            --model:SetScaling(scale, scale, scale)
            self:UnloadModelSFX(nIndex, equipType)

            self:LoadModelSFX(nIndex, model, equipType, aNewEquipRes)
        end
    else
        self:UnloadPart(equipType)
    end
end

function ModelsView:LoadSocket(nIndex, equipType, aNewEquipRes, aEquipRes, bHaveCloak)

    nIndex = nIndex or 0

    if aNewEquipRes[equipType]["Mesh"] then

        -- 刀宗会多一把剑在背上，目前 s_tangdao 这个插槽只有 刀宗在用，因此先这样屏蔽这个插槽的资源加载
        if equipType == "RL_WEAPON_DART" then
            if aNewEquipRes[equipType]["Socket"] == _tSocketName[WEAPON_DETAIL.MASTER_BLADE].DART then
                return
            end
        end

        local mdl = self:GetModel(nIndex, "MDL")
        local model = self:GetModel(nIndex, equipType)
        local new_model = false
        if not aEquipRes or not model or aNewEquipRes[equipType]["Mesh"] ~= aEquipRes[equipType]["Mesh"] then
            self:UnloadSocket(equipType)

            model = self.m_modelMgr:NewModel(aNewEquipRes[equipType]["Mesh"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)

            self:SetModel(nIndex, equipType, model)

            local szAni = aNewEquipRes[equipType]["Ani"]
            if szAni and szAni ~= "" and model then
                model:PlayAnimation("loop", szAni, 1.0, 0)
            end
            new_model = true
        end

        if model then
            model:UnbindFromOther()
            if bHaveCloak then
                if szSocketName == "s_spine2" then --TODO: szSocketName?
                    aNewEquipRes[equipType]["Socket"] = "s_movespine2"
                end

                if szSocketName == "s_bigbrush" then
                    aNewEquipRes[equipType]["Socket"] = "s_movebigbrush"
                end
            end

            if equipType ~= "LANTERN" then
                model:BindToSocket(mdl, aNewEquipRes[equipType]["Socket"])
            end

            -- if aNewEquipRes[equipType]["Mtl"] and
            -- 	(new_model or not aEquipRes or (aNewEquipRes[equipType]["Mtl"] ~= aEquipRes[equipType]["Mtl"]) ) then
            --     model:LoadMaterialFromFile(aNewEquipRes[equipType]["Mtl"])
            -- end

            model:SetAlpha(1)
            if equipType == "RL_WEAPON_LH" or equipType == "RL_WEAPON_RH" or
                equipType == "RL_WEAPON_DART" or equipType == "RL_WEAPON_RACK" or
                equipType == "HeavySword"
            then
                local nColorChannelTable = Player_GetColorChannelTable()

                --LOG.ERROR("[UI] LoadSocket("..equipType..", "..nColorChannelTable..", "..aNewEquipRes[equipType]["ColorChannel"]..", "..aNewEquipRes[equipType]["Mesh"]..")")

               	model:SetDetail(nColorChannelTable, aNewEquipRes[equipType]["ColorChannel"])

               	if self.WeaponVisible and self.WeaponVisible[equipType] ~= nil then
                    if not self.WeaponVisible[equipType] then
                        model:SetAlpha(0)
                    end
               	end
            else
                -- LOG.ERROR("[UI] LoadSocket("..equipType..", "..self.m_nRoleType..", "..aNewEquipRes[equipType]["ColorChannel"]..", "..aNewEquipRes[equipType]["Mesh"]..")")
               	model:SetDetail(self.m_nRoleType, aNewEquipRes[equipType]["ColorChannel"])
            end
            local tRepresentID = self.m_aRepresentID
            if equipType == "CLOAK" then
                local nColor1 = tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1]
                local nColor2 = tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2]
                local nColor3 = tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3]
                if nColor1 ~= 0 and nColor2 ~=0 and nColor3 ~=0 then
                    model:SetDetail(self.m_nRoleType, nColor1)
                    model:SetDetailColor(nColor1, nColor2, nColor3)
                end
            end

            local fSocketOffset = 0
            local x = 0
            local y = 0
            local z = 0
            for i = EQUIPMENT_REPRESENT.FACE_STYLE, EQUIPMENT_REPRESENT.TOTAL do
                x, y, z = Character_GetPlayerSocketOffset(self.m_nRoleType, i, tRepresentID[i], aNewEquipRes[equipType]["Socket"])
                if x ~= 0 or y ~= 0 or z ~= 0 then
                    break
                end
            end

            if x ~= 0 or y ~= 0 or z ~= 0  then
                model:SetTranslation(x, y, z)
            end

            local scale = aNewEquipRes[equipType]["MeshScale"]

            model:SetScaling(scale, scale, scale)
            self:UnloadModelSFX(nIndex, equipType)
            self:LoadModelSFX(nIndex, model, equipType, aNewEquipRes)
        end
    else
        self:UnloadSocket(nIndex, equipType)
    end
end

function ModelsView:UpdateWeaponPos(bSheath, nWeaponType, dwPoseState, bSwitchSword)
    local aRes = clone(self.m_aEquipRes)

    if bSheath then --- 武器收起状态，把武器绑定指定插槽上
        local tSocket = _tSocketName[nWeaponType]
        if nWeaponType == WEAPON_DETAIL.BIG_SWORD then
            tSocket = _tSocketName[WEAPON_DETAIL.SWORD]
            aRes["HeavySword"]["Socket"] = "S_epee"
        elseif nWeaponType == WEAPON_DETAIL.BROAD_SWORD then
            aRes["RL_WEAPON_DART"]["Socket"] = tSocket.DART
            aRes["RL_WEAPON_RACK"]["Socket"] = tSocket.RACK
        end

        if tSocket and tSocket.LH then
            aRes["RL_WEAPON_LH"]["Socket"] = tSocket.LH
        end

        if tSocket and tSocket.RH then
            aRes["RL_WEAPON_RH"]["Socket"] = tSocket.RH
        end
    elseif dwPoseState and dwPoseState >= 0 then
        local tSocket = Character_GetPoseStateSocket(nWeaponType, dwPoseState)
        for szName, szSocket in pairs(tSocket) do
            aRes[szName]["Socket"] = szSocket
        end
    elseif bSwitchSword then
        aRes["HeavySword"]["Socket"]  = "S_RH"
        aRes["RL_WEAPON_RH"]["Socket"] = "S_RC"
    else--正常情况 武器绑到左右手
        aRes["HeavySword"]["Socket"]   = "S_epee"
        aRes["RL_WEAPON_LH"]["Socket"] = "S_LH"
        aRes["RL_WEAPON_RH"]["Socket"] = "S_RH"
        aRes["RL_WEAPON_DART"]["Socket"] = "s_bdshell"
        aRes["RL_WEAPON_RACK"]["Socket"] = "s_BDshelf"

        if nWeaponType == WEAPON_DETAIL.MASTER_BLADE then
            local tSocket = _tSocketName[nWeaponType]
            aRes["RL_WEAPON_DART"]["Socket"] = tSocket.DART
            aRes["RL_WEAPON_RACK"]["Socket"] = tSocket.RACK
        end
    end
    self:UpdateRoleModel(aRes, self.m_nRoleType)
end

function ModelsView:SetWeaponVisible(nIndex, equipType, bShow)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, equipType)
    if mdl then
        if bShow then
            mdl:SetAlpha(1)
        else
            mdl:SetAlpha(0)
        end
    end
    self.WeaponVisible = self.WeaponVisible or {}
    self.WeaponVisible[equipType] = bShow
end


function ModelsView:UpdateRoleModel(nIndex, aNewEquipRes, nRoleType)
    nIndex = nIndex or 0

    if not aNewEquipRes or not aNewEquipRes["MDL"] then
        return
    end
    self.m_nRoleType = nRoleType

    self.m_modelRole = self.m_modelRole or {}
    self.m_modelRoleSFX = self.m_modelRoleSFX or {}
    self.m_ResourceSFX = self.m_ResourceSFX or {}
    local aEquipRes = self.m_aEquipRes
    self.m_aEquipRes = aNewEquipRes

    local mdlOld = nil
    local mdl = self:GetModel(nIndex, "MDL")
    if not aEquipRes or mdl == nil or aNewEquipRes["MDL"] ~= aEquipRes["MDL"] then

        playing_delete(self)

        mdlOld = mdl

        self:UnloadModel(nIndex, true);
        aEquipRes = nil
        self.m_modelRole = self.m_modelRole or {}
        self.m_modelRoleSFX = self.m_modelRoleSFX or {}
        self.m_ResourceSFX = self.m_ResourceSFX or {}

        mdl = self.m_modelMgr:NewModel(aNewEquipRes["MDL"], self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel)

        local tPos = _tItemDefaultPos[nRoleType][nIndex]
        mdl:SetTranslation(tPos[1], tPos[2], tPos[3])


        self:SetModel(nIndex, "MDL", mdl)

        if self.reg_handler then
            self:RegisterEventHandler(nIndex)
        end

        if self.aAnis and #self.aAnis > 0 then
            playing_add(self, nIndex)
        end
    end
    local scale = aNewEquipRes["MDLScale"]
    mdl:SetScaling(scale, scale, scale)
    local tResourceSFX = {}
    -- load part and sfx

    if aEquipRes then
        for equipType, equipRes in pairs(aEquipRes) do
            if IsEquipType(equipType) and not aEquipRes[equipType]["bPart"] then
                if aEquipRes[equipType]["Socket"] ~= aNewEquipRes[equipType]["Socket"] then
                    self:UnloadSocket(equipType)
                end
            end
        end

        for equipType, equipRes in pairs(aEquipRes) do
            if IsEquipType(equipType) and aEquipRes[equipType]["bPart"] then
                if aEquipRes[equipType]["Socket"] ~= aNewEquipRes[equipType]["Socket"] then
                    self:UnloadPart(equipType)
                end
            end
        end
    end

    local bHaveCloak = IsHaveCloak(aNewEquipRes) or IsHaveExtendCloak(aNewEquipRes)
    for equipType, equipRes in pairs(aNewEquipRes) do
        if IsEquipType(equipType) then
            if aNewEquipRes[equipType]["bPart"] then
                if aNewEquipRes[equipType]["Mesh"] then
                    local tSFXList = Global_GetResourceSfx(aNewEquipRes[equipType]["Mesh"], aNewEquipRes[equipType]["ColorChannel"])
                    tResourceSFX[equipType] = tSFXList
                end
                self:LoadPart(nIndex, equipType, aNewEquipRes, aEquipRes)
            end
        end
    end

    if IsHaveExtendCloak(aNewEquipRes) then
        local modelCloak = self:GetModel(nIndex, "EXTEND_PART")
        mdl:HideMeshPointOutsideCloak(modelCloak)
    else
        mdl:ClearHideMeshPointOutsideCloak()
    end

    for equipType, equipRes in pairs(aNewEquipRes) do
        if IsEquipType(equipType) then
            if not aNewEquipRes[equipType]["bPart"] then
                if aNewEquipRes[equipType]["Mesh"] then
                    local tSFXList = Global_GetResourceSfx(aNewEquipRes[equipType]["Mesh"], aNewEquipRes[equipType]["ColorChannel"])
                    tResourceSFX[equipType] = tSFXList
                end
                if aNewEquipRes[equipType]["Socket"] ~= "" then
                    self:LoadSocket(nIndex, equipType, aNewEquipRes, aEquipRes, bHaveCloak)
                end
            end
        end
    end

    if self:GetModel(nIndex, "LANTERN") then --魂灯的灯笼要绑在武器上
        local mdl = self:GetModel(nIndex, "LANTERN")
        self:BindToSpecialSocket(mdl, aNewEquipRes["LANTERN"]["Socket"])
        local tSfx = clone(_tInitSFX)
        tSfx.SfxPath = aNewEquipRes["LANTERN"]["SFX1"]
        self:LoadResourceSFX(nIndex, "LANTERN", {s_light = tSfx})
    end

    for equipType, tSFXList in pairs(tResourceSFX) do
        self:LoadResourceSFX(nIndex, equipType, tSFXList)
    end

    local tRepresentID = self.m_aRepresentID
    if tRepresentID.bUseLiftedFace and tRepresentID.tFaceData then
        local tFaceData = tRepresentID.tFaceData
        if tFaceData.tBone then
            if tFaceData.bNewFace then
                self:SetFaceDefinition(nIndex, tFaceData.tBone, self.m_nRoleType, tFaceData.tDecal, tFaceData.tDecoration, true)
            else
                self:SetFaceDefinition(nIndex, tFaceData.tBone, self.m_nRoleType, tFaceData.tDecal, tFaceData.nDecorationID)
            end
        end
    end
    -- if tRepresentID.tBody then
    --     self:SetBodyReshapingParams(tRepresentID.tBody)
    -- end

    mdl:SetForceRealInterpolate(self.bForceRealInterpolate)

    self:ShowMDL(mdl)

    if mdlOld then
        self:HideMDL(mdlOld)
        mdlOld:Release()
    end
    self:PlayWeaponAnimation(self.m_nRoleType, self.m_aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE])
end

function ModelsView:LoadModel(nIndex)
    nIndex = nIndex or 0
    if self.m_modelRole and self.m_modelRole[nIndex] then
        return
    end

    local aEquipRes = self.m_aEquipRes
    if aEquipRes["MDL"] then
        self.m_modelRole = self.m_modelRole or {}
        self.m_modelRoleSFX = {}
        self.m_ResourceSFX = {}
        local mdl = self.m_modelMgr:NewModel(aEquipRes["MDL"], self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, nil, self.bAPEX)

        local scale = aEquipRes["MDLScale"]
        mdl:SetScaling(scale, scale, scale)

        mdl:SetTranslation(0, 0, 0)
        mdl:SetMainFlag(true)

        self:SetModel(nIndex, "MDL", mdl)

        local tResourceSFX = {}

        local bHaveCloak = IsHaveCloak(aEquipRes)
        for equipType, equipRes in pairs(aEquipRes) do
            if IsEquipType(equipType) then
                if aEquipRes[equipType]["bPart"] then
                    if aEquipRes[equipType]["Mesh"] then
                        local tSFXList = Global_GetResourceSfx(aEquipRes[equipType]["Mesh"], aEquipRes[equipType]["ColorChannel"])
                        tResourceSFX[equipType] = tSFXList
                    end
                    self:LoadPart(equipType, aEquipRes)
                end
            end
        end

        for equipType, equipRes in pairs(aEquipRes) do
            if IsEquipType(equipType) then
                if not aEquipRes[equipType]["bPart"] then
                    if aEquipRes[equipType]["Mesh"] then
                        local tSFXList = Global_GetResourceSfx(aEquipRes[equipType]["Mesh"], aEquipRes[equipType]["ColorChannel"])
                        tResourceSFX[equipType] = tSFXList
                    end
                    self:LoadSocket(equipType, aEquipRes, nil, bHaveCloak)
                end
            end
        end

        if IsHaveExtendCloak(aEquipRes) then
            local modelCloak = self:GetModel(nIndex, "EXTEND_PART")
            mdl:HideMeshPointOutsideCloak(modelCloak)
        else
            mdl:ClearHideMeshPointOutsideCloak()
        end

        if self:GetModel(nIndex, "LANTERN") then --魂灯的灯笼要绑在武器上
            local mdl = self:GetModel(nIndex, "LANTERN")
            self:BindToSpecialSocket(mdl, aEquipRes["LANTERN"]["Socket"])
            local tSfx = clone(_tInitSFX)
            tSfx.SfxPath = aEquipRes["LANTERN"]["SFX1"]
            self:LoadResourceSFX(nIndex, "LANTERN", {s_light = tSfx})
        end

        for equipType, tSFXList in pairs(tResourceSFX) do
            self:LoadResourceSFX(nIndex, equipType, tSFXList)
        end
        mdl:SetForceRealInterpolate(self.bForceRealInterpolate)
        self:PlayWeaponAnimation(self.m_nRoleType, self.m_aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE])
        local tRepresentID = self.m_aRepresentID
        if tRepresentID.bUseLiftedFace and tRepresentID.tFaceData then
            local tFaceData = tRepresentID.tFaceData
            self:SetFaceDefinition(tFaceData.tBone, self.m_nRoleType, tFaceData.tDecal, tFaceData.nDecorationID)
        end
        self:ShowMDL(mdl)
    end
end;

function ModelsView:IsRegisterEventHandler(nIndex)
    nIndex = nIndex or 0
    return self.reg_handler and self.reg_handler[nIndex]
end

function ModelsView:RegisterEventHandler(nIndex)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "MDL")
    if not mdl then return end

    self.reg_handler = self.reg_handler or {}
    self.reg_handler[nIndex] = true

    mdl:RegisterEventHandler(nIndex)
end

function ModelsView:UnRegisterEventHandler(nIndex)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "MDL")
    if not mdl then return end

    self.reg_handler = self.reg_handler or {}
    self.reg_handler[nIndex] = nil

    mdl:UnregisterEventHandler(nIndex)
end

function ModelsView:UnloadSocket(nIndex, equipType)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, equipType)
    if not mdl then
        return
    end

    self:UnloadModelSFX(nIndex, equipType)
    self:UnloadResourceSFX(nIndex, equipType)
    mdl:UnbindFromOther()
    mdl:Release()

    mdl = nil
    self:SetModel(nIndex, equipType, nil)
end

function ModelsView:UnloadPart(nIndex, equipType)
    nIndex = nIndex or 0
    local mdl = self:GetModel(nIndex, "MDL")
    local equipMdl = self:GetModel(nIndex, equipType)
    if not mdl or not equipMdl then return end

    self:UnloadModelSFX(nIndex, equipType)
    self:UnloadResourceSFX(nIndex, equipType)
    mdl:Detach(model)
    equipMdl:Release()
    equipMdl = nil
    self:SetModel(nIndex, equipType, nil)
end

function ModelsView:HideMDL(mdl)
    if self.m_scene then
        if self.m_canselect  then
            self.m_scene:RemoveRenderEntity(mdl, self.m_canselect)
        else
            self.m_scene:RemoveRenderEntity(mdl)
        end
    end
end

function ModelsView:ShowMDL(mdl)
    if self.m_canselect then
        self.m_scene:AddRenderEntity(mdl, false, self.m_canselect)
    else
        self.m_scene:AddRenderEntity(mdl)
    end
end

function ModelsView:UnloadAllModel()
    if not self.m_modelRole then
        return
    end

    playing_delete(self)

    for nIndex,modelInfo in pairs(self.m_modelRole) do
        local mdl = modelInfo["MDL"]
        if mdl then
            self:HideMDL(mdl)
            mdl:Release()
	        modelInfo["MDL"] = nil
            self.m_modelRole[nIndex] = nil
        end
    end
end

function ModelsView:UnloadModel(nIndex, exchanged)
    nIndex = nIndex or 0
    if not self.m_modelRole or not self.m_modelRole[nIndex] then
        return
    end

    local modelInfo = self.m_modelRole[nIndex]

    local mdl = modelInfo["MDL"]
    if not mdl then
        return
    end

    if modelInfo["LANTERN"] then --魂灯的灯笼要先卸载
        self:UnloadSocket("LANTERN")
    end

    for equipType, model in pairs(modelInfo) do
        if model and self.m_aEquipRes[equipType] and self.m_aEquipRes[equipType]["Socket"] then
            self:UnloadSocket(nIndex, equipType)
        end
    end

    for equipType, model in pairs(modelInfo) do
        if model and self.m_aEquipRes[equipType] and not self.m_aEquipRes[equipType]["Socket"] and equipType ~= "MDL" then
            self:UnloadPart(nIndex, equipType)
        end
    end

    if not exchanged then
        self:HideMDL(mdl)
        mdl:Release()
	    modelInfo["MDL"] = nil
    end


    self.m_ResourceSFX[nIndex] = nil
    self.m_modelRoleSFX[nIndex] = nil
    self.m_modelRole[nIndex] = nil
end

function ModelsView:ClearAnis()
    if not self.aAnis then
        return
    end

    local len = #self.aAnis
    for i=1, len, 1 do
        local a = self.aAnis[ 1 ]
        if a.begin_func then
            a.begin_func(self)
        end

        if a.end_func then
            a.end_func(self)
        end
        table.remove(self.aAnis, 1)
    end
end

function ModelsView:PlayAnimation(nIndex, szAniName, szLoopType, fTweenTime)
    nIndex = nIndex or 0
    local mdl = self:GetModel(nIndex, "MDL")
    if not mdl then return end

    if not szAniName or not self.m_aAnimationRes[szAniName].Ani then
        return
    end

    self:ClearAnis()
    self.aAnis = self.aAnis or  {}
    table.insert(self.aAnis, {id=szAniName, type=szLoopType, tweentime=fTweenTime, usename=true})
    playing_add(self, nIndex)

    self:PlayAni(mdl, self.aAnis[1] )
end

function ModelsView:PlayRoleAnimation(nIndex, szLoopType, szAniPath)
    nIndex = nIndex or 0
    local mdl = self:GetModel(nIndex, "MDL")
    if not mdl then return end

    self:ClearAnis()

    self.aAnis = self.aAnis or  {}
    table.insert(self.aAnis, {id = szAniPath, type = szLoopType, usepath=true})
    playing_add(self, nIndex)

    self:PlayAni(mdl, self.aAnis[1] )
end

function ModelsView:PlayAni(mdl, ani)
    if not mdl then
        return
    end

    if ani.begin_func then
        ani.begin_func(self, ani.id)
        ani.begin_func = nil
    end

    local szAnimationName
    if ani.usename then
        szAnimationName = self.m_aAnimationRes[ani.id].Ani
    elseif ani.usepath then
        szAnimationName =  ani.id
    else
        szAnimationName = Player_GetAnimationResource(self.m_nRoleType, ani.id)
    end

    if szAnimationName then
        ani.type = ani.type or "once"
        if ani.tweentime then
            mdl:PlayAnimation(ani.type, szAnimationName, 1, 0, ani.tweentime)
        else
            mdl:PlayAnimation(ani.type, szAnimationName, 1, 0, 0)
        end
    end

    if not szAnimationName or ani.type == "loop" then
        self:OnAniFinished(mdl, ani.id)
    end
end

function ModelsView:OnAniFinished(nIndex, mdl, ani_id)
    nIndex = nIndex or 0

    if not self.aAnis or mdl ~= self:GetModel(nIndex, "MDL") then
        return
    end
    local len = #self.aAnis
    if len == 0 then
        return
    end
    local a = self.aAnis[ 1 ]
    table.remove(self.aAnis, 1)

    if len - 1 > 0 then
        if a.end_func then
            a.end_func(self, a.id)
        end
        self:PlayAni( mdl, self.aAnis[ 1 ])
        return
    end

    playing_delete( self )

    if a.end_func then
        a.end_func(self, a.id)
    end
end

function ModelsView:PlayAniID(nIndex, id, type, tweentime, replace)
    nIndex = nIndex or 0
    local mdl = self:GetModel(nIndex, "MDL")
    if not mdl then
        return
    end

    if replace or replace == nil then
        self:ClearAnis()
    end

    self.aAnis = self.aAnis or  {}
    table.insert(self.aAnis, {id=id, type=type, tweentime=tweentime})
    playing_add(self, nIndex)
    self:PlayAni(mdl, self.aAnis[1] )
end

function ModelsView:PlayAniSequence(nIndex, aIDs, replace)
    nIndex = nIndex or 0
    local mdl = self:GetModel(nIndex, "MDL")
    if not mdl then
        return
    end

    self.aAnis = self.aAnis or  {}
    if replace or replace == nil then
        self:ClearAnis()
    end

    for _, id in pairs(aIDs) do
        table.insert(self.aAnis, id)
    end

    playing_add(self, nIndex)

    self:PlayAni(mdl, self.aAnis[ 1 ])
end

function ModelsView:UpdateFacePendant()
    if self.m_aRepresentID.bHideFacePendent then
        self.m_aRepresentID[EQUIPMENT_REPRESENT.FACE_EXTEND] = 0
    end
end

function ModelsView:UpdatePetRepresentID(nIndex, dwModelID, nRoleType, bNotLoad, bIngoreReplace)
    nIndex = nIndex or 0
    self.m_aEquipRes = NPC_GetEquipResource(dwModelID)
    local aEquipRes = self.m_aEquipRes

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

    local mdl = self:GetModel(nIndex, "MDL")
    if mdl == nil then
        if aEquipRes["Main"] and aEquipRes["Main"]["MDL"] then

            local modelScale = aEquipRes["Main"]["ModelScale"]
            local socketScale = aEquipRes["Main"]["SocketScale"]
            local nColorChannelTable = aEquipRes["Main"]["ColorChannelTable"]
            local nColorChannel      = aEquipRes["Main"]["ColorChannel"]

            local mdl = self.m_modelMgr:NewModel(aEquipRes["Main"]["MDL"])
            mdl:SetScaling(modelScale, modelScale, modelScale)
            mdl:SetTranslation(0, 0, 0)
            mdl:SetDetail(nColorChannelTable, nColorChannel)

            if self.bLight then
                self.m_scene:AddRenderEntity(mdl, true)
            else
                self.m_scene:AddRenderEntity(mdl)
            end
            self.bModelInScene = true
            -- load socket
            for equipType, equipRes in pairs(aEquipRes) do
                local socketName = aEquipRes[equipType]["Socket"]
                local meshFile = aEquipRes[equipType]["Mesh"]

                if socketName and meshFile then
                    local model = self.m_modelMgr:NewModel(meshFile, false, false, false, false, 0, mdl)
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
            self:SetModel(nIndex, "MDL", mdl)
            if self.reg_handler then
                self:RegisterEventHandler(nIndex)
            end
        end
    end

	if aEquipRes["Main"] and aEquipRes["Main"]["MDL"] then

		local modelScale = aEquipRes["Main"]["ModelScale"]
		local socketScale = aEquipRes["Main"]["SocketScale"]
		local nColorChannelTable = aEquipRes["Main"]["ColorChannelTable"]
		local nColorChannel      = aEquipRes["Main"]["ColorChannel"]

		local mdl = self.m_modelMgr:NewModel(aEquipRes["Main"]["MDL"])
		mdl:SetScaling(modelScale, modelScale, modelScale)
		mdl:SetTranslation(0, 0, 0)
		mdl:SetDetail(nColorChannelTable, nColorChannel)

		if self.bLight then
			self.m_scene:AddRenderEntity(mdl, true)
		else
			self.m_scene:AddRenderEntity(mdl)
		end
		self.bModelInScene = true
		-- load socket
		for equipType, equipRes in pairs(aEquipRes) do
			local socketName = aEquipRes[equipType]["Socket"]
			local meshFile = aEquipRes[equipType]["Mesh"]

			if socketName and meshFile then
				local model = self.m_modelMgr:NewModel(meshFile, false, false, false, false, 0, mdl)
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
        self:SetModel(nIndex, "MDL", mdl)
        if self.reg_handler then
            self:RegisterEventHandler(nIndex)
        end
	end
    self.m_modelRoleSFX = self.m_modelRoleSFX or {}
    self.m_ResourceSFX = self.m_ResourceSFX or {}
end

function ModelsView:UpdateRepresentID(nIndex, aRepresentID, nRoleType, dwSchoolID, bNotLoad, bIngoreReplace)
    nIndex = nIndex or 0

    local bModified = false

    if not self.m_aRepresentID or not self.m_modelRole or not self.m_modelRole[nIndex] then
        self.m_aRepresentID = clone(aRepresentID)
        self.m_nRoleType = nRoleType
        bModified = true
    else
        for i, v in pairs(aRepresentID) do
            if v ~= self.m_aRepresentID[i] then
                self.m_aRepresentID[i] = v
                bModified = true
            end
        end
        if self.m_nRoleType ~= nRoleType and not bNotLoad then
            bModified = true
        end
    end

    self:UpdateFacePendant()

    if bModified and not bNotLoad then
        local bReplace = not bIngoreReplace
        local aNewEquipRes = self:GetModuleRes(nRoleType, dwSchoolID, self.m_aRepresentID, bReplace)
        self:UpdateRoleModel(nIndex, aNewEquipRes, nRoleType)

        self:LoadPlayerAnimation(nRoleType)
    end

    return bModified
end

function ModelsView:LoadRes(dwPlayerID, tRepresentID)
    local hPlayer = GetPlayer(dwPlayerID)
    local nRoleType = Player_GetRoleType(hPlayer)
    local dwSchoolID = hPlayer.dwSchoolID
    local tRes = clone(tRepresentID)
    self:UpdateFaceDecoration(hPlayer, tRes)
    self:UpdateRepresentID(tRes, nRoleType, dwSchoolID)
end

local function CheckReplace(tRepresentID, tKeyList)
    for _, tKey in ipairs(tKeyList) do
        if tRepresentID[tKey[1]] ~= tKey[2] then
            return false
        end
    end

    return true
end

local function Replace(tRepresentID, tReplaceList)
    for _, tReplace in ipairs(tReplaceList) do
        tRepresentID[tReplace[1]] = tReplace[2]
    end
end

function ModelsView:RepresentReplace(tRepresentID)
    local tViewReplace = Table_ViewReplace()
    for _, tLine in ipairs(tViewReplace) do
        local bReplace = CheckReplace(tRepresentID, tLine.tKey)
        if bReplace then
            Replace(tRepresentID, tLine.tReplace)
        end
    end
end

function ModelsView:GetModuleRes(nRoleType, dwSchoolID, tRepresentID, bReplace)
    if bReplace then
        self:RepresentReplace(tRepresentID, tRepresentID.bHideHair)
    end

    local bNewFace = false
    if tRepresentID.tFaceData then
        bNewFace = tRepresentID.tFaceData.bNewFace
    else
        bNewFace = tRepresentID.bNewFace
    end

    local tTransformID = Player_TransformEquipDefaultResource(
        nRoleType,
        dwSchoolID,
        tRepresentID.nHatStyle,
        tRepresentID
    )
    if tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] == 0 then
        tTransformID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
    end
    if tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] == 0 then
        tTransformID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end
    local tRes = Player_GetEquipResource(
        nRoleType,
        EQUIPMENT_REPRESENT.TOTAL,
        tTransformID,
        tRepresentID.bUseLiftedFace,
        false,
        tRepresentID.nHatStyle,
        bNewFace
    )

    -- if tRepresentID.bUseLiftedFace then
    -- 	local tMesh = Table_GetFaceMeshInfo(nRoleType)
    -- 	if tMesh then
    -- 		tRes["FACE"]["Mesh"] = tMesh.szMeshPath
    -- 		tRes["FACE"]["Mtl"] = tMesh.szMtlPath
    -- 	end
    -- end

    return tRes
end

function ModelsView:LoadModuleRes(nRoleType, dwSchoolID, tRepresentID)
    self:UpdateRepresentID(tRepresentID, nRoleType, dwSchoolID, false, true)
end

function ModelsView:UpdateFaceData(hPlayer)
    local bModified = false
    local aRepresentID = self.m_aRepresentID
    if not aRepresentID then
        return true
    end
    if hPlayer.bEquipLiftedFace and not IsRoleInFakeState(hPlayer) then
        aRepresentID.bUseLiftedFace = true
        aRepresentID.tFaceData = hPlayer.GetEquipLiftedFaceData()
        self:UpdateFaceDecoration(hPlayer, aRepresentID)
        bModified = true
    elseif aRepresentID.bUseLiftedFace then
        aRepresentID.bUseLiftedFace = false
        aRepresentID.tFaceData = nil
        bModified = true
    end

    return bModified
end

function ModelsView:LoadPlayerRes(dwPlayerID, bPortraitOnly)
    -- load model and mesh
    local player=GetPlayer(dwPlayerID)
    if not player then
        return
    end

    local nRoleType = Player_GetRoleType(player)
    local dwSchoolID = player.dwSchoolID
    local aRepresentID = player.GetRepresentID()
    aRepresentID.nHatStyle = Role_GetHatStyle(player.bHideHair)
    aRepresentID.bHideFacePendent = player.bHideFacePendent
    local bModified = self:UpdateRepresentID(aRepresentID, nRoleType, dwSchoolID, true)
    local bModifiedFace = self:UpdateFaceData(player)

    if bModified or bModifiedFace then
        -- self.m_aEquipRes = Player_GetEquipResource(
        --           	player.nRoleType,
        --		  	EQUIPMENT_REPRESENT.TOTAL,
        --          	aRepresentID
        --       )

        self.m_aEquipRes = self:GetModuleRes(nRoleType, dwSchoolID, self.m_aRepresentID, false)

        local res = self.m_aEquipRes
        if bPortraitOnly then
            self:ClearRes(res)
        end

        -- load animation
        self:LoadPlayerAnimation(nRoleType)
        local tRepresentID = self.m_aRepresentID
        -- if tRepresentID.bUseLiftedFace then
        -- 	local tMesh = Table_GetFaceMeshInfo(self.m_nRoleType)
        -- 	if tMesh then
        -- 		self.m_aEquipRes["FACE"]["Mesh"] = tMesh.szMeshPath
        -- 		self.m_aEquipRes["FACE"]["Mtl"] = tMesh.szMtlPath
        -- 	end
        -- end
    end
end;

function ModelsView:LoadPlayerAnimation(nRoleType)
    for szAniName, v in pairs(self.m_aAnimationRes) do
        self.m_aAnimationRes[szAniName] = {
            Ani = nil, AniSound = nil, AniPlayType = "loop", AniPlaySpeed = 1, AniSoundRange = 0,
            SFX = nil, SFXBone = nil, SFXPlayType = "loop", SFXPlaySpeed = 1, SFXScale = 1
        }

        local dwAnimationID
        local nWeaponType = self.m_aEquipRes["nWeaponType"]
        if nWeaponType then
            local t = GetRoleAnimation(nWeaponType)
            if t then
                dwAnimationID = t[szAniName]
            end
        end

        if dwAnimationID == nil then
            dwAnimationID = self.m_aRoleAnimation[szAniName]
        end

        local aAniRes = self.m_aAnimationRes[szAniName]

        aAniRes["Ani"], aAniRes["AniSound"], aAniRes["AniPlayType"], aAniRes["AniPlaySpeed"]
            = Player_GetAnimationResource(nRoleType, dwAnimationID)
    end
end

function ModelsView:LoadMemberRes(helm, face, nRoleType, bPortraitOnly)
    -- load model and mesh
    local aRepresentID = {}
    local i = 0
    for i = 0, EQUIPMENT_REPRESENT.TOTAL - 1 do
        aRepresentID[i] = 0
    end
    aRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE] = face
    aRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = helm

    local bModified = self:UpdateRepresentID(aRepresentID, nRoleType, true)
    if bModified then
        self.m_aEquipRes = self:GetModuleRes(nRoleType, aRepresentID, false)

        local res = self.m_aEquipRes
        if bPortraitOnly then
            self:ClearRes(res)
        end

        -- load animation
        for szAniName, v in pairs(self.m_aAnimationRes) do
            self.m_aAnimationRes[szAniName] = {
                Ani = nil, AniSound = nil, AniPlayType = "loop", AniPlaySpeed = 1, AniSoundRange = 0,
                SFX = nil, SFXBone = nil, SFXPlayType = "loop", SFXPlaySpeed = 1, SFXScale = 1
            }

            local aAniRes = self.m_aAnimationRes[szAniName]

            aAniRes["Ani"], aAniRes["AniSound"], aAniRes["AniPlayType"], aAniRes["AniPlaySpeed"], aAniRes["AniSoundRange"],
            aAniRes["SFX"], aAniRes["SFXBone"], aAniRes["SFXPlayType"], aAniRes["SFXPlaySpeed"], aAniRes["SFXScale"]
                = Player_GetAnimationResource(nRoleType, self.m_aRoleAnimation[szAniName])
        end
    end
end;

function ModelsView:PlayWeaponAnimation(nIndex, nRoleType, nWeaponID)
    nIndex = nIndex or 0
    local fnAction = function(szWeaponPos)

        local szSocketName = self.m_aEquipRes[szWeaponPos]["Socket"]
        local mesh = self.m_aEquipRes[szWeaponPos]["Mesh"]

        local model = self:GetModel(nIndex, szWeaponPos)
        if not model then
            return
        end

        if not mesh or string.sub(mesh, string.len(mesh) - 3) ~= ".mdl" then
            return
        end

        if not nWeaponID or nWeaponID == 0 then
            return
        end

        if not szSocketName or szSocketName == "" then
            return
        end

        local WeaponAni = Weapon_GetAnimation(nRoleType, nWeaponID, szSocketName)
        model:PlayAnimation("loop", WeaponAni, 1.0, 0)
    end
    fnAction("RL_WEAPON_RH")
    fnAction("RL_WEAPON_LH")
end;


function ModelsView:LoadFaceDefinitionINI(nIndex, szFileName)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "FACE")
    if not mdl then
        return
    end

    mdl:LoadFaceDefinitionINI(szFileName)
end

function ModelsView:GetFaceModel(nIndex)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "FACE")
    if not mdl then
        return
    end

    return mdl
end

function ModelsView:SetFaceDefinition(nIndex, tBoneParams, nRoleType, tDecalDefinition, nDecorationID)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "FACE")
    if not mdl then
        return
    end

    mdl:SetFaceDefinition(tBoneParams, nRoleType, tDecalDefinition, nDecorationID)
end

function ModelsView:SetFaceBoneParams(nIndex, tBoneParams)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "FACE")
    if not mdl then
        return
    end

    mdl:SetFaceBoneParams(tBoneParams)
end

function ModelsView:SetFaceDecals(nIndex, nRoleType, tDecalDefinition)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "FACE")
    if not mdl then
        return
    end
    mdl:SetFaceDecals(nRoleType, tDecalDefinition)
end

function ModelsView:SetTranslation(nIndex, x, y, z)

    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "MDL")
    if mdl then
        self._x = self._x or {}
        self._y = self._y or {}
        self._z = self._z or {}

        self._x[nIndex], self._y[nIndex], self._z[nIndex] = x, y, z
        mdl:SetTranslation(x, y, z)
    end
end

function ModelsView:GetTranslation(nIndex)
    nIndex = nIndex or 0

    local x, y, z = 0

    if self._x and self._x[nIndex] then
        x = self._x[nIndex]
    end

    if self._y and self._y[nIndex] then
        y = self._y[nIndex]
    end

    if self._z and self._z[nIndex] then
        z = self._z[nIndex]
    end

    return x, y, z
end

function ModelsView:SetYaw(nIndex, yaw)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "MDL")
    if mdl then
        self._yaw = self._yaw or {}
        self._yaw[nIndex] = yaw
        mdl:SetYaw(yaw)
    end
end

function ModelsView:GetYaw(nIndex)
    nIndex = nIndex or 0

    if not self._yaw and not self._yaw[nIndex] then
        return 0
    end

    return self._yaw[nIndex]
end

function ModelsView:Show(nIndex, bShow)
    nIndex = nIndex or 0

    local mdl = self:GetModel(nIndex, "MDL")
    if mdl then
        local fAlpha = 0
        if bShow then
            fAlpha = 1
        end
        mdl:SetAlpha(fAlpha)
    end
end

function ModelsView:GetModel(nIndex, szTag)
    nIndex = nIndex or 0

    if not self.m_modelRole or not self.m_modelRole[nIndex] or not self.m_modelRole[nIndex][szTag] then
        return
    end

    return self.m_modelRole[nIndex][szTag]
end

function ModelsView:SetModel(nIndex, szTag, model)
    nIndex = nIndex or 0

    self.m_modelRole = self.m_modelRole or {}
    self.m_modelRole[nIndex] = self.m_modelRole[nIndex] or {}
    self.m_modelRole[nIndex][szTag] = model
end

function ModelsView:UpdateFaceDecoration(hPlayer, tRepresentID)
    local bShowFlag = hPlayer.GetFaceDecorationShowFlag()
    local bHide = not bShowFlag
    if bHide and tRepresentID.tFaceData then
        tRepresentID.tFaceData.nDecorationID = 0
    end
end

--把角色模型放到某个制定的图片上的功能（还没用过）
--例：DrawSpecialPlayerModelImage(Helper_GetUIObject("Normal/MentorPanel|Image_GBg4"), 183, "data\\rcdata\\textures\\Wanhua.dds","StandardNew", "loop")
function DrawSpecialPlayerModelImage(hImage, dwPlayerID, szBgPath, szAniName, szLoopType)
    local player 			= GetPlayer(dwPlayerID)
    local modelView		 	= ModelsView.new()
    local m_aCameraInfo 	= {
        [0] = { -30, 160, -25, 0, 150, 0 }, --rtInvalid = 0,
        [1] = { 0, 70, -240, 0, 100, 150 }, --rtStandardMale,	 // 标准男
        [2] = { 0, 78, -235, 0, 100, 150 }, --rtStandardFemale,   // 标准女
        [3] = { -30, 160, -25, 0, 150, 0 }, --rtStrongMale,	   // 魁梧男
        [4] = { -30, 160, -25, 0, 150, 0 }, --rtSexyFemale,	   // 性感女
        [5] = { 0, 90, -215, 0, 80, 150 },  --rtLittleBoy,	   // 小男孩
        [6] = { 0, 90, -215, 0, 80, 150 }  --rtLittleGirl,	   // 小孩女
    };

    modelView:init()

    local aCameraParams = m_aCameraInfo[player.nRoleType]
    modelView:SetCamera({aCameraParams[1], aCameraParams[2], aCameraParams[3], aCameraParams[4], aCameraParams[5], aCameraParams[6], math.pi / 4, 350 / 330, nil, nil, true})

    modelView:UnloadModel()
    modelView:LoadPlayerRes(dwPlayerID, false)
    modelView:LoadModel()
    modelView:PlayAnimation(szAniName, szLoopType)
    local m_scene = modelView.m_scene
    hImage:FromSpecialMiniScene(m_scene, szBgPath, dwPlayerID)

    modelView:release()
end

--完成返回的事件
--RegisterEvent("SPECIAL_MINI_SCREEN_FINISHED", function() Output("SPECIAL_MINI_SCREEN_FINISHED", arg0, arg1) end)

---------------- 以下为新增代码 ----------------
function ModelsView:ClearRes(res)
    local aKey1List = {
        "WAIST", "PANTS", "BANGLE", "MELEE_WEAPON_LH", "MELEE_WEAPON_RH",
        "BACK_EXTEND", "BACK_EXTEND", "WAIST_EXTEND", "LSHOULDER", "RSHOULDER", "CLOAK"
    }

    local aKey2List = {
        "Socket", "Mesh", "Mtl", "MeshScale", "SFX1", "SFX2"
    }

    for _, key1 in pairs(aKey1List) do
        for _, key2 in pairs(aKey2List) do
            if res[key1] and res[key1][key2] then
                res[key1][key2] = nil
            end
        end
    end

    --以下为原代码
    -- res["WAIST"]["Socket"], res["WAIST"]["Mesh"], res["WAIST"]["Mtl"], res["WAIST"]["MeshScale"], res["WAIST"]["SFX1"], res["WAIST"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["PANTS"]["Socket"], res["PANTS"]["Mesh"], res["PANTS"]["Mtl"], res["PANTS"]["MeshScale"], res["PANTS"]["SFX1"], res["PANTS"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["BANGLE"]["Socket"], res["BANGLE"]["Mesh"], res["BANGLE"]["Mtl"], res["BANGLE"]["MeshScale"], res["BANGLE"]["SFX1"], res["BANGLE"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["MELEE_WEAPON_LH"]["Socket"], res["MELEE_WEAPON_LH"]["Mesh"], res["MELEE_WEAPON_LH"]["Mtl"], res["MELEE_WEAPON_LH"]["MeshScale"], res["MELEE_WEAPON_LH"]["SFX1"], res["MELEE_WEAPON_LH"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["MELEE_WEAPON_RH"]["Socket"], res["MELEE_WEAPON_RH"]["Mesh"], res["MELEE_WEAPON_RH"]["Mtl"], res["MELEE_WEAPON_RH"]["MeshScale"], res["MELEE_WEAPON_RH"]["SFX1"], res["MELEE_WEAPON_RH"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["BACK_EXTEND"]["Socket"], res["BACK_EXTEND"]["Mesh"], res["BACK_EXTEND"]["Mtl"], res["BACK_EXTEND"]["MeshScale"], res["BACK_EXTEND"]["SFX1"], res["BACK_EXTEND"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["WAIST_EXTEND"]["Socket"], res["WAIST_EXTEND"]["Mesh"], res["WAIST_EXTEND"]["Mtl"], res["WAIST_EXTEND"]["MeshScale"], res["WAIST_EXTEND"]["SFX1"], res["WAIST_EXTEND"]["SFX2"] = nil, nil, nil, nil, nil, nil

    -- res["LSHOULDER"]["Socket"], res["LSHOULDER"]["Mesh"], res["LSHOULDER"]["Mtl"], res["LSHOULDER"]["MeshScale"], res["LSHOULDER"]["SFX1"], res["LSHOULDER"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["RSHOULDER"]["Socket"], res["RSHOULDER"]["Mesh"], res["RSHOULDER"]["Mtl"], res["RSHOULDER"]["MeshScale"], res["RSHOULDER"]["SFX1"], res["RSHOULDER"]["SFX2"] = nil, nil, nil, nil, nil, nil
    -- res["CLOAK"]["Socket"], 	res["CLOAK"]["Mesh"], 	  res["CLOAK"]["Mtl"], res["CLOAK"]["MeshScale"], res["CLOAK"]["SFX1"], res["CLOAK"]["SFX2"] = nil, nil, nil, nil, nil, nil
end


