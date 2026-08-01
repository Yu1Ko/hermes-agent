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

-- PlayerModelView = class()
PlayerModelView = class("PlayerModelView")

local _tInitSFX = {
    SfxPath     = "",
    Scale       = 1.0,
    Position    = {x = 0, y = 0, z = 0,},
    Rotation    = {x = 0, y = 0, z = 0, w = 1}, -- 标准四元素的w==1
}

local _play_ref
local _tPlaying = {}
local _play_count = 0
local function SetBreatheCallSubsetDissolveFalse(script)
    for i = 1, 8 do
        if script.tbDissolveTimer[i] then
            for j = 1, #script.tbDissolveTimer[i] do
                Timer.DelTimer(script, script.tbDissolveTimer[i][j])
            end
        end
    end
end

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
        _play_ref = Event.Reg(PlayerModelView, "KG3D_PLAY_ANIMAION_FINISHED", play_onfinished)
    end
end

local function playing_delete(modelview)
    if not modelview:IsRegisterEventHandler() then
        return
    end

    local id = KG3DEngine.ModelToID( modelview:Mdl() )
    if _tPlaying[id] then
        _tPlaying[id] = nil
        _play_count = _play_count - 1
    end

    if _play_count == 0 and _play_ref then
        -- UnRegisterEvent("KG3D_PLAY_ANIMAION_FINISHED", _play_ref)
        Event.UnReg(PlayerModelView, "KG3D_PLAY_ANIMAION_FINISHED")

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

--下面这几个暂时没用到，先注释掉
-- function MaskModelImage(image)
--     local dwImageID = image:GetImageID()
--     local dwMaskImageID = LoadImage("ui\\Image\\Common\\PortraitMask.tga")
--     if dwMaskImageID then
--         MaskImage(dwImageID, dwMaskImageID)
--         UnloadImage(dwMaskImageID)
--     end
-- end;

-- function DrawPlayerModelImage(dwPlayerID, aCameraParams, image, bPortraitOnly)
--     -- local modelView = PlayerModelView.new()
--     local modelView = PlayerModelView.CreateInstance(PlayerModelView)

--     modelView:init()
--     modelView:SetCamera(aCameraParams)

--     modelView:UnloadModel()
--     modelView:LoadPlayerRes(dwPlayerID, bPortraitOnly)
--     modelView:LoadModel()
--     modelView:PlayAnimation("Idle", "loop")

--     image:FromScene(modelView.m_scene)

--     MaskModelImage(image)

--     image:ToManagedImage()

--     modelView:release()
-- end;

-- function DrawMemberModelImage(helm, face, nRoleType, aCameraParams, image, bPortraitOnly)
--     -- local modelView = PlayerModelView.new()
--     local modelView = PlayerModelView.CreateInstance(PlayerModelView)

--     modelView:init()
--     modelView:SetCamera(aCameraParams)

--     modelView:UnloadModel()
--     modelView:LoadMemberRes(helm, face, nRoleType, bPortraitOnly)
--     modelView:LoadModel()
--     modelView:PlayAnimation("Idle", "loop")

--     image:FromScene(modelView.m_scene)

--     MaskModelImage(image)
--     image:ToManagedImage()

--     modelView:release()
-- end;

--这个在LoginScene里有了，不重复写了
-- function FormatRepresentData(tRoleEquipID)
--     --tRoleEquipID["RoleType"],
--     local aRepresent = {
--         --tRoleEquipID["FaceStyle"],
--         tRoleEquipID["HairStyle"],
--         tRoleEquipID["HelmStyle"],       tRoleEquipID["HelmColor"],       tRoleEquipID["HelmEnchant"],
--         tRoleEquipID["ChestStyle"],      tRoleEquipID["ChestColor"],      tRoleEquipID["ChestEnchant"],
--         tRoleEquipID["WaistStyle"],      tRoleEquipID["WaistColor"],      tRoleEquipID["WaistEnchant"],
--         tRoleEquipID["BangleStyle"],     tRoleEquipID["BangleColor"],     tRoleEquipID["BangleEnchant"],
--         tRoleEquipID["BootsStyle"],      tRoleEquipID["BootsColor"],
--         tRoleEquipID["WeaponStyle"],     tRoleEquipID["WeaponColor"], tRoleEquipID["WeaponEnchant1"],  tRoleEquipID["WeaponEnchant2"],
--         tRoleEquipID["BigSwordStyle"],   tRoleEquipID["BigSwordColor"],  tRoleEquipID["BigSwordEnchant1"],  tRoleEquipID["BigSwordEnchant2"],
--         tRoleEquipID["BackExtend"],      tRoleEquipID["WaistExtend"],
--         tRoleEquipID["HorseStyle"],      tRoleEquipID["HorseAdornment1"], tRoleEquipID["HorseAdornment2"],
--         tRoleEquipID["HorseAdornment3"], tRoleEquipID["HorseAdornment4"], tRoleEquipID["FaceExtend"],
--         tRoleEquipID["LShoulder"],		 tRoleEquipID["RShoulder"],  tRoleEquipID["Cloak"],
--         tRoleEquipID["CloakColor1"],     tRoleEquipID["CloakColor2"],  tRoleEquipID["CloakColor3"], tRoleEquipID["PantsStyle"], tRoleEquipID["PantsColor"],
--         tRoleEquipID["Reserved"]
--     }
--     aRepresent[0] = tRoleEquipID["FaceStyle"]
--     aRepresent.bUseLiftedFace = tRoleEquipID.bUseLiftedFace
--     aRepresent.tFaceData = tRoleEquipID.tFaceData
--     for i = 0 , EQUIPMENT_REPRESENT.TOTAL - 1, 1 do
--         if not aRepresent[i] then
--             aRepresent[i] = 0
--         end
--     end
--     return aRepresent
-- end

local m_tRoleAnimations
function GetRoleAnimation(nWeaponType)
    if g_tRoleAnimations then
        return g_tRoleAnimations[nWeaponType]
    end
end

local function IsEquipType(equipType)
    if equipType ~= "MDL" and equipType ~= "MDLScale" and equipType ~= "nWeaponType" and equipType ~= "nHeadformID" then
        return true
    end
end

local function ModelSfxBind(modelsfx, mdl, aNewEquipRes, equipType, szSocketName)
    local sub = string.lower(string.sub(aNewEquipRes[equipType][szSocketName], 1, 2))
    if sub == "s_" then
        modelsfx:BindToSocket(mdl, aNewEquipRes[equipType][szSocketName])
    else
        modelsfx:BindToBone(mdl, aNewEquipRes[equipType][szSocketName])
    end
end

function PlayerModelView:ctor()
    self.m_modelMgr = nil;
    self.m_modelRole = nil;
    self.m_modelRoleSFX = nil;
    self.m_WeaponSocketDynamic = nil
    self.m_ResourceSFX = nil
    self.m_aEquipRes = {};
    self.m_aAnimationRes = { Idle = {}, Standard = {}, StandardNew = {}};
    self.m_aRoleAnimation = { Idle = 100 , Standard = 30, StandardNew = 60211};
    self.m_aRepresentID = nil;
    self.m_nRoleType = nil;
    self.m_dwSchoolID = nil
    self.aAnis = nil
    self.WeaponVisible = nil
    self.bAdjustByAnimation = false
    self.bForceRealInterpolate = false
    self.bMainPlayer = true
    self.m_aOriginalRepresentID = nil
    self.tbDissolveTimer = {}
    self.m_modelSocketDynamicEffect = nil;
    LastModelView = self
end;

function PlayerModelView:release()
    self:UnloadPuppet()
    self:Free3D()
end;

function PlayerModelView:init(szEnvPath, bExScene, scene, canselect, szExSceneFile, bModLod, bAPEX)
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

function PlayerModelView:InitBy(tParam)
    self:Init3D(tParam)
end

function PlayerModelView:SetSceneName(szName)
    if self.m_scene then
        self.m_scene:SetName(szName)
    end
end

function PlayerModelView:SetAdjustByAnimation(bAdjustByAnimation)
    self.bAdjustByAnimation = bAdjustByAnimation
end

function PlayerModelView:Init3D(tParam)
    --	Log("Init3D\n")
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

    self.bAPEX = tParam.bAPEX or false

    self.bExScene = tParam.bExScene
    self.m_modelMgr = KG3DEngine.GetModelMgr()

    self.m_canselect = tParam.canselect

    self.nModelType = tParam.nModelType

    if self.bMgrScene then
        self:SetCamera({ 0, 150, -200, 0, 50, 150 })
    end
end;

function PlayerModelView:Free3D()
    --	Log("Free3D()\n")
    self:UnloadModelEffect()
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
    self.reg_handler = nil
    self.aAnis = nil

    LastModelView = nil
end;

function PlayerModelView:SwitchScene(tParam)
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

function PlayerModelView:Mdl()
    return self.m_modelRole["MDL"];
end

function PlayerModelView:RoleType()
    return self.m_nRoleType
end

function PlayerModelView:SetCamera(args)
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

function PlayerModelView:GetCameraPos()
    return self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ
end

function PlayerModelView:SetCameraPos(x, y, z)
    self.nCameraPosX, self.nCameraPosY, self.nCameraPosZ = x, y, z
	self.m_scene:SetCameraPosition(x, y, z)
end

function PlayerModelView:GetCameraLookPos()
    return self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ
end

function PlayerModelView:SetCameraLookPos(x, y, z)
    self.nCameraLookPosX, self.nCameraLookPosY, self.nCameraLookPosZ = x, y, z
	self.m_scene:SetCameraLookAtPosition(x, y, z)
end

function PlayerModelView:GetCameraPerspective()
    return self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar
end

function PlayerModelView:SetCameraPerspective(fovY, aspect, near, far)
    self.nCameraFovY, self.nCameraAspect, self.nCameraNear, self.nCameraFar = fovY, aspect, near, far
	self.m_scene:SetCameraPerspective(fovY, aspect, near, far)
end

function PlayerModelView:GetCameraOrthogonal()
    return self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar
end

function PlayerModelView:SetCameraOrthogonal(w, h, near, far)
    self.nCameraWidth, self.nCameraHeight, self.nCameraNear, self.nCameraFar = w, h, near, far
	self.m_scene:SetCameraOrthogonal(w, h, near, far)
end

function PlayerModelView:LoadModelSFXByName(model, equipType, aNewEquipRes, szName, szSocketName, bSocket, fSfxScale)
    if aNewEquipRes[equipType][szName] then
        local mdl = self.m_modelRole["MDL"]
        local modelsfx = self.m_modelMgr:NewModel(aNewEquipRes[equipType][szName], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
        self.m_modelRoleSFX[equipType .. szName] = modelsfx
        if modelsfx then
            if aNewEquipRes[equipType][szSocketName] then
                if bSocket then
                    if equipType == "LANTERN" then
                        modelsfx:BindToSocket(model, aNewEquipRes[equipType][szSocketName])
                    elseif szSocketName and szSocketName ~= "" then
                        ModelSfxBind(modelsfx, model, aNewEquipRes, equipType, szSocketName)
                    else
                        modelsfx:BindToBone(model)
                    end
                else
                    ModelSfxBind(modelsfx, mdl, aNewEquipRes, equipType, szSocketName)
                end
                modelsfx:SetScaling(fSfxScale, fSfxScale, fSfxScale)
            else
                modelsfx:BindToBone(model)
            end
        end
    end
end

function PlayerModelView:LoadModelSFX(model, equipType, aNewEquipRes, bSocket)
    --Load SFX1
    local fSfx1Scale = aNewEquipRes[equipType]["SFX1Scale"]
    self:LoadModelSFXByName(model, equipType, aNewEquipRes, "SFX1", "SFX1Socket", bSocket, fSfx1Scale)

    --Load SFX2
    local fSfx2Scale = aNewEquipRes[equipType]["SFX2Scale"]
    self:LoadModelSFXByName(model, equipType, aNewEquipRes, "SFX2", "SFX2Socket", bSocket, fSfx2Scale)
end

function PlayerModelView:UnloadModelSFX(equipType)
    --Unload SFX2
    if self.m_modelRoleSFX[equipType.."SFX2"] then
        self.m_modelRoleSFX[equipType.."SFX2"]:UnbindFromOther()
        self.m_modelRoleSFX[equipType.."SFX2"]:Release()
        self.m_modelRoleSFX[equipType.."SFX2"] = nil
        --
    end
    --Unload SFX1
    if self.m_modelRoleSFX[equipType.."SFX1"] then
        self.m_modelRoleSFX[equipType.."SFX1"]:UnbindFromOther()
        self.m_modelRoleSFX[equipType.."SFX1"]:Release()
        self.m_modelRoleSFX[equipType.."SFX1"] = nil
    end
end

function PlayerModelView:UnloadAllModelSocketDynamicEffect()
    if not self.m_modelSocketDynamicEffect then
        return
    end
    for equipType, _ in pairs(self.m_modelSocketDynamicEffect) do
        self:UnloadModelSocketDynamicEffect(equipType)
    end
end

function PlayerModelView:UnloadModelSocketDynamicEffect(equipType)
    if not self.m_modelSocketDynamicEffect then
        return
    end
    if self.m_modelSocketDynamicEffect[equipType] then
        self.m_modelSocketDynamicEffect[equipType]:UnbindFromOther()
        self.m_modelSocketDynamicEffect[equipType]:Release()
        self.m_modelSocketDynamicEffect[equipType] = nil
    end
end

function PlayerModelView:UnloadWeaponSocketDynamic()
    if self.m_WeaponSocketDynamic then
        self.m_WeaponSocketDynamic:Release()
        self.m_WeaponSocketDynamic = nil
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

function PlayerModelView:BindSFX(equipType, szSocketName, tSFX, tModels)
    local mdl = self.m_modelRole["MDL"]
    local sfx = self.m_modelMgr:NewModel(tSFX["SfxPath"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
    local model = self.m_modelRole[equipType]
    if model then
        local UserData = {}
        UserData.szSocketName = szSocketName
        UserData.tSFX = tSFX
        UserData.tModels = tModels
        UserData.sfx = sfx
        Post3DModelThreadCall(OnSfxFind, UserData, model, "Find", szSocketName)
        tModels[szSocketName] = sfx
    end
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

function PlayerModelView:BindToSpecialSocket(mdl, szSocketName)
    for equipType, model in pairs(self.m_modelRole) do
        local UserData = {}
        UserData.mdl = mdl
        UserData.szSocketName = szSocketName

        Post3DModelThreadCall(OnFind, UserData, model, "Find", szSocketName)
    end
end

function PlayerModelView:LoadResourceSFX(equipType, tSFXList)
    self.m_ResourceSFX[equipType] = self.m_ResourceSFX[equipType] or {}
    local tModels = self.m_ResourceSFX[equipType]
    for szSocketName, tSFX in pairs(tSFXList) do
        if not tModels[szSocketName] and tSFX.SfxPath and tSFX.SfxPath ~= "" then
            self:BindSFX(equipType, szSocketName, tSFX, tModels)
        end
    end
end

function PlayerModelView:UnloadResourceSFX(equipType)
    local tModels = self.m_ResourceSFX[equipType] or {}
    for szSocketName, model in pairs(tModels) do
        model:UnbindFromOther()
        model:Release()
        tModels[szSocketName] = nil
    end
    self.m_ResourceSFX[equipType] = nil
end

local function SetSubSet(model, tInfo, tHatResource)
    if tInfo.UseColorScale == 1 then
        model:SetSubsetArgFloat(tInfo.SubSetIndex, tHatResource.ColorScaleName, tInfo.ColorScale)
    end
    if tInfo.UseBaseColor == 1 then
        model:SetSubsetTexture(tInfo.SubSetIndex, tHatResource.BaseColorName, tInfo.BaseColor)
    end
    if tInfo.UseSpecularMap == 1 then
        model:SetSubsetTexture(tInfo.SubSetIndex, tHatResource.SpecularMapName, tInfo.SpecularMap)
    end
    if tInfo.UseAbledoColor == 1 then
        model:SetSubsetArgColor(tInfo.SubSetIndex, tHatResource.AbledoColorName, tInfo.AbledoColorFloat1, tInfo.AbledoColorFloat2, tInfo.AbledoColorFloat3, tInfo.AbledoColorFloat4)
    end
    if tInfo.UseRoughness == 1 then
        model:SetSubsetArgFloat(tInfo.SubSetIndex, tHatResource.RoughnessName, tInfo.Roughness)
    end
end

function PlayerModelView:LoadPart(equipType, aNewEquipRes, aEquipRes)
    if aNewEquipRes[equipType]["Mesh"] then
        local mdl = self.m_modelRole["MDL"]
        local model = self.m_modelRole[equipType]
        local new_model = false
        if not aEquipRes or not model or aNewEquipRes[equipType]["Mesh"] ~= aEquipRes[equipType]["Mesh"] then
            self:UnloadPart(equipType)
            model = self.m_modelMgr:NewModel(aNewEquipRes[equipType]["Mesh"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)
            self.m_modelRole[equipType] = model

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

            -- Log("[UI] LoadPart("..equipType..", "..self.m_nRoleType..", "..aNewEquipRes[equipType]["ColorChannel"]..", "..aNewEquipRes[equipType]["Mesh"]..")")

            model:SetDetail(self.m_nRoleType, aNewEquipRes[equipType]["ColorChannel"])

            local scale = aNewEquipRes[equipType]["MeshScale"]

            --model:SetScaling(scale, scale, scale)
            self:UnloadModelSFX(equipType)

            self:LoadModelSFX(model, equipType, aNewEquipRes)

            local tRepresentID = self.m_aRepresentID
            if equipType == "CHEST" and tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] and tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] ~= 0 then
                local tHatResource = Player_GetMysteryHatResource(tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE], tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING], self.m_nRoleType, tRepresentID[EQUIPMENT_REPRESENT.CHEST_STYLE])
                if tHatResource and tHatResource.Enable == 1 then
                    for _, tInfo in pairs(tHatResource.ChestSubset) do
                        SetSubSet(model, tInfo, tHatResource)
                    end
                end
            end

            if aNewEquipRes[equipType]["Ani"] and aNewEquipRes[equipType]["Ani"]  ~= "" then
                model:PlayAnimation("loop", aNewEquipRes[equipType]["Ani"] , 1.0, 0)
            end

            self:SetHairDyeingAndSubsetVisiable(equipType)

            self:SetSubsetChestVisiable(equipType, aNewEquipRes, model)
        end
    else
        self:UnloadPart(equipType)
    end
end

function PlayerModelView:SetHairDyeingAndSubsetVisiable(equipType)
    if equipType == "HEADFORM" then
        local model = self.m_modelRole["HEADFORM"]
        local aNewEquipRes = self.m_aEquipRes
        local tRepresentID = self.m_aRepresentID
        if tRepresentID.tHairDyeingData and not IsEmpty(tRepresentID.tHairDyeingData) then
            self:SetHairDyeing(tRepresentID.tHairDyeingData)
        else
            model:ResetSubsetModify()
        end
        --隐藏一定要在SetHairDyeing后面做，不然SetHairDyeing会把隐藏部分显示出来
        self:SetSubsetHeadformVisiable(equipType, aNewEquipRes, model)
    end
end

function PlayerModelView:SetSubsetVisiable(nType, nFlag)
    local tRepresentID = self.m_aRepresentID
    if tRepresentID[nType] == nFlag then
        return
    end
    local nLastFlag = tRepresentID[nType]
    tRepresentID[nType] = nFlag
    local equipType
    if nType == EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK then
        equipType = "HEADFORM"
    elseif nType == EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK then
        equipType = "CHEST"
    end

    local model = self.m_modelRole[equipType]
    local aNewEquipRes = self.m_aEquipRes
    if not model or not aNewEquipRes then
        return
    end

    if nType == EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK then
        self:SetSubsetHeadformVisiable(equipType, aNewEquipRes, model, true, nLastFlag)
    elseif nType == EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK then
        self:SetSubsetChestVisiable(equipType, aNewEquipRes, model, true, nLastFlag)
    end
end

function PlayerModelView:SetHairDyeingData(tData)
    local tRepresentID = self.m_aRepresentID
    tRepresentID.tHairDyeingData = tData
    self:SetHairDyeingAndSubsetVisiable("HEADFORM")
end

local function SetSubsetDissolve(script, tResource, model, tRepresentID, nType, nLastFlag)
    for i = 1, tResource.nGroupCount do
        if kmath.is_bit1(tRepresentID[nType], i) ~= kmath.is_bit1(nLastFlag, i) then
            local nVisiable = kmath.is_bit1(tRepresentID[nType], i) and 0 or 1
            local tSubset = tResource[i]
            if nVisiable == 0 then --消融
                for j = 1, tSubset.nSubsetCount do
                    local nSubsetIndex = tSubset["nSubsetIndex" .. j]
                    local szDissolveTexture2DMask = tSubset["szDissolveTexture2DMask" .. j]
                    local szDissolveTexture2DTex = tSubset["szDissolveTexture2DTex" .. j]

                    if szDissolveTexture2DMask and szDissolveTexture2DMask ~= "" then
                        model:SetSubsetTexture(nSubsetIndex, tResource.szDissolveTexture2DMaskArgName, szDissolveTexture2DMask)
                    end
                    if szDissolveTexture2DTex and szDissolveTexture2DTex ~= "" then
                        model:SetSubsetTexture(nSubsetIndex, tResource.szDissolveTexture2DTexArgName, szDissolveTexture2DTex)
                    end
                    model:SetSubsetArgColor(nSubsetIndex, tResource.szDissolveColorAArgName, tResource.fDissolveColorAR, tResource.fDissolveColorAG, tResource.fDissolveColorAB, tResource.fDissolveColorAA)
                    model:SetSubsetArgColor(nSubsetIndex, tResource.szDissolveColorBArgName, tResource.fDissolveColorBR, tResource.fDissolveColorBG, tResource.fDissolveColorBB, tResource.fDissolveColorBA)
                    model:SetSubsetArgFloat(nSubsetIndex, tResource.szDissolveArgName, tResource.fDissolveBeginValue)
                    local nStartTime = GetTickCount()
                    if not script.tbDissolveTimer[i] then
                        script.tbDissolveTimer[i] = {}
                    end
                    script.tbDissolveTimer[i][j] = Timer.AddFrameCycle(script, 1, function()
                        if not model then
                            Timer.DelTimer(script, script.tbDissolveTimer[i][j])
                            return
                        end
                        local nNowTime = GetTickCount()
                        local fValue = (tResource.fDissolveEndValue - tResource.fDissolveBeginValue) / tResource.fTime * (nNowTime - nStartTime) + tResource.fDissolveBeginValue
                        model:SetSubsetArgFloat(nSubsetIndex, tResource.szDissolveArgName, fValue)
                        local nLeaveTime = nStartTime + tResource.fTime - nNowTime
                        if nLeaveTime <= 0 then
                            model:SetSubsetVisiable(nSubsetIndex, nVisiable)
                            Timer.DelTimer(script, script.tbDissolveTimer[i][j])
                            return
                        end
                    end)
                end
            else --复原
                for j = 1, tSubset.nSubsetCount do
                    local nSubsetIndex = tSubset["nSubsetIndex" .. j]
                    local szAssembleTexture2DMask = tSubset["szAssembleTexture2DMask" .. j]
                    local szAssembleTexture2DTex = tSubset["szAssembleTexture2DMask" .. j]

                    if szAssembleTexture2DMask and szAssembleTexture2DMask ~= "" then
                        model:SetSubsetTexture(nSubsetIndex, tResource.szDissolveTexture2DMaskArgName, szAssembleTexture2DMask)
                    end
                    if szAssembleTexture2DTex and szAssembleTexture2DTex ~= "" then
                        model:SetSubsetTexture(nSubsetIndex, tResource.szDissolveTexture2DTexArgName, szAssembleTexture2DTex)
                    end
                    model:SetSubsetArgColor(nSubsetIndex, tResource.szDissolveColorAArgName, tResource.fAssembleColorAR, tResource.fAssembleColorAG, tResource.fAssembleColorAB, tResource.fAssembleColorAA)
                    model:SetSubsetArgColor(nSubsetIndex, tResource.szDissolveColorBArgName, tResource.fAssembleColorBR, tResource.fAssembleColorBG, tResource.fAssembleColorBB, tResource.fAssembleColorBA)
                    model:SetSubsetArgFloat(nSubsetIndex, tResource.szDissolveArgName, tResource.fDissolveEndValue)
                    model:SetSubsetVisiable(nSubsetIndex, nVisiable)
                    local nStartTime = GetTickCount()
                    if not script.tbDissolveTimer[i] then
                        script.tbDissolveTimer[i] = {}
                    end
                    script.tbDissolveTimer[i][j] = Timer.AddFrameCycle(script, 1, function()
                        if not model then
                            Timer.DelTimer(script, script.tbDissolveTimer[i][j])
                            return
                        end
                        local nNowTime = GetTickCount()
                        local fValue = (tResource.fDissolveBeginValue - tResource.fDissolveEndValue) / tResource.fTime * (nNowTime - nStartTime) + tResource.fDissolveEndValue
                        model:SetSubsetArgFloat(nSubsetIndex, tResource.szDissolveArgName, fValue)
                        local nLeaveTime = nStartTime + tResource.fTime - nNowTime
                        if nLeaveTime <= 0 then
                            Timer.DelTimer(script, script.tbDissolveTimer[i][j])
                            return
                        end
                    end)
                end
            end
        end
    end
end

local function SetSubsetVisiable(tResource, model, tRepresentID, nType)
    for i = 1, tResource.nGroupCount do
        local nVisiable = kmath.is_bit1(tRepresentID[nType], i) and 0 or 1
        local tSubset = tResource[i]
        for j = 1, tSubset.nSubsetCount do
            local nSubsetIndex = tSubset["nSubsetIndex" .. j]
            model:SetSubsetVisiable(nSubsetIndex, nVisiable)
        end
    end
end

function PlayerModelView:SetSubsetHeadformVisiable(equipType, aNewEquipRes, model, bDissolve, nLastFlag)
    --SubSet隐藏发型
    local tRepresentID = self.m_aRepresentID
    if equipType == "HEADFORM" and self.m_aEquipRes.nHeadformID and self.m_aEquipRes.nHeadformID ~= 0 then
        SetBreatheCallSubsetDissolveFalse(self)
        local tResource = Player_GetHairSubsetHideResource(self.m_aEquipRes.nHeadformID, self.m_nRoleType, aNewEquipRes[equipType]["ColorChannel"])
        if tResource then
            if bDissolve and tResource.bHaveDissolve == 1 then
                SetSubsetDissolve(self, tResource, model, tRepresentID, EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK, nLastFlag)
            else
                SetSubsetVisiable(tResource, model, tRepresentID, EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK)
            end
        end
    end
end

function PlayerModelView:SetSubsetChestVisiable(equipType, aNewEquipRes, model, bDissolve, nLastFlag)
    --SubSet隐藏外观
    local tRepresentID = self.m_aRepresentID
    if equipType == "CHEST" and tRepresentID[EQUIPMENT_REPRESENT.CHEST_STYLE] and tRepresentID[EQUIPMENT_REPRESENT.CHEST_STYLE] ~= 0 then
        SetBreatheCallSubsetDissolveFalse(self)
        local tResource = Player_GetChestSubsetHideResource(tRepresentID[EQUIPMENT_REPRESENT.CHEST_STYLE], self.m_nRoleType, aNewEquipRes[equipType]["ColorChannel"])
        if tResource then
            if bDissolve and tResource.bHaveDissolve == 1 then
                SetSubsetDissolve(self, tResource, model, tRepresentID, EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK, nLastFlag)
            else
                SetSubsetVisiable(tResource, model, tRepresentID, EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK)
            end
        end
    end
end

local function SetPendantCustom(model, tRepresentData, scale)
    local fCustomScale = tRepresentData.fScale
    model:SetTranslation(tRepresentData.nOffsetX, tRepresentData.nOffsetY, tRepresentData.nOffsetZ)
    model:SetEulerRotation(tRepresentData.fRotationX, tRepresentData.fRotationY, tRepresentData.fRotationZ)

    model:SetScaling(scale * fCustomScale, scale * fCustomScale, scale * fCustomScale)
end

function PlayerModelView:UpdatePendantCustom(nType, tRepresentData)
    local equipType = GetCustomPendantType(nType)
    if not equipType then
        return
    end
    local model = self.m_modelRole[equipType]
    if not model then
        return
    end
    local scale = self.m_aEquipRes[equipType]["MeshScale"]
    SetPendantCustom(model, tRepresentData, scale)
    self:UpdateDynamicEffectCustom(equipType, tRepresentData)
end

function PlayerModelView:SetHairDyeing(tData)
    local model = self.m_modelRole["HEADFORM"]
    if not model then
        return
    end
    local tRepresentID = self.m_aRepresentID
    model:ResetSubsetModify()
    if not tData or IsTableEmpty(tData) or (tData[HAIR_CUSTOM_DYEING_TYPE.BASE_COLOR] == 0 and tData[HAIR_CUSTOM_DYEING_TYPE.HAIR_COLOR] == 0 and tData[HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR] == 0) then
        return
    end
    local nColorID, yRoughness, byHighLight, byAbledoColorA, bySpecularColorA, nHairColorID, byHairRoughness, byHairHighLight, byHairAbledoColorA, byHairSpecularColorA, nDColorID, byColorA, byColorStrength, byAlphaEnhance = tData[0], unpack(tData)
    local tResource = Player_GetMysteryHairParam(self.m_aRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE], self.m_nRoleType, tData)
    --原发颜色
    if nColorID ~= 0 then
        for i = 1, tResource.BaseHairCount do
            local nSubsetIndex = tResource["SubsetIndex" .. i]
            if tResource.BaseHairTable.BaseColorTexture and tResource.BaseHairTable.BaseColorTexture ~= "" then
                model:SetSubsetTextureByMysteryHair(nSubsetIndex, RL_MYSTERY_HAIR_TEXTURE_TYPE.BASE_COLOR, tResource.BaseColorArgName, tResource.BaseHairTable.BaseColorTexture or "")
            end
            if tResource.BaseHairTable.SpecularMapTexture and tResource.BaseHairTable.SpecularMapTexture ~= "" then
                model:SetSubsetTextureByMysteryHair(nSubsetIndex, RL_MYSTERY_HAIR_TEXTURE_TYPE.SPECULAR_MAP, tResource.SpecularMapArgName, tResource.BaseHairTable.SpecularMapTexture or "")
            end
            if byAbledoColorA ~= 0 then
                model:SetSubsetArgColorA(nSubsetIndex, tResource.AbledoColorArgName, tResource.BaseHairTable.AbledoColorA)
            end
            if bySpecularColorA ~= 0 then
                model:SetSubsetArgColorA(nSubsetIndex, tResource.SpecularColorArgName, tResource.BaseHairTable.SpecularColorA)
            end
            model:SetSubsetArgColorRGB(nSubsetIndex, tResource.AbledoColorArgName, tResource.BaseHairTable.AbledoColorR, tResource.BaseHairTable.AbledoColorG, tResource.BaseHairTable.AbledoColorB)
            model:SetSubsetArgColorRGB(nSubsetIndex, tResource.SpecularColorArgName, tResource.BaseHairTable.SpecularColorR, tResource.BaseHairTable.SpecularColorG, tResource.BaseHairTable.SpecularColorB)
            if yRoughness ~= 0 then
                model:SetSubsetArgFloat(nSubsetIndex, tResource.RoughnessArgName, tResource.BaseHairTable.Roughness)
            end
            if byHighLight ~= 0 then
                model:SetSubsetArgFloat(nSubsetIndex, tResource.HighLightOffsetArgName, tResource.BaseHairTable.HighLightOffset)
                model:SetSubsetArgFloat(nSubsetIndex, tResource.HighLightStrengthArgName, tResource.BaseHairTable.HighLightStrength)
            end
            model:SetSubsetArgColor(nSubsetIndex, tResource.EmissiveArgName, 0, 0, 0, 0)
            model:SetSubsetArgFloat(nSubsetIndex, tResource.ColorScaleArgName or "color_scale", 0.5)
            model:SetSubsetArgFloat(nSubsetIndex, tResource.RemapMinArgName, 1) -- vk端特殊处理
        end
    end

    --发丝颜色
    if nHairColorID ~= 0 then
        for i = 1, tResource.HairCount do
            local nIndex = tResource.BaseHairCount + i
            local nSubsetIndex = tResource["SubsetIndex" .. nIndex]
            if tResource.HairTable.BaseColorTexture and tResource.HairTable.BaseColorTexture ~= "" then
                model:SetSubsetTextureByMysteryHair(nSubsetIndex, RL_MYSTERY_HAIR_TEXTURE_TYPE.BASE_COLOR, tResource.BaseColorArgName, tResource.HairTable.BaseColorTexture or "")
            end
            if tResource.HairTable.SpecularMapTexture and tResource.HairTable.SpecularMapTexture ~= "" then
                model:SetSubsetTextureByMysteryHair(nSubsetIndex, RL_MYSTERY_HAIR_TEXTURE_TYPE.SPECULAR_MAP, tResource.SpecularMapArgName, tResource.HairTable.SpecularMapTexture or "")
            end
            if byHairAbledoColorA ~= 0 then
                model:SetSubsetArgColorA(nSubsetIndex, tResource.AbledoColorArgName, tResource.HairTable.AbledoColorA)
            end
            if byHairSpecularColorA ~= 0 then
                model:SetSubsetArgColorA(nSubsetIndex, tResource.SpecularColorArgName, tResource.HairTable.SpecularColorA)
            end
            model:SetSubsetArgColorRGB(nSubsetIndex, tResource.AbledoColorArgName, tResource.HairTable.AbledoColorR, tResource.HairTable.AbledoColorG, tResource.HairTable.AbledoColorB)
            model:SetSubsetArgColorRGB(nSubsetIndex, tResource.SpecularColorArgName, tResource.HairTable.SpecularColorR, tResource.HairTable.SpecularColorG, tResource.HairTable.SpecularColorB)
            if byHairRoughness ~= 0 then
                model:SetSubsetArgFloat(nSubsetIndex, tResource.RoughnessArgName, tResource.HairTable.Roughness)
            end
            if byHairHighLight ~= 0 then
                model:SetSubsetArgFloat(nSubsetIndex, tResource.HighLightOffsetArgName, tResource.HairTable.HighLightOffset)
                model:SetSubsetArgFloat(nSubsetIndex, tResource.HighLightStrengthArgName, tResource.HairTable.HighLightStrength)
            end

            if byAlphaEnhance ~= 0 then
                model:SetSubsetArgFloat(nSubsetIndex, tResource.AlphaEnhanceArgName, tResource.HairTable.AlphaEnhance)
            end
            model:SetSubsetArgColor(nSubsetIndex, tResource.EmissiveArgName, 0, 0, 0, 0)
            model:SetSubsetArgFloat(nSubsetIndex, tResource.ColorScaleArgName or "color_scale", 0.5)
            model:SetSubsetArgFloat(nSubsetIndex, tResource.RemapMinArgName, 1) -- vk端特殊处理
        end
    end

    --设置发饰颜色
    if nDColorID ~= 0 then
        for i = 1, tResource.HairAccessorizesCount do
            local nIndex = tResource.BaseHairCount + tResource.HairCount + i
            local nSubsetIndex = tResource["SubsetIndex" .. nIndex]

            if tResource.HairAccessorizesTable.ColorOffsetMapTexture and tResource.HairAccessorizesTable.ColorOffsetMapTexture ~= "" then
                model:SetSubsetTexture(nSubsetIndex, tResource.ColorOffsetMapArgName, tResource.HairAccessorizesTable.ColorOffsetMapTexture)
            end
            model:SetSubsetArgColorRGB(nSubsetIndex, tResource.Part01ColorArgName, tResource.HairAccessorizesTable.Part01ColorR, tResource.HairAccessorizesTable.Part01ColorG, tResource.HairAccessorizesTable.Part01ColorB)
            model:SetSubsetArgFloat(nSubsetIndex, tResource.SpecialArgName, 0)

            if byColorA ~= 0 then
                model:SetSubsetArgColorA(nSubsetIndex, tResource.Part01ColorArgName, tResource.HairAccessorizesTable.Part01ColorA)
                model:SetSubsetArgFloat(nSubsetIndex, tResource.Decal1ColorStrengthName, 0)
            end

            if byColorStrength ~= 0 then
                model:SetSubsetArgFloat(nSubsetIndex, tResource.Part01ColorStrengthArgName, tResource.HairAccessorizesTable.Part01ColorStrength)
            end
        end
    end
end

function PlayerModelView:LoadSocket(equipType, aNewEquipRes, aEquipRes, bHaveCloak)
     -- 披风被标记为隐藏时：不加载socket模型，但仍处理动态特效
     if equipType == "CLOAK" and self.m_aRepresentID.bHideBackCloakModel then
        self:UnloadSocket(equipType)
        if aNewEquipRes[equipType] and aNewEquipRes[equipType]["Mesh"] then
            local dwPendantType = GetPendantTypeByResEquipType(equipType)
            if dwPendantType then
                self:LoadSocketDynamicEffect(self.m_modelRole["MDL"], equipType, aNewEquipRes)
            end
        end
        return
    end
    if aNewEquipRes[equipType]["Mesh"] then
        -- 刀宗会多一把剑在背上，目前 s_tangdao 这个插槽只有 刀宗在用，因此先这样屏蔽这个插槽的资源加载
        --if self.m_aRepresentID.key == ForceTypeToSchool[FORCE_TYPE.DAO_ZONG] then
        if equipType == "RL_WEAPON_DART" then
            if aNewEquipRes[equipType]["Socket"] == _tSocketName[WEAPON_DETAIL.MASTER_BLADE].DART then
                return
            end
        end

        local mdl = self.m_modelRole["MDL"]
        local model = self.m_modelRole[equipType]
        local new_model = false
        if not aEquipRes or not model or aNewEquipRes[equipType]["Mesh"] ~= aEquipRes[equipType]["Mesh"] then
            self:UnloadSocket(equipType)

            model = self.m_modelMgr:NewModel(aNewEquipRes[equipType]["Mesh"], self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, self.bAPEX)

            self.m_modelRole[equipType] = model

            if equipType == "FACE" and model.SetCompressFaceTexture then
                model:SetCompressFaceTexture(false)
            end

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

                --Log("[UI] LoadSocket("..equipType..", "..nColorChannelTable..", "..aNewEquipRes[equipType]["ColorChannel"]..", "..aNewEquipRes[equipType]["Mesh"]..")")

               	model:SetDetail(nColorChannelTable, aNewEquipRes[equipType]["ColorChannel"])

               	if self.WeaponVisible and self.WeaponVisible[equipType] ~= nil then
                    if not self.WeaponVisible[equipType] then
                        model:SetAlpha(0)
                    end
               	end
            else
                -- Log("[UI] LoadSocket("..equipType..", "..self.m_nRoleType..", "..aNewEquipRes[equipType]["ColorChannel"]..", "..aNewEquipRes[equipType]["Mesh"]..")")
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

            -- local fSocketOffset = 0
            -- local x = 0
            -- local y = 0
            -- local z = 0
            -- for i = EQUIPMENT_REPRESENT.FACE_STYLE, EQUIPMENT_REPRESENT.TOTAL do
            --     x, y, z = Character_GetPlayerSocketOffset(self.m_nRoleType, i, tRepresentID[i], aNewEquipRes[equipType]["Socket"])
            --     if x ~= 0 or y ~= 0 or z ~= 0 then
            --         break
            --     end
            -- end

            -- if x ~= 0 or y ~= 0 or z ~= 0  then
            --     model:SetTranslation(x, y, z)
            -- end
            local dwPendantType = GetPendantTypeByResEquipType(equipType)
            local scale = aNewEquipRes[equipType]["MeshScale"]
            if dwPendantType and tRepresentID.tCustomRepresentData and tRepresentID.tCustomRepresentData[dwPendantType] and IsCustomPendantRepresentType(equipType, tRepresentID[dwPendantType], self.m_nRoleType) then
                SetPendantCustom(model, tRepresentID.tCustomRepresentData[dwPendantType], scale)
            else
                model:SetScaling(scale, scale , scale)
            end

            -- model:SetScaling(scale, scale, scale)
            self:UnloadModelSFX(equipType)
            self:LoadModelSFX(model, equipType, aNewEquipRes, true)
            if dwPendantType then
                self:LoadSocketDynamicEffect(mdl, equipType, aNewEquipRes)
            end

            --校服头发染色
            if equipType == "HAT" and tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] and tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] ~= 0 then
                local tHatResource = Player_GetMysteryHatResource(tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE], tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING], self.m_nRoleType)
                if tHatResource and tHatResource.Enable == 1 then
                    for _, tInfo in pairs(tHatResource.Subset) do
                        SetSubSet(model, tInfo, tHatResource)
                    end
                end
            end
        end
    else
        self:UnloadSocket(equipType)
    end
end

function PlayerModelView:UpdateWeaponPos(bSheath, nWeaponType, dwPoseState, bSwitchSword)
    local aRes = clone(self.m_aEquipRes)
    self.bSheath = bSheath

    if bSheath then --- 武器收起状态，把武器绑定指定插槽上
        local tSocket = _tSocketName[nWeaponType]
        if nWeaponType == WEAPON_DETAIL.BIG_SWORD then
            tSocket = _tSocketName[WEAPON_DETAIL.SWORD]
            aRes["HeavySword"]["Socket"] = "S_epee"
        elseif nWeaponType == WEAPON_DETAIL.BROAD_SWORD or nWeaponType == WEAPON_DETAIL.MASTER_BLADE then
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

function PlayerModelView:SetWeaponVisible(equipType, bShow)
    local model = self.m_modelRole[equipType]
    if model then
        if bShow then
            model:SetAlpha(1)
        else
            model:SetAlpha(0)
        end
    end
    self.WeaponVisible = self.WeaponVisible or {}
    self.WeaponVisible[equipType] = bShow
end


function PlayerModelView:UpdateRoleModel(aNewEquipRes, nRoleType)
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
    local mdl = self.m_modelRole["MDL"]
    if not aEquipRes or mdl == nil or aNewEquipRes["MDL"] ~= aEquipRes["MDL"] then

        playing_delete(self)

        mdlOld = mdl

        self:UnloadModel(true);
        aEquipRes = nil
        self.m_modelRole = self.m_modelRole or {}
        self.m_modelRoleSFX = self.m_modelRoleSFX or {}
        self.m_ResourceSFX = self.m_ResourceSFX or {}
        self.m_modelSocketDynamicEffect = self.m_modelSocketDynamicEffect or {}
        mdl = self.m_modelMgr:NewModel(aNewEquipRes["MDL"], self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel)

        mdl:SetFurLODFlags(self.bMainPlayer)
        mdl:SetTranslation(0, 0, 0)

        self.m_modelRole["MDL"] = mdl

        if self.reg_handler then
            self:RegisterEventHandler()
        end

        if self.aAnis and #self.aAnis > 0 then
            playing_add(self)
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
                self:LoadPart(equipType, aNewEquipRes, aEquipRes)
            end
        end
    end

    if IsHaveExtendCloak(aNewEquipRes) then
        local modelCloak = self.m_modelRole["EXTEND_PART"]
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
                    self:LoadSocket(equipType, aNewEquipRes, aEquipRes, bHaveCloak)
                end
            end
        end
    end

    if self.m_modelRole["LANTERN"] then --魂灯的灯笼要绑在武器上
        local mdl = self.m_modelRole["LANTERN"]
        self:BindToSpecialSocket(mdl, aNewEquipRes["LANTERN"]["Socket"])
        local tSfx = clone(_tInitSFX)
        tSfx.SfxPath = aNewEquipRes["LANTERN"]["SFX1"]
        self:LoadResourceSFX("LANTERN", {s_light = tSfx})
    end

    for equipType, tSFXList in pairs(tResourceSFX) do
        self:LoadResourceSFX(equipType, tSFXList)
    end

    local tRepresentID = self.m_aRepresentID
    if tRepresentID.bUseLiftedFace and tRepresentID.tFaceData then
        local tFaceData = tRepresentID.tFaceData
        if tFaceData.tBone then
            if tFaceData.bNewFace then
                self:SetFaceDefinition(tFaceData.tBone, self.m_nRoleType, tFaceData.tDecal, tFaceData.tDecoration, true)
            else
                self:SetFaceDefinition(tFaceData.tBone, self.m_nRoleType, tFaceData.tDecal, tFaceData.nDecorationID)
            end
        end
    end
    if tRepresentID.tBody then
        self:SetBodyReshapingParams(tRepresentID.tBody)
    end

    mdl:SetForceRealInterpolate(self.bForceRealInterpolate)

    self:ShowMDL(mdl)

    if mdlOld then
        self:HideMDL(mdlOld)
        mdlOld:Release()
    end
    self:PlayWeaponAnimation(self.m_nRoleType, self.m_aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE])
    self:SetWeaponSocketDynamic()
    -- self:SetEffectSfx()
end

function PlayerModelView:LoadModel()
    if self.m_modelRole then
        return
    end

    local aEquipRes = self.m_aEquipRes
    if aEquipRes["MDL"] then
        self.m_modelRole = {}
        self.m_modelRoleSFX = {}
        self.m_ResourceSFX = {}
        self.m_modelSocketDynamicEffect = {}
        local mdl = self.m_modelMgr:NewModel(aEquipRes["MDL"], self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, nil, self.bAPEX)

        local scale = aEquipRes["MDLScale"]
        mdl:SetScaling(scale, scale, scale)

        mdl:SetTranslation(0, 0, 0)

        self.m_modelRole["MDL"] = mdl

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
            local modelCloak = self.m_modelRole["EXTEND_PART"]
            mdl:HideMeshPointOutsideCloak(modelCloak)
        else
            mdl:ClearHideMeshPointOutsideCloak()
        end

        if self.m_modelRole["LANTERN"] then --魂灯的灯笼要绑在武器上
            local mdl = self.m_modelRole["LANTERN"]
            self:BindToSpecialSocket(mdl, aEquipRes["LANTERN"]["Socket"])
            local tSfx = clone(_tInitSFX)
            tSfx.SfxPath = aEquipRes["LANTERN"]["SFX1"]
            self:LoadResourceSFX("LANTERN", {s_light = tSfx})
        end

        for equipType, tSFXList in pairs(tResourceSFX) do
            self:LoadResourceSFX(equipType, tSFXList)
        end
        mdl:SetForceRealInterpolate(self.bForceRealInterpolate)
        mdl:SetFurLODFlags(self.bMainPlayer)
        self:PlayWeaponAnimation(self.m_nRoleType, self.m_aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE])
        local tRepresentID = self.m_aRepresentID
        if tRepresentID.bUseLiftedFace and tRepresentID.tFaceData then
            local tFaceData = tRepresentID.tFaceData
            if tFaceData.tBone then
                if tFaceData.bNewFace then
                    self:SetFaceDefinition(tFaceData.tBone, self.m_nRoleType, tFaceData.tDecal, tFaceData.tDecoration, true)
                else
                    self:SetFaceDefinition(tFaceData.tBone, self.m_nRoleType, tFaceData.tDecal, tFaceData.nDecorationID)
                end
            end
        end
        if tRepresentID.tBody then
            self:SetBodyReshapingParams(tRepresentID.tBody)
        end
        self:ShowMDL(mdl)
    end
end;

function PlayerModelView:IsRegisterEventHandler()
    return self.reg_handler
end

function PlayerModelView:RegisterEventHandler()
    self.reg_handler = true
    self.m_modelRole["MDL"]:RegisterEventHandler()
end

function PlayerModelView:UnRegisterEventHandler()
    self.reg_handler = nil
    self.m_modelRole["MDL"]:UnregisterEventHandler()
end

function PlayerModelView:UnloadSocket(equipType)
    -- -- 动态特效独立卸载，不依赖socket模型是否存在
    self:UnloadModelSocketDynamicEffect(equipType)
    local model = self.m_modelRole[equipType]
    if not model then
        return
    end
    self:UnloadModelSFX(equipType)
    self:UnloadResourceSFX(equipType)
    model:UnbindFromOther()
    model:Release()

    model = nil
    self.m_modelRole[equipType] = nil
end

function PlayerModelView:UnloadPart(equipType)
    local model = self.m_modelRole[equipType]
    if not model then
        return
    end

    self:UnloadModelSFX(equipType)
    self:UnloadResourceSFX(equipType)
    self.m_modelRole["MDL"]:Detach(model)
    model:Release()
    model = nil
    self.m_modelRole[equipType] = nil
end

function PlayerModelView:HideMDL(mdl)
    if self.m_scene then
        if self.m_canselect  then
            self.m_scene:RemoveRenderEntity(mdl, self.m_canselect)
        else
            self.m_scene:RemoveRenderEntity(mdl)
        end
    end
end

function PlayerModelView:ShowMDL(mdl)
    if self.m_canselect then
        self.m_scene:AddRenderEntity(mdl, false, self.m_canselect)
    else
        self.m_scene:AddRenderEntity(mdl)
    end
end

function PlayerModelView:UnloadModel(exchanged)
    if not self.m_modelRole then
        return
    end

    local mdl = self.m_modelRole["MDL"]
    if not mdl then
        return
    end

    SetBreatheCallSubsetDissolveFalse(self)

    self:EndReshape()
    self:EndFaceHighlightMgr()

    if self.m_modelRole["LANTERN"] then --魂灯的灯笼要先卸载
        self:UnloadSocket("LANTERN")
    end

    for equipType, model in pairs(self.m_modelRole) do
        if model and self.m_aEquipRes[equipType]["Socket"] then
            self:UnloadSocket(equipType)
        end
    end

    for equipType, model in pairs(self.m_modelRole) do
        if model and not self.m_aEquipRes[equipType]["Socket"] and equipType ~= "MDL" then
            self:UnloadPart(equipType)
        end
    end

    self:UnloadWeaponSocketDynamic()
    self:UnloadAllModelSocketDynamicEffect()
    if not exchanged then
        self:HideMDL(mdl)
        mdl:Release()
	    self.m_modelRole["MDL"] = nil
    end

    if self.m_tExModel then
        for k, v in pairs(self.m_tExModel) do
            self:RemoveModel(k)
        end
    end

    self:UnloadModelEffect()
    self.m_tExModel = nil
    self.m_ResourceSFX = nil
    self.m_modelRoleSFX = nil
    self.m_modelRole = nil
    self.m_WeaponSocketDynamic = nil
    self.m_modelSocketDynamicEffect = nil
end

function PlayerModelView:GetLastAni()
    if not self.aAnis then
        return
    end

    local len = #self.aAnis
    return self.aAnis[len]
end

function PlayerModelView:ClearAnis()
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

function PlayerModelView:PlayAnimation(szAniName, szLoopType, fTweenTime)
    if not self.m_modelRole or not self.m_modelRole["MDL"] then
        return
    end
    if not szAniName or not self.m_aAnimationRes[szAniName].Ani then
        return
    end

    self:ClearAnis()
    self.aAnis = self.aAnis or  {}
    table.insert(self.aAnis, {id=szAniName, type=szLoopType, tweentime=fTweenTime, usename=true})
    playing_add(self)

    self:PlayAni( self.m_modelRole["MDL"], self.aAnis[1] )
end

function PlayerModelView:PlayAnimationByLogicID(dwLogicID, szDefaultAniName)
    if not self.m_modelRole or not self.m_modelRole["MDL"] then
        return
    end

    local type = "loop"
    local mdl = self.m_modelRole["MDL"]
    if dwLogicID ~= 0 then
        local dwAdjustAniID = Player_GetAdjustAnimationByIdleActionID(dwLogicID)
        if dwAdjustAniID ~= 0 then
            local szAnimationName, _, _, _, dwPoseState = Player_GetAnimationResource(self.m_nRoleType, dwAdjustAniID)
            mdl:PlayAnimation(type, szAnimationName, 1, 0, 0)
            return
        end
    end

    if szDefaultAniName and szDefaultAniName ~= "" then
        --self:PlayAnimation(szDefaultAniName, type)
        self:PlayAni(mdl, {id = szDefaultAniName, type = type, usename = true})
    end
end


function PlayerModelView:PlayRoleAnimation(szLoopType, szAniPath , endCallback)
    self:ClearAnis()

    self.aAnis = self.aAnis or  {}
    table.insert(self.aAnis, {id = szAniPath, type = szLoopType, usepath=true , end_func= endCallback})
    playing_add(self)

    self:PlayAni( self.m_modelRole["MDL"], self.aAnis[1] )
end

function PlayerModelView:PlayAni(mdl, ani)
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

function PlayerModelView:OnAniFinished(mdl, ani_id)
    if not self.aAnis or mdl ~= self.m_modelRole["MDL"] then
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

function PlayerModelView:PlayAniID(id, type, tweentime, replace)
    if not self.m_modelRole or not self.m_modelRole["MDL"] then
        return
    end

    if replace or replace == nil then
        self:ClearAnis()
    end

    self.aAnis = self.aAnis or  {}
    table.insert(self.aAnis, {id=id, type=type, tweentime=tweentime})
    playing_add(self)
    self:PlayAni( self.m_modelRole["MDL"], self.aAnis[1] )
end

function PlayerModelView:PlayAniSequence(aIDs, replace)
    if not self.m_modelRole or not self.m_modelRole["MDL"] then
        return
    end

    self.aAnis = self.aAnis or  {}
    if replace or replace == nil then
        self:ClearAnis()
    end

    for _, id in pairs(aIDs) do
        table.insert(self.aAnis, id)
    end

    playing_add(self)

    local mdl = self.m_modelRole["MDL"]
    self:PlayAni( mdl, self.aAnis[ 1 ] )
end

function PlayerModelView:UpdateFacePendant()
    if self.m_aRepresentID.bHideFacePendent then
        self.m_aRepresentID[EQUIPMENT_REPRESENT.FACE_EXTEND] = 0
    end
end

function PlayerModelView:TransformEquipDefaultResource(aRepresentID, nRoleType, dwSchoolID)
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

local function ClearWeapon(aRepresentID)
    aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
    aRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
end

function PlayerModelView:UpdateRepresentID(aRepresentID, nRoleType, dwSchoolID, bNotLoad, bIngoreReplace, bClearWeapon)
    if bClearWeapon then
        ClearWeapon(aRepresentID)
    end

    aRepresentID = clone(aRepresentID)
    self.m_aOriginalRepresentID = clone(aRepresentID)

    local aTransformID = self:TransformEquipDefaultResource(aRepresentID, nRoleType, dwSchoolID)
    for i = 0, EQUIPMENT_REPRESENT.TOTAL-1 do
        aRepresentID[i] = aTransformID[i]
    end

    local bModified = false

    if not self.m_aRepresentID or not self.m_modelRole then
        self.m_aRepresentID = clone(aRepresentID)
        self.m_nRoleType = nRoleType
        self.m_dwSchoolID = dwSchoolID
        bModified = true
    else
        for i, v in pairs(aRepresentID) do
            if v ~= self.m_aRepresentID[i] then
                self.m_aRepresentID[i] = v
                bModified = true
            end
        end

        for i, v in pairs(self.m_aRepresentID) do
            if aRepresentID[i] == nil then
                self.m_aRepresentID[i] = nil
                bModified = true
            end
        end

        if self.m_nRoleType ~= nRoleType and not bNotLoad then
            --self:UnloadModel()
            bModified = true
        end
        -- if self.m_aRepresentID.nHatStyle ~= aRepresentID.nHatStyle then
        --     self.m_aRepresentID.nHatStyle = aRepresentID.nHatStyle
        --     bModified = true
        -- end

        -- if self.m_aRepresentID.bHideFacePendent ~= aRepresentID.bHideFacePendent then

        --     self.m_aRepresentID.bHideFacePendent = aRepresentID.bHideFacePendent
        -- end
    end

    self:UpdateFacePendant()

    if bModified and not bNotLoad then
        local bReplace = not bIngoreReplace
        local aNewEquipRes = self:GetModuleRes(nRoleType, dwSchoolID, self.m_aRepresentID, bReplace)
        self:UpdateRoleModel(aNewEquipRes, nRoleType)

        self:LoadPlayerAnimation(nRoleType)
    end

    return bModified
end

function PlayerModelView:LoadRes(dwPlayerID, tRepresentID, bIngoreReplace, bClearWeapon)
    local hPlayer = GetPlayer(dwPlayerID)
    local nRoleType = Player_GetRoleType(hPlayer)
    local dwSchoolID = hPlayer.dwSchoolID
    local tRes = clone(tRepresentID)
    self:UpdateFaceDecoration(hPlayer, tRes)
    self:UpdateRepresentID(tRes, nRoleType, dwSchoolID, nil, bIngoreReplace, bClearWeapon)
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

function GetPlayerViewReplace(tRepresentID)
	local tViewReplace = Table_ViewReplace()
    for _, tLine in ipairs(tViewReplace) do
        local bReplace = CheckReplace(tRepresentID, tLine.tKey)
        if bReplace then
			return tLine.tReplace
		 end
    end
end

function PlayerModelView:RepresentReplace(tRepresentID)
    local tReplace = GetPlayerViewReplace(tRepresentID)
    if tReplace then
        Replace(tRepresentID, tReplace)
    end
end

function PlayerModelView:GetModuleRes(nRoleType, dwSchoolID, tRepresentID, bReplace)
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

    --TODO_xt 使用捏脸的脸型，C++里面可能没设置插槽名称，临时补齐，12-20
    if tRepresentID.bUseLiftedFace and tRes["FACE"] and not tRes["FACE"]["Socket"] then
        tRes["FACE"]["Socket"] = "s_face"
    end

    -- if tRepresentID.bUseLiftedFace then
    -- 	local tMesh = Table_GetFaceMeshInfo(nRoleType)
    -- 	if tMesh then
    -- 		tRes["FACE"]["Mesh"] = tMesh.szMeshPath
    -- 		tRes["FACE"]["Mtl"] = tMesh.szMtlPath
    -- 	end
    -- end

    return tRes
end

function PlayerModelView:LoadModuleRes(nRoleType, dwSchoolID, tRepresentID, bClearWeapon)
    self:UpdateRepresentID(tRepresentID, nRoleType, dwSchoolID, false, true, bClearWeapon)
end

function PlayerModelView:UpdateFaceData(hPlayer)
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

function PlayerModelView:UpdateCustomRepresentData(hPlayer)
    local aRepresentID = self.m_aRepresentID
    if not aRepresentID then
        return true
    end
    local tNowData = clone(aRepresentID.tCustomRepresentData)
    aRepresentID.tCustomRepresentData = GetEquipCustomRepresentData(hPlayer)
    if tNowData then
        if not IsTableEqual(tNowData, aRepresentID.tCustomRepresentData) then
            return true
        end
    else
        return true
    end
    return false
end

function PlayerModelView:UpdateBodyData(hPlayer)
    local aRepresentID = self.m_aRepresentID
    if not aRepresentID then
        return true
    end
    local tNowBody = clone(aRepresentID.tBody)
    aRepresentID.tBody = hPlayer.GetEquippedBodyBoneData()
    if tNowBody then
        if not IsTableEqual(tNowBody, aRepresentID.tBody) then
            return true
        end
    else
        return true
    end
    return false
end

function PlayerModelView:UpdateHairDyeingData(hPlayer)
    local aRepresentID = self.m_aRepresentID
    if not aRepresentID then
        return true
    end
    local tHairDyeingData = clone(aRepresentID.tHairDyeingData)
    aRepresentID.tHairDyeingData = Role_GetHairDyeingData(hPlayer, aRepresentID)
    if tHairDyeingData and aRepresentID.tHairDyeingData then
        if not IsTableEqual(tHairDyeingData, aRepresentID.tHairDyeingData) then
            return true
        end
    elseif not tHairDyeingData and not aRepresentID.tHairDyeingData then
        return false
    else
        return true
    end
    return false
end

function PlayerModelView:LoadPlayerRes(dwPlayerID, bPortraitOnly, bWithCustom, bClearWeapon)
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
    Role_DealWithCloak(player, aRepresentID)
    local bModified = self:UpdateRepresentID(aRepresentID, nRoleType, dwSchoolID, true, nil, bClearWeapon)
    local bModifiedFace = self:UpdateFaceData(player)
    local bModifiedBody = self:UpdateBodyData(player)
    if bWithCustom == nil then bWithCustom = true end
    local bModifiedRepresent = bWithCustom and self:UpdateCustomRepresentData(player)
    local bModifiedHairDyeing = self:UpdateHairDyeingData(player)

    if bModified or bModifiedFace or bModifiedBody or bModifiedRepresent or bModifiedHairDyeing then
        -- self.m_aEquipRes = Player_GetEquipResource(
        --           	player.nRoleType,
        --		  	EQUIPMENT_REPRESENT.TOTAL,
        --          	aRepresentID
        --       )

        self.m_aEquipRes = self:GetModuleRes(nRoleType, dwSchoolID, self.m_aRepresentID, false)

        local res = self.m_aEquipRes
        if bPortraitOnly then
            self:ClearRes(res)
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

function PlayerModelView:LoadPlayerAnimation(nRoleType)
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

function PlayerModelView:LoadMemberRes(helm, face, nRoleType, bPortraitOnly)
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

function PlayerModelView:SetWeaponSocketDynamic()
    local tResource = nil

    if self.m_aRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] ~= 0 then
        if self.m_aEquipRes["nWeaponType"] == 3 then
            tResource = Player_GetSocketDynamicObjectResource(self.m_nRoleType, self.m_aRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE], true)
        else
            tResource = Player_GetSocketDynamicObjectResource(self.m_nRoleType, self.m_aRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE], self.bSheath or false)
        end
    end

    if not tResource and self.m_aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] ~= 0 then
        tResource = Player_GetSocketDynamicObjectResource(self.m_nRoleType, self.m_aRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE], self.bSheath or false)
    end

    self:UnloadWeaponSocketDynamic()

    if not tResource then
        return
    end

    local equipType = tResource.EquipType

    if tResource.MDL and tResource.MDL ~= "" then
        local mdl = nil
        if equipType and equipType ~= "" then
            mdl = self.m_modelRole[equipType]
        else
            mdl = self.m_modelRole["MDL"]
        end

        local model = self.m_modelMgr:NewModel(tResource.MDL, self.bModLod, self.bExScene, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, self.m_modelRole["MDL"], self.bAPEX, false, self.m_aEquipRes.bLoadBDMaterialInHD)
        model:SetPositionOnlyFlag(true)
        model:SetScaling(tResource.Scale, tResource.Scale, tResource.Scale)
        if (self.nModelType and self.nModelType == UI_MODEL_TYPE.COINSHOP) or
        (self.nModelType and (self.nModelType == UI_MODEL_TYPE.C_PANEL or self.nModelType == UI_MODEL_TYPE.PANEL_VIEW) and self.m_nRoleType == ROLE_TYPE.LITTLE_GIRL and self.m_dwSchoolID and (self.m_dwSchoolID == SCHOOL_TYPE.WU_DU or self.m_dwSchoolID == SCHOOL_TYPE.GAI_BANG)) or
        (not mdl) then
            model:PlayAnimation("loop", Table_GetPath("ANI_COINSHOP_WEAPON_SOCKET_DYNAMIC"), 1, 0, 0)
            model:BindToSocket(self.m_modelRole["MDL"], "s_lshoulder")
        else
            model:PlayAnimation("loop", tResource.IdleAnimation, 1, 0, 0)
            model:BindToSocket(mdl, tResource.SocketPos)
        end

        self.m_WeaponSocketDynamic = model
    end
end

function PlayerModelView:PlayWeaponAnimation(nRoleType, nWeaponID)
    local fnAction = function(weaponPos)
        local szSocketName = self.m_aEquipRes[weaponPos]["Socket"]
        local mesh = self.m_aEquipRes[weaponPos]["Mesh"]
        local model = self.m_modelRole[weaponPos]


        if not mesh or string.sub(mesh, string.len(mesh) - 3) ~= ".mdl" then
            return
        end

        if not nWeaponID or nWeaponID == 0 then
            return
        end

        if not szSocketName or szSocketName == "" then
            return
        end

        if not model then
            return
        end

        local WeaponAni = Weapon_GetAnimation(nRoleType, nWeaponID, szSocketName)
        model:PlayAnimation("loop", WeaponAni, 1.0, 0)
    end
    fnAction("RL_WEAPON_RH")
    fnAction("RL_WEAPON_LH")
end;


function PlayerModelView:LoadFaceDefinitionINI(szFileName)
    local model = self.m_modelRole["FACE"]
    if not model then
        Log("PlayerModelView LoadFaceDefinitionINI model is not exist")
        return
    end

    model:LoadFaceDefinitionINI(szFileName)
end

function PlayerModelView:GetFaceModel()
    local model = self.m_modelRole["FACE"]
    return model
end

function PlayerModelView:SetFaceDefinition(tBoneParams, nRoleType, tDecalDefinition, nDecorationID, bNewFace)
    local model = self.m_modelRole["FACE"]
    if not model then
        Log("PlayerModelView SetFaceDefinition model is not exist")
        return
    end
    --bNewFace为true的情况下nDecorationID是个table
    model:SetFaceDefinition(tBoneParams, nRoleType, tDecalDefinition, nDecorationID, bNewFace)
end

function PlayerModelView:SetFaceBoneParams(tBoneParams, nRoleType, bNewFace)
    local model = self.m_modelRole["FACE"]
    if not model then
        Log("PlayerModelView SetFaceBoneParams model is not exist")
        return
    end

    model:SetFaceBoneParams(tBoneParams, bNewFace, nRoleType)
end

function PlayerModelView:SetBodyReshapingParams(tBodyParams)
    local model = self.m_modelRole["MDL"]
    if not model then
        Log("PlayerModelView SetBodyReshapingParams model is not exist")
        return
    end

    model:SetBodyReshapingParams(tBodyParams)
end

function PlayerModelView:SetFaceDecals(nRoleType, tDecalDefinition, bNewFace)
    local model = self.m_modelRole["FACE"]
    if not model then
        Log("PlayerModelView SetFaceDecals model is not exist")
        return
    end

    model:SetFaceDecals(nRoleType, tDecalDefinition, bNewFace)
end

function PlayerModelView:SetFacePartID(tDecalDefinition, bNewFace, nRoleType)
    if not self.m_modelRole then return end
    local model = self.m_modelRole["FACE"]
    if not model then
        Log("PlayerModelView SetFaceDecals model is not exist")
        return
    end

    model:SetFacePartID(tDecalDefinition, bNewFace, nRoleType)
end

function PlayerModelView:SetTranslation(x, y, z)
    if not self.m_modelRole then return end
    local mdl = self.m_modelRole["MDL"]
    if mdl then
        self._x, self._y, self._z = x, y, z
        mdl:SetTranslation(x, y, z)
    end
end

function PlayerModelView:GetTranslation()
    return (self._x or 0), (self._y or 0), (self._z or 0)
end

function PlayerModelView:SetYaw(yaw)
    if not self.m_modelRole then return end
    local mdl = self.m_modelRole["MDL"]
    if mdl then
        self._yaw = yaw
        mdl:SetYaw(yaw)
        if self.m_WeaponSocketDynamic then
            self.m_WeaponSocketDynamic:SetYaw(yaw)
        end
        self:UpdateAllEffectCustom(true)
    end
end

function PlayerModelView:GetYaw()
    return (self._yaw or 0)
end

function PlayerModelView:Show(bShow)
    if not self.m_modelRole then
        return
    end
    local mdl = self.m_modelRole["MDL"]
    if mdl then
        local fAlpha = 0
        if bShow then
            fAlpha = 1
        end
        mdl:SetAlpha(fAlpha)
    end
end

local CHARACTER_ROLE_TURN_YAW = math.pi / 54
function PlayerModelView:TouchModel(bTouch, x, y)
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

function PlayerModelView:UpdateFaceDecoration(hPlayer, tRepresentID)
    local bShowFlag = hPlayer.GetFaceDecorationShowFlag()
    local bHide = not bShowFlag
    if bHide and tRepresentID.tFaceData then
        tRepresentID.tFaceData.nDecorationID = 0
    end
end

function PlayerModelView:BeginReshape()
    if not self.bBeginReshape then
        local model = self.m_modelRole["MDL"]
        if not model then
            Log("PlayerModelView BeginReshape model is not exist")
            return
        end
        self.tBodyHighlightIndex = {}
        model:BeginReshape(self.m_nRoleType)
        self.bBeginReshape = true
    end
end

function PlayerModelView:EndReshape()
    if self.bBeginReshape and self.m_modelRole then
        local model = self.m_modelRole["MDL"]
        if not model then
            Log("PlayerModelView EndReshape model is not exist")
            return
        end
        model:EndReshape()
        self.tBodyHighlightIndex = nil
        self.bBeginReshape = false
    end
end

function PlayerModelView:EnableHighlight(nIndex)
    self:BeginReshape()
    local model = self.m_modelRole["MDL"]
    if not model then
        Log("PlayerModelView EnableHighlight model is not exist")
        return
    end
    self.tBodyHighlightIndex[nIndex] = true
    model:EnableHighlight(self.m_nRoleType, nIndex)
end

function PlayerModelView:DisableHighlight(nIndex)
    local model = self.m_modelRole["MDL"]
    if not model then
        Log("PlayerModelView DisableHighlight model is not exist")
        return
    end

    if self.tBodyHighlightIndex[nIndex] then
        self.tBodyHighlightIndex[nIndex] = nil
        model:DisableHighlight(self.m_nRoleType, nIndex)
    end
end

--新捏脸高亮
function PlayerModelView:BeginFaceHighlightMgr()
    if not self.bBeginFaceHighlightMgre then
        local model = self.m_modelRole["FACE"]
        if not model then
            Log("PlayerModelView BeginFaceHighlightMgr model is not exist")
            return
        end
        self.tFaceHighlightIndex = {}
        model:BeginFaceHighlightMgr(self.m_nRoleType)
        self.bBeginFaceHighlightMgre = true
    end
end

function PlayerModelView:EndFaceHighlightMgr()
    if self.bBeginFaceHighlightMgre then
        local model = self.m_modelRole["FACE"]
        if not model then
            Log("PlayerModelView EndFaceHighlightMgr model is not exist")
            return
        end
        model:EndFaceHighlightMgr()
        self.tFaceHighlightIndex = nil
        self.bBeginFaceHighlightMgre = false
    end
end

function PlayerModelView:EnableFaceHighlight(nIndex)
    self:BeginFaceHighlightMgr()
    local model = self.m_modelRole["FACE"]
    if not model then
        Log("PlayerModelView EnableHighlight model is not exist")
        return
    end
    self.tFaceHighlightIndex[nIndex] = true
    model:EnableFaceHighlight(self.m_nRoleType, nIndex)
end

function PlayerModelView:DisableFaceHighlight(nIndex)
    local model = self.m_modelRole["FACE"]
    if not model then
        Log("PlayerModelView DisableFaceHighlight model is not exist")
        return
    end

    if self.tFaceHighlightIndex[nIndex] then
        self.tFaceHighlightIndex[nIndex] = nil
        model:DisableFaceHighlight(self.m_nRoleType, nIndex)
    end
end

function PlayerModelView:GetMdlScale(fnCallBack)
    local mdl = self.m_modelRole["MDL"]
    local UserData = {
        mdl = mdl
    }
    Post3DModelThreadCall(fnCallBack, UserData, mdl, "GetBodyHeightScaleFactor")
end

--把角色模型放到某个制定的图片上的功能（还没用过）
--例：DrawSpecialPlayerModelImage(Helper_GetUIObject("Normal/MentorPanel|Image_GBg4"), 183, "data\\rcdata\\textures\\Wanhua.dds","StandardNew", "loop")
function DrawSpecialPlayerModelImage(hImage, dwPlayerID, szBgPath, szAniName, szLoopType)
    local player 			= GetPlayer(dwPlayerID)
    local modelView		 	= PlayerModelView.new()
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
function PlayerModelView:ClearRes(res)
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

function PlayerModelView:GetPakEquipResource()
    local nRoleType = self:RoleType()
    local tRepresentID = self.m_aOriginalRepresentID
    local tEquipList = {}
    local tEquipSfxList = {}
    if nRoleType and tRepresentID then
        tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    end
    return nRoleType, tEquipList, tEquipSfxList
end

function PlayerModelView:SetLodLevel(nLevel)
    self.nLodLevel = nLevel
end

function PlayerModelView:GetOriginalRepresent()
    return self.m_aOriginalRepresentID
end

function PlayerModelView:PauseAnimation(bPause)
    if not self.m_modelRole or not self.m_modelRole["MDL"] then
        return
    end
    self.m_modelRole["MDL"]:PauseAnimation(bPause)
end

function PlayerModelView:UpdatePuppet(dwPuppet)
    if not dwPuppet or not self.m_modelMgr or not self.m_scene then
        return
    end

    if dwPuppet ~= self.m_dwPuppet then
        self:UnloadPuppet()
    end
    self.m_dwPuppet = dwPuppet

    if self.m_dwPuppet == 0 then
        return
    end

    local puppet = g_tPuppet_info[self.m_nRoleType]
    if not puppet then
        --Log("PlayerModelView LoadPuppet puppet is not exist", self.m_nRoleType)
        return
    end

    if not self.m_modelPuppet then
        local filepath = puppet.path[self.m_dwPuppet]
        if not filepath then
            --Log("PlayerModelView LoadPuppet filepath is not exist", self.m_nRoleType, self.m_dwPuppet)
            return
        end

        local mdl_puppet = self.m_modelMgr:NewModel(filepath, self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, nil, false, false, self.m_aEquipRes.bLoadBDMaterialInHD)
        mdl_puppet:SetMBFurFlag(true)

        local x, y, z = self:GetTranslation()
        mdl_puppet:SetScaling(puppet.scale, puppet.scale, puppet.scale)
        mdl_puppet:SetTranslation(x + puppet.x, y + puppet.y, z + puppet.z)
        self.m_scene:AddRenderEntity(mdl_puppet)

        self.m_modelPuppet = mdl_puppet
    end

    if puppet.ani and puppet.ani ~= "" then
        self.m_modelPuppet:PlayAnimation("loop", puppet.ani, 1.0, 0)
    end
end

function PlayerModelView:UnloadPuppet()
    if not self.m_modelPuppet then
        return
    end
    self:HideMDL(self.m_modelPuppet)
    self.m_modelPuppet:Release()
    self.m_dwPuppet = 0
    self.m_modelPuppet = nil
end

function PlayerModelView:UnloadModelEffect()
    if not self.m_modelEffect then
        return
    end
    for nType, tTable in pairs(self.m_modelEffect) do
        if type(tTable) == "table" then
            self:UnloadModelEffectType(nType)
        end
    end
    self.m_modelEffect = {}
end

function PlayerModelView:UnloadModelEffectType(nType)
    if not self.m_modelEffect then
        return
    end
    local tModel = self.m_modelEffect[nType]
    if not tModel then
        return
    end

    for nIndex, model in pairs(tModel) do
        if nIndex ~= "bDefaultCustomData" then
            model:UnbindFromOther()
            model:Release()
        end
    end
    if nType == PLAYER_SFX_REPRESENT.FOOTPRINT then
        Timer.DelTimer(self, self.nRightFootEffectTimer)
        self.nRightFootEffectTimer = nil
    end
end

function PlayerModelView:AddFootEffect(tSFXInfo, tPosition)
    local modelsfx = self.m_modelMgr:NewModel(tSFXInfo.SfxFile, self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, nil, false, false, self.m_aEquipRes.bLoadBDMaterialInHD)
    modelsfx:SetScaling(tSFXInfo.Scale, tSFXInfo.Scale, tSFXInfo.Scale)

    local mdl = self.m_modelRole["MDL"]
    modelsfx:BindToBone(mdl)
    modelsfx:SetTranslation(tPosition.x, tPosition.y, tPosition.z)
    modelsfx:PlayAnimation("once", "", 1, 0)
    return modelsfx
end

local function SfxBind(modelsfx, mdl, tModelInfo, aNewEquipRes)
    if not modelsfx or not mdl then
        return
    end

    if modelsfx.UnbindFromOther then
        pcall(function()
            modelsfx:UnbindFromOther()
        end)
    end

    local szSocketName = (tModelInfo and tModelInfo.Socket) or ""
    if type(szSocketName) ~= "string" then
        szSocketName = tostring(szSocketName or "")
    end

    local sub = ""
    if szSocketName ~= "" then
        sub = string.lower(string.sub(szSocketName, 1, 2)) or ""
    end

    local Scale = tModelInfo.Scale or 1
    modelsfx:SetScaling(Scale, Scale, Scale)

    if szSocketName ~= "" then
        if sub == "s_" then
            modelsfx:BindToSocket(mdl, szSocketName)
        else
            modelsfx:BindToBone(mdl, szSocketName)
        end
    else
        modelsfx:BindToBone(mdl)
    end
end

function PlayerModelView:SetEffectSfx()
    local tEffect = self.m_aRepresentID.tEffect
    if not tEffect then
        return
    end

    self:UnloadModelEffect()
    self.m_modelEffect = {}
    for nType, tInfo in pairs(tEffect) do
        self.m_modelEffect[nType] =  self.m_modelEffect[nType] or {}
        self:SetAEffectSfx(nType, tInfo)
    end
end

function PlayerModelView:SetAEffectSfx(nType, tInfo)
    local mdl = self.m_modelRole["MDL"]
    if not mdl then
        return
    end
    self:UnloadModelEffectType(nType)
    local aNewEquipRes = self.m_aEquipRes
    local nRepresentID = Table_GetPendantEffectRepresentID(tInfo.nEffectID)
     if nType == PLAYER_SFX_REPRESENT.FOOTPRINT then
        local tSFXRes = Player_GetFootprintResource(nRepresentID, self.m_nRoleType)
        if tInfo.nState == 0 then
            local tSFXInfo = tSFXRes.Idle
            local modelsfx = self:AddFootEffect(tSFXInfo, {x = 0, y = 0, z = 0})
            table.insert(self.m_modelEffect[nType], modelsfx)
        else
            local tSFXInfo = tSFXRes.Left.tResource[tInfo.nState - 1]
            local modelsfx = self:AddFootEffect(tSFXInfo, {x = -50, y = 0, z = 0})
            table.insert(self.m_modelEffect[nType], modelsfx)

            self.nRightFootEffectTimer =  Timer.Add(self, 0.5, function ()
                if not self.m_modelEffect or not self.m_modelEffect[nType] then
                    return
                end

                local tSFXInfo = tSFXRes.Right.tResource[tInfo.nState - 1]
                local modelsfx = self:AddFootEffect(tSFXInfo, {x = 50, y = 0, z = 0})
                table.insert(self.m_modelEffect[nType], modelsfx)
            end)
        end
    else
        local bDefaultCustomData = CharacterEffectData.IsDefaultCustomData(tInfo.tCustomPos)
        local tSFXRes = Player_GetEquipSfxResource(nRepresentID, self.m_nRoleType, bDefaultCustomData)
        for nIndex, tModelInfo in pairs(tSFXRes) do
            local modelsfx
            if tModelInfo.SubType == RL_PLAYER_EQUIP_SFX_SUB_TYPE.LONE_SFX then
                modelsfx = self.m_modelMgr:NewModel(tModelInfo.SfxFile1, self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, false, false, self.m_aEquipRes.bLoadBDMaterialInHD)
            elseif tModelInfo.SubType == RL_PLAYER_EQUIP_SFX_SUB_TYPE.DOUBLE_SFX then
                modelsfx = self.m_modelMgr:NewModel(tModelInfo["SfxFile" .. (tInfo.nState + 1)], self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, false, false, self.m_aEquipRes.bLoadBDMaterialInHD)
            elseif tModelInfo.SubType == RL_PLAYER_EQUIP_SFX_SUB_TYPE.MDL then
                modelsfx = self.m_modelMgr:NewModel(tModelInfo.SfxFile1, self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, false, false, self.m_aEquipRes.bLoadBDMaterialInHD)
                if tInfo.nState == 0 then
                    modelsfx:PlayAnimation("loop", tModelInfo.IdleAni, 1, 0, 0)
                else
                    modelsfx:PlayAnimation("loop", tModelInfo.NotIdleAni, 1, 0, 0)
                end
            end

            if tModelInfo.PositionOnlyFlag then
                modelsfx:SetPositionOnlyFlag(true)
            end

            SfxBind(modelsfx, mdl, tModelInfo, aNewEquipRes)
            self.m_modelEffect[nType][nIndex] = modelsfx
        end
        self:UpdateEffectCustom(nType, tInfo.tCustomPos)
    end
end

--挂件上绑定特效的情况
function PlayerModelView:LoadSocketDynamicEffect(mdl, equipType, aNewEquipRes)
    -- if self.nModelType ~= UI_MODEL_TYPE.COINSHOP then -- 目前只有商城界面显示挂件特效
    --     return
    -- end
    self:UnloadModelSocketDynamicEffect(equipType)
    local tInfo                     = aNewEquipRes[equipType]
    if not tInfo or not tInfo.DynamicSFXID or tInfo.DynamicSFXID == 0 then
        return
    end
    local nRepresentID              = tInfo.DynamicSFXID
    local tModelInfo                = Player_GetSocketDynamicSFXResource(nRepresentID, self.m_nRoleType)
    self.m_modelSocketDynamicEffect[equipType] = self.m_modelSocketDynamicEffect[equipType] or {}
    local modelsfx
    if tModelInfo.SFXType  == RL_PLAYER_SOCKET_DYNAMIC_SFX_TYPE.DOUBLE_SFX then
        modelsfx = self.m_modelMgr:NewModel(tModelInfo.IdleSfxFile, self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, false, false, self.m_aEquipRes.bLoadBDMaterialInHD)
    elseif tModelInfo.SFXType == RL_PLAYER_SOCKET_DYNAMIC_SFX_TYPE.MDL then
        modelsfx = self.m_modelMgr:NewModel(tModelInfo.IdleSfxFile, self.bModLod, false, self.bAdjustByAnimation, self.bMainPlayer, self.nLodLevel, mdl, false, false, self.m_aEquipRes.bLoadBDMaterialInHD)
        modelsfx:PlayAnimation("loop", tModelInfo.IdleAni, 1, 0, 0)
    end
    if not modelsfx then
        return
    end
    SfxBind(modelsfx, mdl, tModelInfo)
    self.m_modelSocketDynamicEffect[equipType] = modelsfx

    self:UpdateDynamicEffectCustom(equipType)
end

function PlayerModelView:UpdateAllEffectCustom(bSetYaw)
    local tAllModel = self.m_modelEffect
    if not tAllModel then
        return
    end
    local tEffect = self.m_aRepresentID.tEffect
    if not tEffect then
        return
    end
    for nType, tModel in pairs(tAllModel) do
        local tInfo = tEffect[nType]
        local tRepresentData = tInfo.tCustomPos
        self:UpdateEffectCustom(nType, tRepresentData, bSetYaw)
    end
end

function PlayerModelView:UpdateEffectCustom(nType, tRepresentData, bSetYaw)
    if not tRepresentData then
        return
    end

    if not self.m_modelEffect then
        return
    end

    local tModel = self.m_modelEffect[nType]
    if not tModel then
        return
    end

    local tInfo = self.m_aRepresentID.tEffect[nType]
    if not tInfo then
        return
    end

    if nType ~= PLAYER_SFX_REPRESENT.SURROUND_BODY then
        return
    end

    self.m_aRepresentID.tEffect[nType].tCustomPos = tRepresentData
    local mdl                   = self.m_modelRole["MDL"]
    local bDefaultCustomData    = CharacterEffectData.IsDefaultCustomData(tRepresentData)
    local bReBind               = false
    if tModel.bDefaultCustomData == nil then
        bReBind = not bDefaultCustomData
    else
        bReBind = tModel.bDefaultCustomData ~= bDefaultCustomData
    end


    local nRepresentID = Table_GetPendantEffectRepresentID(tInfo.nEffectID)
    local tSFXRes = Player_GetEquipSfxResource(nRepresentID, self.m_nRoleType, bDefaultCustomData)

    local tCustomInfo = GetSFXCustomInfo(self.m_nRoleType, tInfo.nEffectID)
    for nIndex, modelsfx in pairs(tModel) do
        if nIndex ~= "bDefaultCustomData" then
            local tModelInfo = tSFXRes[nIndex]
            if bReBind then
                local aNewEquipRes = self.m_aEquipRes
                SfxBind(modelsfx, mdl, tModelInfo, aNewEquipRes)
            end

            if (not bSetYaw) or (bSetYaw and tModelInfo.PositionOnlyFlag) then
                modelsfx:SetPlayerEquipSfxTransform(mdl, nRepresentID, nIndex, self.m_nRoleType, tRepresentData.nOffsetX * tCustomInfo.OffsetMagnification, tRepresentData.nOffsetY * tCustomInfo.OffsetMagnification, tRepresentData.nOffsetZ * tCustomInfo.OffsetMagnification, tRepresentData.fRotationX, tRepresentData.fRotationY, tRepresentData.fRotationZ, tRepresentData.fScale)
            end
        end
    end
    tModel.bDefaultCustomData = bDefaultCustomData
end

local function SetPendantDynamicEffectCustom(model, tRepresentData, tInfo)
    local nOffsetX   = tRepresentData and tRepresentData.nOffsetX   or 0
    local nOffsetY   = tRepresentData and tRepresentData.nOffsetY   or 0
    local nOffsetZ   = tRepresentData and tRepresentData.nOffsetZ   or 0
    local fRotationX = tRepresentData and tRepresentData.fRotationX or 0
    local fRotationY = tRepresentData and tRepresentData.fRotationY or 0
    local fRotationZ = tRepresentData and tRepresentData.fRotationZ or 0
    local fScale     = tRepresentData and tRepresentData.fScale     or 1
    local fCustomScale = fScale * (tInfo.Scale or 1)
    model:SetTranslation(nOffsetX + tInfo.OffsetX, nOffsetY + tInfo.OffsetY, nOffsetZ + tInfo.OffsetZ)
    model:SetEulerRotation(fRotationX, fRotationY, fRotationZ)
    model:SetScaling(fCustomScale, fCustomScale, fCustomScale)
end

function PlayerModelView:UpdateDynamicEffectCustom(nType, tRepresentData)
    if not self.m_modelSocketDynamicEffect then
        return
    end

    local Model = self.m_modelSocketDynamicEffect[nType]
    if not Model then
        return
    end

    local dwPendantType = GetPendantTypeByResEquipType(nType)
    if not dwPendantType then
        return
    end

    if not tRepresentData then
        local tCustomData = self.m_aRepresentID.tCustomRepresentData
        tRepresentData = tCustomData and tCustomData[dwPendantType]
    end

    local aNewEquipRes = self.m_aEquipRes
    local tInfo        = aNewEquipRes[nType]
    if not tInfo or not tInfo.DynamicSFXID or tInfo.DynamicSFXID == 0 then
        return
    end
    local nRepresentID  = tInfo.DynamicSFXID
    local tModelInfo  = Player_GetSocketDynamicSFXResource(nRepresentID, self.m_nRoleType)
    SetPendantDynamicEffectCustom(Model, tRepresentData, tModelInfo)
end

function PlayerModelView:AddExModel(szModelPath, scale)
    self.m_tExModel =  self.m_tExModel or {}
    local model = self.m_modelMgr:NewModel(UIHelper.UTF8ToGBK(szModelPath), true, false, false, true)
    self.m_scene:AddRenderEntity(model)
    model:SetScaling(scale, scale, scale)
    self.m_tExModel[szModelPath] = model
end

function PlayerModelView:RemoveModel(szModelPath)
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