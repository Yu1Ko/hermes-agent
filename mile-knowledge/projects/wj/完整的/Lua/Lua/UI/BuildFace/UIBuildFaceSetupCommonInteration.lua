-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIBuildFaceSetupCommonInteration
-- Date: 2024-04-10 11:16:13
-- Desc: 创角捏脸步骤公有交互内容
-- ---------------------------------------------------------------------------------

local UIBuildFaceSetupCommonInteration = class("UIBuildFaceSetupCommonInteration")

local tWeatherPresetIDs = {2,3,4,5,6}

local PageType =
{
    Clothes = BuildPresetData.PageType.Clothes,
    Weather = BuildPresetData.PageType.Weather,
    Action = BuildPresetData.PageType.Action,
}

function UIBuildFaceSetupCommonInteration:OnEnter(nRoleType , nKungfuID ,togSelectCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nRoleType = nRoleType
    self.nKungfuID = nKungfuID
    self.togSelectCallback = togSelectCallback
    self:UpdateInfo()
end

function UIBuildFaceSetupCommonInteration:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if UIMgr.GetView(VIEW_ID.PanelShareStation) then
        UIMgr.Close(VIEW_ID.PanelShareStation)
    end
end

function UIBuildFaceSetupCommonInteration:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFaceStation, EventType.OnClick, function ()
        local nDataType = SHARE_DATA_TYPE.FACE
        if UIHelper.GetVisible(self.BtnEnterBodyCode) then
            nDataType = SHARE_DATA_TYPE.BODY
        end
        Event.Dispatch(EventType.OnOpenShareStation, nDataType)
    end)

    UIHelper.BindUIEvent(self.BtnMyCloud, EventType.OnClick, function ()
        self:ClearTogState()
        UIMgr.Open(VIEW_ID.PanelCoinFaceCodeList, true)
    end)

    UIHelper.BindUIEvent(self.BtnCommit, EventType.OnClick, function ()
        self:ClearTogState()
        -- UIMgr.Open(VIEW_ID.PanelPrintFaceToCloud)
        Event.Dispatch(EventType.OnStartDoUploadShareData, true)
    end)

    UIHelper.BindUIEvent(self.BtnEnterFaceCode, EventType.OnClick, function ()
        self:ClearTogState()
        UIMgr.Open(VIEW_ID.PanelEnterFaceCode, SHARE_DATA_TYPE.FACE)
    end)

    UIHelper.BindUIEvent(self.BtnMyCloudBody, EventType.OnClick, function ()
        self:ClearTogState()
        UIMgr.Open(VIEW_ID.PanelBodyCodeList, true)
    end)

    UIHelper.BindUIEvent(self.BtnCommitBody, EventType.OnClick, function ()
        self:ClearTogState()
        UIMgr.Open(VIEW_ID.PanelPrintFaceToCloud, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnEnterBodyCode, EventType.OnClick, function ()
        self:ClearTogState()
        UIMgr.Open(VIEW_ID.PanelEnterFaceCode, SHARE_DATA_TYPE.BODY)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelEditFolderName, function (szFileName)
            local tFace = BuildFaceData.tNowFaceData
            local bSucc, szMsg = NewFaceData.ExportData(szFileName, tFace, BuildFaceData.nRoleType, not BuildFaceData.bPrice)
            if not bSucc and szMsg then
                TipsHelper.ShowNormalTip(szMsg)
            end
        end)
    end)

    UIHelper.BindUIEvent(self.BtnInput, EventType.OnClick, function ()
        if Platform.IsWindows() and GetOpenFileName then
            local szFile = GetOpenFileName(g_tStrings.STR_NEW_FACE_LIFT_CHOOSE_FILE, g_tStrings.STR_FACE_LIFT_CHOOSE_INI .. "(*.ini)\0*.ini\0\0")
            if not string.is_nil(szFile) then
                self:LoadFaceData(szFile)
            end
        else
            UIMgr.Open(VIEW_ID.PanelFacePrintLocal, function (szFile)
                if not Platform.IsWindows() then
                    szFile = UIHelper.UTF8ToGBK(GetFullPath(szFile))
                end
                self:LoadFaceData(szFile)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.TogClothes, EventType.OnClick, function ()
        self.bClickClothes = not self.bClickClothes
        self.bClickWeather = false
        self.bClickEmotion = false
        UIHelper.SetSelected(self.TogWeather, false)
        UIHelper.SetSelected(self.TogEmotion, false)
        self:OpenCellView(self.bClickClothes , PageType.Clothes)
    end)

    UIHelper.BindUIEvent(self.TogWeather, EventType.OnClick, function ()
        self.bClickWeather = not self.bClickWeather
        self.bClickClothes = false
        self.bClickEmotion = false
        UIHelper.SetSelected(self.TogClothes, false)
        UIHelper.SetSelected(self.TogEmotion, false)
        self:OpenCellView(self.bClickWeather , PageType.Weather)
    end)

    UIHelper.BindUIEvent(self.TogEmotion, EventType.OnClick, function ()
        self.bClickEmotion = not self.bClickEmotion
        self.bClickClothes = false
        self.bClickWeather = false
        UIHelper.SetSelected(self.TogWeather, false)
        UIHelper.SetSelected(self.TogClothes, false)
        self:OpenCellView(self.bClickEmotion , PageType.Action)
    end)

    for i, tog in ipairs(self.tbTogEmotion) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self:OnSelectedEmotion(i)
            UIHelper.SetSelected(tog, false)
        end)
    end

    for i, img in ipairs(self.tbImgEmotion1) do
        UIHelper.SetTexture(img, BuildFaceAniImg[i])
    end
    for i, img in ipairs(self.tbImgEmotion2) do
        UIHelper.SetTexture(img, BuildFaceAniImg[i])
    end

    self:ShowActionToggle(false)

    UIHelper.SetVisible(self.BtnInput , Platform.IsWindows())
    UIHelper.SetVisible(self.BtnPrint , Platform.IsWindows())

end

function UIBuildFaceSetupCommonInteration:RegEvent()
    -- Event.Reg(self, EventType.OnSceneTouchBegan, function ()
    --     UIHelper.SetSelected(self.TogWeather, false)
    --     UIHelper.SetSelected(self.TogClothes, false)
    --     UIHelper.SetSelected(self.TogEmotion, false)
    -- end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.Add(self, 0.1, function ()
            UIHelper.CascadeDoLayoutDoWidget(self.LayoutRightTop, true, true)
        end)
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeData, function (bSuccess, szShareCode, szFilePath, nDataType)
        if bSuccess and ShareCodeData.szCurGetShareCode == szShareCode then
            if nDataType == SHARE_DATA_TYPE.FACE then
                self:LoadFaceData(szFilePath)
            elseif nDataType == SHARE_DATA_TYPE.BODY then
                self:LoadBodyData(szFilePath)
            end
        end
    end)

    Event.Reg(self, EventType.OnDownloadBodyCodeData, function (bSuccess, szCode, szFilePath)
        if bSuccess and BodyCodeData.szCurGetBodyCode == szCode then
            self:LoadBodyData(szFilePath)
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelCoinFaceCodeList or nViewID == VIEW_ID.PanelBodyCodeList then
            UIHelper.SetVisible(self.widgetTopLayout , false)
            UIHelper.SetVisible(self.WidgetRightList , false)
            UIHelper.SetVisible(self.TogWeather, false)
            UIHelper.SetVisible(self.TogClothes, false)
            UIHelper.SetVisible(self.TogEmotion, false)
        end

        if nViewID == VIEW_ID.PanelShareStation then
            UIHelper.SetVisible(self.AniAll, false)
            UIHelper.LayoutDoLayout(self.LayoutRightTop)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelCoinFaceCodeList or nViewID == VIEW_ID.PanelBodyCodeList then
            UIHelper.SetVisible(self.widgetTopLayout , true)
            UIHelper.SetVisible(self.WidgetRightList , self.bCurOpenState)
            UIHelper.SetVisible(self.TogWeather, self.bShowTogWeather)
            UIHelper.SetVisible(self.TogClothes, self.bShowTogClothes)
            UIHelper.SetVisible(self.TogEmotion, self.bShowTogEmotion)
        end

        if nViewID == VIEW_ID.PanelShareStation then
            UIHelper.SetVisible(self.AniAll, true)
            UIHelper.LayoutDoLayout(self.LayoutRightTop)
        end

        if nViewID == VIEW_ID.PanelFaceCoverCropping then
            UIHelper.SetVisible(self.AniAll, true)
        end
    end)

    Event.Reg(self, EventType.OnOpenShareStation, function (nDataType)
        UIHelper.PlayAni(self, self.AniAll, "AniRightShow")

        local nCurSuffix = 1
        local nRoleType = self.nRoleType
        UIMgr.OpenSingle(false, VIEW_ID.PanelShareStation, nDataType, nRoleType, nCurSuffix, true)
    end)

    Event.Reg(self, EventType.OnCloseShareStation, function ()
        -- UIHelper.SetVisible(self.BtnCommit , true)
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
        UIHelper.PlayAni(self, self.AniAll, "AniRightShow")
        UIMgr.Close(VIEW_ID.PanelShareStation)
    end)
end

function UIBuildFaceSetupCommonInteration:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBuildFaceSetupCommonInteration:UpdateInfo()
    if self.BtnMyCloud then
        self.widgetTopLayout = UIHelper.GetParent( UIHelper.GetParent(self.BtnMyCloud))
    end
    self.bShowTogWeather = UIHelper.GetVisible(self.TogWeather)
    self.bShowTogClothes = UIHelper.GetVisible(self.TogClothes)
    self.bShowTogEmotion = UIHelper.GetVisible(self.TogEmotion)
end
-- ----------------------------------------------------------
-- Clothes
-- ----------------------------------------------------------

function UIBuildFaceSetupCommonInteration:LoadClothesCell(itemParent)
    local tbExteriorCell = {}
    local tbBodyCloths = {}
    local tbSchoolCloths = TabHelper.GetUILoginSchoolBodyClothTab(self.nRoleType , KUNGFU_ID_FORCE_TYPE[self.nKungfuID])
    for k, v in pairs(tbSchoolCloths) do
        v.szMobileIconPath = UIHelper.UTF8ToGBK(v.szIconPath)
        table.insert(tbBodyCloths , v)
    end
    for k, v in pairs(BuildBodyData.tBodyCloth) do
        table.insert(tbBodyCloths , v)
    end
    for i, tbData in ipairs(tbBodyCloths) do
        if not tbExteriorCell[i] then
            local cellLua = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFacePreview_Item, itemParent)
            local effectInfo =
            {
                nType = PageType.Clothes,
                szIconPath = tbData.szMobileIconPath,
                szRepresent = tbData.szRepresent
            }
            cellLua:OnEnter(PageType.Clothes , i , effectInfo , function (nPageType , nIndex , cellScript, bSelected)
                BuildPresetData.nCurSelectHairIndex  = 0
                if bSelected then
                    local bNeedDownload = false
                    BuildPresetData.nCurSelectClothesIndex = nIndex
                    BuildBodyData.UpdateCloth(tbBodyCloths[nIndex].szRepresent)
                    bNeedDownload = BuildPresetData.CheckDownloadRes(BuildPresetData.PageType.Clothes , nIndex, BuildBodyData.tNowCloth, cellScript , nil)
                    if bNeedDownload then
                        BuildBodyData.UpdateCloth("" , Lib.copyTab(BuildPresetData.GetDefaultReprent(BuildPresetData.tSelectOriginalRepresent)))
                    end
                else
                    BuildBodyData.UpdateCloth({} , Lib.copyTab(BuildPresetData.tSelectOriginalRepresent))
                end
                local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
                moduleRole.UpdateRoleModel()
                if UIMgr.GetView(VIEW_ID.PanelBuildFace_Step2) then
                    if self.nRoleType == ROLE_TYPE.LITTLE_BOY or self.nRoleType == ROLE_TYPE.LITTLE_GIRL then
                        BuildPresetData.ResetPlayAnimation(BuildPresetData.szFisrtStanderAnimation)
                    else
                        BuildPresetData.ResetPlayAnimation()
                    end
                else
                    BuildPresetData.ResetPlayAnimation(BuildPresetData.szSelectRoleAni)
                end

                if UIMgr.IsViewVisible(VIEW_ID.PanelBuildFace_Step2) then
                    BuildPresetData.PausePlayAnimation(true)
                end
                Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , BuildPresetData.PageType.DEFAULT , 0 , true)
            end)
            if BuildPresetData.nCurSelectClothesIndex == i then
                cellLua:UpdateToggleSelect(true)
            end
        end
    end
end
-- ----------------------------------------------------------
-- Weather
-- ----------------------------------------------------------

function UIBuildFaceSetupCommonInteration:OnSelectedWeather(nIndex)
    if self.TogWeather then
        local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
        local tInfo = Table_GetLoginSceneInfo(nIndex)
        tInfo.szMapName = tInfo.szMobileMapName
        moduleScene.SceneChange(tInfo)
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

function UIBuildFaceSetupCommonInteration:UnLoadSceneSfx()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    if moduleScene then
        moduleScene.UnLoadScenePresetSFX()
    end
end

function UIBuildFaceSetupCommonInteration:LoadWeatherCell(itemParent)
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local nCurChooseScene = moduleScene.GetChooseScene()
    for k, v in pairs(tWeatherPresetIDs) do
        local tInfo = Table_GetLoginSceneInfo(v)
        if tInfo then
            local tbEffect = TabHelper.GetUILoginScenePresetEffectTab(UIHelper.GBKToUTF8(tInfo.szMobileMapName))
            local cellLua = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFacePreview_Item, itemParent)
            local effectInfo =
            {
                nType = PageType.Weather,
                szIconPath = UIHelper.UTF8ToGBK(tbEffect[1].szIconPath)
            }
            cellLua:OnEnter(PageType.Weather , v , effectInfo , function (nPageType , nIndex , cellScript, bSelected)
                if bSelected then
                    self:OnSelectedWeather(nIndex)
                else
                    self:OnSelectedWeather(1)
                end
            end)
            if nCurChooseScene == v then
                cellLua:UpdateToggleSelect(true)
            end
        end
    end
end

-- ----------------------------------------------------------
-- Action
-- ----------------------------------------------------------

function UIBuildFaceSetupCommonInteration:LoadActionCell(itemParent)
    local tActionData = BuildPresetData.GetActionData(self.nRoleType,  KUNGFU_ID_FORCE_TYPE[self.nKungfuID])
    local szCurAniName = BuildPresetData.szSelectRoleAni
    for k, v in pairs(tActionData) do
        local cellLua = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFacePreview_Item, itemParent)
        local effectInfo =
        {
            nType = PageType.Action,
            szIconPath = v.szMobileIconPath
        }
        cellLua:OnEnter(PageType.Action , k , effectInfo , function (nPageType , nIndex , cellScript, bSelected)
            BuildPresetData.szSelectRoleAni = tActionData[nIndex].szStandbyAnimation
            if bSelected then
                local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
                moduleRole:PlayRoleAnimation("loop", tActionData[nIndex].szStandbyAnimation)
            end
        end)
        if szCurAniName then
            if szCurAniName == v.szStandbyAnimation then
                cellLua:UpdateToggleSelect(true)
            end
        elseif k == 1 then
            cellLua:UpdateToggleSelect(true)
        end

    end
end

function UIBuildFaceSetupCommonInteration:OnSelectedEmotion(nIndex)
    if self.TogEmotion then
        local tAni 	= Table_GetFaceAniList(BuildFaceData.nRoleType)
        local tbInfo = tAni[nIndex]
        if not tbInfo then
            return
        end

        local ModleView = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
        local mdl = ModleView:GetFaceModel()
        ModleView:PlayAni(mdl, {id = tbInfo.szAniPath, type = "once", usepath = true})
    end
end
-- ----------------------------------------------------------
-- ----------------------------------------------------------

function UIBuildFaceSetupCommonInteration:LoadBodyData(szFile)
    local tBodyData, szError = BuildBodyData.LoadBodyData(szFile)
    if not tBodyData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_DATA_VAILD)
        return
    end

    if tBodyData.nRoleType ~= BuildBodyData.nRoleType then
        local szName = g_tStrings.tRoleTypeFormalName[tBodyData.nRoleType]
        local szMsg = FormatString( g_tStrings.STR_BODY_TYPE_VAILD, szName)
        TipsHelper.ShowNormalTip(szMsg)
        return
    end

    local nResult = BuildBodyData.ImportData(tBodyData)
    if nResult then
        if not ShareStationData.bOpening then
            TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_DATA_IMPROT)
        end
        if self.fnInputDataCallback then
            self.fnInputDataCallback()
        end
    end
end


function UIBuildFaceSetupCommonInteration:LoadFaceData(szFile)
    local tFaceData, szError = NewFaceData.LoadFaceData(szFile)
    if szError then
        TipsHelper.ShowNormalTip(szError)
        return
    end

    if not tFaceData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_NEW_FACE_LIFT_DATA_VAILD)
        return
    end

    -- if tFaceData.bShop then
    --     TipsHelper.ShowNormalTip("无法使用商城的捏脸数据")
    --     return
    -- end

    if tFaceData.nRoleType ~= BuildFaceData.nRoleType then
        local szName = g_tStrings.tRoleTypeFormalName[tFaceData.nRoleType]
        local szMsg = FormatString( g_tStrings.FACE_LIFT_TYPE_VAILD, szName)
        TipsHelper.ShowNormalTip(szMsg)
        return
    end

    local nResult = BuildFaceData.ImportData(tFaceData)
    if nResult then
        if not ShareStationData.bOpening then
            TipsHelper.ShowNormalTip(g_tStrings.STR_NEW_FACE_DATA_IMPROT)
        end
        if self.fnInputDataCallback then
            self.fnInputDataCallback()
        end
    end
end

function UIBuildFaceSetupCommonInteration:SetInputDataCallback(callback)
    self.fnInputDataCallback = callback
end

function UIBuildFaceSetupCommonInteration:OpenCellView(bOpen , pageType)
    if self.bOpenView == bOpen then
        return
    end
    self.bCurOpenState = bOpen
    UIHelper.RemoveAllChildren(self.LayoutList1)
    UIHelper.RemoveAllChildren(self.ScrollViewList)
    UIHelper.SetVisible(self.WidgetRightList , bOpen)
    if bOpen then
        local presetCount = table.get_len(tWeatherPresetIDs)
        local isScrollView = presetCount > 6
        local itemParent = isScrollView and self.ScrollViewList or self.LayoutList1
        UIHelper.SetVisible(self.LayoutList1 , not isScrollView)
        UIHelper.SetVisible(self.ScrollViewList , isScrollView)
        if pageType == PageType.Weather then
            self:LoadWeatherCell(itemParent)
        elseif pageType == PageType.Clothes then
            self:LoadClothesCell(itemParent)
        elseif pageType == PageType.Action then
            self:LoadActionCell(itemParent)
        end

        if isScrollView then
            UIHelper.ScrollViewDoLayoutAndToTop(itemParent)
        else
            UIHelper.LayoutDoLayout(itemParent)
        end
    else
        self.bClickClothes = false
        self.bClickWeather = false
        self.bClickEmotion = false
        UIHelper.SetSelected(self.TogWeather, false)
        UIHelper.SetSelected(self.TogEmotion, false)
        UIHelper.SetSelected(self.TogClothes, false)
    end
    if self.togSelectCallback then
        self.togSelectCallback(bOpen)
    end
end

function UIBuildFaceSetupCommonInteration:ShowActionToggle(bShow)
   UIHelper.SetVisible(self.TogEmotion , bShow)
   self.bShowTogEmotion = bShow
   --UIHelper.SetVisible(self.TogEmotion , false)
end

function UIBuildFaceSetupCommonInteration:ShowBodyMgr(bShow)
    UIHelper.SetVisible(self.BtnEnterBodyCode, bShow)
    UIHelper.SetVisible(self.BtnCommitBody , false)
    UIHelper.SetVisible(self.BtnMyCloudBody , false)

    UIHelper.SetVisible(self.BtnEnterFaceCode, not bShow) 
    UIHelper.SetVisible(self.BtnFaceStation, not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.BtnCommit, false)
    UIHelper.SetVisible(self.BtnMyCloud, false)
    UIHelper.SetVisible(self.BtnPrint, not bShow)
    UIHelper.SetVisible(self.BtnInput, not bShow)

    UIHelper.LayoutDoLayout(self.LayoutRightTop)
 end
function UIBuildFaceSetupCommonInteration:ClearTogState()
    self.bClickClothes = false
    self.bClickWeather = false
    self.bClickEmotion = false
    UIHelper.SetSelected(self.TogClothes, false)
    UIHelper.SetSelected(self.TogWeather, false)
    UIHelper.SetSelected(self.TogEmotion, false)

    self:OpenCellView(self.bClickClothes , PageType.Clothes)
    self:OpenCellView(self.bClickWeather , PageType.Weather)
    self:OpenCellView(self.bClickEmotion , PageType.Action)
 end

return UIBuildFaceSetupCommonInteration