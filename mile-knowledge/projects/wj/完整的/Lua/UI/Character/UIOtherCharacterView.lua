-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOtherCharacterView
-- Date: 2023-03-07 11:31:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOtherCharacterView = class("UIOtherCharacterView")

local PageType = {
    Equip       = 1,
    Exterior    = 2,
    Ride        = 3,
    Home        = 4,
}

local PageInfo = {
    [PageType.Equip] = {
        nPrefabID = PREFAB_ID.WidgetOtherPlayerEquip,
    },
    [PageType.Exterior] = {
        nPrefabID = PREFAB_ID.WidgetOtherPlayerAppearance,
    },
    [PageType.Ride] = {
        nPrefabID = PREFAB_ID.WidgetOtherPlayerRide,
    },
    [PageType.Home] = {
        nPrefabID = PREFAB_ID.WidgetOtherPlayerHome,
    },
}

local tbNeedHideBaseInfo = {
    [PageType.Equip] = true,
    [PageType.Exterior] = true,
    [PageType.Home] = true,
}

function UIOtherCharacterView:OnEnter(nPlayerID, nCenterID, szGlobalRoleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if nCenterID and nCenterID > 0 and szGlobalRoleID  then
        PeekOtherPlayerByGlobalID(nCenterID, szGlobalRoleID)
    else
        PeekOtherPlayer(nPlayerID)
    end

    local nSelfPlayerID = PlayerData.GetPlayerID()
    if not IsRemotePlayer(nSelfPlayerID) and not IsRemotePlayer(nPlayerID) then
        RemoteCallToServer("OnInscriptionRequest", nPlayerID)
    end

    self.nPlayerID = nPlayerID
    self.nCenterID = nCenterID
    self.szGlobalRoleID = szGlobalRoleID
    self.nCurPage = PageType.Equip

    self:OpenWait()
end

function UIOtherCharacterView:OnExit()
    self.bInit = false

    if self.hModelView then
		self.hModelView:release()
		self.hModelView = nil
	end

    UITouchHelper.UnBindModel()

    if UIMgr.GetView(VIEW_ID.PanelFriendRecommendPop) then
        UIMgr.ShowView(VIEW_ID.PanelFriendRecommendPop)
    end

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end

    SelfieData.ResetFilterFromStorage()
end

function UIOtherCharacterView:BindUIEvent()
    for index, tog in ipairs(self.tbTogPage) do
        UIHelper.ToggleGroupAddToggle(self.TogGroupPage, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            local nLastPage = self.nCurPage
            self.nCurPage = index
            self:UpdatePageInfo()
            if self.nCurPage ~= nLastPage and (nLastPage == PageType.Ride or self.nCurPage == PageType.Ride) then
                self:UpdateModelInfo()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIOtherCharacterView:RegEvent()
    Event.Reg(self, "PEEK_OTHER_PLAYER", function (nResult, dwID)
        if nResult == PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
            if self.nCenterID and self.nCenterID > 0 and self.szGlobalRoleID then
                self.nPlayerID = dwID
                PeekOtherPlayerExteriorByGlobalID(self.nCenterID, self.szGlobalRoleID)
            elseif self.nPlayerID then
                PeekOtherPlayerExterior(self.nPlayerID)
            end
        end
    end)

    Event.Reg(self, "PEEK_PLAYER_EXTERIOR", function ()
        self:UpdateInfo()
        self:CloseWait()
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateModelInfo()
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local scene = self.hModelView.m_scene
            if scene and not QualityMgr.bDisableCameraLight then
                scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end
        end
    end)

    Event.Reg(self, "ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE", function()
        UIHelper.TempHidePlayerMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelOutfitPreview)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelExteriorMain then
            UIHelper.TempHidePlayerMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelExteriorMain)
        end
    end)
end

function UIOtherCharacterView:SetTogCanSelecte(bCanSelect)
    for index, tog in ipairs(self.tbTogPage) do
        UIHelper.SetCanSelect(tog, bCanSelect)
    end
end

function UIOtherCharacterView:InitMiniScene()
    if not self.hModelView then
        self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
        self.hModelView:ctor()
        self.hModelView:InitBy({
            szName = "OtherCharacter",
            bExScene = true,
            szExSceneFile = "data\\source\\maps\\MB商城_2023_001\\MB商城_2023_001.jsonmap",
            bAPEX = false,
            nModelType = UI_MODEL_TYPE.PANEL_VIEW
        })
        self.MiniScene:SetScene(self.hModelView.m_scene)

        self.hRideModelView = RidesModelView.CreateInstance(RidesModelView)
        self.hRideModelView:ctor()
        self.hRideModelView:init(self.hModelView.m_scene, nil)
        RidesModelPreview.RegisterHorse(self.MiniScene, self.hRideModelView, "SaddleHorse_view", "SaddleHorse")
    end
end

function UIOtherCharacterView:UpdateInfo()
    self:UpdateBaseInfo()
    self:UpdatePageInfo()
    self:UpdateModelInfo()
end

function UIOtherCharacterView:UpdateBaseInfo()
    local targetPlayer = self:GetPlayer()
    if not targetPlayer or targetPlayer.IsInMorph() then
        TipsHelper.ShowNormalTip("获取侠士数据失败，暂无法查看")
        Timer.AddFrame(self, 2, function ()
            UIMgr.Close(self)
        end)
        return
    end

    UIHelper.SetString(self.LabelName, GBKToUTF8(targetPlayer.szName))
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg[targetPlayer.dwForceID])
    UIHelper.SetString(self.LabelLevel, targetPlayer.nLevel .. "级")
    UIHelper.SetString(self.LabelCamp, g_tStrings.STR_GUILD_CAMP_NAME[targetPlayer.nCamp])
end

function UIOtherCharacterView:UpdatePageInfo()
    local tbPageInfo = PageInfo[self.nCurPage]
    UIHelper.RemoveAllChildren(self.WidgetRight)
    self.scriptPage = UIHelper.AddPrefab(tbPageInfo.nPrefabID, self.WidgetRight)
    self.scriptPage:OnEnter(self.nPlayerID, self.nCenterID, self.szGlobalRoleID)
    UIHelper.SetVisible(self.WidgetAnchorBasic, not tbNeedHideBaseInfo[self.nCurPage])
end

function UIOtherCharacterView:UpdateModelInfo()
    self:InitMiniScene()

    UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
	self.hModelView:UnloadModel()
	self.hRideModelView:UnloadRidesModel()

    local targetPlayer = self:GetPlayer()
    if not targetPlayer then
        return
    end

    if self.nCurPage == PageType.Ride then
        local item = targetPlayer.GetEquippedHorse()
        if not item then
            return
        end

        self.hRideModelView:LoadRidesRes(self.nPlayerID, false)
        self.hRideModelView:LoadRidesModel()
        self.hRideModelView:PlayRidesAnimation("Idle", "loop")
        self.hRideModelView:SetTranslation(table.unpack(Const.MiniScene.OtherCharacterView.tbRidePos))
        self.hRideModelView:SetMainFlag(true)
        self.hRideModelView.m_scene:SetMainPlayerPosition(unpack(Const.MiniScene.OtherCharacterView.tbRidePos))

        local fScale = Const.MiniScene.RideScale
        self.hRideModelView:SetScaling(fScale, fScale, fScale)
        self.hRideModelView:SetYaw(Const.MiniScene.OtherCharacterView.fRideYaw)
        self.hRideModelView:SetCamera(Const.MiniScene.OtherCharacterView.tbRideCamare)

        UITouchHelper.BindModel(self.TouchContainer, self.hRideModelView)
    else
        local dwIdleActionID = targetPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL)
        local bClearWeapon = dwIdleActionID > 0
        self.hModelView:LoadPlayerRes(self.nPlayerID, false, nil, bClearWeapon)
        self.hModelView:LoadModel()
        self.hModelView:SetWeaponSocketDynamic()
        self:UpdatePlayerAction()
        -- self.hModelView:PlayAnimation("Idle", "loop")
        self.hModelView:SetTranslation(table.unpack(Const.MiniScene.OtherCharacterView.tbPos))
        self.hModelView:SetYaw(Const.MiniScene.OtherCharacterView.fYaw)
        self.hModelView:SetCamera(Const.MiniScene.OtherCharacterView.tbCamare)
        self.hModelView.m_scene:SetMainPlayerPosition(unpack(Const.MiniScene.OtherCharacterView.tbPos))
        self.hModelView:UpdatePuppet(targetPlayer.dwPuppetSkinID)
        -- self:ApplyModelEffectPreview()

        UITouchHelper.BindModel(self.TouchContainer, self.hModelView)
        self:UpdateDownloadEquipRes()
    end
end

function UIOtherCharacterView:TouchModel(bTouch, x, y)
    self.hModelView:TouchModel(bTouch, x, y)
end

function UIOtherCharacterView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    local targetPlayer = self:GetPlayer()
    if not targetPlayer then
        return
    end
    local tRepresentID = Role_GetRepresentID(targetPlayer)
    local nRoleType = targetPlayer.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function UIOtherCharacterView:GetPlayer()
    if self.szGlobalRoleID then
        local player = GetPlayerByGlobalID(self.szGlobalRoleID)
        return player
    end

    if self.nPlayerID then
        local player = GetPlayer(self.nPlayerID)
        return player
    end
end

function UIOtherCharacterView:UpdatePlayerAction()
    if self.nCurPage == PageType.Ride then
        return
    end

    local targetPlayer = self:GetPlayer()
    if not targetPlayer then
        return
    end

    local dwIdleActionID = targetPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL)
    local dwRepresentID = CharacterIdleActionData.GetActionRepresentID(dwIdleActionID)

    if dwIdleActionID and dwIdleActionID > 0 then
        local szDefaultAni = CharacterIdleActionData.GetDefaultAni(PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL)
        self.hModelView:PlayAnimationByLogicID(dwRepresentID, szDefaultAni)
    else
        self.hModelView:PlayAnimation("Idle", "loop")
    end
end

function UIOtherCharacterView:OpenWait()
    self:SetTogCanSelecte(false)

    Timer.DelTimer(self, self.nHideBgTimerID)
    UIHelper.SetVisible(self.WidgetAniBg, true)

    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetString(self.LabelTimeout, "侠士数据请求中...")
    Timer.DelTimer(self, self.nPeekTime)
    self.nPeekTime = Timer.Add(self, 5, function()
        UIHelper.SetString(self.LabelTimeout, "侠士处于跨服或离线中时，暂无法查看其数据")
        UIHelper.SetVisible(self.WidgetAnchorBottom, false)
    end)
end

function UIOtherCharacterView:CloseWait()
    self:SetTogCanSelecte(true)

    Timer.DelTimer(self, self.nHideBgTimerID)
    self.nHideBgTimerID = Timer.Add(self, 1.5, function()
        UIHelper.SetVisible(self.WidgetEmpty, false)
        --UIHelper.SetVisible(self.WidgetAniBg, false)
    end)

    UIHelper.SetString(self.LabelTimeout, "侠士数据加载中，请稍后...")
    --UIHelper.SetVisible(self.LabelTimeout, false)
    Timer.DelTimer(self, self.nPeekTime)
end

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0, nOffsetY = 0, nOffsetZ = 0,
    fRotationX = 0, fRotationY = 0, fRotationZ = 0,
}

function UIOtherCharacterView:GetPreviewEffectData()
    local targetPlayer = self:GetPlayer()
    if not targetPlayer then
        return nil
    end

    local tEffect = {}
    local EFFECT_TYPE = CharacterEffectData.CoinShop_GetEffectTypeTable()
    for nType, _ in pairs(EFFECT_TYPE) do
        local nEffectID = targetPlayer.GetEquipSFXID(nType)
        if nEffectID and nEffectID > 0 then
            tEffect[nType] = {
                nEffectID = nEffectID,
                nState = 1,
                tCustomPos = DEFAULT_CUSTOM_DATA,
            }
        end
    end
    return tEffect
end

function UIOtherCharacterView:ApplyModelEffectPreview()
    if not self.hModelView or not self.hModelView.m_modelRole then
        return
    end

    local tEffect = self:GetPreviewEffectData()
    if not tEffect then
        return
    end

    self.hModelView.m_aRepresentID = self.hModelView.m_aRepresentID or {}
    self.hModelView.m_aRepresentID.tEffect = tEffect
    self.hModelView:SetEffectSfx()
end

return UIOtherCharacterView