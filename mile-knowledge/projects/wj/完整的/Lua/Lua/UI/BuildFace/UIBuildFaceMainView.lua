-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceMainView
-- Date: 2023-09-07 14:33:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceMainView = class("UIBuildFaceMainView")
function UIBuildFaceMainView:OnEnter(nRoleType, nKungfuID)
    self.scriptCommonInteraction = UIHelper.GetBindScript(self.widgetCommonScript)
    self.scriptCommonInteraction:OnEnter(nRoleType, nKungfuID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nRoleType = nRoleType
    self.nKungfuID = nKungfuID
    BuildFaceData.SetInBuildMode(true)
    self:InitRoleModel()

    --模型加载提示
    local tMsg = {
        szType = "LoadModel",
        szWaitingMsg = "正在加载角色模型中，请稍候...",
    }
    WaitingTipsData.PushWaitingTips(tMsg)

    self.nFinishCount = 0;
    self.nLoadTimerID = Timer.AddFrameCycle(self, 1, function()
        GetSceneLoadingTaskCount(SceneMgr.GetCurSceneID())
    end)
    BuildPresetData.nPresetRoleType = nRoleType
    BuildPresetData.ResetDownloadDynamic()
    BuildPresetData.EnablePakResourceDownloadEvent(true)
    self:UpdateInfo()

    --资源下载
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    scriptDownload:OnInitTotal()

    Timer.AddCycle(self, 5, function ()
        NewFaceData.AutoCacheCreateRoleFaceData(BuildFaceData.tNowFaceData, BuildFaceData.nRoleType, nKungfuID)
    end)
end

function UIBuildFaceMainView:OnExit()
    self.bInit = false
    if not UIMgr.GetView(VIEW_ID.PanelModelVideo) then
        local ModleView = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
        if ModleView then
            ModleView:EndReshape()
            ModleView:EndFaceHighlightMgr()
        end
        UIHelper.HideFullScreenSFX()
        BuildFaceData.SetInBuildMode(false)
        self:InitRoleModel()
    end
    local nBuildFaceTime = BuildFaceData.GetBuildFaceTime()
    if nBuildFaceTime then
        XGSDK_TrackEvent("game.buileface.end", "createrole", {{"BuildFaceTime", tostring(nBuildFaceTime)}})
    end
    self.scriptCommonInteraction:OnExit()
    self.scriptCommonInteraction = nil
    BuildFaceData.tNowFaceData = self.tDefalutRepresentList.tFaceData
    BuildBodyData.tNowBodyData = self.tDefalutRepresentList.tBody
    BuildBodyData.UpdateCloth({} , {})
    self:UnLoadSceneSfx()
    BuildPresetData.ResetDownloadDynamic()
    BuildPresetData.EnablePakResourceDownloadEvent(false)
    BuildPresetData.tbDefaultReprent = nil
end

function UIBuildFaceMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
        moduleCamera.SetCameraStatus(LoginCameraStatus.ROLE_LIST, self.nRoleType)

        BuildFaceData.SetInBuildMode(false)

        local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
        moduleRole.UpdateRoleModel()

        NewFaceData.DelCacheCreateRoleFaceData()
        UIMgr.Close(self)
        UIMgr.ShowView(VIEW_ID.PanelSchoolSelect)
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSchoolSelect)
        scriptView:UpdateUIAnimation(0, "AniRightShow")
    end)

    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function ()
        self.scriptCommonInteraction:OpenCellView(false)

        -- local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
        -- local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
        -- local nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_FACE
        -- moduleRole.UpdateModelScale()
        -- moduleCamera.SetCameraStatus(nCameraStatus, self.nRoleType)

        BuildPresetData.szLastAnimation = BuildPresetData.szSelectRoleAni
        UIMgr.HideView(VIEW_ID.PanelBuildFace)
        UIMgr.Open(VIEW_ID.PanelBuildFace_Step2, self.nRoleType, self.nKungfuID)
    end)

    UIHelper.BindUIEvent(self.BtnRevertAll, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.STR_NEW_FACE_RESET_MSG, function ()
            BuildFaceData.ResetFaceData()
            self:UpdateDefaultList()
            self:UpdateModleInfo()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnRandom, EventType.OnClick, function ()

    end)

    self.scriptCommonInteraction:SetInputDataCallback(function ()
        self:UpdateModleInfo()
        if ShareStationData.bOpening then
            return
        end

        self:UpdatePageInfo()
    end)
end

function UIBuildFaceMainView:RegEvent()
    Event.Reg(self, EventType.OnChangeBuildFaceDefault, function ()
        self:UpdateDefaultList(true)

        if not UIHelper.GetVisible(self._rootNode) then
            return
        end
        self:UpdateModleInfo()
    end)

    Event.Reg(self, "RESET_NEW_FACE", function ()
        self:UpdateDefaultList()
    end)

    Event.Reg(self, EventType.OnSceneTouchBegan, function ()
        -- UIHelper.SetSelected(self.TogWeather, false)
        -- UIHelper.SetSelected(self.TogClothes, false)
        -- UIHelper.SetSelected(self.TogEmotion, false)
    end)

    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)

    Event.Reg(self, "COMMON_CALL_BACK", function()
        if self.nLoadTimerID and arg0 == "GetSceneLoadingTaskCount" then
            local nTotalCount = tonumber(arg2);
            if nTotalCount <= 0 then
                self.nFinishCount = self.nFinishCount + 1;

                --有时加载完成后界面还未打开，等打开再关闭
                if self.nFinishCount > 10 then
                    WaitingTipsData.RemoveWaitingTips("LoadModel")
                    Timer.DelTimer(self, self.nLoadTimerID)
                    self.nLoadTimerID = nil
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnBuildFacePresetToggleSelect, function (nPageType , nIndex , bIgnoreAni)
        if nPageType == BuildPresetData.PageType.DEFAULT then
            self.nSelectExterialIndex = nIndex
            if nIndex == 0 and not bIgnoreAni then
                BuildPresetData.szSelectRoleAni = nil
            end
        end
        if UIMgr.IsViewVisible(VIEW_ID.PanelBuildFace) then
            BuildPresetData.PausePlayAnimation(self.nCurSelectPageType == BuildPresetData.PageType.FACE)
        end

    end)

    Event.Reg(self, EventType.OnRestoreBuildFaceCacheDataStep2, function (tbData)
        local nResult = BuildFaceData.ImportData(tbData)
        if nResult then
            if not ShareStationData.bOpening then
                TipsHelper.ShowNormalTip(g_tStrings.STR_NEW_FACE_DATA_IMPROT)
            end
            self:UpdateModleInfo()
        end
    end)
end

function UIBuildFaceMainView:UpdateInfo()
    BuildPresetData.Init()
    self.tPresetDataList = BuildPresetData.GetPresetData(self.nRoleType, KUNGFU_ID_FORCE_TYPE[self.nKungfuID])
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)

    self.tDefalutRepresentList = self.moduleRole:GetOriginalRepresent()
    BuildPresetData.tRoleDefalutRepresentList = Lib.copyTab(self.tDefalutRepresentList)
    BuildPresetData.tSelectOriginalRepresent = Lib.copyTab(self.tDefalutRepresentList)
    self:UpdateDefaultList()
    self:UpdatePageType()
end

function UIBuildFaceMainView:UpdatePageInfo()
    if self.nCurSelectPageType then
        self:OnSelectPageHandler(self.nCurSelectPageType)
    end
end

function UIBuildFaceMainView:UpdateDefaultList(bJustUpdateState)

end

function UIBuildFaceMainView:InitRoleModel()
    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    moduleRole.UpdateRoleModel()
end

function UIBuildFaceMainView:UpdateModleInfo()
    local ModleView = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
    ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tDecal, BuildFaceData.tNowFaceData.tDecoration, true)

    ModleView:SetBodyReshapingParams(BuildBodyData.tNowBodyData)
end

-- 左侧标签页选择
function UIBuildFaceMainView:UpdatePageType()
    UIHelper.HideAllChildren(self.LayoutLeftType)
    self.tbScrollViewByPage = {
        [BuildPresetData.PageType.DEFAULT] = self.ScrollViewDefaultList,
        [BuildPresetData.PageType.FACE] = self.ScrollViewFaceList,
        [BuildPresetData.PageType.BODY] = self.ScrollViewBodyList,
    }
    self.tbLoadPrefabIDByPage = {
        [BuildPresetData.PageType.DEFAULT] = PREFAB_ID.WidgetBulidFaceDefault_All,
        [BuildPresetData.PageType.FACE] = PREFAB_ID.WidgetBulidFaceDefault_Face,
        [BuildPresetData.PageType.BODY] = PREFAB_ID.WidgetBulidFaceDefault_Body,
    }

    self.tbPageDefaultCells =
    {
        [BuildPresetData.PageType.DEFAULT] = nil,
        [BuildPresetData.PageType.FACE] = nil,
        [BuildPresetData.PageType.BODY] = nil,
    }

    self.tbPageSelectToggle =
    {
        [BuildPresetData.PageType.DEFAULT] = nil,
        [BuildPresetData.PageType.FACE] = nil,
        [BuildPresetData.PageType.BODY] = nil,
    }

    self.tbPagePresetData = {}

    -- 清空ScrollView 内容
    for k, v in pairs(self.tbScrollViewByPage) do
        UIHelper.HideAllChildren(v)
        UIHelper.SetVisible(v , false)
    end

    local tbPageCell = {}
    for i, szName in ipairs(BuildPresetData.PageTypeName) do
        if not tbPageCell[i] then
            tbPageCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetDefaultLeftType, self.LayoutLeftType)
            UIHelper.ToggleGroupAddToggle(self.TogGroupTabType, tbPageCell[i].TogAll)
        end
        UIHelper.SetVisible(tbPageCell[i]._rootNode, true)
        tbPageCell[i]:OnEnter(i, szName , function (nPageType)
            self:OnSelectPageHandler(nPageType)
        end)
        UIHelper.LayoutDoLayout(self.LayoutLeftType)
    end


    self.curSelectScrollView = self.tbScrollViewByPage[BuildPresetData.PageType.DEFAULT]
    UIHelper.SetToggleGroupSelectedToggle(self.TogGroupTabType , tbPageCell[1].TogAll)
    tbPageCell[1]:OnInvokeSelect()
    self:UpdateScenePresetSFX(1)
end
-- 选中标签页回调处理
function UIBuildFaceMainView:OnSelectPageHandler(nPageType)

    if self.curSelectScrollView then
        UIHelper.SetVisible(self.curSelectScrollView , false)
    end
    self.curSelectScrollView = self.tbScrollViewByPage[nPageType]
    self.nCurSelectPageType = nPageType
    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    local nCameraStatus = LoginCameraStatus.ROLE_LIST
    self.scriptCommonInteraction:ShowBodyMgr(false)
    if nPageType == BuildPresetData.PageType.DEFAULT then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_BUILDALL
        moduleRole.UpdateModelScale()
    elseif nPageType == BuildPresetData.PageType.FACE then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_FACE
        moduleRole.UpdateModelScale()
    elseif nPageType == BuildPresetData.PageType.BODY then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_BODY
        moduleRole.ResetModelScale()
        self.scriptCommonInteraction:ShowBodyMgr(true)
    end

    moduleCamera.SetCameraStatus(nCameraStatus, self.nRoleType)
    self.scriptCommonInteraction:OpenCellView(false)
    UIHelper.SetVisible(self.curSelectScrollView , true)
    BuildPresetData.PausePlayAnimation(self.nCurSelectPageType == BuildPresetData.PageType.FACE)
    if not self.tbPageDefaultCells[nPageType] then
        local nLoadPrefabID = self.tbLoadPrefabIDByPage[nPageType]
        local tbDefalutList = self:_getPageDataList(nPageType)
        local onSelectCallback = function(nType , nCellIndex , script , bSelected)

            if nType == BuildPresetData.PageType.DEFAULT then
                self:_selectExterialHandler(nCellIndex ,false, bSelected , script)
                Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStepBuildAll, true)
            elseif nType == BuildPresetData.PageType.FACE then
                self:_selectFaceHandler(nCellIndex ,false, bSelected)
                Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Face, true)
            elseif nType == BuildPresetData.PageType.BODY then
                self:_selectBodyHandler(nCellIndex ,false, bSelected)
                Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Body, true)
            end
            self.scriptCommonInteraction:OpenCellView(false)
        end
        local tbDefaultCell = {}
        for i, tbData in ipairs(tbDefalutList) do
            if not tbDefaultCell[i] then
                tbDefaultCell[i] = UIHelper.AddPrefab(nLoadPrefabID, self.curSelectScrollView)
            end

            UIHelper.SetVisible(tbDefaultCell[i]._rootNode, true)
            tbDefaultCell[i]:OnEnter(nPageType , i, tbData , onSelectCallback)
        end
        self.tbPageDefaultCells[nPageType] = tbDefaultCell
    end

    local nChooseIndex = self:_getPageChildChooseIndex(nPageType)
    local nScrollIndex = 0
    if nPageType == BuildPresetData.PageType.FACE or nPageType == BuildPresetData.PageType.BODY then
        nScrollIndex = (nChooseIndex %2 == 0) and (nChooseIndex - 1) or nChooseIndex
    end
    if self.tbPageDefaultCells[nPageType][nChooseIndex] then
        for i, cell in pairs(self.tbPageDefaultCells[nPageType]) do
            if i == nChooseIndex then
                cell:OnInvokeSelect(true)
            else
                cell:UpdateToggleSelect(false)
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.curSelectScrollView)
    UIHelper.ScrollToIndex(self.curSelectScrollView, nScrollIndex)
    self.scriptCommonInteraction:ShowActionToggle(nPageType == BuildPresetData.PageType.DEFAULT)

    self:UpdateAnimation()
end

function UIBuildFaceMainView:_getPageChildChooseIndex(nPageType)
    if nPageType == BuildPresetData.PageType.DEFAULT then
       return self.nSelectExterialIndex or 1
    elseif nPageType == BuildPresetData.PageType.FACE then
        self.tFaceDefinitionInfo = self.tFaceDefinitionInfo or {}
        local tbClassConfig = Lib.copyTab(BuildFaceData.tFaceList)
        local tNowData 		= BuildFaceData.tNowFaceData
        for i, tInfo in ipairs(tbClassConfig) do
            if not self.tFaceDefinitionInfo[i] then
                local tBoneParams , tDecals , tDecorations = KG3DEngine.GetFaceDefinitionFromINIFile(tInfo.szFilePath , true)
                self.tFaceDefinitionInfo[i] =
                {
                    tBone = tBoneParams,
                    tDecal = tDecals,
                    tDecoration = tDecorations,
                    bNewFace = true,
                }
            end

            if BuildFaceData.IsEqualFace(self.tFaceDefinitionInfo[i], tNowData) then
                self.nSelectFaceIndex = i
                break
            end
        end

        return self.nSelectFaceIndex or 0
    elseif nPageType == BuildPresetData.PageType.BODY then
        self.tBodyDefinitionInfo = self.tBodyDefinitionInfo or {}
        local tbClassConfig = Lib.copyTab(BuildBodyData.tBodyList)
        local tNowData 		= BuildBodyData.tNowBodyData
        for i, tInfo in ipairs(tbClassConfig) do
            if not self.tBodyDefinitionInfo[i] then
                self.tBodyDefinitionInfo[i] = KG3DEngine.GetBodyDefinitionFromINIFile(tInfo.szFilePath)
            end
            if BuildBodyData.IsTableEqual(self.tBodyDefinitionInfo[i], tNowData) then
                self.nSelectBodyIndex = i
                break
            end
        end
        return self.nSelectBodyIndex or 1
    end
    return 1
end

function UIBuildFaceMainView:_getPageDataList(nPageType)
    local tbDefalutList = {}
    if nPageType == BuildPresetData.PageType.DEFAULT then
        tbDefalutList = self:_getExterialAllList()
    elseif nPageType == BuildPresetData.PageType.FACE then
        tbDefalutList = self:_getFaceList()
    elseif nPageType == BuildPresetData.PageType.BODY then
        tbDefalutList = self:_getBodyList()
    end
    return tbDefalutList
end

function UIBuildFaceMainView:_getExterialAllList()
    if not self.tbPagePresetData[BuildPresetData.PageType.DEFAULT] then
        local tbDataList = {}
        for k, v in pairs(self.tPresetDataList) do
            table.insert(tbDataList , {
                nType = BuildPresetData.PageType.DEFAULT,
                tbData = {
                    szIconPath = v.szMobileIconPath,
                    szFrameIconPath = v.szMobileIconBgPath,
                },
                tRepresentList = v.szRepresent,
                szFaceFilePath = v.szFaceFilePath,
                szBodyFilePath = v.szBodyFilePath,
                szStandbyAnimation = v.szMoblieStandbyAnimation,
                nLoginSceneID = v.nLoginSceneID,
                szGetDesc = v.szMobileGetIconPath,
            })
        end
        self.tbPagePresetData[BuildPresetData.PageType.DEFAULT] = tbDataList
    end

    return self.tbPagePresetData[BuildPresetData.PageType.DEFAULT]
end

function UIBuildFaceMainView:_selectExterialHandler(nIndex , bUpdate , bSelected , cellScript)
    if self.nSelectExterialIndex == nIndex and bSelected  then
        return
    end
    if not self.tbPagePresetData[BuildPresetData.PageType.DEFAULT] then
        return
    end
    local tOriginalRepresent = {}
    local szAnimation = nil
    local nLoginSceneID = 1
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
    if not bSelected then
        self.nSelectExterialIndex = 0
        tOriginalRepresent = self.tDefalutRepresentList
    else
        self.nSelectExterialIndex = nIndex
        local tbRepresent = string.split(self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].tRepresentList, ";")
        local i = 0
        for k, v in pairs(tbRepresent) do
            local tPart = string.split(v, "|")
            tOriginalRepresent[tonumber(tPart[1])] = tonumber(tPart[2])
        end
        if not self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].tBody then
            tOriginalRepresent.tBody = KG3DEngine.GetBodyDefinitionFromINIFile(self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].szBodyFilePath)
            if not tOriginalRepresent.tBody or table.is_empty(tOriginalRepresent.tBody) then
                tOriginalRepresent.tBody = {}
                for i = 0, 29, 1 do
                    tOriginalRepresent.tBody[i] = 0
                end
            end
            self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].tBody = tOriginalRepresent.tBody
        end
        if not self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].tFaceData then
            self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].tFaceData = BuildFaceData.GetFaceByFile(self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].szFaceFilePath)
        end
        tOriginalRepresent.tFaceData = self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].tFaceData
        tOriginalRepresent.tBody = self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].tBody
        szAnimation = self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].szStandbyAnimation
        nLoginSceneID = self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][nIndex].nLoginSceneID
    end


    self.nSelectBodyIndex = 1
    self.nSelectFaceIndex = 0


    Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.FACE , 0)
    Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.BODY , 0)

    BuildPresetData:RestInfo()
    BuildPresetData.szSelectRoleAni = szAnimation
    BuildPresetData.tSelectOriginalRepresent = tOriginalRepresent
    BuildFaceData.tNowFaceData = Lib.copyTab(tOriginalRepresent.tFaceData)
    BuildBodyData.tNowBodyData = Lib.copyTab(tOriginalRepresent.tBody)
    local isDownload = BuildPresetData.CheckDownloadRes(BuildPresetData.PageType.DEFAULT , nIndex ,tOriginalRepresent , cellScript , szAnimation)

    self.moduleRole:UpdateRepresentID(tOriginalRepresent, self.nRoleType, KUNGFU_ID_FORCE_TYPE[self.nKungfuID])
    if not isDownload then
        BuildBodyData.UpdateCloth("" , Lib.copyTab(tOriginalRepresent))
    else
        local tOriginalRepresent_tmp = BuildPresetData.GetDefaultReprent(self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][1].tRepresentList)
        BuildBodyData.UpdateCloth("" , Lib.copyTab(tOriginalRepresent_tmp))
    end

    self:UpdateScenePresetSFX(nLoginSceneID)
    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    moduleRole.UpdateRoleModel()
    BuildPresetData.nCurSelectHairIndex  = 0
    BuildPresetData.ResetPlayAnimation(szAnimation)
    moduleRole.UpdateModelScale()
end

function UIBuildFaceMainView:_getFaceList()

    if not self.tbPagePresetData[BuildPresetData.PageType.FACE] then
        local tbDataList = {}
        for i, tFaceData in ipairs(BuildFaceData.tFaceList) do
            table.insert(tbDataList , {
                nType = BuildPresetData.PageType.FACE,
                tbData = tFaceData,
                tFaceParams = nil
            })
        end
        self.tbPagePresetData[BuildPresetData.PageType.FACE] = tbDataList
    end

    return self.tbPagePresetData[BuildPresetData.PageType.FACE]
end

function UIBuildFaceMainView:_selectFaceHandler(nIndex , bUpdate , bSelected)
    if self.nSelectFaceIndex == nIndex and bSelected and not bUpdate then
        return
    end
    if not self.tbPagePresetData[BuildPresetData.PageType.FACE] then
        return
    end
    local tFaceParams
    if not bSelected then
        self.nSelectFaceIndex = 0
        tFaceParams = BuildPresetData.tSelectOriginalRepresent.tFaceData
    else
        self.nSelectFaceIndex = nIndex
        local tFaceData = self.tbPagePresetData[BuildPresetData.PageType.FACE][nIndex].tbData
        tFaceParams = self.tbPagePresetData[BuildPresetData.PageType.FACE][nIndex].tFaceParams
        if not tFaceParams then
            local tBoneParams, tDecals, tDecorations = KG3DEngine.GetFaceDefinitionFromINIFile(tFaceData.szFilePath, true)
            self.tbPagePresetData[BuildPresetData.PageType.FACE][nIndex].tFaceParams =
            {
                tBone = tBoneParams,
                tDecal = tDecals,
                tDecoration = tDecorations,
                bNewFace = true,
            }
            tFaceParams = self.tbPagePresetData[BuildPresetData.PageType.FACE][nIndex].tFaceParams
        end
    end
    BuildFaceData.tNowFaceData = Lib.copyTab(tFaceParams)
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
    self.moduleRole:SetFaceDefinition(tFaceParams.tBone , self.nRoleType , tFaceParams.tDecal , tFaceParams.tDecoration , true)
    Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.DEFAULT , 0)
    Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Face, true)
end

function UIBuildFaceMainView:_getBodyList()
    if not self.tbPagePresetData[BuildPresetData.PageType.BODY] then
        local tbDataList = {}
        local tbClassConfig = Lib.copyTab(BuildBodyData.tBodyList)
        for i, tInfo in ipairs(tbClassConfig) do
            tInfo.szName = UIHelper.GBKToUTF8(tInfo.szName)
            if tInfo.szName == "" then
                tInfo.szName = string.format("体型（%d）", i-1)
                tInfo.szIconPath = string.format("体型%d", i-1)
            else
                tInfo.szIconPath = tInfo.szName
            end
            tInfo.szIconPath = UIHelper.UTF8ToGBK(string.format("Texture/NieLian/Body/%s/%s%s.png",tRoleFileSuffix[self.nRoleType],tRoleFileSuffix[self.nRoleType],tInfo.szIconPath))
            table.insert(tbDataList , {
                nType = BuildPresetData.PageType.BODY,
                tbData = tInfo,
                tBodyParams= nil,
            })
        end
        self.tbPagePresetData[BuildPresetData.PageType.BODY] = tbDataList
    end

    return self.tbPagePresetData[BuildPresetData.PageType.BODY]
end

function UIBuildFaceMainView:_selectBodyHandler(nIndex , bUpdate , bSelected)
    if self.nSelectBodyIndex == nIndex and bSelected  and not bUpdate then
        return
    end
    if not self.tbPagePresetData[BuildPresetData.PageType.BODY] then
        return
    end
    local tBodyParams
    if not bSelected then
        self.nSelectBodyIndex = 1
        tBodyParams = BuildPresetData.tSelectOriginalRepresent.tBody
    else
        self.nSelectBodyIndex = nIndex
        local tBodyData = self.tbPagePresetData[BuildPresetData.PageType.BODY][nIndex].tbData
        tBodyParams = self.tbPagePresetData[BuildPresetData.PageType.BODY][nIndex].tBodyParams

        if not tBodyParams then
            tBodyParams = KG3DEngine.GetBodyDefinitionFromINIFile(tBodyData.szFilePath)
            if not tBodyParams or table.is_empty(tBodyParams) then
                tBodyParams = {}
                for i = 0, 29, 1 do
                    tBodyParams[i] = 0
                end
            end
            self.tbPagePresetData[BuildPresetData.PageType.BODY][nIndex].tBodyParams = tBodyParams
        end
    end
    BuildBodyData.UpdateNowBodyData(tBodyParams)
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
    self.moduleRole:SetBodyReshapingParams(tBodyParams)
    Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.DEFAULT , 0)
    Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Body, true)
end

function UIBuildFaceMainView:UnLoadSceneSfx()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    if moduleScene then
        moduleScene.UnLoadScenePresetSFX()
    end
end

function UIBuildFaceMainView:UpdateScendSelectInfo()

    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    local nCameraStatus = LoginCameraStatus.ROLE_LIST
    if self.nCurSelectPageType == BuildPresetData.PageType.DEFAULT then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_BUILDALL
        moduleRole.UpdateModelScale()
    elseif self.nCurSelectPageType == BuildPresetData.PageType.FACE then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_FACE
        moduleRole.UpdateModelScale()
    elseif self.nCurSelectPageType == BuildPresetData.PageType.BODY then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_BODY
        moduleRole.ResetModelScale()
    end

    self:UpdateAnimation()

    BuildPresetData.PausePlayAnimation(self.nCurSelectPageType == BuildPresetData.PageType.FACE)
    moduleCamera.SetCameraStatus(nCameraStatus, self.nRoleType)
    local updatePage = function(nPageType)
        local nSelectIndex = 0
        if nPageType == BuildPresetData.PageType.BODY then
            self.tBodyDefinitionInfo = self.tBodyDefinitionInfo or {}
            local tbClassConfig = Lib.copyTab(BuildBodyData.tBodyList)
            local tNowData 		= BuildBodyData.tNowBodyData
            for i, tInfo in ipairs(tbClassConfig) do
                if not self.tBodyDefinitionInfo[i] then
                    self.tBodyDefinitionInfo[i] = KG3DEngine.GetBodyDefinitionFromINIFile(tInfo.szFilePath)
                end
                if BuildBodyData.IsTableEqual(self.tBodyDefinitionInfo[i], tNowData) then
                    nSelectIndex = i
                    break
                end
            end
        elseif nPageType == BuildPresetData.PageType.FACE then
            self.tFaceDefinitionInfo = self.tFaceDefinitionInfo or {}
            local tbClassConfig = Lib.copyTab(BuildFaceData.tFaceList)
            local tNowData 		= BuildFaceData.tNowFaceData
            for i, tInfo in ipairs(tbClassConfig) do
                if not self.tFaceDefinitionInfo[i] then
                    local tBoneParams , tDecals , tDecorations = KG3DEngine.GetFaceDefinitionFromINIFile(tInfo.szFilePath , true)
                    self.tFaceDefinitionInfo[i] =
                    {
                        tBone = tBoneParams,
                        tDecal = tDecals,
                        tDecoration = tDecorations,
                        bNewFace = true,
                    }
                end

                if BuildFaceData.IsEqualFace(self.tFaceDefinitionInfo[i], tNowData) then
                    nSelectIndex = i
                    break
                end
            end
        end
        Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , nPageType , nSelectIndex , true)
        return nSelectIndex
    end
    self.nSelectBodyIndex = updatePage(BuildPresetData.PageType.BODY)
    self.nSelectFaceIndex = updatePage(BuildPresetData.PageType.FACE)
end

function UIBuildFaceMainView:UpdateScenePresetSFX(nSceneIndex)
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local tInfo = Table_GetLoginSceneInfo(nSceneIndex)
    if tInfo then
        tInfo.szMapName = tInfo.szMobileMapName
        moduleScene.SceneChange(tInfo)
        -- 选择场景
        self:UnLoadSceneSfx()
        local tbEffect = TabHelper.GetUILoginScenePresetEffectTab(UIHelper.GBKToUTF8(tInfo.szMapName))
        local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
        for k, v in pairs(tbEffect) do
            if v.szEffectPath ~= "" then
                moduleScene.LoadScenePresetSFX(UIHelper.UTF8ToGBK(v.szEffectPath),v.vPosition,v.vRotation,v.vScale)
            end
        end
    end
end

function UIBuildFaceMainView:UpdateAnimation()
    if self.nCurSelectPageType == BuildPresetData.PageType.DEFAULT then
        if self.nRoleType == ROLE_TYPE.LITTLE_BOY or self.nRoleType == ROLE_TYPE.LITTLE_GIRL then
            BuildPresetData.szFisrtStanderAnimation = self.tbPagePresetData[BuildPresetData.PageType.DEFAULT][1].szStandbyAnimation
        end
        BuildPresetData.ResetPlayAnimation(BuildPresetData.szSelectRoleAni or  BuildPresetData.szFisrtStanderAnimation)
    else
        if self.nRoleType == ROLE_TYPE.LITTLE_BOY or self.nRoleType == ROLE_TYPE.LITTLE_GIRL then
            BuildPresetData.ResetPlayAnimation(BuildPresetData.szFisrtStanderAnimation)
        else
            BuildPresetData.ResetPlayAnimation()
        end
    end
end



return UIBuildFaceMainView

