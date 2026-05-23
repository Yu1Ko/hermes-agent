local LoginRoleList = {className = "LoginRoleList"}
local self = LoginRoleList

local m_szRoleName

-- ui\Config\Default\LoginRoleList.lua
local tRoleAnimations =
{
	--[1] = 31, --少林
	--[2] = 39, --万花
	--[3] = 32, --天策
	--[4] = 33, --纯阳
	--[5] = 38, --七秀
	--[6] = 845, --五毒
	--[7] = 1141, --唐门
	--[8] = 34, --藏剑
	--[9] = 2217, --丐帮
	--[10] = 1457, --明教
	[21] = 18006, --苍云
	[22] = 4207, --长歌
	[23] = 69995, --霸刀
	[24] = 85011, --蓬莱
	--[25] = 91013, --凌雪
	--[211] = 74013, --衍天
	[212] = 100, --药宗
	[213] = 7788, --刀宗
	[214] = 396, --万灵
}

function LoginRoleList.RegisterEvent()
    LoginMgr.RegisterLoginNotify(LOGIN.GET_ROLE_LIST_SUCCESS, self.OnGetRoleListSuccess) -- 单个角色同步到客户端
    LoginMgr.RegisterLoginNotify(LOGIN.GET_ALL_ROLE_LIST_SUCCESS, self.OnGetAllRoleListSuccess) -- 所有角色同步完
    LoginMgr.RegisterLoginNotify(LOGIN.DELETE_ROLE_SUCCESS, self.OnDeleteRoleSuccess)
    LoginMgr.RegisterLoginNotify(LOGIN.RENAME_SUCCESS, function () self.OnReName(LOGIN.RENAME_SUCCESS) end)
    LoginMgr.RegisterLoginNotify(LOGIN.RENAME_NAME_ALREADY_EXIST, function () self.OnReName(LOGIN.RENAME_NAME_ALREADY_EXIST) end)
    LoginMgr.RegisterLoginNotify(LOGIN.RENAME_NAME_TOO_LONG, function () self.OnReName(LOGIN.RENAME_NAME_TOO_LONG) end)
    LoginMgr.RegisterLoginNotify(LOGIN.RENAME_NAME_TOO_SHORT, function () self.OnReName(LOGIN.RENAME_NAME_TOO_SHORT) end)
    LoginMgr.RegisterLoginNotify(LOGIN.RENAME_NEW_NAME_ERROR, function () self.OnReName(LOGIN.RENAME_NEW_NAME_ERROR) end)
    LoginMgr.RegisterLoginNotify(LOGIN.RENAME_ERROR, function () self.OnReName(LOGIN.RENAME_ERROR) end)
    LoginMgr.RegisterLoginNotify(LOGIN.DEL_ROLE_MIBAO_VERIFY_SUCCESS, function () self.OnRoleMiBaoVerifySuccess() end)

    LoginMgr.RegisterLoginNotify(LOGIN.MIBAO_SYSTEM_ERROR, function () self.OnRoleMiBaoVerifyFailed(LOGIN.MIBAO_SYSTEM_ERROR) end)
    LoginMgr.RegisterLoginNotify(LOGIN.TOKEN_SYSTEM_ERROR, function () self.OnRoleMiBaoVerifyFailed(LOGIN.TOKEN_SYSTEM_ERROR) end)
    LoginMgr.RegisterLoginNotify(LOGIN.PHONE_SYSTEM_ERROR, function () self.OnRoleMiBaoVerifyFailed(LOGIN.PHONE_SYSTEM_ERROR) end)
    LoginMgr.RegisterLoginNotify(LOGIN.TOKEN_USED, function () self.OnRoleMiBaoVerifyFailed(LOGIN.TOKEN_USED) end)
    LoginMgr.RegisterLoginNotify(LOGIN.TOKEN_FAILED, function () self.OnRoleMiBaoVerifyFailed(LOGIN.TOKEN_FAILED) end)
    LoginMgr.RegisterLoginNotify(LOGIN.TOKEN_NOTFOUND, function () self.OnRoleMiBaoVerifyFailed(LOGIN.TOKEN_NOTFOUND) end)
    LoginMgr.RegisterLoginNotify(LOGIN.TOKEN_DISABLE, function () self.OnRoleMiBaoVerifyFailed(LOGIN.TOKEN_DISABLE) end)
    LoginMgr.RegisterLoginNotify(LOGIN.TOKEN_EXPIRED, function () self.OnRoleMiBaoVerifyFailed(LOGIN.TOKEN_EXPIRED) end)

    local tbFailEventList = {
        LOGIN.DELETE_ROLE_DELAY,                     -- 进入延时删除队列
        LOGIN.DELETE_ROLE_TONG_MASTER,               -- 帮主不允许删除
        LOGIN.DELETE_ROLE_FREEZE_ROLE,               -- 冻结角色不允许删除
        LOGIN.DELETE_ROLE_SELLING_GAME_CARD,         -- 有通宝在寄卖，不能删除
        LOGIN.DELETE_ROLE_HAVE_PEER_PAY_FOR_TAKE,    -- 有待领取的通宝代付，不能删除
        LOGIN.DELETE_ROLE_MIBAO_VERIFY_FAILED,       -- 密保验证失败
        LOGIN.DELETE_ROLE_CAPTCHA_VERIFY_TIMEOUT,    -- 图形验证码验证有效期超时（一般在等待输入令牌时）
        LOGIN.DELETE_ROLE_SWITCHING_CENTER,          -- 转服中不允许删除角色
        LOGIN.DELETE_ROLE_HAVE_TONG_BIND_ITEM,       -- 包裹或仓库中有帮会绑定物品，不能删除
        LOGIN.DELETE_ROLE_HAVE_UNFINISHED_GROUPON,   -- 有没完成的商城团购，不能删除
        LOGIN.DELETE_ROLE_UNKNOWN_ERROR,             -- 不晓得什么原因，反正失败了:)
        LOGIN.DELETE_ROLE_IN_ASURA_TEAM,             -- 处于修罗挑战战队中，不能删除
    }

    for i = 1, #tbFailEventList do
        local nEvent = tbFailEventList[i]
        LoginMgr.RegisterLoginNotify(nEvent, function()
            self.OnDeleteRoleFail(nEvent)
        end)
    end
end

function LoginRoleList.OnEnter(szPrevStep, szRoleName)
    m_szRoleName = nil

    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    moduleCamera.SetCameraStatus(LoginCameraStatus.ROLE_LIST, 1)

    local nCount = Login_GetRoleCount()
    XGSDK_TrackEvent("game.getrolecount", "login", {})
    if nCount <= 0 then
        if szPrevStep == LoginModule.LOGIN_ROLE then
            LoginMgr.BackToLogin(true)
        elseif not NewFaceData.CheckHadCreateRoleFaceCache() then
            LoginMgr.SwitchStep(LoginModule.LOGIN_ROLE)
        end
    else
        self.UpdateValues()
        UIMgr.Close(VIEW_ID.PanelLogin)
        UIMgr.Close(VIEW_ID.PanelResourcesDownload)
        if self.scriptView then
            Timer.Add(LoginRoleList, 0.5, function ()
                self.scriptView = UIMgr.OpenSingle(false, VIEW_ID.PanelRoleChoices, szRoleName)
            end)
        else
            self.scriptView = UIMgr.OpenSingle(false, VIEW_ID.PanelRoleChoices, szRoleName)
        end
        self:_updateChoicesInfo()
    end

    local scene = SceneMgr.curScene
    if scene then
        if QualityMgr.bDisableCameraLight then
            KG3DEngine.SetPostRenderVignetteEnable(true)
            KG3DEngine.SetPostRenderVignetteIntensity(1.0)
        else
            scene:OpenCameraLight(QualityMgr.szCameraLightForUI, true)
        end
    end
end

function LoginRoleList.OnExit(szNextStep)
    UIMgr.CloseImmediately(VIEW_ID.PanelInputName)
    UIMgr.CloseImmediately(VIEW_ID.PanelRoleChoices)
    self.scriptView = nil
    if szNextStep ~= LoginModule.LOGIN_ENTERGAME then
        self._clearRoleModel()
    else
        m_szRoleName = nil
    end
end

-------------------------------- Public --------------------------------

function LoginRoleList.EnterGame(szRoleName, bDefaultMap)
    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    moduleEnterGame.CheckEnterGame(szRoleName, bDefaultMap)
end

function LoginRoleList.CreateRole()
    LoginMgr.SwitchStep(LoginModule.LOGIN_ROLE)
end

function LoginRoleList.GetRoleInfoList()
    return self.tbRoleInfoList
end

function LoginRoleList.GetRoleIndex(szRoleName)
    if self.tbRoleInfoList then
        for nIndex, tbRoleInfo in ipairs(self.tbRoleInfoList) do
            if tbRoleInfo.RoleName == szRoleName then
                return nIndex
            end
        end
    end
    return nil
end

function LoginRoleList.GetRoleCount()
    return self.nRoleCount
end

function LoginRoleList.UpdateValues()
    self.tbRoleInfoList = {}
    self.nRoleCount = Login_GetRoleCount()
    for nRoleIndex = 0,self.nRoleCount - 1 do
        local tbRoleInfo = Login_GetRoleInfo(nRoleIndex)
        if tbRoleInfo.bUseLiftedFace then
            local bShowFaceDecoration
            tbRoleInfo.tFaceData, bShowFaceDecoration = Login_GetRoleLiftedFaceData(nRoleIndex)
            if not bShowFaceDecoration then
                if tbRoleInfo.tFaceData.bNewFace then
                    tbRoleInfo.tFaceData.tDecoration =
                    {
                        [FACE_LIFT_DECORATION_TYPE.MOUTH] = {
                            nShowID = 0,
                            nColorID = 0,
                        },
                        [FACE_LIFT_DECORATION_TYPE.NOSE] = {
                            nShowID = 0,
                            nColorID = 0,
                        },
                    }
                else
                    tbRoleInfo.tFaceData.nDecorationID = 0
                end
            end
        end

        -- 创角后，没进入游戏（比如正在等待下载首包，这里要做特殊处理）
        if tbRoleInfo.dwForceID == 0 and tbRoleInfo.nLastSaveTime == 0 and tbRoleInfo.nTotalGameTime == 0 then
            tbRoleInfo.dwForceID = KUNGFU_ID_FORCE_TYPE[tbRoleInfo.dwKungfuID]

            -- 这个UILoginRepresentDataTab除了去做这个外观的匹配，还有一个用处就是打包的时候要根据这个配置把正确的外观资源放进首包，以确保资源未下载完之前能穿上正确的衣服
            local tbConf = UILoginRepresentDataTab[tbRoleInfo.dwKungfuID][tbRoleInfo.RoleType]
            if tbConf then
                LoginMgr.GetModule(LoginModule.LOGIN_SCENE)._formatRepresentData(tbConf, tbRoleInfo.RepresentData)
            end
        end

        if tbRoleInfo.dwSchoolID == 0 then
            tbRoleInfo.dwSchoolID = KUNGFU_ID_SCHOOL_TYPE[tbRoleInfo.dwKungfuID]
        end

        tbRoleInfo.tBody = Login_GetRoleBodyBoneData(nRoleIndex)
        tbRoleInfo.RepresentData.bUseLiftedFace = tbRoleInfo.bUseLiftedFace
        tbRoleInfo.RepresentData.tFaceData = tbRoleInfo.tFaceData
        tbRoleInfo.RepresentData.tBody = tbRoleInfo.tBody
        tbRoleInfo.RepresentData.nHatStyle = tbRoleInfo.bHideHair
        tbRoleInfo.RepresentData.bHideFacePendent = tbRoleInfo.bHideFacePendent
        tbRoleInfo.RepresentData.tCustomRepresentData = Login_GetEquipCustomRepresentData(nRoleIndex)
        tbRoleInfo.RepresentData.tHairDyeingData = Login_GetRoleHairCustomDyeingData(nRoleIndex)
        tbRoleInfo.RepresentData.bHideBackCloakModel = kmath.is_bit1(tbRoleInfo.nRepresentHideFlag, PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL + 1)
        table.insert(self.tbRoleInfoList, tbRoleInfo)
    end
    table.sort(self.tbRoleInfoList, function(a, b)  return a.nLastSaveTime > b.nLastSaveTime end)
    self.nMonthEndTime, self.nPointLeftTime, self.nDayLeftTime, self.nEndTimeOfFee= Login_GetTimeOfFee()
    self.nLoginTime = Login_GetLoginTime()
    self.nLastLoginYear, self.nLastLoginMonth, self.nLastLoginDay, self.nLastLoginHour, self.nLastLoginMinute = Login_GetLastLoginTime()

    self._setRoleModel()
end


function LoginRoleList.SelectRole(nRoleIndex)
    self.nSelRoleIndex = nRoleIndex
    self._setRoleModel(nRoleIndex)
    self._updateChoicesInfo()
    Event.Dispatch(EventType.OnRoleSelected, nRoleIndex)
end

function LoginRoleList.GetSelRoleIndex()
    return self.nSelRoleIndex
end

function LoginRoleList.UpdateRoleModel(nRoleIndex)
    self._updateRoleModel(nRoleIndex)
end

--点卡剩余时间
function LoginRoleList.GetStringPointLeftTime()
	if self.nPointLeftTime >= 0 then
		return math.floor(self.nPointLeftTime / 3600)..g_tStrings.STR_TIME_HOUR..
							math.floor((self.nPointLeftTime % 3600) / 60)..g_tStrings.STR_TIME_MINUTE..
							(self.nPointLeftTime % 60)..g_tStrings.STR_TIME_SECOND
	else
		local nAbsPointLeftTime = -self.nPointLeftTime
		return "-"..math.floor(nAbsPointLeftTime / 3600)..g_tStrings.STR_TIME_HOUR..
							math.floor((nAbsPointLeftTime % 3600) / 60)..g_tStrings.STR_TIME_MINUTE..
							(nAbsPointLeftTime % 60)..g_tStrings.STR_TIME_SECOND

	end
end

function LoginRoleList.GetNumberPointLeftTime()
    return self.nPointLeftTime
end
--包月截止时间
function LoginRoleList.GetMonthEndTime()
    return TimeToDate(self.nMonthEndTime)
end

--天卡剩余时间
function LoginRoleList.GetDayLeftTime()
    return self.nDayLeftTime
end

function LoginRoleList.GetLoginTime()
    return TimeToDate(self.nLoginTime)
end

function LoginRoleList.GetLastLoginTime()
    return self.nLastLoginYear, self.nLastLoginMonth, self.nLastLoginDay, self.nLastLoginHour, self.nLastLoginMinute
end

function LoginRoleList.IsFirstLoginToday()
    local nLoginTime = self.GetLoginTime()
    return not (nLoginTime.year == self.nLastLoginYear and nLoginTime.month == self.nLastLoginMonth and nLoginTime.day == self.nLastLoginDay)
end

function LoginRoleList.OnCancelDeleteRole()
    LoginMgr.SetWaiting(false)
end

function LoginRoleList.UpdateRoleCount()
    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbServer = moduleServerList and moduleServerList.GetSelectServer()
    if not tbServer then
        return
    end

    local nRoleCount = Login_GetRoleCount()
    local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
    local szAccountKey = moduleAccount.GetStorageAccountKey()
    if szAccountKey then
        if not Storage.ServerRoleCount.tbRoleCount[szAccountKey] then
            Storage.ServerRoleCount.tbRoleCount[szAccountKey] = {}
        end
        Storage.ServerRoleCount.tbRoleCount[szAccountKey][tbServer.szServer] = nRoleCount
        Storage.ServerRoleCount.Flush()
    end
end

-------------------------------- Protocol --------------------------------

function LoginRoleList.OnGetRoleListSuccess()
    -- Request: LoginAccount.AccountVerify
    LoginMgr.Log(self, "OnGetRoleListSuccess")
end

function LoginRoleList.OnGetAllRoleListSuccess()
    -- Request: LoginAccount.AccountVerify
    LoginMgr.Log(self, "OnGetAllRoleListSuccess")
    LoginMgr.SetWaiting(false)

    self.UpdateRoleCount()

    g_tbLoginData.bIsGetAllRoleListSuccess = true

    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    moduleEnterGame.ClearTimer()

    LoginMgr.SwitchStep(LoginModule.LOGIN_DOWNLOAD)
end

function LoginRoleList.ConfirmDeleteRole(tbRoleInfo)
    -- if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.DELETING_ROLE) then return end
    self.tbDeleteRoleInfo = tbRoleInfo
    local bCaptcha = Login_GetDeleteRoleCaptchaFlag()
	if bCaptcha then
        --进入删除角色
        self.ShowCaptcha()
    else
        UIHelper.ShowConfirm(g_tStrings.STR_DELETE_ROLE_WARNING, function()
            self.DeleteRole(tbRoleInfo.RoleName)
        end)
    end
end

function LoginRoleList.OnRoleMiBaoVerifySuccess()
    LoginMgr.SetWaiting(false)

    g_tbLoginData.bVerifyMiBao = false
    UIMgr.Close(VIEW_ID.PanelLingLongMiBao)
    Login_DeleteRole(self.tbDeleteRoleInfo.RoleName)
end

function LoginRoleList.OnRoleMiBaoVerifyFailed(nErrCode)
    LoginMgr.SetWaiting(false)

    TipsHelper.ShowNormalTip(g_tStrings.tTokenErrorCode[nErrCode])
    g_tbLoginData.bVerifyMiBao = false
end

function LoginRoleList.ShowCaptcha()
    UIMgr.Open(VIEW_ID.PanelDeleteCharacterPicConfirm, self.tbDeleteRoleInfo)
end


function LoginRoleList.OnReName(nEvent)
    if LoginEventName[nEvent] then
        LoginMgr.ErrorMsg(self, LoginEventName[nEvent])
    end

    self.UpdateValues()
    LoginMgr.SetWaiting(false)
    if self.scriptView then
        self.scriptView:OnReName()
    end
end

function LoginRoleList.DeleteRole(szRoleName)
    local nType, bVerified = Login_GetMibaoMode()
	if nType == PASSPOD_MODE.UNBIND or bVerified then
        if not LoginMgr.SetWaiting(true, g_tStrings.tbLoginString.DELETING_ROLE) then return end
		Login_DeleteRole(szRoleName)
	elseif nType == PASSPOD_MODE.TOKEN then
		UIMgr.Open(VIEW_ID.PanelEnterDynamicPassword)
	elseif nType == PASSPOD_MODE.PHONE then
		UIMgr.Open(VIEW_ID.PanelEnterDynamicPassword)
	end
end

function LoginRoleList.OnDeleteRoleSuccess()
    LoginMgr.Log(self, "OnDeleteRoleSuccess")
    self.UpdateRoleCount()
    self.UpdateValues()
    if self.scriptView then
        self.scriptView:OnDeleteRoleSuccess()
    end
    LoginMgr.SetWaiting(false)
end

function LoginRoleList.OnDeleteRoleFail(nEvent)
    LoginMgr.ErrorMsg(self, LoginEventName[nEvent])
    self.UpdateValues()
    LoginMgr.SetWaiting(false)
    if self.scriptView then
        self.scriptView:OnDeleteRoleFail()
    end
end


function LoginRoleList.GetCaptcha()
    Login_GetCaptcha()
end


function LoginRoleList.VerifyCaptcha(szAnswer)
    Login_VerifyCaptcha(szAnswer)
end

-------------------------------- Private --------------------------------

function LoginRoleList._setRoleModel(nRoleIndex)
    if not self.tbRoleInfoList or not self.tbRoleInfoList[nRoleIndex] then return end
    local tbRoleInfo = self.tbRoleInfoList[nRoleIndex]
    if tbRoleInfo.RoleName == m_szRoleName then return end
    m_szRoleName = tbRoleInfo.RoleName
    --LOG.TABLE(tbRoleInfo, "LoginRoleList.SelectRole")

    self._updateRoleModel(nRoleIndex)
end

function LoginRoleList._clearRoleModel()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    moduleScene.UnloadModel()
    moduleScene.UnloadSFX()
    m_szRoleName = nil
end

function LoginRoleList._updateRoleModel(nRoleIndex)
    local tbRoleInfo = self.tbRoleInfoList and self.tbRoleInfoList[nRoleIndex]
    if not tbRoleInfo then
        LOG.ERROR("UpdateModel Error, Invalid nRoleIndex: %s", tostring(nRoleIndex))
        return
    end

    if tbRoleInfo.RoleName ~= m_szRoleName then
        return
    end
    local bClearWeapon = tbRoleInfo.dwLoginIdleAction > 0 -- 设置了待机动作需要把武器卸下
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)

    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    moduleCamera.SetCameraStatus(LoginCameraStatus.ROLE_LIST, tbRoleInfo.RoleType)

    --引擎那边做了处理来避免部件加载不一致导致闪烁，不缓存模型对象，每次切门派都重新创建
    moduleScene.UnloadModel()
    local modelView = moduleScene.LoadModel(LoginModel.ROLE, tbRoleInfo, bClearWeapon)

    if modelView then
        --设置模型位置

        local yaw = g_tRoleListPos.tRoleYaw[tbRoleInfo.RoleType]

        modelView:SetTranslation(g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)
        modelView:SetYaw(yaw)

        moduleCamera.SetModelScale(1, tbRoleInfo.RoleType)
        if moduleCamera.GetCamera() then
            moduleCamera.GetCamera():set_mainplayer_pos(g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)
        end
        modelView:GetMdlScale(function (_, _, fScale)
            moduleCamera.SetModelScale(fScale, tbRoleInfo.RoleType)
        end)

        if tbRoleInfo.dwLoginIdleAction > 0 then
            local dwRepresentID = CharacterIdleActionData.GetActionRepresentID(tbRoleInfo.dwLoginIdleAction)
            local szDefaultAni = CharacterIdleActionData.GetDefaultAni(PLAYER_IDLE_ACTION_DISPLAY_TYPE.LOGIN)
            modelView:PlayAnimationByLogicID(dwRepresentID, szDefaultAni)
        else
            local dwID = nil--tRoleAnimations[tbRoleInfo.dwForceID]
            if dwID then
                modelView:PlayAniID(dwID, "loop")
            else
                modelView:PlayAnimation("Standard", "loop")
            end
        end

        if tbRoleInfo.dwPuppet then
            modelView:UpdatePuppet(tbRoleInfo.dwPuppet)
        end

        -- --播放与创角界面相同的动画
        -- local loginRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
        -- local nAniID = loginRole and loginRole._getSchoolData(ForceTypeToSchool[tbRoleInfo.dwForceID], tbRoleInfo.RoleType, "idle_ani")
        -- if nAniID then
        --     modelView:PlayAniID(nAniID, "loop")
        -- end
    end

    local scene = moduleScene.GetScene()
    if scene then
        scene:SetMainPlayerPosition(g_tRoleListPos.x, g_tRoleListPos.y, g_tRoleListPos.z)
    end
end

function LoginRoleList._updateChoicesInfo()
    local tbRoleInfo =  self.tbRoleInfoList and self.tbRoleInfoList[self.nSelRoleIndex or 1] or {}
    if self.scriptView and self.scriptView.SetRoleTypeAndForceID then
        self.scriptView:SetRoleTypeAndForceID(tbRoleInfo)
    end

    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    moduleEnterGame.SetRoleTypeAndForceID(tbRoleInfo)
end

return LoginRoleList