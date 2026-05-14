-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationCenterViewScene
-- Date: 2026-04-02 11:38:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationCenterViewScene = class("UIOperationCenterViewScene")

local szScenePath         = Const.COMMON_SCENE
local tbModelPreviewInfo  = Const.MiniScene.OperationCenter.tbModelPreviewInfo
local tbFurnitureModelPos = Const.MiniScene.OperationCenter.tbFurnitureModelPos
local tbFurnitureCamare   = Const.MiniScene.OperationCenter.tbFurnitureCamare
local tbPetPos            = Const.MiniScene.OperationCenter.tbPetPos
local tbPetCamare         = Const.MiniScene.OperationCenter.tbPetCamare
local tbFrame             = { tRadius = { 280, 700 } }

local tRepresentSub = {
    [EQUIPMENT_SUB.HELM] = EQUIPMENT_REPRESENT.HELM_STYLE,
    [EQUIPMENT_SUB.HEAD_EXTEND] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
    [EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
}

local tHorseEquipToRe = {
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT4,
}

local function TableCombine(A, B)
    local C = {}
    for _, value in ipairs(A) do
        table.insert(C, value)
    end
    for _, value in ipairs(B) do
        table.insert(C, value)
    end
    return C
end

function UIOperationCenterViewScene:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitMiniScene()
    self:UpdateInfo()
end

function UIOperationCenterViewScene:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.UnBindModel()

    if self.hModelView then
        local scene = self.hModelView.m_scene
        if scene then
            scene:RestoreCameraLight()
        end

        self.hModelView:release()
        self.hModelView  = nil
        self.cameraModel = nil
    end

    if self.hPendantModelView then
        self.hPendantModelView:release()
        self.hPendantModelView = nil
    end

    if self.hRideModelView then
        self.hRideModelView:release()
        self.hRideModelView  = nil
        self.cameraRideModel = nil
    end

    if self.hFurnitureModelView then
        self.hFurnitureModelView:release()
        self.hFurnitureModelView   = nil
        self.tFurniturModelSetting = nil
        self.cameraFurnitureModel  = nil
    end

    local tbPetFrames = NpcModelPreview.tResisterFrame
    if tbPetFrames and tbPetFrames["OperationCenterPet"] and tbPetFrames["OperationCenterPet"]["OperationCenterPet"] then
        local tbPetFrame = tbPetFrames["OperationCenterPet"]["OperationCenterPet"]
        local hPetModelView = tbPetFrame.hNpcModelView
        if hPetModelView then
            if hPetModelView.m_scene then
                hPetModelView.m_scene:RestoreCameraLight()
            end
            hPetModelView:UnloadModel()
            hPetModelView:release()
            tbPetFrame.hNpcModelView = nil
        end
    end

    if not UIMgr.IsLayerVisible(UILayer.Scene) then
        UIMgr.ShowLayer(UILayer.Scene)
    end
end

function UIOperationCenterViewScene:BindUIEvent()

end

function UIOperationCenterViewScene:RegEvent()
    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local scene = self.hModelView.m_scene
            if scene and not QualityMgr.bDisableCameraLight then
                scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end
        end
    end)
end

function UIOperationCenterViewScene:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationCenterViewScene:UpdateInfo()

end

function UIOperationCenterViewScene:InitMiniScene()
    self.szScenePath = szScenePath
    self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
    self.hModelView:ctor()
    self.hModelView:InitBy({
        szName = "OperationCenter",
        bExScene = true,
        szExSceneFile = self.szScenePath,
        bAPEX = false,
    })
    self.tbModelPreviewInfo = tbModelPreviewInfo[GetClientPlayer().nRoleType]
    self._rootNode:SetScene(self.hModelView.m_scene)

    self.hPendantModelView = PendantModelView.CreateInstance(PendantModelView)
    self.hPendantModelView:ctor()
    self.hPendantModelView:InitBy({
        szName = "OperationCenterPendant",
        scene = self.hModelView.m_scene,
    })

    self.hRideModelView = RidesModelView.CreateInstance(RidesModelView)
    self.hRideModelView:ctor()
    self.hRideModelView:init(self.hModelView.m_scene, nil)
    RidesModelPreview.RegisterHorse(self._rootNode, self.hRideModelView, "OperationCenterHorse", "OperationCenterHorse")

    self.tFurniturModelSetting = {}
    self.hFurnitureModelView   = FurnitureModelView.CreateInstance(FurnitureModelView)
    self.hFurnitureModelView:ctor()
    self.hFurnitureModelView:init(self.hModelView.m_scene, false, _, "OperationCenterFurniture")

    -- 初始化宠物模型视图
    local tPetPos = UICameraTab["Pet"]["default"]["tbModelTranslation"]
    local tPetCamera = {0, 75, -304, 0, 75, 44, 1.78}
    ExteriorCharacter.AddCameraPos(tPetCamera, tPetPos)
    local tNpcParam = {
        szName = "OperationCenterPet",
        szFrameName = "OperationCenterPet",
        szFramePath = "Normal/OperationCenterPet",
        Viewer = self._rootNode,
        scene = self.hModelView.m_scene,
        bNotMgrScene = true,
        tPos = tPetPos,
        tCamera = tPetCamera,
        tRadius = {280, 700},
        tHorAngle = {5.9, 1.1},
        tVerAngle = {-1, 0.1},
    }
    RegisterNpcModelPreview(tNpcParam)
end

function UIOperationCenterViewScene:InitCamera(camera, tbCameraInfo, tMainPlayerPos)
    if not camera then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(self._rootNode)
    camera:ctor()
    camera:init(
        self.hModelView.m_scene,
        tbCameraInfo[1], tbCameraInfo[2], tbCameraInfo[3], tbCameraInfo[4], tbCameraInfo[5], tbCameraInfo[6],
        math.pi / 4, nWidth / nHeight, nil, nil, true
    )
    if tMainPlayerPos then
        camera:set_mainplayer_pos(tMainPlayerPos[1], tMainPlayerPos[2], tMainPlayerPos[3])
    end
end

function UIOperationCenterViewScene:UpdateModelInfo(dwItemTabType, dwItemTabIndex)
    self.hPendantModelView:UnloadModel()
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()
    self.hFurnitureModelView:UnloadModel()
    Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)

    -- 卸载宠物模型
    local tbPetFrames = NpcModelPreview.tResisterFrame
    if tbPetFrames and tbPetFrames["OperationCenterPet"] and tbPetFrames["OperationCenterPet"]["OperationCenterPet"] then
        local hPetModelView = tbPetFrames["OperationCenterPet"]["OperationCenterPet"].hNpcModelView
        if hPetModelView then
            hPetModelView:UnloadModel()
        end
    end

    self.cameraModel = self.cameraModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraModel, self.tbModelPreviewInfo.tbCamere, Const.MiniScene.OperationCenter.tbPos)

    self.dwItemType = dwItemTabType
    self.dwItemID = dwItemTabIndex
    if not self.dwItemType or not self.dwItemID then
        return
    end

    local itemInfo = ItemData.GetItemInfo(self.dwItemType, self.dwItemID)
    if not itemInfo then
        return
    end

    if ItemData.IsPendantItem(itemInfo) then
        self:UpdatePendantItemModelInfo()
    elseif itemInfo.nGenre == ITEM_GENRE.HOMELAND then
        self:UpdateFurnitureModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE then
        self:UpdateHorseModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        self:UpdateHorseEquipModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.PET then
        self:UpdatePetModelInfo()
    end
end

function UIOperationCenterViewScene:UpdatePendantItemModelInfo()
    if not self.dwItemType or not self.dwItemID then
        return
    end
    local itemInfo = ItemData.GetItemInfo(self.dwItemType, self.dwItemID)
    if not itemInfo then
        return
    end
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    self.hPendantModelView:UnloadModel()
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()

    local nYaw = self.tbModelPreviewInfo[itemInfo.nSub] or self.tbModelPreviewInfo.nYaw
    if not self.bPandantShowPlayerModel then
        self.hPendantModelView:LoadRes(itemInfo, tRepresentSub[itemInfo.nSub])
        self.hPendantModelView:LoadModel()
        self.hPendantModelView:SetTranslation(0, 100, 0)
        self.hPendantModelView:SetYaw(nYaw)
        self.hPendantModelView:SetCamera(self.tbModelPreviewInfo.tbCamere)
        UITouchHelper.BindModel(self.TouchContainer, self.hPendantModelView, self.cameraModel, { tbFrame = tbFrame })
    else
        local tRepresentID = Role_GetRepresentID(hPlayer)
        for _, nRepresentSub in ipairs(tRepresentSub) do
            tRepresentID[nRepresentSub] = 0
        end
        tRepresentID[tRepresentSub[itemInfo.nSub]] = itemInfo.nRepresentID
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE]    = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
        self.hModelView:LoadRes(hPlayer.dwID, tRepresentID)
        self.hModelView:PlayAnimation("Idle", "loop")
        self.hModelView:SetTranslation(table.unpack(Const.MiniScene.OperationCenter.tbPos))
        self.hModelView:SetYaw(nYaw)
        self.hModelView:SetCamera(self.tbModelPreviewInfo.tbCamere)
        UITouchHelper.BindModel(self.TouchContainer, self.hModelView, self.cameraModel, { tbFrame = tbFrame })
    end

    self.cameraModel = self.cameraModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraModel, self.tbModelPreviewInfo.tbCamere, Const.MiniScene.OperationCenter.tbPos)
end

function UIOperationCenterViewScene:UpdateFurnitureModelInfo()
    if not self.dwItemType or not self.dwItemID then
        return
    end
    local itemInfo = ItemData.GetItemInfo(self.dwItemType, self.dwItemID)
    if not itemInfo then
        return
    end
    self:LoadSetting(self.tFurniturModelSetting)
    local nFurnitureType = itemInfo.nFurnitureType
    local dwFurnitureID  = itemInfo.dwFurnitureID
    local tLine          = Table_GetAwardFurnitureModelInfo(dwFurnitureID)
    local tUIInfo        = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
    local dwRepresentID  = tUIInfo and tUIInfo.dwModelID
    local tbPos          = tLine and SplitString(tLine.szPosMB, ";") or tbFurnitureModelPos
    local fScale         = tLine and tLine.fScaleMB or Const.MiniScene.OperationCenter.fFurnitureModelScale
    local nYaw           = tLine and tLine.nYaw or Const.MiniScene.OperationCenter.fFurnitureModelYaw
    local nPutType       = tLine and tLine.nPutType or 0
    local nDetails       = tLine and tLine.nDetails or 0

    self.hFurnitureModelView:LoadModel(dwRepresentID, nPutType, nDetails, fScale)
    self.hFurnitureModelView:SetTranslation(unpack(tbPos))
    self.hFurnitureModelView:SetCamera(tbFurnitureCamare)
    self.hFurnitureModelView:SetYaw(nYaw)
    self.hFurnitureModelView:SetScale(fScale, fScale, fScale)

    self.cameraFurnitureModel = self.cameraFurnitureModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraFurnitureModel, tbFurnitureCamare)
    UITouchHelper.BindModel(self.TouchContainer, self.hFurnitureModelView, self.cameraFurnitureModel, { tbFrame = tbFrame })
end

function UIOperationCenterViewScene:UpdateHorseModelInfo()
    if not self.dwItemType or not self.dwItemID then
        return
    end
    local itemInfo = ItemData.GetItemInfo(self.dwItemType, self.dwItemID)
    if not itemInfo then
        return
    end

    local player        = g_pClientPlayer
    local tbRepresentID = player.GetRepresentID()

    if itemInfo and itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.HORSE then
        tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = itemInfo.nRepresentID
    else
        return
    end

    local tbCamera = UICameraTab["Ride"][VIEW_ID.PanelAwardGather]

    self.hRideModelView:LoadResByRepresent(tbRepresentID, false)
    self.hRideModelView:LoadRidesModel()
    self.hRideModelView:PlayRidesAnimation("Idle", "loop")
    self.hRideModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    self.hRideModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    self.hRideModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    self.hRideModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))

    local fScale = Const.MiniScene.RideScale
    self.hRideModelView:SetScaling(fScale, fScale, fScale)
    self.hRideModelView:SetYaw(tbCamera.nModelYaw)
    self.hRideModelView:SetMainFlag(true)

    local tbRideModelCamera = TableCombine(tbCamera.tbCameraPos, tbCamera.tbCameraLookPos)
    self.cameraRideModel    = self.cameraRideModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraRideModel, tbRideModelCamera, tbCamera.tbModelTranslation)
    UITouchHelper.BindModel(self.TouchContainer, self.hRideModelView, self.cameraRideModel, { tbFrame = tbFrame })
end

function UIOperationCenterViewScene:UpdateHorseEquipModelInfo()
    if not self.dwItemType or not self.dwItemID then
        return
    end
    local itemInfo = ItemData.GetItemInfo(self.dwItemType, self.dwItemID)
    if not itemInfo then
        return
    end

    local player        = g_pClientPlayer
    local tbRepresentID = player.GetRepresentID()
    local nRepresentSub = tHorseEquipToRe[itemInfo.nDetail]
    for _, nHorseEquipToRe in ipairs(tHorseEquipToRe) do
        tbRepresentID[nHorseEquipToRe] = 0
    end

    if itemInfo and itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        tbRepresentID[nRepresentSub] = itemInfo.nRepresentID
    end

    local tbCamera = UICameraTab["Ride"][VIEW_ID.PanelAwardGather]

    self.hRideModelView:LoadResByRepresent(tbRepresentID, false)
    self.hRideModelView:LoadRidesModel()
    self.hRideModelView:PlayRidesAnimation("Idle", "loop")
    self.hRideModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    self.hRideModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    self.hRideModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    self.hRideModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))

    local fScale = Const.MiniScene.RideScale
    self.hRideModelView:SetScaling(fScale, fScale, fScale)
    self.hRideModelView:SetYaw(tbCamera.nModelYaw)
    self.hRideModelView:SetMainFlag(true)

    local tbRideModelCamera = TableCombine(tbCamera.tbCameraPos, tbCamera.tbCameraLookPos)
    self.cameraRideModel    = self.cameraRideModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraRideModel, tbRideModelCamera, tbCamera.tbModelTranslation)
    UITouchHelper.BindModel(self.TouchContainer, self.hRideModelView, self.cameraRideModel, { tbFrame = tbFrame })
end

function UIOperationCenterViewScene:UpdatePetModelInfo()
    if not self.dwItemType or not self.dwItemID then
        return
    end

    local itemInfo = ItemData.GetItemInfo(self.dwItemType, self.dwItemID)
    if not itemInfo then
        return
    end

    -- 获取宠物索引
    local nPetIndex = GetFellowPetIndexByItemIndex(self.dwItemType, self.dwItemID)
    if not nPetIndex then
        return
    end

    local tPet = Table_GetFellowPet(nPetIndex)
    if not tPet then
        return
    end

    -- 获取 NpcModelPreview 框架
    if not NpcModelPreview.tResisterFrame then return end
    if not NpcModelPreview.tResisterFrame["OperationCenterPet"] then return end
    local tbPetFrame = NpcModelPreview.tResisterFrame["OperationCenterPet"]["OperationCenterPet"]
    if not tbPetFrame then
        return
    end

    local hModelView = tbPetFrame.hNpcModelView
    if not hModelView then
        return
    end

    -- 卸载当前模型
    hModelView:UnloadModel()

    -- 获取宠物相机配置
    local tbCamera = UICameraTab["Pet"][tPet.dwPetIndex] or UICameraTab["Pet"]["default"]

    -- 加载宠物模型
    hModelView:LoadNpcRes(tPet.dwModelID, false)
    APIHelper.SetNpcLODLvl(0)
    hModelView:LoadModel()
    APIHelper.SetNpcLODLvl()
    hModelView:SetDetail(tPet.nColorChannelTable, tPet.nColorChannel)
    hModelView:SetScaling(tPet.fModelScaleMB)
    hModelView:PlayAnimation("Idle", "loop")

    -- 设置 NpcModelPreview 相机位置
    NpcModelPreview_SetCameraPosition("OperationCenterPet", "OperationCenterPet", {
        tbCamera.tbCameraPos[1], tbCamera.tbCameraPos[2], tbCamera.tbCameraPos[3],
        tbCamera.tbCameraLookPos[1], tbCamera.tbCameraLookPos[2], tbCamera.tbCameraLookPos[3]
    })

    -- 设置相机位置
    hModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    hModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    hModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    hModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))
    hModelView:SetYaw(tbCamera.nModelYaw)

    -- 绑定触摸交互
    local camera = tbPetFrame.camera
    camera:set_mainplayer_pos(unpack(tbCamera.tbModelTranslation))
    UITouchHelper.BindModel(self.TouchContainer, hModelView, camera, {tbFrame = tbPetFrame, bCanZoom = false})
end

function UIOperationCenterViewScene:LoadSetting(tSetting)
    local szSettingFile = "/ui/Scheme/Setting/CoinShopFurnitureSetting.ini"
    local pFile         = Ini.Open(szSettingFile)
    if not pFile then
        return
    end
    local szSection       = "FurnitureModelSetting"
    tSetting              = {}
    tSetting.CriterionX   = pFile:ReadInteger(szSection, "CriterionX", 0)
    tSetting.CriterionY   = pFile:ReadInteger(szSection, "CriterionY", 0)
    tSetting.CriterionZ   = pFile:ReadInteger(szSection, "CriterionZ", 0)
    tSetting.MaxScale     = pFile:ReadFloat(szSection, "MaxScale", 0)
    tSetting.MinScale     = pFile:ReadFloat(szSection, "MinScale", 0)
    tSetting.PlatformMesh = pFile:ReadString(szSection, "PlatformMesh", "")
    tSetting.PlatformX    = pFile:ReadFloat(szSection, "PlatformX", 0)
    tSetting.PlatformY    = pFile:ReadFloat(szSection, "PlatformY", 0)
    tSetting.PlatformZ    = pFile:ReadFloat(szSection, "PlatformZ", 0)
    tSetting.PlatformYaw  = pFile:ReadFloat(szSection, "PlatformYaw", 0)
    pFile:Close()
    Homeland_SendMessage(HOMELAND_FURNITURE.ENTER, self.hModelView.m_scene, tSetting.PlatformMesh, tSetting.PlatformX, tSetting.PlatformY, tSetting.PlatformZ, tSetting.PlatformYaw)
end

function UIOperationCenterViewScene:SetSceneVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
    if bVisible then
        if UIMgr.IsLayerVisible(UILayer.Scene) then
            UIMgr.HideLayer(UILayer.Scene)
        end
    end
end

return UIOperationCenterViewScene
