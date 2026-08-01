local LoginRole = {className = "LoginRole"}
local self = LoginRole

local m_tbSchoolData

local m_nKungfuID, m_nRoleType

--默认参数
local m_nFace = 1
local m_nHair = 1
local m_nBang = 1
local m_nPlait = 1
local m_nDress = 1
local m_nBoots = 1
local m_nBangle = 1
local m_nWaist = 1
local m_nWeapon = 1

local m_tbBodyType =
{
    m1 = ROLE_TYPE.LITTLE_BOY,
    m2 = ROLE_TYPE.STANDARD_MALE,
    f1 = ROLE_TYPE.LITTLE_GIRL,
    f2 = ROLE_TYPE.STANDARD_FEMALE,
}

local m_tbDefenseKunfuID = {
    [1] = true,
    [3] = true,
    [9] = true,
    [11] = true,
}

local m_tbKungfuTypeName = {
    [1] = "输出",
    [2] = "治疗",
    [3] = "防御",
}

local m_tbSchoolWeaponType =
{
    -- 改为读CreateRole_Param表初始化
    -- ["cy"] = WEAPON_DETAIL.SWORD,
    -- ["wh"] = WEAPON_DETAIL.PEN,
    -- ["tm"] = WEAPON_DETAIL.BOW,
    -- ["wd"] = WEAPON_DETAIL.FLUTE,
    -- ["tc"] = WEAPON_DETAIL.SPEAR,
    -- ["cj"] = WEAPON_DETAIL.SWORD,
    -- ["sl"] = WEAPON_DETAIL.WAND,
    -- ["qx"] = WEAPON_DETAIL.DOUBLE_WEAPON,
    -- ["mj"] = WEAPON_DETAIL.KNIFE,
    -- ["gb"] = WEAPON_DETAIL.STICK,
    -- ["cangyun"] = WEAPON_DETAIL.BLADE_SHIELD,
    -- ["changge"] = WEAPON_DETAIL.HEPTA_CHORD,
    -- ["badao"] = WEAPON_DETAIL.BROAD_SWORD,
    -- ["penglai"] = WEAPON_DETAIL.UMBRELLA,
    -- ["lxg"] = WEAPON_DETAIL.CHAIN_BLADE,
    -- ["ytz"] = WEAPON_DETAIL.SOUL_LAMP,
    -- ["btyz"] = WEAPON_DETAIL.SCROLL,
    -- ["dz"] = WEAPON_DETAIL.MASTER_BLADE,
    -- ["wl"] = WEAPON_DETAIL.LONGBOW,
    -- ["ds"] = WEAPON_DETAIL.FAN,
}


local m_tbHotSchool = {   --创角门派热门图标配置，可以在UIDef.lua查看门派定义
    KUNGFU_ID.YAO_ZONG,
    KUNGFU_ID.TANG_MEN,
    KUNGFU_ID.WAN_HUA,
}

function LoginRole.IsHotSchool(nKungfuID)
    return table.contain_value(m_tbHotSchool, nKungfuID)
end


function LoginRole.RegisterEvent()
    LoginMgr.RegisterLoginNotify(LOGIN.CREATE_ROLE_SUCCESS, self.OnCreateRoleSuccess)

    local tbFailEventList = {
        -- LOGIN.CREATE_ROLE_SUCCESS,                      -- "创建角色成功"
        LOGIN.CREATE_ROLE_NAME_EXIST,                   -- "创建失败,角色名已存在"
        LOGIN.CREATE_ROLE_INVALID_NAME,                 -- "创建失败,角色名非法"
        LOGIN.CREATE_ROLE_NAME_TOO_LONG,                -- "创建失败,角色名太长"
        LOGIN.CREATE_ROLE_NAME_TOO_SHORT,               -- "创建失败,角色名太短"
        LOGIN.CREATE_ROLE_NEED_OLD_ROLE_MAX_LEVEL,      -- "创建失败，需要至少拥有大于XX级的角色"
        LOGIN.CREATE_ROLE_LIMIT_BY_IP,                  -- "创建失败，此IP无法创建新角色"
        LOGIN.CREATE_ROLE_UNABLE_TO_CREATE,             -- "创建失败,无法创建角色"
    }

    for i = 1, #tbFailEventList do
        local nEvent = tbFailEventList[i]
        LoginMgr.RegisterLoginNotify(nEvent, function()
            self.OnCreateRoleFail(nEvent)
        end)
    end
end

function LoginRole.OnEnter(szPrevStep)
    -- 如果服务器不让创角
    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    if not moduleServerList.CanCreateRole() then
        LoginMgr.ErrorMsg(self, LoginEventName[LOGIN.CREATE_ROLE_UNABLE_TO_CREATE])
        LoginMgr.BackToLogin()
        return
    end

    UIMgr.Open(VIEW_ID.PanelSchoolSelect)
    UIMgr.Close(VIEW_ID.PanelLogin)
    UIMgr.Close(VIEW_ID.PanelResourcesDownload)
    if szPrevStep ~= LoginModule.LOGIN_ENTERGAME then
        self.szPrevStep = szPrevStep
    end

    -- local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    -- moduleCamera.SetCameraStatus(LoginCameraStatus.ROLE_LIST)

    Event.Reg(self, EventType.OnUpdateBuildFaceModule, function(tbParams, bNotYaw)
        self._updateBuildFaceModule(tbParams, bNotYaw)
    end)
end

function LoginRole.OnExit(szNextStep)
    UIMgr.Close(VIEW_ID.PanelSchoolSelect)

    if szNextStep ~= LoginModule.LOGIN_ENTERGAME then
        self._clearRoleModel()
    else
        m_nKungfuID = nil
        m_nRoleType = nil
    end

    BuildFaceData.UnInit()
    BuildHairData.UnInit()
    BuildBodyData.UnInit()

    if szNextStep ~= LoginModule.LOGIN_ROLELIST and szNextStep ~= LoginModule.LOGIN_ENTERGAME then
        local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
        moduleCamera.SetCameraStatus(LoginCameraStatus.LOGIN)
    end
end

-------------------------------- Public --------------------------------

function LoginRole.BackToPrevStep()
    LoginMgr.SwitchStep(self.szPrevStep)
end

function LoginRole.InitRoleModel(nKungfuID, nRoleType)
    if nKungfuID == m_nKungfuID and nRoleType == m_nRoleType then return end
    m_nKungfuID = nKungfuID
    m_nRoleType = nRoleType

    BuildFaceData.UnInit()
    BuildHairData.UnInit()
    BuildBodyData.UnInit()

    local aRepresent = {}

    BuildFaceData.Init({
        nRoleType = nRoleType,
        bPrice = false,
        nMaxDecalCount = 24,
        nMaxDefaultCount = 15,
        nMaxBoneDefaultCount = 24,
    })

    BuildHairData.Init({
        nRoleType = nRoleType,
        nKungfuID = nKungfuID,
        bPrice = false,
    })

    BuildBodyData.Init({
        nRoleType = nRoleType,
        bPrice = false,
        aRepresent = aRepresent or {},
    })

end

function LoginRole.UpdateRoleModel()
    if not m_nKungfuID or not m_nRoleType then
        return
    end

    -- --改为读配置表，详见端游LoginCustomRole.lua: 1651
    local szSchool = KUNGFU_IDToSchool[m_nKungfuID]
    local tbRes = self._getModelConfig(m_nRoleType, szSchool)
    --local tbRes = self._getJHEquipIDS(m_nRoleType, szSchool)

    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)

    --引擎那边做了处理来避免部件加载不一致导致闪烁，不缓存模型对象，每次切门派都重新创建
    moduleScene.UnloadModel()
    local modelView = moduleScene.LoadModel(LoginModel.FORCE_ROLE, tbRes)

    local szSchool = KUNGFU_IDToSchool[m_nKungfuID]
    modelView:SetWeaponVisible("RL_WEAPON_RH", szSchool ~= "changge")

    if modelView then
        --设置模型位置
        if BuildFaceData.GetInBuildMode() then
            self._updateBuildFaceModule(g_tBuildFaceCameraStep1)
            modelView:PlayAniID(60211, "loop")
        else
            modelView:SetTranslation(g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)
            modelView:SetYaw(g_tRoleListPos.yaw)

            local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
            if moduleCamera.GetCamera() then
                moduleCamera.GetCamera():set_mainplayer_pos(g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)
            end

            --播放动画
            local id = self._getSchoolData(szSchool, m_nRoleType, "idle_ani")
            modelView:PlayAniID(id, "loop")
        end
    end

    self.UpdateModelScale()
end


--门派定位 如：外功近战输出，高群攻，高机动性
function LoginRole.GetSchoolSpecialty(nForceID)
    local tbInfo = self.GetCreateRoleParam(nForceID)
    return UIHelper.GBKToUTF8(tbInfo.szIntroduce), UIHelper.GBKToUTF8(tbInfo.szIntroduce1)
end


function LoginRole.GetCreateRoleParam(nForceID)

    if not self.tbRoleParam then
        self.tbRoleParam = Table_GetCreateRoleParam()
    end
    return self.tbRoleParam[KUNGFU_IDToSchool[nForceID]]
end

function LoginRole.UpdateModelScale()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    if not moduleScene or not moduleCamera then return end

    local modelView = moduleScene.GetModel(LoginModel.FORCE_ROLE)
    if not modelView then return end

    modelView:GetMdlScale(function (_, _, fScale)
        moduleCamera.SetModelScale(fScale, m_nRoleType)
    end)
end

function LoginRole.ResetModelScale()
    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    moduleCamera.SetModelScale(1, m_nRoleType)
end

-------------------------------- Protocol --------------------------------

function LoginRole.CreateRole(nRoleType, nForceID, szRoleName)
    if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.CRATING_ROLE) then return end

    -- local szRoleName = RandomName(nRoleType)
    self.szRoleName = szRoleName
    local moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
    local dwMapID, nMapCopyIndex = moduleGateway.GetSelectedHomeplaceInfo()
    local nKungfuID = nForceID or 3

    local tbRoleEquip = self._getRoleEquip(nRoleType, nKungfuID)
    local tbFaceData = BuildFaceData.tNowFaceData or self._getDefaultFace(nRoleType)
    local nCostTime = 0.1

    LoginMgr.Log(self, "CreateRole RoleName = %s, KungfuID", szRoleName, nKungfuID)

    local nRetCode = GetFaceLiftManager().CheckValid(nRoleType, tbFaceData)
    if nRetCode ~= FACE_LIFT_ERROR_CODE.SUCCESS then
        local szMsg = g_tStrings.tNewFaceLiftNotify[nRetCode]
        TipsHelper.ShowNormalTip(szMsg)
        LoginMgr.SetWaiting(false)
        return
    end

    local tBodyData = BuildBodyData.tNowBodyData

    if tBodyData then
        local nRetCode = GetBodyReshapingManager().CheckValid(nRoleType, tBodyData)
        if nRetCode ~= BODY_RESHAPING_ERROR_CODE.SUCCESS then
            local szMsg = g_tStrings.tBodyCheckNotify[nRetCode]
            TipsHelper.ShowImportantRedTip(szMsg)
        else
            Login_CreateRole(UIHelper.UTF8ToGBK(szRoleName), nRoleType, dwMapID, nMapCopyIndex, nKungfuID, tbRoleEquip, tbFaceData, nCostTime, tBodyData)
        end
        return
    end

    Login_CreateRole(UIHelper.UTF8ToGBK(szRoleName), nRoleType, dwMapID, nMapCopyIndex, nKungfuID, tbRoleEquip, tbFaceData, nCostTime)
end

function LoginRole.OnCreateRoleSuccess()
    self.szRoleName = arg3
    LoginMgr.Log(self, "OnCreateRoleSuccess")
    LoginMgr.SetWaiting(false)
    if not UIMgr.GetView(VIEW_ID.PanelModelVideo) then
        UIMgr.Open(VIEW_ID.PanelModelVideo, self.szRoleName)
    end
    UIMgr.Close(VIEW_ID.PanelSchoolSelect)
    UIMgr.Close(VIEW_ID.PanelBuildFace)
    UIMgr.Close(VIEW_ID.PanelBuildFace_Step2)
    UIMgr.Close(VIEW_ID.PanelCreateName_Login)
    UIMgr.Close(VIEW_ID.PanelShareStation)
end

function LoginRole.OnCreateRoleFail(nEvent)
    LoginMgr.Log(self, "OnCreateRoleFail %d", nEvent)
    LoginMgr.SetWaiting(false)

    local szMessage = LoginEventName[nEvent]
    local szRoleName = self.szRoleName
    local _, _, ver = GetVersion()
    if ver == "zhcn" and szRoleName and not IsSimpleChineseString(UIHelper.UTF8ToGBK(szRoleName)) then
        szMessage = g_tStrings.tbLoginString.CREATE_NAME_ERROR
    end

    --错误提示
    LoginMgr.ErrorMsg(self, szMessage)

    if g_tbLoginData.LoginView then
        g_tbLoginData.LoginView:Logout()
    end
end

function LoginRole.OnEnterGame()
    UIMgr.Close(VIEW_ID.PanelModelVideo)

    local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
    if moduleRoleList then
        moduleRoleList.UpdateRoleCount()
        moduleRoleList.UpdateValues()
    end

    NewFaceData.DelCacheCreateRoleFaceData()

    PakDownloadMgr.DownloadCoreList() --创角后下载核心队列

    --arg3:RoleName
    local szRoleName = self.szRoleName
    local nState, _, _ = PakDownloadMgr.GetBasicPackState(true)
    if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
        LoginMgr.SwitchStep(LoginModule.LOGIN_ENTERGAME, szRoleName)
    else
        --若未下载完成回到选角界面
        LoginMgr.SwitchStep(LoginModule.LOGIN_ROLELIST, szRoleName)
    end
end

function LoginRole.JudgeSchoolHasRoleType(szSchool, nRoleType)
    if not m_tbSchoolData then
        m_tbSchoolData = self._loadSchoolData()
    end

    local tab = m_tbSchoolData[szSchool][nRoleType]
    if tab then
        -- 体服，段氏只显示成男体型 by qinghu 2024.9.23
        -- if nRoleType ~= ROLE_TYPE.STANDARD_MALE and Version.IsEXP() and szSchool == KUNGFU_IDToSchool[KUNGFU_ID.DUAN_SHI] then
        --     return false
        -- end

        return true
    end
    return false
end

-------------------------------- Private --------------------------------

function LoginRole._loadSchoolData()
    local tSchool
    local tResult = {}
    local nRow = g_tTable.LoadSchoolData:GetRowCount()
    for i = 2, nRow, 1 do
        tSchool = g_tTable.LoadSchoolData:GetRow(i)

        if not tResult[tSchool.key] then
            tResult[tSchool.key] = {}
        end
        if tSchool.role_type and tSchool.role_type ~= "" and tSchool.key then
            tResult[tSchool.key][m_tbBodyType[tSchool.role_type]] = tSchool
        end
    end
    return tResult;
end



function LoginRole._getSchoolData(szSchool, nRoleType, szKey)
    if not m_tbSchoolData then
        m_tbSchoolData = self._loadSchoolData()
    end

    local tab = m_tbSchoolData[szSchool][nRoleType]
    if not tab then
        --取第一个
        for _, value in pairs(m_tbSchoolData[szSchool]) do
            tab = value
            break
        end
    end
    if szKey and tab then
        return tab[szKey]
    end
    return tab
end

function LoginRole.convertBodyType(szRole_type)
    return m_tbBodyType[szRole_type]
end

function LoginRole._getModelConfig(nRoleType, szSchool)
    local tbSchoolData = self._getSchoolData(szSchool, nRoleType)
    if not tbSchoolData then
        LOG.ERROR("Get School Data Error: nRoleType: %d, szSchool = %s", nRoleType, szSchool)
    end

    local tbRes = clone(tbSchoolData)
    tbRes.RoleType = nRoleType
    tbRes.FaceStyle = g_tStrings.tFace[nRoleType][m_nFace]
    if tbRes.HairStyle == 0 then
        tbRes.HairStyle = g_tStrings.tHair[nRoleType][m_nHair].HeadForm
    end

    tbRes.bUseLiftedFace = true
    tbRes.bNewFace = true
    tbRes.tFaceData = self._getDefaultFace(nRoleType, true)

    if BuildFaceData.GetInBuildMode() then
        -- 更新发型
        local nSelectHairStyle = BuildHairData.GetSelectedHairStyle()
        if nSelectHairStyle then
            tbRes.HelmStyle = 0
            tbRes.HairStyle = nSelectHairStyle
        end

        tbRes.WeaponStyle = 0
        tbRes.BigSwordStyle = 0

        -- 更新脸型
        local tFaceData = BuildFaceData.tNowFaceData
        tbRes.tFaceData = Lib.copyTab(tFaceData)

        -- 更新体型
        local tBodyData = BuildBodyData.tNowBodyData
        tbRes.tBody = Lib.copyTab(tBodyData)

        if BuildBodyData.tNowCloth then
            tbRes.tCloth = Lib.copyTab(BuildBodyData.tNowCloth)
        end
    end

    return tbRes
end

function LoginRole._getJHEquipIDS(nRoleType, szSchool)
    local aRoleEquip = {}

    aRoleEquip["RoleType"] = nRoleType
    aRoleEquip["FaceStyle"] = g_tStrings.tFace[nRoleType][m_nFace]
    aRoleEquip["HairStyle"] = g_tStrings.tHair[nRoleType][m_nHair].HeadForm
    aRoleEquip["ChestStyle"] = g_tStrings.tDress[nRoleType][m_nDress][1]
    aRoleEquip["ChestColor"] = g_tStrings.tDress[nRoleType][m_nDress][2]
    aRoleEquip["BootsStyle"] = g_tStrings.tBoots[nRoleType][m_nBoots][1]
    aRoleEquip["BootsColor"] = g_tStrings.tBoots[nRoleType][m_nBoots][2]
    aRoleEquip["BangleStyle"] = g_tStrings.tBangle[nRoleType][m_nBangle][1]
    aRoleEquip["BangleColor"] = g_tStrings.tBangle[nRoleType][m_nBangle][2]
    aRoleEquip["WaistStyle"] = g_tStrings.tWaist[nRoleType][m_nWaist][1]
    aRoleEquip["WaistColor"] = g_tStrings.tWaist[nRoleType][m_nWaist][2]
    aRoleEquip["WeaponStyle"] = g_tStrings.tWeapon[nRoleType][m_nWeapon]

    aRoleEquip["LShoulder"] = g_tStrings.tLShoulder[nRoleType][1]
    aRoleEquip["RShoulder"] = g_tStrings.tRShoulder[nRoleType][1]
    aRoleEquip["Cloak"] = g_tStrings.tLCloak[nRoleType][1]

    if szSchool then
        aRoleEquip["WeaponStyle"]= self._getWeaponType(szSchool)
    end
    return aRoleEquip
end

function LoginRole._getWeaponType(szSchool)
    if table.is_empty(m_tbSchoolWeaponType) then
        m_tbSchoolWeaponType = {}
        local tInfo = Table_GetCreateRoleParam()
        for szSchoolType, tLine in pairs(tInfo or {}) do
            m_tbSchoolWeaponType[szSchoolType] = WEAPON_DETAIL[tLine.szWeaponType]
        end
    end

    if szSchool == "cj" then
        return WEAPON_DETAIL.BIG_SWORD
    elseif szSchool then
        return	m_tbSchoolWeaponType[szSchool]
    end
end

function LoginRole._getRoleEquip(nRoleType, nForceID)
    local tbRoleEquip = {}

    local nFace = 1
    local szSchool = KUNGFU_IDToSchool[nForceID]
    local tBodyType = {"Hair", "Bang", "Plait", }
    local tClothData = {}
    for _, szType in ipairs(tBodyType) do
        tClothData["n" .. szType] = 1
    end

    local tHair = g_tStrings.tHair
    if szSchool == "sl" then
        tHair = g_tStrings.tShaoLinHair
    end

    local tRoleTypeMap =
    {
        m1 = ROLE_TYPE.LITTLE_BOY,
        m2 = ROLE_TYPE.STANDARD_MALE,
        f1 = ROLE_TYPE.LITTLE_GIRL,
        f2 = ROLE_TYPE.STANDARD_FEMALE,
    }

    local tRoleData = {}
    for k, v in ipairs(UILoginCreateDataTab) do

        local school = v.key
        if not tRoleData[school] then tRoleData[school] = {} end
        tRoleData[school][tRoleTypeMap[v.role_type]] = v
    end


    -- local tRoleData = m_tRoleData[szSchool][nRoleType]

    tbRoleEquip[EQUIPMENT_REPRESENT.FACE_STYLE] = g_tStrings.tFace[nRoleType][nFace]
    tbRoleEquip[EQUIPMENT_REPRESENT.HAIR_STYLE] = tHair[nRoleType][tClothData.nHair].HeadForm

    local nSelectHairStyle = BuildHairData.GetSelectedHairStyle()
    if nSelectHairStyle then
        tbRoleEquip[EQUIPMENT_REPRESENT.HAIR_STYLE] = nSelectHairStyle
    end

    local tEquipType =
    {
        [EQUIPMENT_REPRESENT.CHEST_STYLE] = "ChestStyle",
        [EQUIPMENT_REPRESENT.CHEST_COLOR] = "ChestColor",
        [EQUIPMENT_REPRESENT.WAIST_STYLE] = "BootsStyle",
        [EQUIPMENT_REPRESENT.WAIST_COLOR] = "BootsColor",
        [EQUIPMENT_REPRESENT.BANGLE_STYLE] = "BangleStyle",
        [EQUIPMENT_REPRESENT.BANGLE_COLOR] = "BangleColor",
        [EQUIPMENT_REPRESENT.BOOTS_STYLE] = "WaistStyle",
        [EQUIPMENT_REPRESENT.BOOTS_COLOR] = "WaistColor",
        [EQUIPMENT_REPRESENT.WEAPON_STYLE] = "WeaponStyle",
        [EQUIPMENT_REPRESENT.WEAPON_COLOR] = "WeaponColor",
        [EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND] = "LShoulder",
        [EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND] = "RShoulder",
        [EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = "Cloak",
        [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = "BigSwordStyle",
        [EQUIPMENT_REPRESENT.BIG_SWORD_COLOR] = "BigSwordColor",
    }

    for nIndex, szType in pairs(tEquipType) do
        tbRoleEquip[nIndex] = tRoleData[szType]
    end

    return tbRoleEquip
end

function LoginRole._getDefaultFace(nRoleType, bNewFace)
    local tFaceList, tDefault = Table_GetOfficalFaceList(nRoleType, false)
    local szPath = tDefault.szPath

    if bNewFace then
        tFaceList, tDefault = Table_GetOfficalFaceV2List(nRoleType, false)
        szPath = tDefault.szFilePath
    end

    local tBoneParams, tDecals, nDecorationID = KG3DEngine.GetFaceDefinitionFromINIFile(szPath, bNewFace)
    local tFaceData = {}
    tFaceData.tBone = tBoneParams
    tFaceData.tDecal = tDecals
    if bNewFace then
        tFaceData.tDecoration = nDecorationID
    else
        tFaceData.nDecorationID = nDecorationID
    end
    tFaceData.bNewFace = bNewFace
    return tFaceData
end

function LoginRole._clearRoleModel()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    moduleScene.UnloadModel()
    moduleScene.UnloadSFX()
    m_nKungfuID = nil
    m_nRoleType = nil
end

function LoginRole._getBodyData()
    local tbBodyData = {}
    for k, v in ipairs(UILoginCreateDataTab) do
        local school = v.key
        if not tbBodyData[school] then
            tbBodyData[school] = {}
        end
        table.insert(tbBodyData[school],v.role_type)
    end
-- 纯阳：标男
-- 少林：正太
-- 七秀：标女
-- 天策：标男
-- 万花：萝莉
    -- tbBodyData = {
    --     ['cy'] = {"m2"},
    --     ['sl'] = {"m1"},
    --     ['qx'] = {"f2"},
    --     ['tc'] = {"m2"},
    --     ['wh'] = {"f1"},
    -- }
    return tbBodyData
end

function LoginRole._updateBuildFaceModule(tbParams, bNotYaw)
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local modelView = moduleScene and moduleScene.GetModel(LoginModel.FORCE_ROLE)

    if not modelView then
        return
    end

    if not tbParams then
        return
    end

    if tbParams.fRoleYaw and not bNotYaw then
        modelView:SetYaw(tbParams.fRoleYaw)
    end

    modelView:SetTranslation(g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)

    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    moduleCamera.GetCamera():set_mainplayer_pos(g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)
end

return LoginRole
