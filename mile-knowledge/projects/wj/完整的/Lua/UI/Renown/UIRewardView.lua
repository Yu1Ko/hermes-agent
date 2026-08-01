local UIRewardView = class("UIRewardView")

local nNpcColumnCount = 3
local nItemColumnCount = 4
local nNpcRowCount = 7
local nItemRowCount = 14
local nPerPageMaxNpcCell = nNpcColumnCount * nNpcRowCount
local nPerPageMaxItemCell = nItemColumnCount * nItemRowCount
local tbModelPreviewInfo = Const.MiniScene.RewardView.tbModelPreviewInfo
local tbFurnitureModelPos = Const.MiniScene.RewardView.tbFurnitureModelPos
local tbFurnitureCamare = Const.MiniScene.RewardView.tbFurnitureCamare        --家具模型
local tbAccompanyModelCamare = Const.MiniScene.RewardView.tbAccompanyCamare   --知交模型
local tbFrame ={ tRadius = {280, 700} }
local tRepresentSub =
{
    -- [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
    -- [EQUIPMENT_SUB.CHEST] = EQUIPMENT_REPRESENT.CHEST_STYLE,
    -- [EQUIPMENT_SUB.HELM]  = EQUIPMENT_REPRESENT.HELM_STYLE,
    -- [EQUIPMENT_SUB.WAIST] = EQUIPMENT_REPRESENT.WAIST_STYLE,
    -- [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_REPRESENT.BOOTS_STYLE,
    -- [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_REPRESENT.BANGLE_STYLE,
    [EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    -- [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    -- [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    -- [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    -- [EQUIPMENT_SUB.BAG_EXTEND] = EQUIPMENT_REPRESENT.BAG_EXTEND,
    -- [EQUIPMENT_SUB.PENDENT_PET] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    -- [EQUIPMENT_SUB.GLASSES_EXTEND] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    -- [EQUIPMENT_SUB.L_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    -- [EQUIPMENT_SUB.R_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
}

local tHorseEquipToRe =
{
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT4,
}
function UIRewardView:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        require("Lua/UI/Renown/AccompanyConfig.lua")
    end

    tParam = tParam or {}
    self.bCheckNpc = true
    self.nPageIndex = 1
    self.nPageCount = 1
    self.dwDefaultTabType = tParam.dwTabType
    self.dwDefaultIndex = tParam.dwIndex
    self.dwDefaultRewardForceID = tParam.dwForceID
    self.scriptNpcBarMap = {}
    self.scriptItemBarMap = {}
    self:InitMiniScene()
    self:RefreshShowMode()
    self:UpdateInfo()
    Timer.AddFrame(self, 1, function ()
        self:RedirectNpc(tParam.dwForceID)
    end)
end

function UIRewardView:OnExit()
    UITouchHelper.UnBindModel()
    UITouchHelper.UnBindUIZoom()

    -- Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)
    if self.hModelView then
        if self.hModelView.m_scene then
            self.hModelView.m_scene:RestoreCameraLight()
        end

        self.hModelView:release()
        self.hModelView = nil
        self.cameraModel = nil
    end

    if self.hRideModelView then
        self.hRideModelView:release()
        self.hRideModelView = nil
        self.cameraRideModel = nil
    end

    if self.hFurnitureModelView then
        self.hFurnitureModelView:release()
        self.hFurnitureModelView = nil
        self.tFurniturModelSetting = nil
        self.cameraFurnitureModel = nil
    end

    self.bInit = false

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UIRewardView:BindUIEvent()
    --退出前要先保证Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        self:CloseRewordListView()
    end)

    UIHelper.BindUIEvent(self.BtnRenown, EventType.OnClick, function ()
        local scriptRenownView = UIMgr.GetViewScript(VIEW_ID.PanelRenownList)
        if not scriptRenownView then
            scriptRenownView = UIMgr.Open(VIEW_ID.PanelRenownList)
        end
        scriptRenownView:RedirectForceView(self.dwRewardForceID)
        self:CloseRewordListView()
    end)

    UIHelper.BindUIEvent(self.BtnCallFriend, EventType.OnClick, function ()
        self:OnCallNpc()
    end)

    UIHelper.BindUIEvent(self.BtnResetNpcFliter, EventType.OnClick, function ()
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupNpcFliter, self.scriptAllNpcFliter.ToggleSelect)
        self.scriptAllNpcFliter.fCallBack()
    end)

    UIHelper.BindUIEvent(self.BtnResetItemFliter, EventType.OnClick, function ()
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupItemFliter, self.scriptAllItemFliter.ToggleSelect)
        self.scriptAllItemFliter.fCallBack()
    end)

    UIHelper.BindUIEvent(self.BtnAffirmNpcFliter, EventType.OnClick, function ()
        UIHelper.SetSelected(self.TogScreen, false)
        UIHelper.SetVisible(self.WidgetNpcFliter, false)
    end)

    UIHelper.BindUIEvent(self.BtnAffirmItemFliter, EventType.OnClick, function ()
        UIHelper.SetSelected(self.TogScreen, false)
        UIHelper.SetVisible(self.WidgetItemFliter, false)
    end)

    UIHelper.BindUIEvent(self.BtnRewardClear, EventType.OnClick, function ()
        UIHelper.SetText(self.EditBoxSearch, "")
        self.szRewardKeyWord = nil
        self:RefreshReweardInfo()
    end)

    UIHelper.BindUIEvent(self.TogChangeReward, EventType.OnSelectChanged, function (_, bSelected)
        self.bCheckNpc = bSelected
        self.nPageIndex = 1
        self:RefreshShowMode()
        local szPlaceHolder = "搜索知交"
        if not self.bCheckNpc then
            szPlaceHolder = "搜索物品"
        end
        UIHelper.SetPlaceHolder(self.EditBoxSearch, szPlaceHolder)
        if not self.bInitItemInfo then
            self:InitRewardItemInfoList()
        end
        UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        self:RefreshReweardInfo()
        self:UpdateModelInfo()
        self:UpdateEditPaginateInfo()
    end)

    UIHelper.BindUIEvent(self.TogScreen, EventType.OnSelectChanged, function (_, bSelected)
        self.bFliterOpen = bSelected
        UIHelper.SetVisible(self.WidgetNpcFliter, self.bFliterOpen and self.bCheckNpc)
        UIHelper.SetVisible(self.WidgetItemFliter, self.bFliterOpen and not self.bCheckNpc)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function ()
        self.szRewardKeyWord = UIHelper.GetText(self.EditBoxSearch)
        self:RefreshReweardInfo()
        self.nPageIndex = 1
        UIHelper.SetString(self.EditPaginate, self.nPageIndex)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        if self.nPageIndex > 1 then
            self.nPageIndex = self.nPageIndex - 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self:RefreshReweardInfo()
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            if nPageIndex < 1 then
                self.nPageIndex = 1
            elseif nPageIndex > self.nPageCount then
                self.nPageIndex = self.nPageCount
            else
                self.nPageIndex = nPageIndex
            end
            if self.nPageIndex ~= nPageIndex then
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            end
            self:RefreshReweardInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        if self.nPageIndex < self.nPageCount then
            self.nPageIndex = self.nPageIndex + 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self:RefreshReweardInfo()
        end
    end)

    UIHelper.SetTouchDownHideTips(self.BtnLeft, false)
    UIHelper.SetTouchDownHideTips(self.BtnRight, false)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)

end

function UIRewardView:InitMiniScene()
    self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
    self.hModelView:ctor()
    self.hModelView:InitBy({
        szName = "RenownReward",
        bExScene = true,
        -- szExSceneFile = "data\\source\\maps\\HD商城_2022_灰_001\\HD商城_2022_灰_001.jsonmap",
        szExSceneFile = Const.COMMON_SCENE,
        bAPEX = false,
     })
    self.tbModelPreviewInfo = tbModelPreviewInfo[GetClientPlayer().nRoleType]
    self.MiniScene:SetScene(self.hModelView.m_scene)

    self.hRideModelView = RidesModelView.CreateInstance(RidesModelView)
    self.hRideModelView:ctor()
    self.hRideModelView:init(self.hModelView.m_scene, nil)
    RidesModelPreview.RegisterHorse(self.MiniScene, self.hRideModelView, "RenownRewardHorse", "RenownRewardHorse")

    self.tFurniturModelSetting = {}
    self.hFurnitureModelView = FurnitureModelView.CreateInstance(FurnitureModelView)
    self.hFurnitureModelView:ctor()
    self.hFurnitureModelView:init(self.hModelView.m_scene, true, _, "RenownRewardFurniture")
end

function UIRewardView:RegEvent()
    Event.Reg(self, "UI_CALL_REPU_SERVANT", function ()
        self:UpdateRewardNpcDetail(self.dwRewardForceID)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:HideTypeFliter()
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 and self.hModelView.m_scene and not QualityMgr.bDisableCameraLight then
            self.hModelView.m_scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateModelInfo()
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 1, nil)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            if nPageIndex < 1 then
                self.nPageIndex = 1
            elseif nPageIndex > self.nPageCount then
                self.nPageIndex = self.nPageCount
            else
                self.nPageIndex = nPageIndex
            end
            if self.nPageIndex ~= nPageIndex then
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            end
            self:RefreshReweardInfo()
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then UIHelper.SetVisible(self.WidgetAnchorLeft, false) end
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then UIHelper.SetVisible(self.WidgetAnchorLeft, true) end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self:UpdateNpcInfoPage()
    end)
end

function UIRewardView:UpdateInfo()
    UIHelper.SetTouchDownHideTips(self.TogScreen, false)
    UIHelper.SetTouchDownHideTips(self.SrcollViewNpcFliter, false)
    UIHelper.SetTouchDownHideTips(self.SrcollViewItemFliter, false)
    UIHelper.SetTouchDownHideTips(self.BtnResetNpcFliter, false)
    UIHelper.SetTouchDownHideTips(self.BtnAffirmNpcFliter, false)
    UIHelper.SetTouchDownHideTips(self.BtnResetItemFliter, false)
    UIHelper.SetTouchDownHideTips(self.BtnAffirmItemFliter, false)

    self:InitAllNpcInfoList()
    Timer.AddFrame(self, 10, function ()
        if not self.bInitItemInfo then
            self:InitRewardItemInfoList()
        end
    end)
    self:UpdateEditPaginateInfo()
    self:UpdateTypeFliter()
    self:RefreshReweardInfo()
end

function UIRewardView:UpdateModelInfo()
    UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
    if self.bCheckNpc then
        self:UpdateAccompanyModelInfo()
    else
        self:UpdateItemModelInfo()
    end
end

function UIRewardView:UpdateItemModelInfo()
    UIHelper.SetVisible(self.WidgetModelEmpty, false)
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()
    self.hFurnitureModelView:UnloadModel()
    Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)

    if not self.dwItemTabType or not self.dwItemTabIndex then
        return
    end

    local itemInfo = ItemData.GetItemInfo(self.dwItemTabType, self.dwItemTabIndex)
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
    elseif itemInfo then
        self:UpdateMiddleItemIconInfo()
    end
end

function UIRewardView:UpdateFurnitureModelInfo()
    if not self.dwItemTabType or not self.dwItemTabIndex then
        return
    end
    local itemInfo = ItemData.GetItemInfo(self.dwItemTabType, self.dwItemTabIndex)
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
    local fScale         = tLine and tLine.fScaleMB or Const.MiniScene.RewardView.fFurnitureModelScale
    local nYaw           = tLine and tLine.nYaw or Const.MiniScene.RewardView.fFurnitureModelYaw
    local nPutType       = tLine and tLine.nPutType or 0
    local nDetails       = tLine and tLine.nDetails or 0

    self.hFurnitureModelView:LoadModel(dwRepresentID, nPutType, nDetails, fScale)
    self.hFurnitureModelView:SetTranslation(unpack(tbPos))
    self.hFurnitureModelView:SetCamera(tbFurnitureCamare)
    self.hFurnitureModelView:SetYaw(nYaw)
    self.hFurnitureModelView:SetScale(fScale, fScale, fScale)

    self.cameraFurnitureModel = self.cameraFurnitureModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraFurnitureModel, tbFurnitureCamare)
    UITouchHelper.BindModel(self.TouchContainer, self.hFurnitureModelView, self.cameraFurnitureModel, {tbFrame = tbFrame})
end

function UIRewardView:UpdatePendantItemModelInfo()
    local itemInfo = ItemData.GetItemInfo(self.dwItemTabType, self.dwItemTabIndex)
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
    tRepresentID[tRepresentSub[itemInfo.nSub]] = itemInfo.nRepresentID
    local bShowWeapon = false
    if not bShowWeapon then
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end
    local nYaw = self.tbModelPreviewInfo[itemInfo.nSub] or self.tbModelPreviewInfo.nYaw
    self.hModelView:LoadRes(hPlayer.dwID, tRepresentID)
    self.hModelView:PlayAnimation("Idle", "loop")
    self.hModelView:SetTranslation(table.unpack(Const.MiniScene.RewardView.tbPos))
    self.hModelView:SetYaw(nYaw)
    self.hModelView:SetCamera(self.tbModelPreviewInfo.tbCamere)

    self.cameraModel = self.cameraModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraModel, self.tbModelPreviewInfo.tbCamere)
    UITouchHelper.BindModel(self.TouchContainer, self.hModelView, self.cameraModel, {tbFrame = tbFrame})

    self:UpdateDownloadEquipRes()
end

local function TableCombine(A,B)
    local C = {}
    for _, value in ipairs(A) do
        table.insert(C, value)
    end
    for _, value in ipairs(B) do
        table.insert(C, value)
    end
    return C
end

function UIRewardView:UpdateHorseEquipModelInfo()
    if not self.dwItemTabType or not self.dwItemTabIndex then
        return
    end

    local itemInfo = ItemData.GetItemInfo(self.dwItemTabType, self.dwItemTabIndex)
    if not itemInfo then
        return
    end

    local player = g_pClientPlayer
    local tbRepresentID = player.GetRepresentID()
    local nRepresentSub = tHorseEquipToRe[itemInfo.nDetail]
    for _, nHorseEquipToRe in ipairs(tHorseEquipToRe) do
        tbRepresentID[nHorseEquipToRe] = 0
    end

    if itemInfo and itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        tbRepresentID[nRepresentSub] = itemInfo.nRepresentID
    end

    local tbCamera = UICameraTab["Ride"][VIEW_ID.PanelRenownRewordList]

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

    local tbRideModelCamera = TableCombine(tbCamera.tbCameraPos, tbCamera.tbCameraLookPos)
    self.cameraRideModel = self.cameraRideModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraRideModel, tbRideModelCamera)
    UITouchHelper.BindModel(self.TouchContainer, self.hRideModelView, self.cameraRideModel, {tbFrame = tbFrame})
end

function UIRewardView:UpdateHorseModelInfo()
    if not self.dwItemTabType or not self.dwItemTabIndex then
        return
    end

    local itemInfo = ItemData.GetItemInfo(self.dwItemTabType, self.dwItemTabIndex)
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

    local tbCamera = UICameraTab["Ride"][VIEW_ID.PanelRenownRewordList]

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

    local tbRideModelCamera = TableCombine(tbCamera.tbCameraPos, tbCamera.tbCameraLookPos)
    self.cameraRideModel = self.cameraRideModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraRideModel, tbRideModelCamera)
    UITouchHelper.BindModel(self.TouchContainer, self.hRideModelView, self.cameraRideModel, {tbFrame = tbFrame})
end

function UIRewardView:UpdateAccompanyModelInfo()
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()
    self.hFurnitureModelView:UnloadModel()
    Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)

    local tPartsbConfig = AccompanyConfig.tWearParts[1000 + self.dwRewardForceID]
    if not tPartsbConfig then
        return
    end

    local szFaceINI = AccompanyConfig.tFaceIni[1000 + self.dwRewardForceID]
    if not szFaceINI then
        return
    end

    local tRepresentID = {
        bUseLiftedFace = true,
        nHatStyle = 0,
        tFaceData = {},
    }

    for i = 0, 45, 1 do
        tRepresentID[i] = 0
    end

    --perHairStyle nHeadForm nBang nPlati
    tRepresentID[0] = tPartsbConfig.nFaceIni or 1
    tRepresentID[1] = tPartsbConfig.nHat or 0
    --perHelmStyle nHat
    tRepresentID.nHatStyle = tPartsbConfig.nHat or 0
    tRepresentID[2] = tPartsbConfig.nHat or 0
    tRepresentID[3] = tPartsbConfig.nColor or 0
    --perChestStyle nChest
    tRepresentID[5] = tPartsbConfig.nChest or 0
    tRepresentID[6] = tPartsbConfig.nColor or 0
    --perWaistStyle nWaist
    tRepresentID[8] = tPartsbConfig.nWaist or 0
    tRepresentID[9] = tPartsbConfig.nColor or 0
    --perBangleStyle nBangle
    tRepresentID[11] = tPartsbConfig.nBangle or 0
    tRepresentID[12] = tPartsbConfig.nColor or 0
    --perBootsStyle nPants
    tRepresentID[14] = tPartsbConfig.nPants or 0
    tRepresentID[15] = tPartsbConfig.nColor or 0
    --perWeaponStyle
    tRepresentID[16] = 0
    --perPantsStyle nPants
    tRepresentID[38] = tPartsbConfig.nPants or 0
    tRepresentID[39] = tPartsbConfig.nColor or 0

    self.hModelView:UpdateRepresentID(tRepresentID, tPartsbConfig.nRoleType, self.dwRewardForceID)
    self.hModelView:LoadFaceDefinitionINI(UIHelper.UTF8ToGBK(szFaceINI))
    self.hModelView:PlayAnimation("Idle", "loop")
    self.hModelView:SetTranslation(table.unpack(Const.MiniScene.RewardView.tbAccompanyPos))
    self.hModelView:SetYaw(Const.MiniScene.RewardView.fAccompanyYaw)
    self.hModelView:SetCamera(tbAccompanyModelCamare)
    self.hModelView:SetCamera(tbAccompanyModelCamare)

    self.cameraModel = self.cameraModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraModel, tbAccompanyModelCamare)
    self.cameraModel:set_mainplayer_pos(table.unpack(Const.MiniScene.RewardView.tbAccompanyPos))
    UITouchHelper.BindModel(self.TouchContainer, self.hModelView, self.cameraModel, {tbFrame = tbFrame})
end

function UIRewardView:UpdateMiddleItemIconInfo()
    if not self.dwItemTabType or not self.dwItemTabIndex then
        return
    end
    local itemInfo = ItemData.GetItemInfo(self.dwItemTabType, self.dwItemTabIndex)
    if not itemInfo then
        return
    end
    --UIHelper.SetItemIconByItemInfo(self.ImgGoods, itemInfo)
    UIHelper.SetVisible(self.WidgetModelEmpty, true)
end

function UIRewardView:InitAllNpcInfoList()
    local aReceivedNpcRewards, aUnreceivedNpcRewards = RepuData.GetReceivedNpcRewards(true)
    local nReceivedCount = #aReceivedNpcRewards
    local nUnreceivedCount = #aUnreceivedNpcRewards
    self.dwRewardForceID = nil
    self.tAllNpcInfoList = {}
    self.tCurNpcInfoList = {}
    self.tScriptNpcRowList = {}
    self.tScriptItemRowList = {}
    UIHelper.RemoveAllChildren(self.LayoutContentNpc)
    UIHelper.RemoveAllChildren(self.LayoutContentItem)

    for i = 1, nReceivedCount do
        local tNpcInfo = {}
        tNpcInfo.dwForceID = aReceivedNpcRewards[i]
        tNpcInfo.bReceived = true
        tNpcInfo.fCallBack = function (bSelected)
            self:OnSelectedNpcChanged(i, tNpcInfo)
        end
        local tServantInfo, bSuccess = RepuData.GetServantInfoByForceID(tNpcInfo.dwForceID)
        if bSuccess then
            tNpcInfo.szNpcName = UIHelper.GBKToUTF8(tServantInfo.szNpcName)
            tNpcInfo.szRoleType = tServantInfo.szRoleType
        end
        table.insert(self.tAllNpcInfoList, tNpcInfo)
        table.insert(self.tCurNpcInfoList, tNpcInfo)
    end
    for i = 1, nUnreceivedCount do
        local tNpcInfo = {}
        tNpcInfo.dwForceID = aUnreceivedNpcRewards[i]
        tNpcInfo.bReceived = false
        tNpcInfo.fCallBack = function (bSelected)
            self:OnSelectedNpcChanged(i + nReceivedCount, tNpcInfo)
        end
        local tServantInfo, bSuccess = RepuData.GetServantInfoByForceID(tNpcInfo.dwForceID)
        if bSuccess then
            tNpcInfo.szNpcName = UIHelper.GBKToUTF8(tServantInfo.szNpcName)
            tNpcInfo.szRoleType = tServantInfo.szRoleType
        end
        table.insert(self.tAllNpcInfoList, tNpcInfo)
        table.insert(self.tCurNpcInfoList, tNpcInfo)
    end

    local szProgress = string.format("已解锁的奖励 %d/%d", nReceivedCount, nReceivedCount+nUnreceivedCount)
    UIHelper.SetString(self.LabelUnlockNpcProgress, szProgress)

    self:UpdateNpcInfoPage()
end

function UIRewardView:UpdateNpcInfoPage()
    local nSelectRowIndex = 1
    for nRowIndex = 1, nNpcRowCount do
        local scriptRow = self.tScriptNpcRowList[nRowIndex]
        if not scriptRow then
            scriptRow = UIHelper.AddPrefab(PREFAB_ID.WidgetRenowRewardNpcRow, self.ScrollViewNpc)
            scriptRow:OnEnter(PREFAB_ID.WidgetRenownFriendMessage)
        end
        scriptRow:ClearData()
        for nColIndex = 1, nNpcColumnCount do
            local nTableIndex = (self.nPageIndex-1) * nNpcRowCount * nNpcColumnCount + (nRowIndex - 1) * nNpcColumnCount + nColIndex
            local tNpcInfo = self.tCurNpcInfoList[nTableIndex]
            if tNpcInfo then
                local scriptCell = scriptRow:PushData(nColIndex, tNpcInfo.dwForceID, tNpcInfo.bReceived, tNpcInfo.fCallBack)
                self.scriptNpcBarMap[nTableIndex] = scriptCell
                local bNeedSelected = self.dwRewardForceID and tNpcInfo.dwForceID == self.dwRewardForceID
                UIHelper.SetSelected(scriptCell.ToggleSelect, bNeedSelected, false)
                if bNeedSelected then
                    tNpcInfo.fCallBack()
                    nSelectRowIndex = nRowIndex
                end
            end
        end
        self.tScriptNpcRowList[nRowIndex] = scriptRow
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewNpc)
    UIHelper.ScrollToIndex(self.ScrollViewNpc, nSelectRowIndex - 1, 0)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewNpc, true, true)
end

function UIRewardView:UpdateItemInfoPage()
    for nRowIndex = 1, nItemRowCount do
        local scriptRow = self.tScriptItemRowList[nRowIndex]
        if not scriptRow then
            scriptRow = UIHelper.AddPrefab(PREFAB_ID.WidgetRenowRewardItemRow, self.ScrollViewItem)
            scriptRow:OnEnter(PREFAB_ID.WidgetItem_100)
        end
        scriptRow:ClearData()
        for nColIndex = 1, nItemColumnCount do
            local nTableIndex = (self.nPageIndex-1) * nItemRowCount * nItemColumnCount + (nRowIndex - 1) * nItemColumnCount + nColIndex
            local tItemInfo = self.tCurItemInfoList[nTableIndex]
            if tItemInfo then
                tItemInfo.fCallBack = function()
                    self:OnSelectedItemChanged(nTableIndex, tItemInfo)
                end
                local scriptCell = scriptRow:PushData(nColIndex, tItemInfo)
                self.scriptItemBarMap[nTableIndex] = scriptCell
                local bNeedSelected = self.nSelectedItemInfoIdx and nTableIndex == self.nSelectedItemInfoIdx
                UIHelper.SetSelected(scriptCell.ToggleSelect, bNeedSelected, false)
                if bNeedSelected then tItemInfo.fCallBack() end
            end
        end
        self.tScriptItemRowList[nRowIndex] = scriptRow
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItem)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewItem, true, true)
end

function UIRewardView:OnSelectedNpcChanged(nIdx, tNpcInfo)
    self.nSelectedNpcInfoIdx = nIdx
    self.bReceived = tNpcInfo.bReceived
    self:UpdateRewardNpcDetail(tNpcInfo.dwForceID)

    local scriptBar = self.scriptNpcBarMap[nIdx]
    if scriptBar then
        UIHelper.SetSelected(scriptBar.ToggleSelect, true, false)
    end
end

function UIRewardView:UpdateRewardNpcDetail(dwRewardForceID)
    if not self.bCheckNpc then
        return
    end
    self.dwRewardForceID = dwRewardForceID
    local tServantInfo, bSuccess = RepuData.GetServantInfoByForceID(self.dwRewardForceID)
    if not bSuccess then
        return
    end
    local tForceUIInfo = Table_GetReputationForceInfo(self.dwRewardForceID)
    local szNpcName = UIHelper.GBKToUTF8(tServantInfo.szNpcName)
    local szForceName = UIHelper.GBKToUTF8(tForceUIInfo.szName)
    local szDescBrief = "<color=#ffd778>简介</color>："..UIHelper.GBKToUTF8(tServantInfo.szDescBrief)
    local szDescStory = "<color=#ffd778>故事</color>："..UIHelper.GBKToUTF8(tServantInfo.szDescStory)
    local nCurServantID = Servant_GetCurServantNpcIndex()
    if nCurServantID == tServantInfo.dwNpcIndex then
        UIHelper.SetString(self.LabelCallFriend, g_tStrings.STR_REPUTATION_DISMISS_SERVANT)
    else
        UIHelper.SetString(self.LabelCallFriend, g_tStrings.STR_REPUTATION_CALL_SERVANT)
    end

    UIHelper.SetString(self.LabelName, szNpcName)
    UIHelper.SetString(self.LabelNameType, szForceName)
    UIHelper.SetRichText(self.RichTextDescribe, szDescBrief.."\n"..szDescStory)

    Timer.AddFrame(self, 2, function ()
        UIHelper.ScrollViewDoLayout(self.ScrollViewDetail)
        UIHelper.ScrollToTop(self.ScrollViewDetail, 0)
    end)

    UIHelper.SetVisible(self.BtnCallFriend, self.bCheckNpc and self.bReceived)
    self:UpdateModelInfo()
end

function UIRewardView:RedirectNpc(dwDefaultRewardForceID)
    if dwDefaultRewardForceID then
        local nTargetIndex
        for nIndex, tNpcInfo in ipairs(self.tCurNpcInfoList) do
            if tNpcInfo.dwForceID == dwDefaultRewardForceID then
                nTargetIndex = nIndex
                break
            end
        end
        if nTargetIndex then
            self.nPageIndex = math.ceil(nTargetIndex/nPerPageMaxNpcCell)
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)

            local nIdx = nTargetIndex%nPerPageMaxNpcCell
            if nIdx == 0 then
                nIdx = nPerPageMaxNpcCell
            end
            self:OnSelectedNpcChanged(nIdx, self.tCurNpcInfoList[nTargetIndex])
            self.dwRewardForceID = dwDefaultRewardForceID
            self:UpdateNpcInfoPage()
        end
    end
end

function UIRewardView:InitRewardItemInfoList()
    self.bInitItemInfo = true
    local nUnlockedCount = 0
    local aAllRepuRewards = RepuData.GetAllRepuRewards()
    local aReceivedRepuRewards = RepuData.GetReceivedRepuRewards()
    local nCanReceiveItemCount = #aReceivedRepuRewards

    local fnCompareReceivedReward = function(tInfoL, tInfoR)
        if tInfoL == tInfoR then
            return false
        end

        local bReceivedL = tInfoL[2]
        local bReceivedR = tInfoR[2]
        if bReceivedL == bReceivedR then
            return false
        else
            return not bReceivedL
        end
    end

    table.sort(aReceivedRepuRewards, fnCompareReceivedReward)
    self.tAllItemInfoList = {}
    self.tCurItemInfoList = {}
    for i = 1, nCanReceiveItemCount do
        local tInfo = aReceivedRepuRewards[i]
        local tRewardInfo = aAllRepuRewards[tInfo[1]]
        local dwItemTabType, dwItemTabIndex = tRewardInfo[1], tRewardInfo[2]
        local tItemInfo = {}
        tItemInfo.dwItemTabType = dwItemTabType
        tItemInfo.dwItemTabIndex = dwItemTabIndex
        tItemInfo.bReceived = true
        tItemInfo.dwForceID = tRewardInfo[3]
        -- tItemInfo.fCallBack = function()
        --     self:OnSelectedItemChanged(i, tItemInfo)
        -- end
        local itemInfo = ItemData.GetItemInfo(tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
        local nBookInfo = itemInfo.nDurability
        tItemInfo.szRewardItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo))
        table.insert(self.tAllItemInfoList, tItemInfo)
        table.insert(self.tCurItemInfoList, tItemInfo)
        nUnlockedCount = nUnlockedCount + 1
    end
    local aUnreceivedRepuRewards = RepuData.GetUnreceivedRepuRewards()
    local nCannotReceiveItemCount = #aUnreceivedRepuRewards
    for j = 1, nCannotReceiveItemCount do
        local tRewardInfo = aAllRepuRewards[aUnreceivedRepuRewards[j]]
        local dwItemTabType, dwItemTabIndex = tRewardInfo[1], tRewardInfo[2]
        local tItemInfo = {}
        tItemInfo.dwItemTabType = dwItemTabType
        tItemInfo.dwItemTabIndex = dwItemTabIndex
        tItemInfo.bReceived = false
        tItemInfo.dwForceID = tRewardInfo[3]
        -- tItemInfo.fCallBack = function()
        --     self:OnSelectedItemChanged(j + nCanReceiveItemCount, tItemInfo)
        -- end
        local itemInfo = ItemData.GetItemInfo(tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
        local nBookInfo
        if itemInfo.nGenre == ITEM_GENRE.BOOK then
            nBookInfo = itemInfo.nDurability
        end
        tItemInfo.szRewardItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo))
        table.insert(self.tAllItemInfoList, tItemInfo)
        table.insert(self.tCurItemInfoList, tItemInfo)
    end
    local szProgress = string.format("已解锁的奖励 %d/%d", nCanReceiveItemCount, nCanReceiveItemCount+nCannotReceiveItemCount)
    UIHelper.SetString(self.LabelUnlockItemProgress, szProgress)

    self:UpdateItemInfoPage()
end

function UIRewardView:OnSelectedItemChanged(nIdx, tItemInfo)
    self.nSelectedItemInfoIdx = nIdx
    self.bReceived = tItemInfo.bReceived

    -- update两次，防止itemtips显示错误
    self:UpdateRewardItemDetail(tItemInfo.dwForceID, tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
    -- self:UpdateRewardItemDetail(tItemInfo.dwForceID, tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex)
    local scriptBar = self.scriptItemBarMap[nIdx]
    if scriptBar then
        UIHelper.SetSelected(scriptBar.ToggleSelect, true, false)
    end
    self:UpdateModelInfo()
end

function UIRewardView:UpdateRewardItemDetail(dwRewardForceID, dwItemTabType, dwItemTabIndex)
    if self.bCheckNpc then
        return
    end
    self.dwRewardForceID = dwRewardForceID
    self.dwItemTabType = dwItemTabType
    self.dwItemTabIndex = dwItemTabIndex
    self.scriptItemTips = self.scriptItemTips or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemDetail)
    self.scriptItemTips:HidePreviewBtn(true)
    self.scriptItemTips:OnInitWithTabID(dwItemTabType, dwItemTabIndex)
    self.scriptItemTips:SetForbidAutoShortTip(true)
    -- local tbBtnState = {
    --     {
    --         szName = "查看势力",
    --         OnClick = function ()
    --             if not self.scriptRenownView then
    --                 self.scriptRenownView = UIMgr.Open(VIEW_ID.PanelRenownList)
    --             end
    --             self.scriptRenownView:RedirectForceView(self.dwRewardForceID)
    --             self:CloseRewordListView()
    --         end
    --     }
    -- }
    -- self.scriptItemTips:SetBtnState(tbBtnState)
    self.scriptItemTips:SetBtnState({})
    self.scriptItemTips:UpdateScrollViewHeight(371)
end

function UIRewardView:UpdateTypeFliter()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupNpcFliter)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupItemFliter)
    UIHelper.RemoveAllChildren(self.LayoutNpcFliter)
    UIHelper.RemoveAllChildren(self.LayoutItemFliter)

    self.scriptAllNpcFliter = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownRewardFliter, self.LayoutNpcFliter, "全部类型", function ()
        self.szFliterRoleType = nil
        self.nPageIndex = 1
        self:RefreshReweardInfo()
        -- self:HideTypeFliter()
        UIHelper.SetString(self.EditPaginate, self.nPageIndex)
    end)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNpcFliter, self.scriptAllNpcFliter.ToggleSelect)
    local aRoleTypes = RepuData.GetServantRoleTypes()
    for _, szRoleType in ipairs(aRoleTypes) do
        local szName = g_tStrings.tServantRoleType[szRoleType]
        local scriptNpc = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownRewardFliter, self.LayoutNpcFliter, szName, function ()
            self.szFliterRoleType = szRoleType
            self.nPageIndex = 1
            self:RefreshReweardInfo()
            -- self:HideTypeFliter()
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNpcFliter, scriptNpc.ToggleSelect)
    end

    self.scriptAllItemFliter = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownRewardFliter, self.LayoutItemFliter, "全部类型", function ()
        self.tFliterItemUIType = nil
        self.nPageIndex = 1
        self:RefreshReweardInfo()
        -- self:HideTypeFliter()
        UIHelper.SetString(self.EditPaginate, self.nPageIndex)
    end)
    --UIHelper.SetVisible(self.scriptAllItemFliter._rootNode, false)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupItemFliter, self.scriptAllItemFliter.ToggleSelect)
    local aItemTypes = RepuData.GetItemTypes()
    for _, tItemUIType in ipairs(aItemTypes) do
        local szName = RepuData.GetItemTypeName(tItemUIType)
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownRewardFliter, self.LayoutItemFliter, szName, function ()
            self.tFliterItemUIType = tItemUIType
            self.nPageIndex = 1
            self:RefreshReweardInfo()
            -- self:HideTypeFliter()
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupItemFliter, scriptItem.ToggleSelect)
    end

    UIHelper.LayoutDoLayout(self.LayoutNpcFliter)
    UIHelper.LayoutDoLayout(self.LayoutItemFliter)
    UIHelper.ScrollViewDoLayout(self.SrcollViewNpcFliter)
    UIHelper.ScrollToTop(self.SrcollViewNpcFliter, 0)
    UIHelper.ScrollViewDoLayout(self.SrcollViewItemFliter)
    UIHelper.ScrollToTop(self.SrcollViewItemFliter, 0)
end

function UIRewardView:UpdateEditPaginateInfo()
    local nMaxPageCount = 0
    if self.bCheckNpc then
        nMaxPageCount = math.ceil(#self.tCurNpcInfoList / nPerPageMaxNpcCell)
    else
        nMaxPageCount = math.ceil(#self.tCurItemInfoList / nPerPageMaxItemCell)
    end
    self.nPageCount = nMaxPageCount
    UIHelper.SetString(self.LabelPaginate, "/"..self.nPageCount)
end

function UIRewardView:HideTypeFliter()
    self.bFliterOpen = false
    UIHelper.SetVisible(self.WidgetNpcFliter, self.bFliterOpen and self.bCheckNpc)
    UIHelper.SetVisible(self.WidgetItemFliter, self.bFliterOpen and not self.bCheckNpc)
    UIHelper.SetSelected(self.TogScreen, false)
end

function UIRewardView:RefreshShowMode()
    UIHelper.SetVisible(self.BtnRenown, true)
    UIHelper.SetVisible(self.BtnCallFriend, self.bCheckNpc and self.bReceived)
    UIHelper.SetVisible(self.ScrollViewNpc, self.bCheckNpc)
    UIHelper.SetVisible(self.LayoutContentItem, not self.bCheckNpc)
    UIHelper.SetVisible(self.WidgetNpcDetail, self.bCheckNpc)
    UIHelper.SetVisible(self.WidgetItemDetail, not self.bCheckNpc)
    UIHelper.SetVisible(self.LabelUnlockNpcProgress, self.bCheckNpc)
    UIHelper.SetVisible(self.LabelUnlockItemProgress, not self.bCheckNpc)
    UIHelper.SetVisible(self.WidgetNpcFliter, self.bFliterOpen and self.bCheckNpc)
    UIHelper.SetVisible(self.WidgetItemFliter, self.bFliterOpen and not self.bCheckNpc)
    if self.bCheckNpc then
        self:UpdateRewardNpcDetail(self.dwRewardForceID)
    elseif self.scriptItem then
        self:UpdateRewardItemDetail(self.dwRewardForceID, self.scriptItem.dwItemTabType, self.scriptItem.dwItemTabIndex)
    end
end

function UIRewardView:OnCallNpc()
    local bCall, bSuccess, dwNpcIndex = Servant_CallOrDismissServant(self.dwRewardForceID, true)
    if bCall and bSuccess then
        local szMessage = FormatString(g_tStrings.STR_REPUTATION_CALL_SERVANT_SUCCESS_TIP, UIHelper.GBKToUTF8(Table_GetServantInfo(dwNpcIndex).szNpcName))
        UIMgr.Close(VIEW_ID.PanelRenownList)
        self:CloseRewordListView()
        TipsHelper.ShowNormalTip(szMessage)
    end
    self:UpdateRewardNpcDetail(self.dwRewardForceID)
end

function UIRewardView:RefreshReweardInfo()
    if self.bCheckNpc then
        self.dwRewardForceID = nil
        self.tCurNpcInfoList = {}
        for nIndex, tNpcInfo in ipairs(self.tAllNpcInfoList) do
            local bVisible = self.szFliterRoleType == nil or tNpcInfo.szRoleType == self.szFliterRoleType
            if bVisible and self.szRewardKeyWord and self.szRewardKeyWord ~= "" then
                local nStart,_,_ = string.find(tNpcInfo.szNpcName, self.szRewardKeyWord)
                bVisible = bVisible and nStart ~= nil
            end
            if bVisible then
                table.insert(self.tCurNpcInfoList, tNpcInfo)
            end
        end
        local bIsEmpty = #self.tCurNpcInfoList == 0
        if not bIsEmpty then self.dwRewardForceID = self.tCurNpcInfoList[1].dwForceID end

        self:UpdateNpcInfoPage()

        UIHelper.SetVisible(self.MiniScene, not bIsEmpty)
        UIHelper.SetVisible(self.WidgetAniRight, not bIsEmpty)
        UIHelper.SetVisible(self.WidgetPaginate, not bIsEmpty)
        UIHelper.SetVisible(self.WidgetItemEmpty, bIsEmpty)
        UIHelper.SetVisible(self.WidgetModelEmpty, false)
    else
        self.dwItemTabType = nil
        self.tCurItemInfoList = {}
        for _, tItemInfo in ipairs(self.tAllItemInfoList) do
            local bVisible = self.tFliterItemUIType == nil or RepuData.IsItemOfItemType(tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex, self.tFliterItemUIType)
            if bVisible and self.szRewardKeyWord and self.szRewardKeyWord ~= "" then
                local nStart,_,_ = string.find(tItemInfo.szRewardItemName, self.szRewardKeyWord)
                bVisible = bVisible and nStart ~= nil
            end
            if bVisible then
                table.insert(self.tCurItemInfoList, tItemInfo)
            end
        end
        local bIsEmpty = #self.tCurItemInfoList == 0
        if not bIsEmpty then self.nSelectedItemInfoIdx = 1 end
        self:UpdateItemInfoPage()

        UIHelper.SetVisible(self.MiniScene, not bIsEmpty)
        UIHelper.SetVisible(self.WidgetAniRight, not bIsEmpty)
        UIHelper.SetVisible(self.WidgetPaginate, not bIsEmpty)
        UIHelper.SetVisible(self.WidgetItemEmpty, bIsEmpty)
        UIHelper.SetVisible(self.WidgetModelEmpty, false)
    end
    self:UpdateEditPaginateInfo()
end

function UIRewardView:InitCamera(camera, tbCameraInfo)
    if not camera then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(self.MiniScene)
    camera:ctor()
    camera:init(self.hModelView.m_scene, tbCameraInfo[1], tbCameraInfo[2], tbCameraInfo[3] , tbCameraInfo[4], tbCameraInfo[5], tbCameraInfo[6], math.pi / 4, nWidth / nHeight, nil, nil, true)
end

function UIRewardView:LoadSetting(tSetting)
    local szSettingFile = "/ui/Scheme/Setting/CoinShopFurnitureSetting.ini"
    local pFile = Ini.Open(szSettingFile)
    if not pFile then
        return
    end
    local szSection = "FurnitureModelSetting"
    tSetting = {}
    tSetting.CriterionX = pFile:ReadInteger(szSection, "CriterionX" , 0)
    tSetting.CriterionY = pFile:ReadInteger(szSection, "CriterionY" , 0)
    tSetting.CriterionZ = pFile:ReadInteger(szSection, "CriterionZ" , 0)
    tSetting.MaxScale = pFile:ReadFloat(szSection, "MaxScale" , 0)
    tSetting.MinScale = pFile:ReadFloat(szSection, "MinScale" , 0)
    tSetting.PlatformMesh = pFile:ReadString(szSection, "PlatformMesh" , "")
    tSetting.PlatformX = pFile:ReadFloat(szSection, "PlatformX" , 0)
    tSetting.PlatformY = pFile:ReadFloat(szSection, "PlatformY" , 0)
    tSetting.PlatformZ = pFile:ReadFloat(szSection, "PlatformZ" , 0)
    tSetting.PlatformYaw = pFile:ReadFloat(szSection, "PlatformYaw" , 0)
    pFile:Close()
    Homeland_SendMessage(HOMELAND_FURNITURE.ENTER, self.hModelView.m_scene, tSetting.PlatformMesh, tSetting.PlatformX, tSetting.PlatformY, tSetting.PlatformZ, tSetting.PlatformYaw)
end

function UIRewardView:CloseRewordListView()
    Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)

    Timer.AddFrame(self, 1, function ()
        UIMgr.Close(VIEW_ID.PanelRenownRewordList)
    end)
end

function UIRewardView:UpdateDownloadEquipRes()
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

return UIRewardView