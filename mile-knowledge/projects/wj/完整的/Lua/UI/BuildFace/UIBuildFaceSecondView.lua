-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceSecondView
-- Date: 2023-09-07 14:35:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceSecondView = class("UIBuildFaceSecondView")

local PageType = {
    ["Face"]    = 1,
    ["Makeup"]  = 2,
    ["Hair"]    = 3,
    ["Body"]    = 4,
    ["Prefab"]  = 5,
    ["Recommend"] = 6,
}

function UIBuildFaceSecondView:OnEnter(nRoleType, nKungfuID, bPrice)
    self.scriptCommonInteraction = UIHelper.GetBindScript(self.widgetCommonScript)
    self.scriptCommonInteraction:OnEnter(nRoleType, nKungfuID , function (bOpenView)
        self:OpenInterationView(bOpenView)
    end)
    if not self.bInit then
        self.nCurSelectPageIndex = PageType.Recommend
        self.nCurSelectClass1Index = 1
        self.nCurSelectClass3Index = 1
        self.nCurSelectClass4Index = 1

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.scriptCommonInteraction:ShowBodyMgr(false)
    end

    BuildFaceData.SetInBuildMode(true)
    self:UpdateModleInfo()
    --self:UpdateRoleModel()

    -- 模型加载提示
    -- local tMsg = {
    --     szType = "LoadModel",
    --     szWaitingMsg = "正在加载角色模型中，请稍候...",
    -- }
    -- WaitingTipsData.PushWaitingTips(tMsg)

    self.nFinishCount = 0;
    self.nLoadTimerID = Timer.AddFrameCycle(self, 1, function()
        GetSceneLoadingTaskCount(SceneMgr.GetCurSceneID())
    end)

    self.nKungfuID = nKungfuID
    self.nRoleType = nRoleType
    self:UpdateInfo()


    --资源下载
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    --scriptDownload:OnInitBasic()
    scriptDownload:OnInitTotal()

    if self.nRoleType == ROLE_TYPE.LITTLE_BOY or self.nRoleType == ROLE_TYPE.LITTLE_GIRL then
        BuildPresetData.ResetPlayAnimation(BuildPresetData.szFisrtStanderAnimation)
    else
        BuildPresetData.ResetPlayAnimation()
    end

    BuildPresetData.PausePlayAnimation(true)
    self.scriptCommonInteraction:ShowActionToggle(false)
    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    moduleRole.UpdateModelScale()
end

function UIBuildFaceSecondView:OnExit()
    self.bInit = false
    self.scriptCommonInteraction:OnExit()
    self.scriptCommonInteraction = nil
end

function UIBuildFaceSecondView:BindUIEvent()
    self.scriptScrollViewTab2 = UIHelper.GetBindScript(self.WidgetList2)
    self.scriptScrollViewTab3 = UIHelper.GetBindScript(self.WidgetList3)

    UIHelper.BindUIEvent(self.TogList3LeftRight, EventType.OnClick, function()
        BuildFaceData.SetMeanwhileSwitch(self.nCurMeanwhile, UIHelper.GetSelected(self.TogList3LeftRight))
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
        UIMgr.ShowView(VIEW_ID.PanelBuildFace)
        local viewLua =  UIMgr.GetViewScript(VIEW_ID.PanelBuildFace)
        viewLua:UpdateScendSelectInfo()
    end)

    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function ()
        BuildPresetData.nCreateRoleType = self.nRoleType
        BuildPresetData.nCreateForceID = self.nKungfuID
        UIMgr.HideView(VIEW_ID.PanelBuildFace_Step2)
        BuildPresetData.ResetPlayAnimation(BuildPresetData.szLastAnimation)
        local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
        local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
        moduleRole.UpdateModelScale()
        moduleCamera.SetCameraStatus(LoginCameraStatus.BUILD_FACE_STEP_INPUTNAME,self.nRoleType or 1)
        local scriptInputName = UIMgr.Open(VIEW_ID.PanelCreateName_Login, false, self.nRoleType)
        scriptInputName:SetCancelCallback(function ()
            if self.nRoleType == ROLE_TYPE.LITTLE_BOY or self.nRoleType == ROLE_TYPE.LITTLE_GIRL then
                BuildPresetData.ResetPlayAnimation(BuildPresetData.szFisrtStanderAnimation)
            else
                BuildPresetData.ResetPlayAnimation()
            end
            BuildPresetData.PausePlayAnimation(self.nCurSelectPageIndex == PageType.Face or self.nCurSelectPageIndex == PageType.Prefab or self.nCurSelectPageIndex == PageType.Makeup)
            moduleRole.UpdateModelScale()
            moduleCamera.SetCameraStatus(self.nCurCameraStatus,self.nRoleType or 1)
            Event.Dispatch(EventType.OnUpdateBuildFaceModule, self.tbCurCameraStep, false)
            UIMgr.ShowView(VIEW_ID.PanelBuildFace_Step2)
        end)
        Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStepInputName, false)
        local nBuildFaceTime = BuildFaceData.GetBuildFaceTime()
        if nBuildFaceTime then
            XGSDK_TrackEvent("game.buileface.end", "createrole", {{"BuildFaceTime", tostring(nBuildFaceTime)}})
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function ()
        if self.nCurSelectPageIndex == PageType.Face then
            if not self.tbClassConfig then
                return
            end

            local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
            if not tbConfig1 then
                return
            end

            local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
            if not tbConfig2 then
                return
            end

            local szMessage = FormatString(g_tStrings.STR_NEW_FACE_RESET_SKE_MSG, UIHelper.GBKToUTF8(tbConfig2.szClassName))
            UIHelper.ShowConfirm(szMessage, function ()
                BuildFaceData.InitBoneClass(tbConfig2)
                self:UpdateInfo()
            end)
        elseif self.nCurSelectPageIndex == PageType.Makeup then
            local tData 		= BuildFaceData.GetDefaultFaceData()
            if self.bDecoration then
                BuildFaceData.tNowFaceData.tDecoration = clone(tData.tDecoration)
            else
                if not self.tbClassConfig then
                    return
                end

                local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
                if not tbConfig1 then
                    return
                end

                local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
                if not tbConfig2 then
                    return
                end

                for _, tInfo in ipairs(tbConfig2) do
                    local nDecalsType = tInfo.nDecalsType
                    BuildFaceData.tNowFaceData.tDecal[nDecalsType] = tData.tDecal[nDecalsType]
                    BuildFaceData.CopyRightType(nDecalsType)
                end
            end

            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevertAll, EventType.OnClick, function ()
        if self.nCurSelectPageIndex == PageType.Face or
                self.nCurSelectPageIndex == PageType.Makeup or
                self.nCurSelectPageIndex == PageType.Prefab or
                self.nCurSelectPageIndex == PageType.Recommend then
            UIHelper.ShowConfirm(g_tStrings.STR_NEW_FACE_RESET_MSG, function ()
                BuildFaceData.ResetFaceData()
                FireUIEvent("RESET_NEW_FACE")
                self:UpdateInfo()
            end)
        elseif self.nCurSelectPageIndex == PageType.Body then
            UIHelper.ShowConfirm(g_tStrings.STR_BODY_RESET_MSG, function ()
                BuildBodyData.ResetBodyData()
                self:UpdateInfo()
            end)
        end
    end)

    for nType, tog in ipairs(self.tbTogPage) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nCurSelectPageIndex = nType
            self.nCurSelectClass1Index = 1
            if nType == PageType.Body then
                self.nCurSelectClass1Index = 0
                self.scriptCommonInteraction:ShowBodyMgr(true)
            else
                self.nCurSelectClass1Index = 1
                self.scriptCommonInteraction:ShowBodyMgr(false)
            end
            if nType == PageType.Face or nType == PageType.Hair then
                self.nCurSelectClass2Index = 0
            else
                self.nCurSelectClass2Index = 1
            end

            self.nCurSelectClass3Index = 1

            local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
            if self.nCurSelectPageIndex == PageType.Face or
                self.nCurSelectPageIndex == PageType.Makeup or
                self.nCurSelectPageIndex == PageType.Prefab or
                self.nCurSelectPageIndex == PageType.Hair then
                moduleRole.UpdateModelScale()
            else
                moduleRole.ResetModelScale()
            end

            self:UpdateInfo()

            self.scriptCommonInteraction:OpenCellView(false)
            BuildPresetData.PausePlayAnimation(self.nCurSelectPageIndex == PageType.Face or self.nCurSelectPageIndex == PageType.Prefab or self.nCurSelectPageIndex == PageType.Makeup)
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupPage, tog)
    end

    for nType, tog in ipairs(self.tbTogSubType) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nCurSelectClass3Index = nType
            if self.nCurSelectPageIndex == PageType.Makeup then
                self:UpdateMakeupRightInfo()
            end
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjustType, tog)
    end

    UIHelper.SetToggleGroupSelected(self.TogGroupPage, self.nCurSelectPageIndex - 1)

    self.scriptCommonInteraction:SetInputDataCallback(function ()
        self:UpdateModleInfo()
        if ShareStationData.bOpening or self.nCurSelectPageIndex == PageType.Recommend then
            return
        end

        if self.nCurSelectPageIndex == PageType.Prefab then
            self:UpdateDefaultList(true)
        else
            self:UpdateRightInfo()
        end
    end)
end

function UIBuildFaceSecondView:RegEvent()
    Event.Reg(self, "RESET_NEW_FACE", function ()
        if not ShareStationData.bOpening then
            self:UpdateDefaultList()
        end
    end)

    Event.Reg(self, "RESET_BODY", function ()
        BuildBodyData.ResetBodyData()
        if not ShareStationData.bOpening then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogWeather, false)
        UIHelper.SetSelected(self.TogClothes, false)
        UIHelper.SetSelected(self.TogEmotion, false)
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
                    -- WaitingTipsData.RemoveWaitingTips("LoadModel")
                    Timer.DelTimer(self, self.nLoadTimerID)
                    self.nLoadTimerID = nil
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceDefault, function ()
        if self.nCurSelectPageIndex == PageType.Face then
            self:UpdateModleInfo()
        elseif self.nCurSelectPageIndex == PageType.Prefab then
            self:UpdateDefaultList(true)
            self:UpdateModleInfo()
        end
        Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.DEFAULT , 0)
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceSubPrefab, function ()
        if self.nCurSelectPageIndex == PageType.Face then
            self:UpdateFaceDefaultRightInfo(true)
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValueBegin, function (tbInfo, nValue)
        if self.nCurSelectPageIndex == PageType.Face then
            self:EnableFaceHighlight(true, tbInfo.nBoneType)
        elseif self.nCurSelectPageIndex == PageType.Body then
            self:EnableBodyHighlight(true, tbInfo.nBodyType)
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValueEnd, function (tbInfo, nValue)
        if self.nCurSelectPageIndex == PageType.Face then
            self:EnableFaceHighlight(false, tbInfo.nBoneType)
        elseif self.nCurSelectPageIndex == PageType.Body then
            self:EnableBodyHighlight(false, tbInfo.nBodyType)
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValue, function (tbInfo, nValue)
        if self.nCurSelectPageIndex == PageType.Face then
            BuildFaceData.tNowFaceData.tBone[tbInfo.nBoneType] = nValue
            self:UpdateModleInfo()
        elseif self.nCurSelectPageIndex == PageType.Body then
            BuildBodyData.tNowBodyData[tbInfo.nBodyType] = nValue
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupValue, function ()
        if self.nCurSelectPageIndex == PageType.Makeup then
            self:UpdateMakeupRightInfo(true)
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupPrefab, function ()
        if self.nCurSelectPageIndex == PageType.Makeup then
            self:UpdateMakeupRightInfo(true)
            self:UpdateDetailBtnState()
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupColor, function (nType, nShowID, nColorID)
        if self.nCurSelectPageIndex == PageType.Makeup then
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildHairValue, function (nClassIndex)
        if self.nCurSelectPageIndex == PageType.Hair then
            self.nCurSelectClass2Index = nClassIndex
            self:UpdateClass1Info()
            self:UpdateModleInfo()
            Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.DEFAULT , 0)
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildBodyDefault, function ()
        if self.nCurSelectPageIndex == PageType.Body then
            self:UpdateModleInfo()
            Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.DEFAULT , 0)
        end
    end)

    Event.Reg(self, EventType.OnRestoreBuildFaceCacheDataStep2, function (tbData)
        local nResult = BuildFaceData.ImportData(tbData)
        if nResult then
            if not ShareStationData.bOpening then
                TipsHelper.ShowNormalTip(g_tStrings.STR_NEW_FACE_DATA_IMPROT)
            end
            self:UpdateDefaultList(true)
            self:UpdateModleInfo()
            self:UpdateRightInfo()
            self:UpdateRoleModel()
        end
    end)

    Event.Reg(self, EventType.OnShowPageBottomBar, function(callback, bIsRightSidePage)
        if bIsRightSidePage then
            UIHelper.SetVisible(self.WidgetAnchorRight, true)
        else
            UIHelper.SetVisible(self.WidgetAnchorLeft, true)
        end
    end)

    Event.Reg(self, EventType.OnHidePageBottomBar, function(callback, bIsRightSidePage)
        if bIsRightSidePage then
            UIHelper.SetVisible(self.WidgetAnchorRight, false)
        else
            UIHelper.SetVisible(self.WidgetAnchorLeft, false)
        end
    end)
end

function UIBuildFaceSecondView:UpdateInfo()
    self:UpdatePageTogInfo()
    self:UpdatePageInfo()
    self:UpdateClass1Info()
    self:UpdateClass2Info()
    self:UpdateRightInfo()

    self:UpdateModleInfo()
    self:UpdateBtnState()
end

function UIBuildFaceSecondView:UpdateDefaultList(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetList2, false)
    UIHelper.SetVisible(self.WidgetDefaultList, true)
    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutTabList)
    end)

    UIHelper.HideAllChildren(self.ScrollViewDefaultList)

    self.tbFaceCell = self.tbFaceCell or {}
    for i, tbData in ipairs(BuildFaceData.tFaceList) do
        if not self.tbFaceCell[i] then
            self.tbFaceCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDefaultList)
            UIHelper.ToggleGroupAddToggle(self.TogGroupDefaultList, self.tbFaceCell[i].ToggleSelect)
        end

        UIHelper.SetVisible(self.tbFaceCell[i]._rootNode, true)
        self.tbFaceCell[i]:OnEnter(3, tbData)
    end

    if not bJustUpdateState then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefaultList)
    end
end

function UIBuildFaceSecondView:UpdateModleInfo()
    local ModleView = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
    if self.nCurSelectPageIndex == PageType.Face or self.nCurSelectPageIndex == PageType.Prefab or self.nCurSelectPageIndex == PageType.Recommend then
        if BuildFaceData.tNowFaceData then
            ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tDecal, BuildFaceData.tNowFaceData.tDecoration, true)
        end
        Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Face, true)
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        ModleView:SetFaceDecals(BuildFaceData.nRoleType, BuildFaceData.tNowFaceData.tDecal, true)
        ModleView:SetFacePartID(BuildFaceData.tNowFaceData.tDecoration, true, BuildFaceData.nRoleType)
        Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Face, true)
    elseif self.nCurSelectPageIndex == PageType.Hair then
        if self.nCurSelectClass2Index ~= 0 then
            self:UpdateRoleModel()
        end
        Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Hair, true)
    elseif self.nCurSelectPageIndex == PageType.Body then
        ModleView:SetBodyReshapingParams(BuildBodyData.tNowBodyData)
        Event.Dispatch(EventType.OnUpdateBuildFaceModule, g_tBuildFaceCameraStep2Body, true)
    end
end

function UIBuildFaceSecondView:UpdateRoleModel()
    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    moduleRole.UpdateRoleModel()
end

function UIBuildFaceSecondView:UpdatePageTogInfo()
    if self.nKungfuID == KUNGFU_ID.SHAO_LIN then
        UIHelper.SetVisible(self.tbTogPage[PageType.Hair], false)
        if self.nCurSelectPageIndex == PageType.Hair then
            self.nCurSelectPageIndex = PageType.Face
            self.nCurSelectClass1Index = 1
            self.nCurSelectClass2Index = 1
            self.nCurSelectClass3Index = 1
        end
    else
        UIHelper.SetVisible(self.tbTogPage[PageType.Hair], true)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab1)
end

function UIBuildFaceSecondView:UpdatePageInfo()
    local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
    local nCameraStatus = LoginCameraStatus.ROLE_LIST
    self.tbClassConfig = nil
    self.tbCurCameraStep = g_tBuildFaceCameraStep1
    if self.nCurSelectPageIndex == PageType.Face then
        local tFaceBoneList = BuildFaceData.tFaceBoneList
        self.tbClassConfig = Lib.copyTab(tFaceBoneList)
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_FACE
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        local tFaceDecalList = BuildFaceData.tDecalClassList
        self.tbClassConfig = Lib.copyTab(tFaceDecalList)
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_FACE
    elseif self.nCurSelectPageIndex == PageType.Hair then
        local tHairClass = BuildHairData.GetHairClass()
        self.tbClassConfig = Lib.copyTab(tHairClass)
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_HAIR
    elseif self.nCurSelectPageIndex == PageType.Body then
        local tBodyList = Table_GetBodyBoneList(self.nRoleType)
        self.tbClassConfig = Lib.copyTab(tBodyList)
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_BODY
    elseif self.nCurSelectPageIndex == PageType.Prefab then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_FACE
    elseif self.nCurSelectPageIndex == PageType.Recommend then
        nCameraStatus = LoginCameraStatus.BUILD_FACE_STEP2_BUILDALL
    end

    if nCameraStatus == LoginCameraStatus.BUILD_FACE_STEP2_FACE then
        self.tbCurCameraStep = g_tBuildFaceCameraStep2Face
    elseif nCameraStatus == LoginCameraStatus.BUILD_FACE_STEP2_HAIR then
        self.tbCurCameraStep = g_tBuildFaceCameraStep2Hair
    elseif nCameraStatus == LoginCameraStatus.BUILD_FACE_STEP2_BODY then
        self.tbCurCameraStep = g_tBuildFaceCameraStep2Body
    end


    moduleCamera.SetCameraStatus(nCameraStatus, self.nRoleType)
    self.nCurCameraStatus = nCameraStatus
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab1)
end

function UIBuildFaceSecondView:UpdateClass1Info()
    if self.nCurSelectPageIndex == PageType.Prefab then
        self:UpdateDefaultList()
        return
    else
        UIHelper.SetVisible(self.WidgetList2, true)
        UIHelper.SetVisible(self.WidgetDefaultList, false)
        UIHelper.LayoutDoLayout(self.LayoutTabList)
    end

    if self.nCurSelectPageIndex == PageType.Recommend then
        return
    end

    if self.nCurSelectPageIndex == PageType.Hair then
        UIHelper.SetVisible(self.WidgetList2, false)
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbData = {}
    local nPrefabID1 = PREFAB_ID.WidgetLeftTabCell
    local nPrefabID2 = PREFAB_ID.WidgetLeftTabCell_Tree

    if self.nCurSelectPageIndex == PageType.Body then
        local tbClassConfig = {}
        tbClassConfig.szAreaName = UIHelper.UTF8ToGBK("预设")

        table.insert(tbData, {
            tArgs = tbClassConfig,
            tItemList = {},
            fnSelectedCallback = function (bSelected)
                if bSelected then
                    self.nCurSelectClass1Index = 0
                    self.nCurSelectClass2Index = 1
                    self.nCurSelectClass3Index = 1
                    self:UpdateRightInfo()
                    self:UpdateBtnState()
                end
            end
        })
    end

    for i, tbConfig in ipairs(self.tbClassConfig) do
        local bShow = true
        if self.nCurSelectPageIndex == PageType.Hair then
            local tbTempConfig = BuildHairData.GetHairConfigWithClassIndex(i)
            if not tbTempConfig or #tbTempConfig <= 0 then
                bShow = false
            end
        end

        if bShow then
            local tbItemList = {}
            if self.nCurSelectPageIndex ~= PageType.Body and self.nCurSelectPageIndex ~= PageType.Hair then
                if self.nCurSelectPageIndex == PageType.Face then
                    if not string.is_nil(tbConfig.szAreaDefault) then
                        local tbClass2Config = {}
                        tbClass2Config.szClassName = tbConfig.szDefaultName

                        local tbTempConfig = { tArgs = {tbClassConfig = tbClass2Config} }
                        tbTempConfig.tArgs.funcClickCallback = function (tbInfo, bIsClass1)
                            self.nCurSelectClass2Index = 0
                            self.nCurSelectClass3Index = 1
                            self:UpdateRightInfo()
                            self:UpdateBtnState()
                        end

                        table.insert(tbItemList, tbTempConfig)
                    end
                end

                for j, tbClass2Config in ipairs(tbConfig) do
                    local tbTempConfig =  { tArgs = {tbClassConfig = tbClass2Config} }
                    tbTempConfig.tArgs.funcClickCallback = function (tbInfo, bIsClass1)
                        self.nCurSelectClass2Index = j
                        self.nCurSelectClass3Index = 1
                        self:UpdateRightInfo()
                        self:UpdateBtnState()
                    end
                    table.insert(tbItemList, tbTempConfig)
                end
            end

            tbConfig.bShowArrow = #tbItemList > 0
            table.insert(tbData, {
                tArgs = tbConfig,
                tItemList = tbItemList,
                fnSelectedCallback = function (bSelected)
                    if bSelected then
                        if self.nCurSelectPageIndex == PageType.Face then
                            BuildFaceData.GetAreaDefault(tbConfig.szAreaDefault)
                        end

                        UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupClass1)
                        local tbCells = self.scriptScrollViewTab2.tContainerList[i].scriptContainer:GetItemScript()
                        for nIndex, cell in ipairs(tbCells) do
                            cell:AddTogGroup(self.TogGroupClass1)
                        end
                        if self.nCurSelectPageIndex == PageType.Face then
                            self.nCurSelectClass2Index = 0
                        else
                            self.nCurSelectClass2Index = 1
                        end
                        UIHelper.SetToggleGroupSelected(self.TogGroupClass1, self.nCurSelectClass2Index - 1)
                        self.nCurSelectClass1Index = i
                        self.nCurSelectClass3Index = 1
                        self:UpdateClass2Info()
                        self:UpdateRightInfo()
                        self:UpdateBtnState()
                    end
                end
            })
        end
    end

    local func = function(scriptContainer, tArgs)
        local szName = UIHelper.GBKToUTF8(tArgs.szAreaName or tArgs.szName)
        local szImg = BuildFaceLoginClassImg[szName]
        UIHelper.SetSpriteFrame(scriptContainer.ImgType, string.format("%s2.png", szImg))
        UIHelper.SetSpriteFrame(scriptContainer.ImgTypeSelected, string.format("%s1.png", szImg))

        UIHelper.SetString(scriptContainer.LabelTitle, szName)
        UIHelper.SetString(scriptContainer.LabelSelect, szName)

        UIHelper.SetVisible(scriptContainer.ImgArrow1, not not tArgs.bShowArrow)
        UIHelper.SetVisible(scriptContainer.ImgArrow2, not not tArgs.bShowArrow)
    end

    self.scriptScrollViewTab2:ClearContainer()
    self.scriptScrollViewTab2:SetOuterInitSelect()
    UIHelper.SetupScrollViewTree(self.scriptScrollViewTab2,
        nPrefabID1,
        nPrefabID2,
        func, tbData, true)

    local nCurSelectIndex1 = self.nCurSelectClass1Index
    if self.nCurSelectPageIndex == PageType.Body then
        nCurSelectIndex1 = nCurSelectIndex1 + 1
    end

    local scriptContainer = self.scriptScrollViewTab2.tContainerList[nCurSelectIndex1].scriptContainer
    Timer.AddFrame(self, 1, function()
        scriptContainer:SetSelected(true)
    end)
end

function UIBuildFaceSecondView:UpdateClass2Info()
    -- UIHelper.HideAllChildren(self.ScrollViewTab3)

    -- if self.nCurSelectPageIndex == PageType.Body or
    --     self.nCurSelectPageIndex == PageType.Hair then
    --     return
    -- end

    -- if not self.tbClassConfig then
    --     return
    -- end

    -- local tbConfig = self.tbClassConfig[self.nCurSelectClass1Index]
    -- if not tbConfig then
    --     return
    -- end

    -- self.tbClass2Cell = self.tbClass2Cell or {}
    -- if self.nCurSelectPageIndex == PageType.Face then
    --     if not string.is_nil(tbConfig.szAreaDefault) then
    --         BuildFaceData.GetAreaDefault(tbConfig.szAreaDefault)
    --         local tbClassConfig = Lib.copyTab(BuildFaceData.tBoneAreaDefault)
    --         tbClassConfig.szClassName = tbConfig.szDefaultName

    --         if not self.tbClass2Cell[0] then
    --             self.tbClass2Cell[0] = UIHelper.AddPrefab(PREFAB_ID.WidgetLeftTabCell2, self.ScrollViewTab3)
    --             self.tbClass2Cell[0]:AddTogGroup(self.TogGroupClass2)
    --             self.tbClass2Cell[0]:SetClickCallback(function (tbInfo, bIsClass1)
    --                 self.nCurSelectClass2Index = 0
    --                 self.nCurSelectClass3Index = 1
    --                 self:UpdateRightInfo()
    --                 self:UpdateBtnState()
    --             end)
    --         end

    --         UIHelper.SetVisible(self.tbClass2Cell[0]._rootNode, true)
    --         self.tbClass2Cell[0]:OnEnter(tbClassConfig, false)
    --     end
    -- end

    -- for i, tbClass2Config in ipairs(tbConfig) do
    --     if not self.tbClass2Cell[i] then
    --         self.tbClass2Cell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetLeftTabCell2, self.ScrollViewTab3)
    --         self.tbClass2Cell[i]:AddTogGroup(self.TogGroupClass2)
    --         self.tbClass2Cell[i]:SetClickCallback(function (tbInfo, bIsClass1)
    --             self.nCurSelectClass2Index = i
    --             self.nCurSelectClass3Index = 1
    --             self:UpdateRightInfo()
    --             self:UpdateBtnState()
    --         end)
    --     end

    --     UIHelper.SetVisible(self.tbClass2Cell[i]._rootNode, true)
    --     self.tbClass2Cell[i]:OnEnter(tbClass2Config, false)
    -- end

    -- UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab3)
    -- UIHelper.SetToggleGroupSelected(self.TogGroupClass2, self.nCurSelectClass2Index)
end

function UIBuildFaceSecondView:UpdateRightInfo()
    UIHelper.SetVisible(self.WidgetDefault, false)
    UIHelper.SetVisible(self.WidgetAdjust, false)
    UIHelper.SetVisible(self.WidgetHairPart, false)
    UIHelper.SetVisible(self.WidgetBodyPart, false)
    UIHelper.SetVisible(self.WidgetDetailAdjust, false)
    UIHelper.SetVisible(self.WidgetRecommend, false)
    UIHelper.SetVisible(self.LayoutList3, false)
    UIHelper.LayoutDoLayout(self.LayoutList3)
    self:ShowBuildFaceSyncSideTog(false)
    local bShowFaceMgr = self.nCurSelectPageIndex == PageType.Prefab or self.nCurSelectPageIndex == PageType.Face or self.nCurSelectPageIndex == PageType.Makeup
    UIHelper.SetVisible(self.BtnInput, bShowFaceMgr)
    UIHelper.SetVisible(self.BtnPrint, bShowFaceMgr)
    UIHelper.SetVisible(self.BtnMyCloud, bShowFaceMgr)
    UIHelper.SetVisible(self.BtnCommit, bShowFaceMgr)
    UIHelper.SetVisible(self.BtnEnterFaceCode, bShowFaceMgr)

    self:OpenDetailAdjustView(false)

    if self.nCurSelectPageIndex == PageType.Face then
        if self.nCurSelectClass2Index == 0 then
            self:UpdateFaceDefaultRightInfo()
        else
            self:UpdateFaceRightInfo()
        end
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        self:UpdateMakeupRightInfo()
    elseif self.nCurSelectPageIndex == PageType.Hair then
        self:UpdateHairRightInfo()
    elseif self.nCurSelectPageIndex == PageType.Body then
        if self.nCurSelectClass1Index == 0 then
            self:UpdateBodyDefaultRightInfo()
        else
            self:UpdateBodyRightInfo()
        end
    elseif self.nCurSelectPageIndex == PageType.Recommend then
        self:UpdateRecommendRightInfo()
    end
    self.scriptCommonInteraction:OpenCellView(false)
end

function UIBuildFaceSecondView:UpdateFaceDefaultRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDefault, true)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDefault)
    end

    local tbClassConfig = Lib.copyTab(BuildFaceData.tBoneAreaDefault)
    for i, nBoneDefault in ipairs(tbClassConfig) do
        self.tbDefaultCell = self.tbDefaultCell or {}
        if not self.tbDefaultCell[i] then
            self.tbDefaultCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDefault)
            UIHelper.ToggleGroupAddToggle(self.TogGroupDefault, self.tbDefaultCell[i].ToggleSelect)
        end
        local tInfo = Table_GetFaceBoneDefault(nBoneDefault, BuildFaceData.nRoleType)

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDefaultCell[i]._rootNode, true)
        end
        self.tbDefaultCell[i]:OnEnter(4, tInfo)
    end

    if not bJustUpdateState then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefault)
    end
end

function UIBuildFaceSecondView:UpdateFaceRightInfo()
    self.bWidgetAdjustVisible = true
    UIHelper.SetVisible(self.WidgetAdjust, true)
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tbAdjustCell = {}
    self.tbAdjustTitleCell = {}

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    for i, tbAdjustConfig in ipairs(tbConfig2) do
        if tbAdjustConfig.szDivideName ~= "" then
            if not self.tbAdjustTitleCell[i] then
                self.tbAdjustTitleCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetFaceAdjustTittleCell_Login, self.ScrollViewAdjust)
            end

            UIHelper.SetVisible(self.tbAdjustTitleCell[i]._rootNode, true)
            self.tbAdjustTitleCell[i]:OnEnter(UIHelper.GBKToUTF8(tbAdjustConfig.szDivideName))
        end

        if not self.tbAdjustCell[i] then
            self.tbAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetAdjustCell, self.ScrollViewAdjust)
        end

        UIHelper.SetVisible(self.tbAdjustCell[i]._rootNode, true)
        self.tbAdjustCell[i]:OnEnter(self.nCurSelectPageIndex, tbAdjustConfig, BuildFaceData.tNowFaceData.tBone[tbAdjustConfig.nBoneType])
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UIBuildFaceSecondView:UpdateMakeupRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDetailAdjust, true)
    UIHelper.SetVisible(self.LayoutList3, false)
    UIHelper.LayoutDoLayout(self.LayoutList3)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDetailAdjust)
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end

    local bMeanwhile, nMeanwhile = BuildFaceData.UpdateMeanwhile(self.nCurSelectClass1Index, self.nCurSelectClass2Index)
    self:ShowBuildFaceSyncSideTog(bMeanwhile, nMeanwhile)

    if #tbConfig2 > 1 then
        UIHelper.SetVisible(self.WidgetDetailAdjust, false)
        UIHelper.SetVisible(self.LayoutList3, true)
        UIHelper.LayoutDoLayout(self.LayoutList3)
        UIHelper.LayoutDoLayout(self.LayoutTabList)

        if bJustUpdateState then
            return
        end

        local tbData = {}
        for i, tbConfig3 in ipairs(tbConfig2) do
            if not tbConfig2.bIsDecoration then
                self:GetDecalsList(tbData, tbConfig3, i)
            else
                self:GetDecorationSubList(tbData, tbConfig3, i)
            end
        end

        local func = function(scriptContainer, tArgs)
            local szName = UIHelper.GBKToUTF8(tArgs.szSubClassName)

            if string.find(szName, "·") then
                local tbName = string.split(szName, "·")
                if #tbName > 1 then
                    szName = tbName[#tbName]
                end
            end

            UIHelper.SetString(scriptContainer.LabelTitle, szName)
            UIHelper.SetString(scriptContainer.LabelSelect, szName)
        end

        self.scriptScrollViewTab3:ClearContainer()
        self.scriptScrollViewTab3:SetOuterInitSelect()
        UIHelper.SetupScrollViewTree(self.scriptScrollViewTab3,
            PREFAB_ID.WidgetLeftTabCell2_Login,
            PREFAB_ID.WidgetBulidFaceItem_80,
            func, tbData, true)

        local nCurSelectIndex3 = self.nCurSelectClass3Index

        local scriptContainer = self.scriptScrollViewTab3.tContainerList[nCurSelectIndex3].scriptContainer
        Timer.AddFrame(self, 1, function()
            scriptContainer:SetSelected(true)
        end)
        return
    end

    local bIsDecoration     = tbConfig2.bIsDecoration
    local nType             = tbConfig2[self.nCurSelectClass3Index].nDecalsType
    local tLogicDecal       = bIsDecoration and hFaceLiftManager.GetDecorationInfoV2(self.nRoleType, nType)
                                or hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
	local tDecalList        = bIsDecoration and BuildFaceData.GetDecorationList(self.nRoleType, nType)
                                or BuildFaceData.GetDecalList(self.nRoleType, nType)

    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
    for i, nShowID in ipairs(tDecalList) do
        self.tbDetailAdjustCell = self.tbDetailAdjustCell or {}
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = {}
        if bIsDecoration then
            tUIInfo = BuildFaceData.GetDecoration(nType, nShowID)
        else
            tUIInfo = BuildFaceData.GetDecal(self.nRoleType, nType, nShowID)
        end

        if not self.tbDetailAdjustCell[i] then
            self.tbDetailAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDetailAdjust)
            UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, self.tbDetailAdjustCell[i].ToggleSelect)
        end

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDetailAdjustCell[i]._rootNode, true)
        end
        self.tbDetailAdjustCell[i]:OnEnter(1, tUIInfo, tDecalInfo)
    end

    if not bJustUpdateState then
        self:UpdateDetailBtnState()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailAdjust)
    end
end

function UIBuildFaceSecondView:UpdateHairRightInfo()
    UIHelper.SetVisible(self.WidgetHairPart, true)
    self.scriptHairPart = self.scriptHairPart or UIHelper.GetBindScript(self.WidgetHairPart)
    self.scriptHairPart:OnEnter(self.nCurSelectClass1Index , nil , self.nRoleType)
end

function UIBuildFaceSecondView:UpdateBodyDefaultRightInfo()
    UIHelper.SetVisible(self.WidgetBodyPart, true)
    self.scriptBodyPart = self.scriptBodyPart or UIHelper.GetBindScript(self.WidgetBodyPart)
    self.scriptBodyPart:OnEnter(self.nRoleType)
end

function UIBuildFaceSecondView:UpdateBodyRightInfo()
    UIHelper.SetVisible(self.WidgetAdjust, true)
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tbAdjustCell = {}

    if not self.tbClassConfig then
        return
    end

    local tbConfig = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig then
        return
    end

    for i, tbAdjustConfig in ipairs(tbConfig) do
        if not self.tbAdjustCell[i] then
            self.tbAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetAdjustCell, self.ScrollViewAdjust)
        end

        UIHelper.SetVisible(self.tbAdjustCell[i]._rootNode, true)
        self.tbAdjustCell[i]:OnEnter(self.nCurSelectPageIndex, tbAdjustConfig, BuildBodyData.tNowBodyData[tbAdjustConfig.nBodyType])
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UIBuildFaceSecondView:UpdateRecommendRightInfo()
    UIHelper.SetVisible(self.WidgetList2, self.nCurSelectPageIndex == PageType.Body)
    UIHelper.SetVisible(self.WidgetRecommend, true)
    UIHelper.LayoutDoLayout(self.LayoutTabList)

    local tFilter = {}
    local bBody = self.nCurSelectPageIndex == PageType.Body

    local nDataType = bBody and SHARE_DATA_TYPE.BODY or SHARE_DATA_TYPE.FACE
    tFilter.nRoleType = self.nRoleType

    if nDataType == SHARE_DATA_TYPE.FACE then
        tFilter.nFaceType = FACE_TYPE.NEW -- 创角只允许创写实
    end

    self.scriptRecommend = self.scriptRecommend or UIHelper.GetBindScript(self.WidgetRecommend)
    self.scriptRecommend:OnEnter(true, nDataType, tFilter)
end


function UIBuildFaceSecondView:UpdateBtnState()
    if self.nCurSelectPageIndex == PageType.Face then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, self.nCurSelectClass2Index > 0)
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, true)
    elseif self.nCurSelectPageIndex == PageType.Hair then
        UIHelper.SetVisible(self.BtnRevertAll, false)
        UIHelper.SetVisible(self.BtnRevert, false)
    elseif self.nCurSelectPageIndex == PageType.Body then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, false)
    elseif self.nCurSelectPageIndex == PageType.Prefab then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIBuildFaceSecondView:UpdateDetailBtnState()
    if self.nCurSelectPageIndex ~= PageType.Makeup then
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end

    local bIsDecoration     = tbConfig2.bIsDecoration
    local tbConfig3         = tbConfig2[self.nCurSelectClass3Index]
    local nType             = bIsDecoration and tbConfig3.nDecorationType or tbConfig3.nDecalsType
    local tLogicDecal       = bIsDecoration and hFaceLiftManager.GetDecorationInfoV2(self.nRoleType, nType)
                                or hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
    local tNowSetting       = BuildFaceData.tNowFaceData[bIsDecoration and "tDecoration" or "tDecal"][nType]
    if not tNowSetting then
        return
    end

    local nShowID = tNowSetting.nShowID
	local tDecalInfo = tLogicDecal[nShowID]

    if tDecalInfo and #tDecalInfo.tColorID > 1 then
        self:OpenDetailAdjustView(true)
    else
        self:OpenDetailAdjustView(false)
    end
end

function UIBuildFaceSecondView:EnableFaceHighlight(bEnabled, nBoneType)
    local ModleView = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)

    if bEnabled then
        ModleView:EnableFaceHighlight(nBoneType)
        self.nLastHighlightFaceType = nBoneType
    elseif self.nLastHighlightFaceType then
        ModleView:DisableFaceHighlight(self.nLastHighlightFaceType)
        self.nLastHighlightFaceType = nil
    end
end

function UIBuildFaceSecondView:EnableBodyHighlight(bEnabled, nBodyType)
    local ModleView = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)

    if bEnabled then
        ModleView:EnableHighlight(nBodyType)
        self.nLastHighlightBodyType = nBodyType
    elseif self.nLastHighlightBodyType then
        ModleView:DisableHighlight(self.nLastHighlightBodyType)
        self.nLastHighlightBodyType = nil
    end
end

function UIBuildFaceSecondView:OpenDetailAdjustView(bOpen)
    if not self.scriptDetailAdjust then
        self.scriptDetailAdjust = UIHelper.GetBindScript(self.WidgetColorAdjust)
    end

    UIHelper.SetVisible(self.WidgetColorAdjust, bOpen)

    if not bOpen then
        return
    end

    if self.nCurSelectPageIndex ~= PageType.Makeup then
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end

    local nType             = tbConfig2[self.nCurSelectClass3Index].nDecalsType
    local tLogicDecal 		= hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
	local tDecalList        = BuildFaceData.GetDecalList(self.nRoleType, nType)

    local tNowSetting = BuildFaceData.tNowFaceData.tDecal[nType]
    local nShowID = tNowSetting.nShowID
    local tUIInfo = BuildFaceData.GetDecal(self.nRoleType, nType, nShowID)
	local tDecalInfo = tLogicDecal[nShowID]

    self.scriptDetailAdjust:OnEnter(tbConfig2.szClassName, tDecalInfo, tUIInfo, Lib.copyTab(tNowSetting))
end

function UIBuildFaceSecondView:OpenInterationView(bOpen)
    UIHelper.SetVisible(self.WidgetAnchorRightContent, not bOpen)
end

function UIBuildFaceSecondView:ShowBuildFaceSyncSideTog(bShow, nMeanwhile)
    UIHelper.SetVisible(self.WidgetList3LeftRight, bShow)
    self.nCurMeanwhile = nMeanwhile
    if bShow then
        BuildFaceData.SetMeanwhileSwitch(self.nCurMeanwhile, UIHelper.GetSelected(self.TogList3LeftRight))
    end
    UIHelper.LayoutDoLayout(self.LayoutList3)
end

function UIBuildFaceSecondView:GetDecalsList(tbData, tbConfig, nIndex)
    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local tItemList         = {}
    local nType             = tbConfig.nDecalsType
    local tLogicDecal       = hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
    local tDecalList        = BuildFaceData.GetDecalList(self.nRoleType, nType)

    for i, nShowID in ipairs(tDecalList) do
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = BuildFaceData.GetDecal(self.nRoleType, nType, nShowID)
        local tbTempConfig =  { tArgs = {nIconType = 1, tUIInfo = tUIInfo, tDecalInfo = tDecalInfo} }
        table.insert(tItemList, tbTempConfig)
    end

    table.insert(tbData, {
        tArgs = tbConfig,
        tItemList = tItemList,
        fnSelectedCallback = function (bSelected, scriptContainer)
            if bSelected then
                self.nCurSelectClass3Index = nIndex
                UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
                local tbCells = scriptContainer:GetItemScript()
                local nSelectIndex = 0
                for j, scriptCell in ipairs(tbCells) do
                    local tbInfo = tItemList[j].tArgs
                    local tDecal = BuildFaceData.tNowFaceData.tDecal[tbInfo.tUIInfo.nType]
                    scriptCell:OnEnter(tbInfo.nIconType, tbInfo.tUIInfo, tbInfo.tDecalInfo)
                    UIHelper.SetSwallowTouches(scriptCell.ToggleSelect, false)
                    UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, scriptCell.ToggleSelect)

                    if tDecal.nShowID == tbInfo.tUIInfo.nShowID then
                        nSelectIndex = j - 1
                    end
                end

                UIHelper.SetToggleGroupSelected(self.TogGroupDetailAdjust, nSelectIndex)
                self:UpdateDetailBtnState()
            end
        end
    })
end

function UIBuildFaceSecondView:GetDecorationSubList(tbData, tbConfig, nIndex)
    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local tItemList         = {}
    local nType             = tbConfig.nDecorationType
    local tLogicDecal       = hFaceLiftManager.GetDecorationInfoV2(self.nRoleType, nType)
    local tDecalList        = BuildFaceData.GetDecorationSub(nType)

    local bEmpty = true
    for i, nShowID in ipairs(tDecalList) do
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = BuildFaceData.GetDecoration(nType, nShowID)
        local tbTempConfig =  { tArgs = {nIconType = 1, tUIInfo = tUIInfo, tDecalInfo = tDecalInfo} }
        if nShowID ~= 0 then
            bEmpty = false
        end
        table.insert(tItemList, tbTempConfig)
    end

    if not bEmpty then
        table.insert(tbData, {
            tArgs = tbConfig,
            tItemList = tItemList,
            fnSelectedCallback = function (bSelected, scriptContainer)
                if bSelected then
                    self.nCurSelectClass3Index = nIndex
                    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
                    local tbCells = scriptContainer:GetItemScript()
                    local nSelectIndex = 0
                    for j, scriptCell in ipairs(tbCells) do
                        local tbInfo = tItemList[j].tArgs
                        local tDecal = BuildFaceData.tNowFaceData.tDecoration[tbInfo.tUIInfo.nDecorationType]
                        scriptCell:OnEnter(tbInfo.nIconType, tbInfo.tUIInfo, tbInfo.tDecalInfo)
                        UIHelper.SetSwallowTouches(scriptCell.ToggleSelect, false)
                        UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, scriptCell.ToggleSelect)
                        
                        if tDecal.nShowID == tbInfo.tUIInfo.nShowID then
                            nSelectIndex = j - 1
                        end
                    end
                    
                    UIHelper.SetToggleGroupSelected(self.TogGroupDetailAdjust, nSelectIndex)
                    self:UpdateDetailBtnState()
                end
            end
        })
    end
end

return UIBuildFaceSecondView