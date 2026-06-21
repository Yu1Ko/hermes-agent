-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItem
-- Date: 2022-12-09 10:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIPanelMysteryItemMain
local UIPanelMysteryItemMain = class("UIPanelMysteryItemMain")

local PREVIEW_TYPE = {
    COLLECTION = 1,
    ROLE = 2
}
local PENDANT_AREA_COUNT = 3

-- 预览人物腰部挂件镜头参数
local tCharacterWaistCameraInfo = {
    [0] = { -30, 160, -25, 0, 150, 0 }, --rtInvalid = 0,
    [1] = { 0, 70, -260, 0, 110, 150 }, --rtStandardMale,	 // 标准男
    [2] = { 0, 78, -235, 0, 100, 150 }, --rtStandardFemale,   // 标准女
    [3] = { -30, 160, -25, 0, 150, 0 }, --rtStrongMale,	   // 魁梧男
    [4] = { -30, 160, -25, 0, 150, 0 }, --rtSexyFemale,	   // 性感女
    [5] = { 0, 90, -215, 0, 80, 150 }, --rtLittleBoy,	   // 小男孩
    [6] = { 0, 90, -215, 0, 80, 150 }  --rtLittleGirl,	   // 小孩女
}

-- 预览人物背部挂件镜头参数
local tCharacterBackCameraInfo = {
    [0] = { -30, 160, -25, 0, 150, 0 }, --rtInvalid = 0,
    [1] = { 0, 70, -260, 0, 110, 150 }, --rtStandardMale,	 // 标准男
    [2] = { 0, 78, -235, 0, 100, 150 }, --rtStandardFemale,   // 标准女
    [3] = { -30, 160, -25, 0, 150, 0 }, --rtStrongMale,	   // 魁梧男
    [4] = { -30, 160, -25, 0, 150, 0 }, --rtSexyFemale,	   // 性感女
    [5] = { 0, 90, -215, 0, 80, 150 }, --rtLittleBoy,	   // 小男孩
    [6] = { 0, 90, -215, 0, 80, 150 }  --rtLittleGirl,	   // 小孩女
}

local tRadius = {
    [ROLE_TYPE.STANDARD_MALE] = { 250, 350 }, --rtStandardMale,
    [ROLE_TYPE.STANDARD_FEMALE] = { 250, 350 }, --rtStandardFemale,
    [ROLE_TYPE.STRONG_MALE] = { 50, 160 }, --rtStrongMale,
    [ROLE_TYPE.SEXY_FEMALE] = { 50, 100 }, --rtSexyFemale,
    [ROLE_TYPE.LITTLE_BOY] = { 100, 300 }, --rtLittleBoy,
    [ROLE_TYPE.LITTLE_GIRL] = { 100, 300 }  --rtLittleGirl,
}

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(szPreviewSource, nPendantType, dwPendantIndex)
    DataModel.szPreviewSource = ""
    DataModel.nPendantType = 0
    DataModel.dwPendantIndex = 0
    DataModel.nPreviewType = DataModel.nPreviewType or PREVIEW_TYPE.COLLECTION

    DataModel.SetPreviewSource(szPreviewSource)
    DataModel.SetPandentType(nPendantType)
    DataModel.SetPendantIndex(dwPendantIndex)
end

function DataModel.UnInit()
    DataModel.szPreviewSource = nil
    DataModel.nPendantType = nil
    DataModel.dwPendantIndex = nil
    DataModel.nPreviewType = nil
end

function DataModel.SetPendantIndex(dwPendantID)
    DataModel.dwPendantID = dwPendantID
end

function DataModel.GetPendantIndex()
    return DataModel.dwPendantID
end

function DataModel.SetPreviewSource(szSource)
    DataModel.szPreviewSource = szSource
end

function DataModel.GetPreviewSource()
    return DataModel.szPreviewSource
end

function DataModel.SetPandentType(nPendantType)
    DataModel.nPendantType = nPendantType
end

function DataModel.GetPandentType()
    return DataModel.nPendantType
end

function DataModel.SetPreviewType(nType)
    DataModel.nPreviewType = nType
end

function DataModel.GetPreviewType()
    return DataModel.nPreviewType
end

function DataModel.GetPendantModelParam(dwID, nType, szSource)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local dwRepresentID, fScale, nWornLevel, DisplayData, tCamera
    local tPendantInfo = Collection_GetPendantInfo(szSource, nType, dwID)
    if not tPendantInfo then
        return
    end
    dwRepresentID = tPendantInfo.dwRepresentID
    fScale = tPendantInfo.fScale
    DisplayData = tPendantInfo.DisplayData
    if DisplayData then
        nWornLevel = DisplayData.uWornLevel
    end
    tCamera = StringParse_PointList(tPendantInfo.szCamera)
    return dwRepresentID, fScale, tCamera, nWornLevel, DisplayData
end

-----------------------------View------------------------------

local tbModelPreviewInfo = {--挂件主角模型
    [ROLE_TYPE.STANDARD_MALE] = {
        nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3, --默认nYaw，腰部nYaw，背部nYaw
        tbCamere = { 133130, 4270, 35910, 133398, 4230, 35910, 0.785398185, 1.77777779, 20, 40000, true },
    },
    [ROLE_TYPE.STANDARD_FEMALE] = {
        nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.65,
        tbCamere = { 133160, 4270, 35890, 133398, 4220, 35900, 0.785398185, 1.77777779, 20, 40000, true },
    },
    [ROLE_TYPE.LITTLE_BOY] = {
        nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.9, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
        tbCamere = { 133250, 4244, 35910, 133398, 4205, 35910, 0.785398185, 1.77777779, 20, 40000, true },
    },
    [ROLE_TYPE.LITTLE_GIRL] = {
        nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 2.4, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
        tbCamere = { 133250, 4244, 35910, 133398, 4205, 35910, 0.785398185, 1.77777779, 20, 40000, true },
    },
}
local tRepresentSub = {
    -- [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
    -- [EQUIPMENT_SUB.CHEST] = EQUIPMENT_REPRESENT.CHEST_STYLE,
    [EQUIPMENT_SUB.HELM] = EQUIPMENT_REPRESENT.HELM_STYLE,
    -- [EQUIPMENT_SUB.WAIST] = EQUIPMENT_REPRESENT.WAIST_STYLE,
    -- [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_REPRESENT.BOOTS_STYLE,
    -- [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_REPRESENT.BANGLE_STYLE,
    [EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    -- [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    -- [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    -- [EQUIPMENT_SUB.BAG_EXTEND] = EQUIPMENT_REPRESENT.BAG_EXTEND,
    -- [EQUIPMENT_SUB.PENDENT_PET] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    -- [EQUIPMENT_SUB.GLASSES_EXTEND] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    -- [EQUIPMENT_SUB.L_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    -- [EQUIPMENT_SUB.R_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
}

local tbFrame1 = { tRadius = { 780, 950 } }
local tbFrame2 = { tRadius = { 220, 700 } }

PendantModelCategory = {
    Pendant = 1,
    Character = 2
}

function UIPanelMysteryItemMain:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.jackpotScript = UIHelper.AddPrefab(PREFAB_ID.WidgetMysteryJackpot, self.WidgetMysteryJackpot, self)
    end

    self:InitMiniScene()
    self:UpdateCamera()

    --self:ShowScene(PendantModelCategory.Pendant)
end

function UIPanelMysteryItemMain:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.UnBindModel()

    if self.hModelView then
        --local scene = self.hModelView.m_scene
        --if scene then
        --    scene:RestoreCameraLight()
        --end

        self.hModelView:release()
        self.hModelView = nil
        self.cameraModel = nil
    end

    if self.pendantModelView then
        local scene = self.pendantModelView.m_scene
        if scene then
            scene:RestoreCameraLight()
        end

        self.pendantModelView:release()
        self.pendantModelView = nil
        self.cameraModel = nil
    end
end

function UIPanelMysteryItemMain:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRightBag, EventType.OnClick, function()
        --UIMgr.Open(VIEW_ID.PanelMysteryRightBag)
        self:ShowScene(self.nModelCategory == PendantModelCategory.Character and PendantModelCategory.Pendant
                or PendantModelCategory.Character)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:CancelBatch()
    end)

    UIHelper.BindUIEvent(self.TogJackpot, EventType.OnSelectChanged, function(tog, bSelected)
        if bSelected then
            self:HideScene()
            UIHelper.SetVisible(self.BtnRightBag, false)
            UIHelper.LayoutDoLayout(self.LayoutRightTop)
        end
    end)

    UIHelper.BindUIEvent(self.TogStorage, EventType.OnSelectChanged, function(tog, bSelected)
        if bSelected then
            UIHelper.SetVisible(self.BtnRightBag, true)
            UIHelper.LayoutDoLayout(self.LayoutRightTop)
            self.storageScript = self.storageScript or UIHelper.AddPrefab(PREFAB_ID.WidgetMysteryStorage, self.WidgetMysteryStorage, self)
            self.storageScript:OnEnterTab()
        end
    end)

    UIHelper.BindUIEvent(self.TogMyCollection, EventType.OnSelectChanged, function(tog, bSelected)
        if bSelected then
            UIHelper.SetVisible(self.BtnRightBag, false)
            UIHelper.LayoutDoLayout(self.LayoutRightTop)
            self.collectionScript = self.collectionScript or UIHelper.AddPrefab(PREFAB_ID.WidgetMysteryMyCollection, self.WidgetMysteryMyCollection, self)
            self.collectionScript:OnEnterTab()
        end
    end)
end

function UIPanelMysteryItemMain:RegEvent()
    --Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
    --    if nProcess >= 100 and self.hModelView.m_scene then
    --        self.pendantModelView.m_scene:OpenCameraLight()
    --    end
    --end)
end

function UIPanelMysteryItemMain:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelMysteryItemMain:InitMiniScene()
    local tFrame = {
        szName = "Collection",
        szFrameName = "Collection_View",
        szFramePath = "Lowest/Collection_View",
        szScene = "Collection/Scene_Collection",
        szSceneFilePath = Const.COMMON_SCENE,
    }

    local szFrame = tFrame.szFrameName
    local szName = tFrame.szName

    local modelView = PendantModelView.CreateInstance(PendantModelView)
    self.pendantModelView = modelView
    modelView:init(self.pendantModelView.scene, tFrame.bNotMgrScene, nil, tFrame.szSceneFilePath, szFrame .. "_" .. szName)
    self.MiniScene:SetScene(self.pendantModelView.m_scene)

    self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
    self.hModelView:ctor()
    self.hModelView:InitBy({
        szName = "AwardGather",
        bExScene = true,
        scene = self.pendantModelView.m_scene,
        szExSceneFile = Const.COMMON_SCENE,
        bAPEX = false,
    })
    self.tbModelPreviewInfo = tbModelPreviewInfo[GetClientPlayer().nRoleType]
end

function UIPanelMysteryItemMain:InitCamera(MiniScene, modelScene, camera, tbCameraInfo)
    if not camera then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(MiniScene)
    camera:ctor()
    camera:init(modelScene, tbCameraInfo[1], tbCameraInfo[2], tbCameraInfo[3], tbCameraInfo[4], tbCameraInfo[5], tbCameraInfo[6], math.pi / 4, nWidth / nHeight, nil, nil, true)
end

function Collection_GetOrangePendantDisplayData(dwItemIndex)
    local tDisplayData = {}
    local tInfo = Table_GetCollectionOrangePendantInfo(dwItemIndex)
    for i = 1, PENDANT_AREA_COUNT do
        tDisplayData[i] = {
            ["uTPos"] = tInfo["uTPos" .. i],
            ["uColor"] = tInfo["uColor" .. i],
            ["uTID"] = tInfo["uTID" .. i],
        }
    end
    return tDisplayData
end

function UIPanelMysteryItemMain:UpdatePendantModel()
    local dwItemIndex = 17
    local nWornLevel = 1
    local modelView = self.pendantModelView

    local tInfo = Table_GetCollectionPendantInfo(dwItemIndex)
    modelView:LoadPendantRes(Player_GetRoleType(g_pClientPlayer), tInfo.nType, tInfo.dwRepresentID)

    local tDisplayData = Collection_GetOrangePendantDisplayData(dwItemIndex)
    if nWornLevel and tDisplayData then
        modelView:LoadPendantDisplayAttribute(tInfo.dwRepresentID, tInfo.nType, nWornLevel, tDisplayData)
    end
    modelView:LoadModel()
    modelView.m_PendantMDL["MDL"]:SetAlpha(1)
    modelView.m_PendantMDL["BACK_EXTEND"]:SetAlpha(1)

    local nYaw = 4.66
    modelView:SetYaw(nYaw)

    modelView.m_PendantMDL["BACK_EXTEND"]:SetCaptureRepeatPhysicsTime(120)--设置柔体需要迭代的次数，没有柔体的挂件默认为1
    modelView.m_PendantMDL["BACK_EXTEND"]:SetCaptureSFXDelayTime(0.5)--为了等待特效播放至效果较好的时候，设置特效播放多久后再拍照，单位：秒

    modelView:SetTranslation(133220, 4265, 35892+5)
end

function UIPanelMysteryItemMain:UpdateCharacterModel()
    local dwItemTabType = 8
    local dwItemTabIndex = 4010
    local itemInfo = ItemData.GetItemInfo(16, 21)
    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    for _, nRepresentSub in ipairs(tRepresentSub) do
        tRepresentID[nRepresentSub] = 0
    end
    tRepresentID[EQUIPMENT_SUB.BAG_EXTEND] = 1043
    local bShowWeapon = false
    if not bShowWeapon then
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end

    local nYaw = self.tbModelPreviewInfo[EQUIPMENT_SUB.BACK_EXTEND] or self.tbModelPreviewInfo.nYaw
    self.hModelView:LoadRes(g_pClientPlayer.dwID, tRepresentID)
    self.hModelView:PlayAnimation("Idle", "loop")
    self.hModelView:SetTranslation(133420, 4140, 35922 - 20)
    self.hModelView:SetYaw(nYaw)
    self.hModelView:SetCamera(self.tbModelPreviewInfo.tbCamere)

    self.hModelView:PlayAnimation("StandardNew", "loop")
end

function UIPanelMysteryItemMain:UpdateInfo()

end

function UIPanelMysteryItemMain:ShowScene(nModelCategory, ...)
    UIHelper.SetVisible(self.MiniScene, true)
    if self.nModelCategory ~= nModelCategory then
        self.nModelCategory = nModelCategory

        self.hModelView:UnloadModel()
        self.pendantModelView:UnloadModel()

        if self.nModelCategory == PendantModelCategory.Character then
            self:UpdateCharacterModel(...)
        else
            self:UpdatePendantModel(...)
        end

        self:UpdateCamera()
    end
end

function UIPanelMysteryItemMain:HideScene()
    UIHelper.SetVisible(self.MiniScene, false)
end

function UIPanelMysteryItemMain:UpdateCamera()
    self.cameraModel = self.cameraModel or camera_plus.CreateInstance(camera_plus)
    if self.nModelCategory == PendantModelCategory.Character then
        self:InitCamera(self.MiniScene, self.pendantModelView.m_scene, self.cameraModel, self.tbModelPreviewInfo.tbCamere)
        UITouchHelper.BindModel(self.TouchContainer, self.hModelView, self.cameraModel, { tbFrame = tbFrame2 })
    else
        local tbCameraInfo = { 133130, 4410, 35910 - 20, 133898, 4230, 35910, 0.785398185, 1.77777779, 20, 40000, true }
        self:InitCamera(self.MiniScene, self.pendantModelView.m_scene, self.cameraModel, tbCameraInfo)
        UITouchHelper.BindModel(self.TouchContainer, self.pendantModelView, self.cameraModel, { tbFrame = tbFrame1 })
    end
end

function UIPanelMysteryItemMain:StartBatch(fnBatchTakeOut, fnBatchDiscard, fnCancel)
    UIHelper.SetVisible(self.WidgetAniDiscard, true)
    UIHelper.SetVisible(self.BtnTackOut, fnBatchTakeOut ~= nil)
    UIHelper.BindUIEvent(self.BtnTackOut, EventType.OnClick, fnBatchTakeOut)
    UIHelper.BindUIEvent(self.BtnDiscard, EventType.OnClick, fnBatchDiscard)

    self.fnCancel = fnCancel
end

function UIPanelMysteryItemMain:CancelBatch()
    UIHelper.SetVisible(self.WidgetAniDiscard, false)
    if self.fnCancel and IsFunction(self.fnCancel) then
        self.fnCancel()
    end
end

function UIPanelMysteryItemMain:UpdateSelectedNum(szText)
    UIHelper.SetString(self.LabelSelectNum, szText)
end

return UIPanelMysteryItemMain