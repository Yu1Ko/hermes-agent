-- 通用商店模型管理器，负责管理各种类型物品的3D模型显示
CommonStoreModelManager = class("CommonStoreModelManager")

local STORE_FRAME_NAME = "ActivityStore_View"
local STORE_NAME = "ActivityStore"

-- 装备子类型到表现ID的映射
local tRepresentSub = {
    [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
    [EQUIPMENT_SUB.CHEST] = EQUIPMENT_REPRESENT.CHEST_STYLE,
    [EQUIPMENT_SUB.HELM] = EQUIPMENT_REPRESENT.HELM_STYLE,
    [EQUIPMENT_SUB.HEAD_EXTEND] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
    [EQUIPMENT_SUB.WAIST] = EQUIPMENT_REPRESENT.WAIST_STYLE,
    [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_REPRESENT.BOOTS_STYLE,
    [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_REPRESENT.BANGLE_STYLE,
    [EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    [EQUIPMENT_SUB.BAG_EXTEND] = EQUIPMENT_REPRESENT.BAG_EXTEND,
    [EQUIPMENT_SUB.PENDENT_PET] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    [EQUIPMENT_SUB.GLASSES_EXTEND] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    [EQUIPMENT_SUB.L_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    [EQUIPMENT_SUB.R_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
}

-- 马具装备到表现ID的映射
local tHorseEquipToRe = {
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT4,
}

-- 面部相关子类型
local tFaceSubTypes = {
    [EQUIPMENT_SUB.HELM] = true,
    [EQUIPMENT_SUB.HEAD_EXTEND] = true,
    [EQUIPMENT_SUB.FACE_EXTEND] = true,
    [EQUIPMENT_SUB.GLASSES_EXTEND] = true,
}

-- 最大半径子类型
local tMaxRadiusSubTypes = {
    [EQUIPMENT_SUB.WAIST] = true,
    [EQUIPMENT_SUB.BOOTS] = true,
    [EQUIPMENT_SUB.WAIST_EXTEND] = true,
    [EQUIPMENT_SUB.BACK_EXTEND] = true,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = true,
    [EQUIPMENT_SUB.BAG_EXTEND] = true,
}

-- 装备子类型对应的摄像机ID
local tEquipSubCameraID = {
    [EQUIPMENT_SUB.FACE_EXTEND] = 1,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = 2,
    [EQUIPMENT_SUB.WAIST_EXTEND] = 3,
    [EQUIPMENT_SUB.BACK_EXTEND] = 5,
    [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = 6,
    [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = 7,
    [EQUIPMENT_SUB.GLASSES_EXTEND] = 8,
    [EQUIPMENT_SUB.HELM] = 1,
    [EQUIPMENT_SUB.HEAD_EXTEND] = 1,
}

-- 根据装备子类型获取摄像机模式
local function GetCameraModeByEquipSub(nSub)
    if tMaxRadiusSubTypes[nSub] then
        return "Normal", "Max"
    end
    return "Normal", "Min"
end

function CommonStoreModelManager:ctor()
    self.hModelView = nil
    self.hPendantModelView = nil
    self.hRideModelView = nil
    self.hFurnitureModelView = nil
    self.hPetModeView = nil
    self.tModelItemInfo = nil
    self.szType = nil
    self.tFurniturModelSetting = {}
    self.nFurnitureTouchTimerID = nil
    self.m_scene = nil
    self.MiniScene = nil
    self.TouchContainer = nil
end

function CommonStoreModelManager:Init(MiniScene, TouchContainer, szScenePath, tbCamOffset)
    self.MiniScene = MiniScene
    self.TouchContainer = TouchContainer
    self.szScenePath = szScenePath or Const.SHOP_SCENE
    tbCamOffset = tbCamOffset or { 0, 0, 0 }
    self:InitMiniScene(tbCamOffset)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            Event.UnReg(self, EventType.OnMiniSceneLoadProgress)
            ExteriorCharacter.OpenCameraLight(STORE_FRAME_NAME, STORE_NAME)
        end
    end)
end

function CommonStoreModelManager:InitMiniScene(tbCamOffset)
    if not self.m_scene then
        self.m_scene = SceneHelper.Create(self.szScenePath, false, true, true)
    end
    local scene = self.m_scene

    if not ExteriorCharacter.tResisterFrame[STORE_FRAME_NAME] then
        RegisterExteriorCharacterEvent(STORE_FRAME_NAME)
        RegisterRidesModelEvent(STORE_FRAME_NAME)
        RegisterNpcModelEvent(STORE_FRAME_NAME)
        RegisterFurnitureModelEvent(STORE_FRAME_NAME)
    end

    local tbPlayerCamOffset = clone(tbCamOffset)
    tbPlayerCamOffset[1] = tbPlayerCamOffset[1] - 3 -- 角色模型特殊偏移
    local tStorePos = { -7, 0, 0 } -- 通过这个做偏移的话会使得切换不同类型的镜头时产生模型位置偏移
    local tCameraInfo = ExteriorCharacter.GetCameraInfo()
    local tCharacterParam = {
        dwPlayerID = g_pClientPlayer.dwID,
        szName = STORE_NAME,
        szFrameName = STORE_FRAME_NAME,
        Viewer = self.MiniScene,
        tCameraInfo = tCameraInfo,
        bRegisterEvent = true,
        bExScene = true,
        scene = scene,
        szAnimation = "Idle",
        szLoopType = "loop",
        bAdjustByAnimation = true,
        tPos = tStorePos,
        tHorAngle = { 5.9, 1.1 },
        tVerAngle = { -1, 0.1 },
        bAPEX = false,
        nModelType = UI_MODEL_TYPE.COINSHOP,
        tbCameraOffset = tbPlayerCamOffset,
    }
    RegisterExteriorCharacter(tCharacterParam)
    local tPlayerFrame = ExteriorCharacter.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    self.hModelView = tPlayerFrame.hModelView

    local tPendantParam = {
        szName = STORE_NAME,
        szFrameName = STORE_FRAME_NAME,
        Viewer = self.MiniScene,
        scene = scene,
        bNotMgrScene = true,
        fScale = 0.4,
        tPos = tStorePos,
        tCamera = { -643, 169, -249, -37, 101, 71, 2.37, 0, 101, 0 },
        tRadius = { 380, 700 },
        tHorAngle = { 5.9, 1.1 },
        tVerAngle = { -1, 0.1 },
        szCameraType = "ShopNpc",
        nCameraIndex = 1,
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
        tbCameraOffset = tbCamOffset,
    }
    RegisterPendantPreview(tPendantParam)
    local tFrame = PendantModelView.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    self.hPendantModelView = tFrame.hPendantModelView

    local tRideParam = {
        szName = STORE_NAME,
        szFrameName = STORE_FRAME_NAME,
        Viewer = self.MiniScene,
        scene = scene,
        fScale = 0.4,
        tPos = tStorePos,
        tCamera = { -643, 169, -249, -37, 101, 71, 2.37, 0, 101, 0 },
        tRadius = { 380, 700 },
        tHorAngle = { 5.9, 1.1 },
        tVerAngle = { -1, 0.1 },
        szCameraType = "ShopRide",
        nCameraIndex = 1,
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
        tbCameraOffset = tbCamOffset,
    }
    RegisterRidesModelPreview(tRideParam)
    local tRideFrame = RidesModelPreview.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    self.hRideModelView = tRideFrame.hRidesModelView

    local tNpcParam = {
        szName = STORE_NAME,
        szFrameName = STORE_FRAME_NAME,
        Viewer = self.MiniScene,
        scene = scene,
        bNotMgrScene = true,
        tPos = tStorePos,
        tCamera = { -486, 75, -304, -34, 77, 44, 1.72, 0, 77, 0 },
        tRadius = { 280, 700 },
        tHorAngle = { 5.9, 1.1 },
        tVerAngle = { -1, 0.1 },
        szCameraType = "ShopNpc",
        nCameraIndex = 1,
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
        tbCameraOffset = tbCamOffset,
    }
    RegisterNpcModelPreview(tNpcParam)
    local tNpcFrame = NpcModelPreview.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    self.hPetModeView = tNpcFrame.hNpcModelView

    self.tFurniturModelSetting = {}
    local tFurnitureParam = {
        szName = STORE_NAME,
        szFrameName = STORE_FRAME_NAME,
        Viewer = self.MiniScene,
        scene = scene,
        bNotMgrScene = true,
        tPos = tStorePos,
        tCamera = { -1600, 980, -645, -120, 160, 153, 1.72, 0, 160, 0 },
        tRadius = { 380, 2000 },
        tHorAngle = { 5.9, 1.1 },
        tVerAngle = { -1, 0 },
        szCameraType = "ShopFurniture",
        nCameraIndex = 1,
        nDefaultZoomIndex = 1,
        nDefaultZoomValue = 100,
        tbCameraOffset = tbCamOffset,
    }
    RegisterFurnitureModelView(tFurnitureParam)
    local tFurnitureFrame = FurnitureModelPreview.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    self.hFurnitureModelView = tFurnitureFrame.hFurnitureModelView
end

function CommonStoreModelManager:UpdateModelInfo(dwItemTabType, dwItemTabIndex)
    UITouchHelper.UnBindModel()
    Timer.DelTimer(self, self.nFurnitureTouchTimerID)

    self.hPendantModelView:UnloadModel()
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()
    self.hPetModeView:UnloadModel()
    self.hFurnitureModelView:UnloadModel()
    self.hFurnitureModelView.dwRepresentID = nil
    Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)

    if not dwItemTabType or not dwItemTabIndex then
        return
    end

    self.tModelItemInfo = {
        dwItemType = dwItemTabType,
        dwItemID = dwItemTabIndex,
    }

    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    local tSpecial = Table_GetSpecialItemPreview(dwItemTabType, dwItemTabIndex)

    if ItemData.IsPendantItem(itemInfo) or ItemData.IsPendantPetItem(itemInfo) or (itemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM) then
        if tSpecial and tSpecial.szType == "SinglePendant" then
            self.szType = "Pendant"
            self:UpdatePendantModelInfo()
        else
            self.szType = "Player"
            self:UpdatePlayerModelInfo()
        end
    elseif itemInfo.nGenre == ITEM_GENRE.HOMELAND then
        self.szType = "Furniture"
        self:UpdateFurnitureModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE then
        self.szType = "Ride"
        self:UpdateHorseModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        self.szType = "Ride"
        self:UpdateHorseEquipModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.PET then
        self.szType = "Pet"
        self:UpdatePetModelInfo()
    elseif itemInfo then
        self:UpdateMiddleItemIconInfo()
    end
end

function CommonStoreModelManager:UpdatePlayerModelInfo()
    if not self.tModelItemInfo then
        return
    end
    local dwItemTabType = self.tModelItemInfo.dwItemType
    local dwItemTabIndex = self.tModelItemInfo.dwItemID
    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    local szDefaultAni = CharacterIdleActionData.GetDefaultAni(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
    local nActionRepresentID = GetActionRepresentID(0) -- 使用商城默认站姿

    if not itemInfo then
        return
    end

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    for _, nRepresentSub in ipairs(tRepresentSub) do
        tRepresentID[nRepresentSub] = 0
    end

    local nRepresentCategory = tRepresentSub[itemInfo.nSub]
    if nRepresentCategory then
        tRepresentID[nRepresentCategory] = itemInfo.nRepresentID
    end
    tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
    tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0

    if ItemData.IsPendantItem(itemInfo) or ItemData.IsPendantPetItem(itemInfo) then
        local hPendant
        if itemInfo.nDetail and itemInfo.nDetail > 0 then
            hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, itemInfo.nDetail)
        else
            hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemTabIndex)
        end
        local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)--14,0
        tRepresentID[nRepresentSub] = itemInfo.nRepresentID
    elseif itemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.IDLE_ACTION then
        nActionRepresentID = itemInfo.nDetail -- 站姿
    elseif itemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
        local dwExteriorID = itemInfo.nDetail
        local tExteriorInfo = hExterior.GetExteriorInfo(dwExteriorID)
        local nRepresentSub = ExteriorView_GetRepresentSub(tExteriorInfo.nSubType)
        tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID -- 外观
    elseif itemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
        local nHairID = itemInfo.nDetail
        tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = 0 -- 去掉帽子
        tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = nHairID  -- 头发
    elseif IsDesignationEffectSfxItemInfo(itemInfo) then
        local nType, nEffectID = ExteriorCharacter.GetRewardsEffectSfxTypeItemInfo(itemInfo)
        Event.Dispatch("PREVIEW_PENDANT_EFFECT_SFX", nType, nEffectID)
        tRepresentID.tEffect = ExteriorCharacter.SetAllPreviewEffectCustomPos()
    end

    ExteriorCharacter.ShowPlayer(STORE_FRAME_NAME, STORE_NAME, tRepresentID)

    local tbFrame = ExteriorCharacter.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    local model = tbFrame.hModelView
    local camera = tbFrame.hCamera
    UITouchHelper.BindModel(self.TouchContainer, model, camera, { tbFrame = tbFrame, bIsExterior = true })
    Timer.Add(self, 0.1, function()
        UITouchHelper.SetYaw(model:GetYaw())
    end)

    local nCameraID = tEquipSubCameraID[itemInfo.nSub] or 0
    local nRoleType = g_pClientPlayer.nRoleType
    local tRewardCamera = TabHelper.GetUIRewardsCameraTab(nCameraID, nRoleType)
    if tRewardCamera then
        local tCameraInfo = {}
        CoinShop_ParseCameraInfo(tRewardCamera, tCameraInfo)
        FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_INFO", STORE_FRAME_NAME, STORE_NAME, tCameraInfo.tCameraInfo)
        FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", STORE_FRAME_NAME, STORE_NAME, tCameraInfo.szInitPosition, nil)
    else
        local szCameraMode, szCameraRadius = GetCameraModeByEquipSub(itemInfo.nSub)
        ExteriorCharacter.SetCameraMode(szCameraMode)
        local tCameraInfo = ExteriorCharacter.GetCameraInfo()
        FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_INFO", STORE_FRAME_NAME, STORE_NAME, tCameraInfo)
        FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", STORE_FRAME_NAME, STORE_NAME, szCameraRadius, nil)
    end

    FireUIEvent("EXTERIOR_CHARACTER_PLAY_LOGIC_ANI", STORE_FRAME_NAME, STORE_NAME, nActionRepresentID, szDefaultAni) -- 设置站姿

    self:UpdateDownloadEquipRes()
end

function CommonStoreModelManager:UpdatePendantModelInfo()
    if not self.tModelItemInfo then
        return
    end
    local dwItemTabType = self.tModelItemInfo.dwItemType
    local dwItemTabIndex = self.tModelItemInfo.dwItemID
    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local tbCamera = self:GetCameraTab()

    self.hPendantModelView:UnloadModel()
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()

    self.hPendantModelView:LoadRes(itemInfo, tRepresentSub[itemInfo.nSub])
    self.hPendantModelView:LoadModel()
    --self.hPendantModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    --self.hPendantModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    --self.hPendantModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    self.hPendantModelView:SetTranslation(unpack({ 0, 50, 0 }))
    self.hPendantModelView:SetYaw(tbCamera.nModelYaw)

    local tbFrame = PendantModelView.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    tbFrame.camera:UpdateZoom(1, 0, 0, 0.2)

    UITouchHelper.BindModel(self.TouchContainer, self.hPendantModelView)

    self:UpdateDownloadEquipRes()
end

function CommonStoreModelManager:UpdateFurnitureModelInfo()
    if not self.tModelItemInfo then
        return
    end
    local dwItemTabType = self.tModelItemInfo.dwItemType
    local dwItemTabIndex = self.tModelItemInfo.dwItemID

    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    self:LoadSetting(self.tFurniturModelSetting)
    local nFurnitureType = itemInfo.nFurnitureType
    local dwFurnitureID = itemInfo.dwFurnitureID
    local tLine = Table_GetAwardFurnitureModelInfo(dwFurnitureID)
    local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
    local dwRepresentID = tUIInfo and tUIInfo.dwModelID
    local tbPos = tLine and SplitString(tLine.szPosMB, ";") or { 0, 12, 0 }
    local fScale = tLine and tLine.fScaleMB or Const.MiniScene.StoreView.fFurnitureModelScale
    local nYaw = tLine and tLine.nYaw or Const.MiniScene.StoreView.fFurnitureModelYaw
    local nPutType = tLine and tLine.nPutType or 0
    local nDetails = tLine and tLine.nDetails or 0

    FireUIEvent(
            "FURNITURE_MODEL_PREVIEW_UPDATE",
            STORE_FRAME_NAME,
            STORE_NAME,
            dwRepresentID,
            nil,
            tbPos,
            nPutType,
            nDetails,
            nYaw,
            fScale
    )

    Timer.DelTimer(self, self.nFurnitureTouchTimerID)
    self.nFurnitureTouchTimerID = Timer.AddFrame(self, 3, function()
        local tbFrame = FurnitureModelPreview.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
        if tbFrame then
            local model = tbFrame.hFurnitureModelView
            local camera = tbFrame.camera
            UITouchHelper.BindModel(self.TouchContainer, model, camera, { tbFrame = tbFrame })
        end
    end)
    FireUIEvent("FURNITURE_MODEL_SET_CAMERA_ZOOM", STORE_FRAME_NAME, STORE_NAME, "Min")
end

function CommonStoreModelManager:UpdateHorseModelInfo()
    if not self.tModelItemInfo then
        return
    end
    local dwItemTabType = self.tModelItemInfo.dwItemType
    local dwItemTabIndex = self.tModelItemInfo.dwItemID

    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    local player = g_pClientPlayer
    local tbRepresentID = player.GetRepresentID()

    if itemInfo and itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.HORSE then
        tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = itemInfo.nRepresentID
    else
        return
    end

    FireUIEvent("RIDES_MODEL_PREVIEW_UPDATE", STORE_FRAME_NAME, STORE_NAME, tbRepresentID)

    local tbFrame = RidesModelPreview.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    if tbFrame then
        local model = tbFrame.hRidesModelView
        local camera = tbFrame.camera
        UITouchHelper.BindModel(self.TouchContainer, model, camera, { tbFrame = tbFrame })
    end
    FireUIEvent("RIDES_MODEL_SET_CAMERA_ZOOM", STORE_FRAME_NAME, STORE_NAME, "Min")
end

function CommonStoreModelManager:UpdateHorseEquipModelInfo()
    if not self.tModelItemInfo then
        return
    end
    local dwItemTabType = self.tModelItemInfo.dwItemType
    local dwItemTabIndex = self.tModelItemInfo.dwItemID

    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    local tNewItem = { dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex = dwItemTabIndex }
    ExteriorCharacter.ClearHorse(false)
    ExteriorCharacter.ClearHorseAdornment(false)
    ExteriorCharacter.PreviewHorseAdornment(tNewItem, true, true, false)
    FireUIEvent("PREVIEW_HORSE_ITEM", tNewItem, true)

    local tRepresentID = ExteriorCharacter.GetRoleRes()
    FireUIEvent("RIDES_MODEL_PREVIEW_UPDATE", STORE_FRAME_NAME, STORE_NAME, tRepresentID)

    local tbFrame = RidesModelPreview.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    if tbFrame then
        local model = tbFrame.hRidesModelView
        local camera = tbFrame.camera
        UITouchHelper.BindModel(self.TouchContainer, model, camera, { tbFrame = tbFrame })
    end
    FireUIEvent("RIDES_MODEL_SET_CAMERA_ZOOM", STORE_FRAME_NAME, STORE_NAME, "Min")
end

function CommonStoreModelManager:UpdatePetModelInfo()
    if not self.tModelItemInfo then
        return
    end
    local dwItemTabType = self.tModelItemInfo.dwItemType
    local dwItemTabIndex = self.tModelItemInfo.dwItemID

    local dwPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemTabIndex)
    local tPet = Table_GetFellowPet(dwPetIndex)
    if not tPet then
        return
    end

    local fScale = tPet.fMobileCoinShopScale > 0.001 and tPet.fMobileCoinShopScale or tPet.fModelScaleMB

    FireUIEvent(
            "NPC_MODEL_PREVIEW_UPDATE",
            STORE_FRAME_NAME,
            STORE_NAME,
            tPet.dwModelID,
            tPet.nColorChannelTable,
            tPet.nColorChannel,
            fScale
    )

    local tbFrame = NpcModelPreview.tResisterFrame[STORE_FRAME_NAME][STORE_NAME]
    if tbFrame then
        local model = tbFrame.hNpcModelView
        local camera = tbFrame.camera
        UITouchHelper.BindModel(self.TouchContainer, model, camera, { tbFrame = tbFrame })
    end
    FireUIEvent("NPC_MODEL_SET_CAMERA_ZOOM", STORE_FRAME_NAME, STORE_NAME, "Min")
end

function CommonStoreModelManager:UpdateDesignationInfo()
    --if not self.tModelItemInfo then
    --    return
    --end
    --local dwItemTabType  = self.tModelItemInfo.dwItemType
    --local dwItemTabIndex = self.tModelItemInfo.dwItemID
    --
    --local szDefaultAni = CharacterIdleActionData.GetDefaultAni(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
    --local nActionRepresentID = GetActionRepresentID(0) -- 使用商城默认站姿
    --
    --local tItemInfo = GetItemInfo(dwItemTabType, dwItemTabIndex)
    --local nEffectID
    --if tItemInfo.nPrefix ~= 0 then
    --    nEffectID = GetDesignationPrefixInfo(tItemInfo.nPrefix).dwSFXID
    --elseif tItemInfo.nPostfix ~= 0 then
    --    nEffectID = GetDesignationPostfixInfo(tItemInfo.nPostfix).dwSFXID
    --end
    --local tInfo = Table_GetPendantEffectInfo(nEffectID)
    --local nType = CharacterEffectData.GetLogicTypeByEffectType(tInfo.szType)
    --
    --local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    --for _, nRepresentSub in ipairs(tRepresentSub) do
    --    tRepresentID[nRepresentSub] = 0
    --end
    --
    --tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
    --tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    --
    --
    --local bIngoreReplace = not ExteriorCharacter.GetRepresentReplace()
    --FireUIEvent("EXTERIOR_CHARACTER_UPDATE", STORE_FRAME_NAME, STORE_NAME, tRepresentID, bIngoreReplace, nActionRepresentID, szDefaultAni)
end

function CommonStoreModelManager:UpdateMiddleItemIconInfo()
    if not self.tModelItemInfo then
        return
    end
    local dwItemTabType = self.tModelItemInfo.dwItemType
    local dwItemTabIndex = self.tModelItemInfo.dwItemID

    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    -- 这里可以设置物品图标显示
    -- UIHelper.SetItemIconByItemInfo(self.ImgGoods, itemInfo)
    -- UIHelper.SetVisible(self.WidgetAnchorMiddle, true)
    -- UIHelper.SetVisible(self.WidgetEmpty, true)
    -- UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
end

function CommonStoreModelManager:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not self.hModelView then
        return
    end
    local nRoleType, tEquipList, tEquipSfxList = self.hModelView:GetPakEquipResource()
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function CommonStoreModelManager:LoadSetting(tSetting)
    local szSettingFile = "/ui/Scheme/Setting/CoinShopFurnitureSetting.ini"
    local pFile = Ini.Open(szSettingFile)
    if not pFile then
        return
    end
    local szSection = "FurnitureModelSetting"
    tSetting = {}
    tSetting.CriterionX = pFile:ReadInteger(szSection, "CriterionX", 0)
    tSetting.CriterionY = pFile:ReadInteger(szSection, "CriterionY", 0)
    tSetting.CriterionZ = pFile:ReadInteger(szSection, "CriterionZ", 0)
    tSetting.MaxScale = pFile:ReadFloat(szSection, "MaxScale", 0)
    tSetting.MinScale = pFile:ReadFloat(szSection, "MinScale", 0)
    tSetting.PlatformMesh = pFile:ReadString(szSection, "PlatformMesh", "")
    tSetting.PlatformX = pFile:ReadFloat(szSection, "PlatformX", 0)
    tSetting.PlatformY = pFile:ReadFloat(szSection, "PlatformY", 0)
    tSetting.PlatformZ = pFile:ReadFloat(szSection, "PlatformZ", 0)
    tSetting.PlatformYaw = pFile:ReadFloat(szSection, "PlatformYaw", 0)
    pFile:Close()
    Homeland_SendMessage(HOMELAND_FURNITURE.ENTER, self.hModelView.m_scene, tSetting.PlatformMesh, tSetting.PlatformX, tSetting.PlatformY, tSetting.PlatformZ, tSetting.PlatformYaw)
end

function CommonStoreModelManager:GetCameraTab()
    local dwItemType = self.tModelItemInfo.dwItemType
    local dwItemID = self.tModelItemInfo.dwItemID

    if string.is_nil(self.szType) then
        return
    end

    local szKey = string.format("%s-%s", tostring(dwItemType), tostring(dwItemID))

    if not UIStoreCameraTab[self.szType] then
        return
    end

    local tbRet = UIStoreCameraTab[self.szType][szKey] or UIStoreCameraTab[self.szType]["default"]
    return tbRet
end

function CommonStoreModelManager:GetModelView()
    return self.hModelView
end

function CommonStoreModelManager:GetPendantModelView()
    return self.hPendantModelView
end

function CommonStoreModelManager:GetRideModelView()
    return self.hRideModelView
end

function CommonStoreModelManager:GetFurnitureModelView()
    return self.hFurnitureModelView
end

function CommonStoreModelManager:GetPetModelView()
    return self.hPetModeView
end

function CommonStoreModelManager:GetCurrentModelType()
    return self.szType or ""
end

function CommonStoreModelManager:GetCurrentItemInfo()
    if not self.tModelItemInfo then
        return nil, nil
    end
    return self.tModelItemInfo.dwItemType, self.tModelItemInfo.dwItemID
end

function CommonStoreModelManager:ClearModelInfo()
    UITouchHelper.UnBindModel()
    Timer.DelTimer(self, self.nFurnitureTouchTimerID)

    ExteriorCharacter.RestoreCameraLight(STORE_FRAME_NAME, STORE_NAME)
    SceneHelper.Delete(self.m_scene)

    if self.hPendantModelView then
        self.hPendantModelView:UnloadModel()
        self.hPendantModelView:release()
        self.hPendantModelView = nil
    end

    ExteriorCharacter.UnRegisterExteriorCharacter(STORE_FRAME_NAME, STORE_NAME)
    UnRegisterNpcModel(STORE_FRAME_NAME, STORE_NAME)
    UnRegisterRidesModel(STORE_FRAME_NAME, STORE_NAME)
    UnRegisterFurnitureModel(STORE_FRAME_NAME, STORE_NAME)

    self.tModelItemInfo = nil
    self.szType = nil
end