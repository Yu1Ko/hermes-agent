local LoginScene = {}
local self = LoginScene


local szSettingFile = "/ui/Scheme/Setting/LoginSceneSetting.ini"

local _tSetting = nil
local m_scene


local m_tbModelViews = {} --model
local m_tbSFXViews = {} --sfx
local m_bCanSelect

local m_bSceneLoaded = false

local NEXT_LOGIN_STEP = LoginModule.LOGIN_GATEWAY

--TODO luwenhao1 以下三个参数暂未使用
local m_mouse_mdl --鼠标指到的模型
local m_selecting --是否选中角色
local m_fliter_id = 0 --筛选ID

local m_nNowSceneID = 1
local m_nDefaultSceneID = 1

local m_tbScenePresetSfxModel = {}

function LoginScene.RegisterEvent()

end

function LoginScene.OnEnter(szPrevStep)
    self._initLoginScene() --初始化登录场景

    if not g_tbLoginData.bReLoginToRoleListFlag then
        LoginMgr.SwitchStep(NEXT_LOGIN_STEP)
    else
        local moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
        moduleGateway.ConnectGateway()
    end
end

function LoginScene.OnExit(szNextStep)

end

function LoginScene.OnClear()
    -- 清理创建的3D模型, 避免无法退出

    --Login_Restore3DOption() --TODO luwenhao1 这是啥

    self.UnloadModel()
    self.UnloadSFX()
    --LoginNpcMgr_ReleaseAll() --TODO luwenhao1 这是啥

    SceneMgr.DeleteCurScene()
    SceneMgr.SetScene(nil)
    m_scene = nil

    ResponseMgr_SetShowModelByEngine(false)
    --LoginMovie_Stop() --TODO luwenhao1 这是啥

    m_bSceneLoaded = false
end


-------------------------------- Public --------------------------------

function LoginScene.GetScene()
    return m_scene
end

function LoginScene.PreLoadLoginScene()
    self._initLoginScene() --初始化登录场景
end

function LoginScene.SceneChange(tInfo , bForceChange)
    if m_nNowSceneID ~= tInfo.nID or bForceChange then
        m_nNowSceneID = tInfo.nID
        m_scene:ResetEnvironment(tInfo.szMapName)
    end
end

function LoginScene.SceneDefault()
    local tInfo = Table_GetLoginSceneInfo(m_nDefaultSceneID)
    LoginScene.SceneChange(tInfo)
end

function LoginScene.GetChooseScene()
    return m_nNowSceneID
end

-------- SFX -------- TODO luwenhao1 SFX暂未使用

function LoginScene.LoadSFX(key, file)
    local model_mgr = KG3DEngine.GetModelMgr()
    local model = model_mgr:NewModel(file)
    m_scene:AddRenderEntity(model)
    m_tbSFXViews[key] = model
    return model
end

function LoginScene.GetSFX(key)
    return m_tbSFXViews[key]
end

function LoginScene.PlaySFX(key, play_type)
    local sfx = m_tbSFXViews[key]
    if sfx then
        sfx:PlayAnimation(play_type, "", 1.0, 0)
    end
end

function LoginScene.UnloadSFX(key)
    if not key then
        for k, v in pairs(m_tbSFXViews) do
            m_scene:RemoveRenderEntity(v)
            v:Release()
            m_tbSFXViews[k] = nil
        end
    else
        local sfx = m_tbSFXViews[key]
        if sfx then
            m_scene:RemoveRenderEntity(sfx)
            sfx:Release()
            m_tbSFXViews[key] = nil
        end
    end
end

-- 场景预设特效
function LoginScene.LoadScenePresetSFX(file, tbPosition , tbRotation , tbScale)
    local model = LoginScene.LoadSFX("LoginSceneEnvPreset", file)
    if model then
        model:SetTranslation(tbPosition[1], tbPosition[2], tbPosition[3])
        model:SetRotation(tbRotation[1], tbRotation[2], tbRotation[3] , 1)
        model:SetScaling(tbScale[1], tbScale[2], tbScale[3])
        table.insert(m_tbScenePresetSfxModel , model)
    end
    return model
end

function LoginScene.UnLoadScenePresetSFX()
    m_tbSFXViews["LoginSceneEnvPreset"] = nil
    for k, v in pairs(m_tbScenePresetSfxModel) do
        if m_scene then
            m_scene:RemoveRenderEntity(v)
        end
        v:Release()
    end
end

-------- Model --------

function LoginScene.GetModel(nModelType)
    return m_tbModelViews[nModelType]
end

function LoginScene.LoadModel(nModelType, tRoleID, bClearWeapon)
    local modelView = m_tbModelViews[nModelType]
    if modelView then
        return modelView
    end

    local rep_ids = tRoleID.RepresentData or self._formatRepresentData(tRoleID)
    rep_ids.key = tRoleID.key or SCHOOL_TYPE_TO_NAME[tRoleID.dwSchoolID]
    modelView = PlayerModelView.CreateInstance(PlayerModelView)

    modelView:init(nil, nil, m_scene, m_bCanSelect)
    modelView:LoadModuleRes(tRoleID.RoleType, tRoleID.dwSchoolID, rep_ids, bClearWeapon)
    modelView:LoadModel()
    --modelView:PlayAnimation("Standard", "loop")
    modelView:PlayAnimation("Idle", "loop")
    modelView:RegisterEventHandler()

    m_tbModelViews[nModelType] = modelView
    return modelView
end

function LoginScene.UnloadModel(nModelType)
    if not nModelType then
        m_mouse_mdl = nil

        for k, v in pairs(m_tbModelViews) do
            v:release()
            m_tbModelViews[k] = nil
        end
        m_selecting = nil
    else
        local modelView = m_tbModelViews[nModelType]
        if modelView then
            if modelView:Mdl() == m_mouse_mdl then
                m_mouse_mdl = nil
            end

            modelView:release()
            m_tbModelViews[nModelType] = nil
        end
    end
end

-------------------------------- Protocol --------------------------------

-------------------------------- Private --------------------------------

local function GetSceneParam()
    if _tSetting then
        return _tSetting
    end
    local pFile = Ini.Open(szSettingFile)
    if not pFile then
        return
    end

    local szSection = "Main_mb"
    _tSetting = {}
    _tSetting.szSceneFile = pFile:ReadString(szSection, "Scene" , "")
    _tSetting.pos_x = pFile:ReadFloat(szSection, "PosX" , 0)
    _tSetting.pos_y = pFile:ReadFloat(szSection, "PosY" , 0)
    _tSetting.pos_z = pFile:ReadFloat(szSection, "PosZ" , 0)

    pFile:Close()

    return _tSetting
end

function LoginScene._initLoginScene()
    if m_bSceneLoaded then
        return
    end

    LOG.INFO("--------------------Scene_New--------------------")

    if Const.USE_NEW_LOGIN_SCENE then
        local tInfo = GetSceneParam()
        m_scene = SceneMgr.NewScene(tInfo.szSceneFile, false, 1000000, tInfo.pos_x,  tInfo.pos_y, tInfo.pos_z)
    else
        local m_szScenePath = UTF8ToGBK("data\\source\\maps\\HD登陆界面_刀宗001\\HD登陆界面_刀宗001.jsonmap")
        m_scene = SceneMgr.NewScene(m_szScenePath, false, 1000000, 133058, 4267, 35417)
    end
    SceneMgr.SetScene(1000000)

    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    moduleCamera.InitSceneCamera(m_scene)
    moduleCamera.SetCameraStatus(LoginCameraStatus.LOGIN)

    ResponseMgr_SetShowModelByEngine(true)
    LOG.INFO("--------------------Scene_End--------------------")

    m_bSceneLoaded = true
    SoundMgr.LockBgMusic(false)
    SoundMgr.PlayBgMusic(Table_GetPath("LOGIN_BGM_NEW"))
end

function LoginScene._formatRepresentData(tRoleEquipID, outputRepresent)
    local aRepresent = {}
    local aKeyList = {
        "FaceStyle",
        "HairStyle",
        "HelmStyle",        "HelmColor",        "HelmEnchant",
        "ChestStyle",       "ChestColor",       "ChestEnchant",
        "WaistStyle",       "WaistColor",       "WaistEnchant",
        "BangleStyle",      "BangleColor",      "BangleEnchant",
        "BootsStyle",       "BootsColor",
        "WeaponStyle",      "WeaponColor",      "WeaponEnchant1",  "WeaponEnchant2",
        "BigSwordStyle",    "BigSwordColor",    "BigSwordEnchant1",  "BigSwordEnchant2",
        "BackExtend",       "WaistExtend",
        "HorseStyle",       "HorseAdornment1",  "HorseAdornment2",
        "HorseAdornment3",  "HorseAdornment4",  "FaceExtend",
        "LShoulder",		"RShoulder",        "Cloak",
        "CloakColor1",      "CloakColor2",      "CloakColor3", "PantsStyle", "PantsColor",
        "Reserved"
    }

    if outputRepresent then
        for i = 1, #aKeyList do
            local nVal = tRoleEquipID[aKeyList[i]]
            if nVal then
                outputRepresent[i - 1] = nVal
            end
        end
        return
    end

    for i = 1, #aKeyList do
        aRepresent[i - 1] = tRoleEquipID[aKeyList[i]]
    end

    aRepresent.bUseLiftedFace = tRoleEquipID.bUseLiftedFace
    aRepresent.bNewFace = tRoleEquipID.bNewFace
    aRepresent.tFaceData = tRoleEquipID.tFaceData
    for i = 0, EQUIPMENT_REPRESENT.TOTAL - 1, 1 do
        if not aRepresent[i] then
            aRepresent[i] = 0
        end
    end

    if tRoleEquipID.tCloth then
        for key, value in pairs(tRoleEquipID.tCloth) do
            local bShowHair = (key ~= 1 and key ~= EQUIPMENT_REPRESENT.HELM_STYLE and key ~= EQUIPMENT_REPRESENT.HELM_COLOR) or (not BuildHairData.bChangeHairPat)
            local bShowBodyAndFace = not UIMgr.GetView(VIEW_ID.PanelBuildFace_Step2)
            if IsNumber(key) then
                if bShowHair then
                    aRepresent[key] = value
                end
            elseif bShowBodyAndFace then
                aRepresent[key] = value
            end
        end
    end
    BuildHairData.bChangeHairPat = false

    aRepresent.tBody = tRoleEquipID.tBody
    -- aRepresent.tHairDyeingData = tRoleEquipID.tHairDyeingData

    return aRepresent
end


-- function LoginScene._setFliterMDL(nModelType)
--     if not nModelType then
--         m_fliter_id = 0
--     end

--     local modelView = self.GetModel(nModelType)
--     if modelView then
--         local model = modelView:Mdl()
--         local id = KG3DEngine.ModelToID(model)
--         m_fliter_id = id or 0
--     end
-- end

-- --在鼠标x,y位置找到选中的角色模型
-- function LoginScene._searchModel(x, y, bSel)
--     if m_bCanSelect then
--         m_selecting = true
--         bSel = bSel or false
--         PostThreadCall(self._onSearchModel, bSel, "Scene_SelectModel", KG3DEngine.SceneToID(m_scene), x, y, m_fliter_id)
--     end
-- end

-- function LoginScene._onSearchModel(bSel, model_id)
--     m_selecting = nil
--     if not model_id or model_id == 0 then
--         if m_mouse_mdl then
--             --FireUIEvent("LOGIN_LEAVE_MODLE", m_mouse_mdl)
--             Event.Dispatch("LOGIN_LEAVE_MODLE", m_mouse_mdl)
--             --Character_SetOutline( KG3DEngine.ModelToID(m_mouse_mdl), 0, 0, 0,  0, 0, true )
--         end
--         return
--     end

--     local model = KG3DEngine.IDToModel(model_id)
--     if model and bSel then
--         for key, v in pairs(m_tbModelViews) do
--             if v:Mdl() == model then
--                 --FireUIEvent("LOGIN_SEL_MODLE", key, v:RoleType())
--                 Event.Dispatch("LOGIN_SEL_MODLE", key, v:RoleType())
--                 -- dbg_call("ShowMld", Station.Lookup("Lowest/LoginScene"), v)
--                 -- dbg_value("mdlview", v)
--                 break
--             end
--         end
--     end
--     m_mouse_mdl = model
--     -- FireUIEvent("LOGIN_ENTER_MODLE", model)
--     Event.Dispatch("LOGIN_ENTER_MODLE", model)
--     --Character_SetOutline(model_id, 1, 160, 240,  240, 50, true)
-- end

-- function LoginScene._enableSelect(enable)
--     m_bCanSelect = enable
--     m_selecting = nil
-- end


return LoginScene