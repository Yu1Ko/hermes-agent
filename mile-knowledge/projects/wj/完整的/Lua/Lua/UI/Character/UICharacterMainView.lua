-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterMainView
-- Date: 2022-11-03 11:20:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local Equip1Enum = {
    -- 头部
    EQUIPMENT_INVENTORY.HELM,
    -- 上衣
    EQUIPMENT_INVENTORY.CHEST,
    -- 腰带
    EQUIPMENT_INVENTORY.WAIST,
    -- 下装
    EQUIPMENT_INVENTORY.PANTS,
    -- 鞋子
    EQUIPMENT_INVENTORY.BOOTS,
}

local Equip2Enum = {
    -- 护腕
    EQUIPMENT_INVENTORY.BANGLE,
    -- 项链
    EQUIPMENT_INVENTORY.AMULET,
    -- 腰坠
    EQUIPMENT_INVENTORY.PENDANT,
    -- 戒指
    EQUIPMENT_INVENTORY.LEFT_RING,
    -- 戒指
    EQUIPMENT_INVENTORY.RIGHT_RING,
}

local WeaponEnum = {
    -- 普通近战武器
    EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 重剑
    EQUIPMENT_INVENTORY.BIG_SWORD,
    -- 远程武器
    EQUIPMENT_INVENTORY.RANGE_WEAPON,
    -- 暗器
    EQUIPMENT_INVENTORY.ARROW,
}

local OptionEnum = {
    ["HideOthers"] = 1,
    ["HideNPC"] = 2,
    ["HideAppearance"] = 3,
    ["HideHat"] = 4,
    ["HideFaceDeco"] = 5,
    ["HideFaceHanging"] = 6,
    ["HideHood"] = 7,
    ["HideCloak"] = 8,
    ["HideWeapon"] = 9,
}

local tbPlayHideAnimOnViewOpen = {
    [VIEW_ID.PanelSideCharacterHome] = true,
}

local UICharacterMainView = class("UICharacterMainView")

function UICharacterMainView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        local nPlayerID = PlayerData.GetPlayerID()
        if not IsRemotePlayer(nPlayerID) then
            RemoteCallToServer("OnInscriptionRequest", nPlayerID)
        end
    end

    RemoteCallToServer("OnSyncEquipIDArray")
    InputHelper.LockCamera(false)
    -- UIHelper.SetVisible(self.BtnPersonalCard, false)
    self:InitEquipPageInfo()
    self:InitTogOptions()
    self:UpdateDownloadEquipRes()
    self:UpdateInfo()
    self:UpdateHead()
    self:UpdateLock()
    self:UpdateTangMenBullet()

    CameraMgr.EnterUIMode(true)
    -- C界面挪摄像机的焦点
    -- -0.19：水平方向向左挪（负为左，正为右）
    -- 0（上、下偏移）
    rlcmd("enable camera focus diverge 1 -0.19 0")
    CharacterIdleActionData.PlayBindIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL)
    Event.Dispatch(EventType.OnSetSystemMenuCloseBtnEnabled, false)
end

function UICharacterMainView:OnExit()
    self.bInit = false

    Event.Dispatch(EventType.OnSetSystemMenuCloseBtnEnabled, true)

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end

    rlcmd("enable camera focus diverge 0")
    rlcmd("set local offline idle action id -1")
    CameraMgr.ExitUIMode(160)
end

function UICharacterMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseOptions, EventType.OnClick, function(btn)
        UIHelper.SetSelected(self.TogOptions, false)
    end)

    UIHelper.BindUIEvent(self.BtnEditName, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelChangeNamePop)
    end)

    UIHelper.BindUIEvent(self.BtnChenghao, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelPersonalTitle)
    end)

    UIHelper.BindUIEvent(self.BtnSkill, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetXinFaTips, self.WidgetTipNode, TipsLayoutDir.BOTTOM_CENTER)
    end)

    UIHelper.BindUIEvent(self.BtnQili, EventType.OnClick, function(btn)
        local _, nSprintPower, nSprintPowerMax = PlayerData.GetPlayerSprintPower()
        nSprintPower = (nSprintPower or 0) / 100
        nSprintPowerMax = (nSprintPowerMax or 0) / 100
        local szDesc = string.format(g_tStrings.STR_SPRINTPOWER_TIPS, nSprintPower, nSprintPowerMax)
        local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetTipNode, TipsLayoutDir.BOTTOM_CENTER, szDesc)
    end)

    UIHelper.BindUIEvent(self.BtnCamp, EventType.OnClick, function(btn)
        UIMgr.Open(CampData_OnClickEntrance())
    end)

    UIHelper.BindUIEvent(self.BtnWuDou, EventType.OnClick, function(btn)
        if not SystemOpen.IsSystemOpen(SystemOpenDef.ReleaseRewardPop, true) then
            return
        end

        if CrossMgr.IsCrossing(nil, true) then
            return
        end

        local scriptView = UIMgr.GetView(VIEW_ID.PanelCharacter)
        UIHelper.SetVisible(scriptView.node, false)
        Timer.AddFrame(self, 5, function ()
            UIMgr.Open(VIEW_ID.PanelWuDou)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnPowerUp, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelPowerUp)
    end)

    UIHelper.BindUIEvent(self.BtnMoZhu, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelShenBingUpgrade, true)
    end)

    UIHelper.BindUIEvent(self.BtnOutfit, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelAccessory)
    end)

    UIHelper.BindUIEvent(self.BtnEquipRank, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelCharacterScorePop)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelCharacterDetail)
    end)

    UIHelper.BindUIEvent(self.BtnMoneyStats, EventType.OnClick, function(btn)
		UIMgr.Open(VIEW_ID.PanelCharacterMoneyPop)
    end)

    UIHelper.BindUIEvent(self.BtnBindOptions, EventType.OnClick, function(btn)
        if not g_pClientPlayer then return end

        local nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMount().dwSkillID
        UIMgr.Open(VIEW_ID.PanelSkillEquipSettingPop, nCurrentKungFuID)

        -- UIMgr.Open(VIEW_ID.PanelSkillNew)
    end)

    UIHelper.BindUIEvent(self.BtnHome, EventType.OnClick, function(btn)
        local pPlayer = GetClientPlayer()
        local nLevel = PlayerData.GetPlayerLevel(pPlayer)
        local nRequireLevel = UISystemOpenTab[15].nOpenLevel
        if CheckPlayerIsRemote() then
            return
        elseif nLevel < nRequireLevel then
            TipsHelper.ShowNormalTip(UISystemOpenTab[15].szDesc)
            return
        end
		UIMgr.Open(VIEW_ID.PanelSideCharacterHome)
    end)

    UIHelper.BindUIEvent(self.ToggleHideNpc, EventType.OnClick, function(btn)
        if UIHelper.GetSelected(self.ToggleHideNpc) then
            CameraMgr.HideNpc(true)
        else
            CameraMgr.HideNpc(false)
        end
    end)

    UIHelper.BindUIEvent(self.ToggleHidePlayer, EventType.OnClick, function(btn)
		if UIHelper.GetSelected(self.ToggleHidePlayer) then
            CameraMgr.HidePlayer(true)
        else
            CameraMgr.HidePlayer(false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHorse, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelSaddleHorse)
    end)

    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function(btn)
        ShopData.OpenSystemShopGroup(1)
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelEquipStore)
        if scriptView then
            UIHelper.SetVisible(self._rootNode, false)
            scriptView:SetExitCallBack(function ()
                UIHelper.SetVisible(self._rootNode, true)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRepair, EventType.OnClick, function(btn)
        self:DoRepair()
    end)

    for nIndex, tog in ipairs(self.tbTogOptions) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            if nIndex == OptionEnum.HideOthers then
                if UIHelper.GetSelected(tog) then
                    CameraMgr.HidePlayer(true)
                else
                    CameraMgr.HidePlayer(false)
                end
            elseif nIndex == OptionEnum.HideNPC then
                if UIHelper.GetSelected(tog) then
                    CameraMgr.HideNpc(true)
                else
                    CameraMgr.HideNpc(false)
                end
            elseif nIndex == OptionEnum.HideAppearance then
                if not UIHelper.GetSelected(tog) then
                    RemoteCallToServer("OnUnApplyExterior")
                    TipsHelper.ShowNormalTip("已隐藏外观显示")

                    self:SetCaStateVisible(false)
                else
                    RemoteCallToServer("OnApplyExterior")
                    TipsHelper.ShowNormalTip("已开启外观显示")

                    self:SetCaStateVisible(true)
                end
                self:SetCaStateSelect(false)
                self:UpdateMingJiaoAvatar()
            elseif nIndex == OptionEnum.HideHat then
                local bSelected = UIHelper.GetSelected(tog)
                local player = PlayerData.GetClientPlayer()
                if player then
                    PlayerData.HideHat(not bSelected)
                    FireUIEvent("PLAYER_HIDE_HAT_CHANGE")
                    if bSelected then
                        TipsHelper.ShowNormalTip("已开启帽子显示")
                    else
                        TipsHelper.ShowNormalTip("已隐藏帽子显示")
                    end
                end
            elseif nIndex == OptionEnum.HideFaceDeco then
                local bSelected = UIHelper.GetSelected(tog)
                GetFaceLiftManager().SetDecorationShowFlag(bSelected)
                if bSelected then
                    TipsHelper.ShowNormalTip("已开启面饰显示")
                else
                    TipsHelper.ShowNormalTip("已隐藏面饰显示")
                end
            elseif nIndex == OptionEnum.HideFaceHanging then
                local bSelected = UIHelper.GetSelected(tog)
                local player = PlayerData.GetClientPlayer()
                if player then
                    player.SetFacePendentHideFlag(not bSelected)
                end
                if bSelected then
                    TipsHelper.ShowNormalTip("已开启面挂显示")
                else
                    TipsHelper.ShowNormalTip("已隐藏面挂显示")
                end
            elseif nIndex == OptionEnum.HideCloak then
                local bSelected = UIHelper.GetSelected(tog)
                local player = PlayerData.GetClientPlayer()
                if player then
                    player.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, not bSelected)
                end
                if bSelected then
                    TipsHelper.ShowNormalTip("已开启披风显示")
                else
                    TipsHelper.ShowNormalTip("已隐藏披风显示")
                end
            elseif nIndex == OptionEnum.HideHood then
                local bSelected = UIHelper.GetSelected(tog)

                if g_pClientPlayer then
                    local bInHat = APIHelper.IsInSecondRepresent()
                    if bInHat then
                        DoAction(g_pClientPlayer.dwID, 11471)
                    else
                        DoAction(g_pClientPlayer.dwID, 11470)
                    end

                    RemoteCallToServer("OnSwitchRepresent", INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
                    self:UpdateMingJiaoAvatar()
                end
            elseif nIndex == OptionEnum.HideWeapon then
                local bSelected = UIHelper.GetSelected(tog)
                local player = PlayerData.GetClientPlayer()
                if player then
                    player.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.IDLE_WEAPON, not bSelected)
                end
                if bSelected then
                    TipsHelper.ShowNormalTip("已开启武器显示")
                else
                    TipsHelper.ShowNormalTip("已隐藏武器显示")
                end
            end

            self:DisableTogCanSelect()
        end)
    end

    for nIndex, tog in ipairs(self.tbTogEquipPreset) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            EquipData.SwitchEquip(nIndex)
            self.nCurEquipPageIndex = nIndex
            UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, self.nCurEquipPageIndex - 1)
        end)
    end

    UIHelper.BindUIEvent(self.BtnPersonalCard, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPersonalCard, function ()
            UIMgr.Close(self)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnChangeHead, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelCustomAvatar)
    end)

    UIHelper.BindUIEvent(self.BtnChangeMingtie, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelNameCard)
    end)

    UIHelper.BindUIEvent(self.BtnRecEquip, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.Bag, true, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnQianJiXia, EventType.OnClick, function()
        if self.QianJiScript and UIHelper.GetVisible(self.QianJiScript._rootNode) then
            self.QianJiScript:Close()
        else
            local nX = UIHelper.GetWorldPositionX(self.BtnQianJiXia)
            local nY = UIHelper.GetWorldPositionY(self.BtnQianJiXia)

            self.QianJiScript = self.QianJiScript or UIHelper.AddPrefab(PREFAB_ID.WidgetQianJiXiaTip, self._rootNode)
            local tips = HoverTips.New(self.QianJiScript._rootNode)
            tips:SetDisplayLayoutDir(TipsLayoutDir.TOP_LEFT)
            tips:Show(nX, nY)
            UIHelper.SetVisible(self.QianJiScript._rootNode, true)
        end
    end)

    UIHelper.BindUIEvent(self.TogSwitchOptions, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.scriptSwitchOptions:OnEnter()
        end
    end)
    UIHelper.SetTouchDownHideTips(self.TogSwitchOptions, false)
    local szDesc = SystemOpen.GetSystemOpenDesc(SystemOpenDef.SwitchEquip)
    UIHelper.SetVisible(self.WidgetLockSwitchOptions, not SystemOpen.IsSystemOpen(SystemOpenDef.SwitchEquip, false))
    UIHelper.SetCanSelect(self.TogSwitchOptions, SystemOpen.IsSystemOpen(SystemOpenDef.SwitchEquip, false), szDesc, true)
    self.scriptSwitchOptions = UIHelper.GetBindScript(self.WidgetSwitchOptionsTip)
end

function UICharacterMainView:RegEvent()
    Event.Reg(self, "ON_SYNC_DISPLAY_IDLE_ACTION_NOTIFY", function(nDisplayType, dwIdleActionID)
        if nDisplayType == PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL then
            CharacterIdleActionData.PlayBindIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL)
        end
    end)

    Event.Reg(self, "SYNC_EQUIPID_ARRAY", function()
        self:InitEquipPageInfo()
    end)

    Event.Reg(self, "FE_STRENGTH_EQUIP", function(arg0)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateEquipInfo()
            self:UpdatePlayerInfo()
            self:UpdatePlayerAttribInfo()
        end
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nInventoryIndex, nEquipmentInventory)
        if nInventoryIndex == INVENTORY_INDEX.EQUIP then
            if self.nEquipUpdateTimerID then
                Timer.DelTimer(self, self.nEquipUpdateTimerID)
                self.nEquipUpdateTimerID = nil
            end

            self.nEquipUpdateTimerID = Timer.Add(self, 0.5, function ()
                self:UpdateInfo()

                if self.scriptItemTip then
                    self.scriptItemTip:OnInit()
                end

                self.nEquipUpdateTimerID = nil
            end)
        end
    end)

    Event.Reg(self, "UNEQUIPALL", function(result)
        if result ~= ITEM_RESULT_CODE.SUCCESS then
            TipsHelper.ShowNormalTip(g_tStrings.tItem_Msg[result])
        else
            TipsHelper.ShowNormalTip("已成功卸载所选装备切页的所有装备")
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "EQUIP_CHANGE", function(result)
        if result == ITEM_RESULT_CODE.SPRINT then
            TipsHelper.ShowNormalTip("轻功中无法切换套装", false)
            self:InitEquipPageInfo()
            return
        end

        if result == ITEM_RESULT_CODE.CAMP_CAN_NOT_EQUIP then
            self:CheckCampEquip()
        elseif result == ITEM_RESULT_CODE.ERROR_EQUIP_PLACE
            or result == ITEM_RESULT_CODE.FORCE_ERROR
            or result == ITEM_RESULT_CODE.TOO_LOW_AGILITY
            or result == ITEM_RESULT_CODE.TOO_LOW_STRENGTH
            or result == ITEM_RESULT_CODE.TOO_LOW_SPIRIT
            or result == ITEM_RESULT_CODE.TOO_LOW_VITALITY
            or result == ITEM_RESULT_CODE.CANNOT_EQUIP
            or result == ITEM_RESULT_CODE.CANNOT_PUT_THAT_PLACE
            or result == ITEM_RESULT_CODE.GENDER_ERROR
            or result == ITEM_RESULT_CODE.FAILED then
            local nCurEquipPageIndex = self.nCurEquipPageIndex
            local szMsg = string.format(g_tStrings.STR_UNEQUIP_ALL, nCurEquipPageIndex, nCurEquipPageIndex)
            UIHelper.ShowConfirm(szMsg, function ()
                self:UnmountAllEquip(nCurEquipPageIndex)
            end, nil, true)
	    elseif result ~= ITEM_RESULT_CODE.SUCCESS then
            if result == ITEM_RESULT_CODE.DISARM then
                TipsHelper.ShowNormalTip("马上无法切换装备以及交换物品，请侠士下马后再次尝试")
            else
                TipsHelper.ShowNormalTip(g_tStrings.tItem_Msg[result])
            end
            self:InitEquipPageInfo()
            return
        end

        self:InitEquipPageInfo()
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if tbPlayHideAnimOnViewOpen[nViewID] then
            UIHelper.PlayAni(self, self.AniAll, "AniRightHide")
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if tbPlayHideAnimOnViewOpen[nViewID] then
            UIHelper.PlayAni(self, self.AniAll, "AniRightShow")
        end

        if nViewID == VIEW_ID.PanelAccessory then
            self:InitTogOptions()
        end

        if nViewID == VIEW_ID.PanelPowerUp then
            self:UpdateEquipInfo()
        end
    end)

    -- Event.Reg(self, EventType.OnShowPageBottomBar, function(callback)
    --     UIHelper.PlayAni(self, self.AniAll, "AniRightShow")
    -- end)

    -- Event.Reg(self, EventType.OnHidePageBottomBar, function(callback)
    --     UIHelper.PlayAni(self, self.AniAll, "AniRightHide")
    -- end)

    Event.Reg(self, EventType.OnChangeCharacterAttribShowConfig, function(szKey, bSelected)
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end

        local tbShowConfig = PlayerData.GetAttribShowConfig(player)
        if tbShowConfig[szKey] ~= bSelected then
            tbShowConfig[szKey] = bSelected
            PlayerData.SetAttribShowConfig(player, tbShowConfig)
            self:UpdatePlayerAttribInfo()
        end
    end)

    Event.Reg(self, EventType.OnShowCharacterChangeEquipList, function(nBox, nIndex)
        if nBox ~= INVENTORY_INDEX.EQUIP then return end

        UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.Bag, true, {nBox = nBox, nIndex = nIndex})
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function (nPlayerID)
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end

        if nPlayerID == player.dwID then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnSceneTouchBegan, function()
        self:UnSelected()
    end)
    Event.Reg(self, "SYNC_DESIGNATION_DATA", function(dwID)
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end

        if player.dwID == dwID then
            self:UpdateDesignation(dwID)
        end
    end)
    Event.Reg(self, "SET_CURRENT_DESIGNATION", function(dwID)
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end

        if player.dwID == dwID then
            self:UpdateDesignation(dwID)
        end
    end)
    Event.Reg(self, "REMOVE_DESIGNATION", function(dwID)
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end

        if player.dwID == dwID then
            self:UpdateDesignation(dwID)
        end
    end)
    Event.Reg(self, "SET_GENERATION_NOTIFY", function(dwID)
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end

        if player.dwID == dwID then
            self:UpdateDesignation(dwID)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:UnSelected()
    end)

    Event.Reg(self, EventType.OnViewPlayHideAnimBegin, function(nViewID)
        if nViewID ~= VIEW_ID.PanelCharacter then
            return
        end

        -- 关闭摄像机焦点偏移

    end)

    Event.Reg(self, "EQUIP_HORSE", function()
        self:UpdateHorseState()
    end)

    Event.Reg(self, "UNEQUIP_HORSE", function()
        self:UpdateHorseState()
    end)

    Event.Reg(self, "HORSE_ITEM_UPDATE", function()
        self:UpdateHorseState()
    end)

    Event.Reg(self, "PLAYER_DISPLAY_DATA_UPDATE", function()
        if arg0 == g_pClientPlayer.dwID then
            self:UpdateDownloadEquipRes()
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownloadEquipRes()
    end)

    Event.Reg(self, "ON_SYNC_EQUIP_BOX_INFO", function()
        self:UpdatePlayerInfo()
    end)

    Event.Reg(self, "ON_SYNC_EQUIP_BOX_COLOR_DIAMOND", function()
        self:UpdatePlayerInfo()
    end)

    Event.Reg(self, "ON_SYNC_WEAPON_2_COLOR_DIAMOND_BIND_INFO", function()
        self:UpdatePlayerInfo()
    end)

    Event.Reg(self, "SET_MINI_AVATAR", function()
        self:UpdateHead()
    end)

    Event.Reg(self, "BULLETBACKUP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        self:UpdateTangMenBullet()
    end)
end

function UICharacterMainView:InitTogOptions()
    local player = PlayerData.GetClientPlayer()
    if not player then return end

    local bIsApplyExterior = player.IsApplyExterior()

    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideOthers], true)
    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideNPC], true)
    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideAppearance], bIsApplyExterior)
    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideHat], not player.bHideHat)
    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideFaceDeco], GetFaceLiftManager().GetDecorationShowFlag())
    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideFaceHanging], not player.bHideFacePendent)
    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideCloak], not player.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL))
    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideWeapon], not player.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.IDLE_WEAPON))

    self:SetCaStateVisible()
    self:SetCaStateSelect()
end

function UICharacterMainView:InitEquipPageInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    self.nCurEquipPageIndex = player.GetEquipIDArray(INVENTORY_INDEX.EQUIP) + 1
    UIHelper.SetToggleGroupSelected(self.ToggleGroupPreset, self.nCurEquipPageIndex - 1)
end

function UICharacterMainView:UpdateInfo()
    self:UpdateEquipInfo()
    self:UpdatePlayerInfo()
    self:UpdatePlayerAttribInfo()
    self:UpdateScorePointInfo()

    self:UpdateHorseState()
    self:UpdateRepairState()
    self:UpdateHomelandState()
    self:UpdateArenaMasterState()
end

function UICharacterMainView:UpdateEquipInfo()
    self.tbEquipCell = {}
    self.tbWeaponCell = {}

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local dwMapID = player.GetMapID()
    local bIsMasterEquipMap = IsMasterEquipMap(dwMapID)

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupEquip)
    for i, nType in ipairs(Equip1Enum) do
        UIHelper.RemoveAllChildren(self.tbWidgetEquip1[i])
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetEquip1[i])
        self.tbEquipCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbEquipCell[nType]:UpdatePVPImg()
        self.tbEquipCell[nType]:SetLabelCountVisible(false)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbEquipCell[nType].ToggleSelect)
        self.tbEquipCell[nType]:SetClickCallback(function(nBox, nIndex)
           if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
            end
            self.scriptItemTip:HidePreviewBtn(true)
            if nBox and nIndex then
                self.nCurSelectedEquipType = nType
            end

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(nBox, nIndex)
            end

            if not ItemData.GetItemByPos(nBox, nIndex) then
                Event.Dispatch(EventType.OnShowCharacterChangeEquipList, nBox, nIndex)
            end

            local dwMapID = player.GetMapID()
            if IsMasterEquipMap(dwMapID) then
                self.scriptItemTip:SetBtnState({
                    {
                        OnClick = function ()
                            UIMgr.Close(self)
                            RemoteCallToServer("On_JJC_GoToEquip")
                        end,
                        szName = "配装"
                    }
                })
            end
        end)

        self.tbEquipCell[nType]:ShowLabelTip(false)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], tbEquipStrengthInfo.nEquipLevel >= tbEquipStrengthInfo.nEquipMaxLevel or tbEquipStrengthInfo.nBoxLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], false)
            end

            local bShowTip = (tbEquipStrengthInfo and tbEquipStrengthInfo.bBoxQualityNotEnough)
                                or EquipData.CheckIsEquipSlotQualityLower(item, nType)
                                or EquipData.CheckIsWeaponNotActiveSlot(player, item, nType)

            bShowTip = bShowTip and not bIsMasterEquipMap
            self.tbEquipCell[nType]:ShowLabelTip(bShowTip)
        else
            UIHelper.SetVisible(self.tbImgMaxFrameEquip1[i], false)
        end
	end

    for i, nType in ipairs(Equip2Enum) do
        UIHelper.RemoveAllChildren(self.tbWidgetEquip2[i])
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.tbWidgetEquip2[i])
        self.tbEquipCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbEquipCell[nType]:UpdatePVPImg()
        self.tbEquipCell[nType]:SetLabelCountVisible(false)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbEquipCell[nType].ToggleSelect)
        self.tbEquipCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
            end
            self.scriptItemTip:HidePreviewBtn(true)
            if nBox and nIndex then
                self.nCurSelectedEquipType = nType
            end

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(nBox, nIndex)
            end

            if not ItemData.GetItemByPos(nBox, nIndex) then
                Event.Dispatch(EventType.OnShowCharacterChangeEquipList, nBox, nIndex)
            end

            local dwMapID = player.GetMapID()
            if IsMasterEquipMap(dwMapID) then
                self.scriptItemTip:SetBtnState({
                    {
                        OnClick = function ()
                            UIMgr.Close(self)
                            RemoteCallToServer("On_JJC_GoToEquip")
                        end,
                        szName = "配装"
                    }
                })
            end
        end)

        self.tbEquipCell[nType]:ShowLabelTip(false)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], tbEquipStrengthInfo.nEquipLevel >= tbEquipStrengthInfo.nEquipMaxLevel or tbEquipStrengthInfo.nBoxLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], false)
            end

            local bShowTip = (tbEquipStrengthInfo and tbEquipStrengthInfo.bBoxQualityNotEnough)
                                or EquipData.CheckIsEquipSlotQualityLower(item, nType)
                                or EquipData.CheckIsWeaponNotActiveSlot(player, item, nType)

            bShowTip = bShowTip and not bIsMasterEquipMap
            self.tbEquipCell[nType]:ShowLabelTip(bShowTip)
        else
            UIHelper.SetVisible(self.tbImgMaxFrameEquip2[i], false)
        end
	end

    for i, nType in ipairs(WeaponEnum) do
        local nPrefabID = PREFAB_ID.WidgetItem_100
        if nType == EQUIPMENT_INVENTORY.ARROW then
            nPrefabID = PREFAB_ID.WidgetItem_80
        end
        UIHelper.RemoveAllChildren(self.tbWidgetWeapon[i])
        self.tbWeaponCell[nType] = UIHelper.AddPrefab(nPrefabID, self.tbWidgetWeapon[i])
        self.tbWeaponCell[nType]:SetLabelCountVisible(nType == EQUIPMENT_INVENTORY.ARROW)
        self.tbWeaponCell[nType]:OnInit(INVENTORY_INDEX.EQUIP, nType)
        self.tbWeaponCell[nType]:UpdatePVPImg()
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, self.tbWeaponCell[nType].ToggleSelect)
        self.tbWeaponCell[nType]:SetClickCallback(function(nBox, nIndex)
            if not self.scriptItemTip then
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemCard)
                self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
            end
            self.scriptItemTip:HidePreviewBtn(true)
            if nBox and nIndex then
                self.nCurSelectedEquipType = nType
            end

            if self.nCurSelectedEquipType == nType then
                self.scriptItemTip:OnInit(nBox, nIndex)
            end

            if not ItemData.GetItemByPos(nBox, nIndex) then
                Event.Dispatch(EventType.OnShowCharacterChangeEquipList, nBox, nIndex)
            end

            local dwMapID = player.GetMapID()
            if IsMasterEquipMap(dwMapID) then
                self.scriptItemTip:SetBtnState({
                    {
                        OnClick = function ()
                            UIMgr.Close(self)
                            RemoteCallToServer("On_JJC_GoToEquip")
                        end,
                        szName = "配装"
                    }
                })
            end
        end)

        self.tbWeaponCell[nType]:ShowLabelTip(false)

        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item then
            local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, nType)
            if tbEquipStrengthInfo and tbEquipStrengthInfo.nEquipMaxLevel > 0 then
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], tbEquipStrengthInfo.nEquipLevel >= tbEquipStrengthInfo.nEquipMaxLevel or tbEquipStrengthInfo.nBoxLevel >= tbEquipStrengthInfo.nEquipMaxLevel)
            else
                UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], false)
            end

            local bShowTip = (tbEquipStrengthInfo and tbEquipStrengthInfo.bBoxQualityNotEnough)
                                or EquipData.CheckIsEquipSlotQualityLower(item, nType)
                                or EquipData.CheckIsWeaponNotActiveSlot(player, item, nType)

            bShowTip = bShowTip and not bIsMasterEquipMap
            self.tbWeaponCell[nType]:ShowLabelTip(bShowTip)
        else
            UIHelper.SetVisible(self.tbImgMaxFrameWeapon[i], false)
        end
	end

    local equip = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
    local bCanUseBigSword = player.bCanUseBigSword
    if equip then
        bCanUseBigSword = true
    end
    UIHelper.SetVisible(self.WidgetWeaponSecondary, bCanUseBigSword)

    UIHelper.LayoutDoLayout(self.LayoutWeapon)
end

function UICharacterMainView:UpdatePlayerInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    UIHelper.SetString(self.LabelName, GBKToUTF8(string.format("%s", PlayerData.GetPlayerName(player))))

    local nLevel = PlayerData.GetPlayerLevel(player)
    local nCurExp = PlayerData.GetPlayerExperience(player)
    local nRoleType = PlayerData.GetPlayerRoleType(player)
    UIHelper.SetString(self.LabelLevel, string.format("%d级", nLevel))

    local tbLevelUP = GetLevelUpData(nRoleType, nLevel)
	local nMaxExp = tbLevelUP['Experience']

	local szSchool = Table_GetForceName(g_pClientPlayer.dwForceID)
    UIHelper.SetString(self.LabelMenPai, szSchool)
    PlayerData.SetSchoolImg(self.ImgMenPai, nil, 2)

    UIHelper.SetProgressBarPercent(self.SliderExp, 100*nCurExp/nMaxExp)
    UIHelper.SetString(self.LabelLevelNum, string.format("%d/%d", nCurExp, nMaxExp))

    self:UpdateDesignation()

    local nCamp = PlayerData.GetPlayerCamp(player)
    UIHelper.SetVisible(self.ImgCampIcon, nCamp ~= CAMP.NEUTRAL)
    UIHelper.SetVisible(self.LabelCampMutual, nCamp == CAMP.NEUTRAL)

    local szCampIcon = CampData.GetCampImgPath(nCamp)
    UIHelper.SetSpriteFrame(self.ImgCampIcon, szCampIcon)

    UIHelper.SetString(self.LabelCamp, string.format("%s", g_tStrings.STR_GUILD_CAMP_NAME[nCamp]))
    UIHelper.SetString(self.LabelRankNum, PlayerData.GetPlayerTotalEquipScore(player))
    UIHelper.SetString(self.LabelWudouNum, tostring(PlayerData.GetPlayerKillPoints(player)))

    self:UpdateSprintPower()
    self:UpdateKungfuMount()
end

function UICharacterMainView:UpdateScorePointInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nBaseScores = player.GetBaseEquipScore()
	local nStrengthScores = player.GetStrengthEquipScore()
	local nStoneScores = player.GetMountsEquipScore()
	local nScores =  nBaseScores + nStrengthScores + nStoneScores

	local nScoreLevel, szFrame = PlayerData.GetEquipScoresLevel(nScores)
    UIHelper.SetSpriteFrame(self.ImgIconEquipRank, szFrame)

    UIHelper.SetTabVisible(self.tbImgScoreDot, false)
    if nBaseScores > 0 then
		UIHelper.SetVisible(self.tbImgScoreDot[1], true)
	end
	if nStrengthScores > 0 then
		UIHelper.SetVisible(self.tbImgScoreDot[2], true)
	end
	if nStoneScores > 0 then
		UIHelper.SetVisible(self.tbImgScoreDot[3], true)
	end
end

local Designation
function UICharacterMainView:UpdateDesignation()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local szChenghao, nQuality = GetPlayerDesignation(player.dwID)
    if szChenghao == "" then
        szChenghao = "暂无称号"
    else
        szChenghao = UIHelper.GBKToUTF8(szChenghao)
    end
    UIHelper.SetString(self.LabelChenghao, szChenghao)
    -- local r, g, b = GetItemFontColorByQuality(nQuality, false)
    -- UIHelper.SetTextColor(self.LabelChenghao, cc.c4b(r, g, b, 255))
end

function UICharacterMainView:UpdateSprintPower()
    if self.nUpdateSprintPowerTimerID then
        Timer.DelTimer(self, self.nUpdateSprintPowerTimerID)
        self.nUpdateSprintPowerTimerID = nil
    end

    local function DoUpdateSprintPower()
        local bOnHorse, nSprintPower, nSprintPowerMax, nHorseSprintPower, nHorseSprintPowerMax = PlayerData.GetPlayerSprintPower()

        if bOnHorse then
            UIHelper.SetString(self.LabelQiLi, "坐骑气力值")
            UIHelper.SetString(self.LabelQiLiNum, string.format("%d/%d", nHorseSprintPower / 100, nHorseSprintPowerMax / 100))
        else
            UIHelper.SetString(self.LabelQiLi, "气力值")
            UIHelper.SetString(self.LabelQiLiNum, string.format("%d", nSprintPowerMax / 100))
        end
    end

    self.nUpdateSprintPowerTimerID = Timer.AddCycle(self, 2, function ()
        DoUpdateSprintPower()
    end)

    DoUpdateSprintPower()
end

function UICharacterMainView:UpdateKungfuMount()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nCurrentKungFuID = player.GetActualKungfuMount().dwSkillID

    local tSkillInfo = TabHelper.GetUISkill(nCurrentKungFuID)
    local szIconPath = PlayerKungfuImg[nCurrentKungFuID]

    UIHelper.SetSpriteFrame(self.ImgSkillIcon, szIconPath)
    if tSkillInfo then
        UIHelper.SetString(self.LabelSkillName, tSkillInfo.szName)
    end
end

function UICharacterMainView:UpdatePlayerAttribInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tbShowConfig = PlayerData.GetAttribShowConfig(player)
    local tbInfo = PlayerData.GetAttribInfo(player)
    local nIndex = 1

    UIHelper.HideAllChildren(self.ScrollViewAttribute)
    self.tbAttrCell = self.tbAttrCell or {}
    for i, tbAttribInfo in ipairs(tbInfo) do
        if tbShowConfig[table.get_key(g_tStrings.PLAYER_ATTRIB_NAME, tbAttribInfo.szName)] then
            if not self.tbAttrCell[nIndex] then
                self.tbAttrCell[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterAttribCell, self.ScrollViewAttribute)
                UIHelper.ToggleGroupAddToggle(self.TogGroupAttrs, self.tbAttrCell[nIndex].TogCell)
            end

            UIHelper.SetVisible(self.tbAttrCell[nIndex]._rootNode, true)
            self.tbAttrCell[nIndex]:OnEnter(nIndex, tbAttribInfo)
            nIndex = nIndex + 1
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewAttribute)
    UIHelper.ScrollToTop(self.ScrollViewAttribute, 0, false)
    UIHelper.SetToggleGroupSelected(self.TogGroupAttrs, 0)

    if self.tbAttrCell[1] then
        UIHelper.SetSelected(self.tbAttrCell[1].TogCell, false)
    end

    local nMaxLife = player.nMaxLife or 1
    local nMaxMana = player.nMaxMana or 1

    UIHelper.SetString(self.LabelHpNum, nMaxLife)
    UIHelper.SetString(self.LabelMpNum, nMaxMana)

end

function UICharacterMainView:UnSelected()
    for _, nType1 in pairs(Equip1Enum) do
        self.tbEquipCell[nType1]:SetSelected(false)
    end

    for _, nType1 in pairs(Equip2Enum) do
        self.tbEquipCell[nType1]:SetSelected(false)
    end

    for _, nType1 in pairs(WeaponEnum) do
        self.tbWeaponCell[nType1]:SetSelected(false)
    end

    if self.scriptItemTip then
        self.scriptItemTip:OnInit()
    end

    if self.personalCardScript then
        UIHelper.SetVisible(self.personalCardScript._rootNode, false)
    end

    for _, value in pairs(self.tbAttrCell) do
        UIHelper.SetSelected(value.TogCell, false)
    end

    UIHelper.SetSelected(self.TogSwitchOptions, false)
end

function UICharacterMainView:UpdateHorseState()
	local hPlayer = PlayerData.GetClientPlayer()
    local horse = hPlayer.GetEquippedHorse()
    UIHelper.SetProgressBarStarPercentPt(self.ImgHungerFg, 0, 0)
	if not horse then
        UIHelper.SetProgressBarPercent(self.ImgHungerFg, 0)
        -- self.nPerc = 0
        -- Timer.AddCycle(self, 0.1, function ()
        --     self.nPerc = self.nPerc + 1
        --     if self.nPerc > 100 then
        --         self.nPerc = 0
        --     end
        --     UIHelper.SetProgressBarPercent(self.ImgHungerFg, self.nPerc * 0.5)
        --     UIHelper.SetString(self.LabelHunger, self.nPerc .. "%")
        -- end)
        UIHelper.SetString(self.LabelHunger, "")
        return
	end

	local nFullLevel = horse.GetHorseFullLevel()
	local fCurFullMeasure = horse.GetHorseFullMeasure()
	local fMaxFullMeasure = horse.GetHorseMaxFullMeasure()

    local fPerc = fCurFullMeasure / fMaxFullMeasure * 100
	local szPerc = string.format("%.0f%%", fPerc)
    UIHelper.SetString(self.LabelHunger, szPerc)
    UIHelper.SetProgressBarPercent(self.ImgHungerFg, fPerc * 0.5)
end

function UICharacterMainView:UpdateHomelandState()
    local pPlayer = GetClientPlayer()
	local dwPlayerID = pPlayer and pPlayer.dwID
    local nLevel = PlayerData.GetPlayerLevel(pPlayer)
	if not dwPlayerID or IsRemotePlayer(dwPlayerID) or nLevel < 108  then
        UIHelper.SetNodeGray(self.BtnHome, true, true)
        return
	end
    UIHelper.SetNodeGray(self.BtnHome, false, true)
end

function UICharacterMainView:UpdateRepairState()
    self.tbNeedRepairableItems = {}
    for _, nType in pairs(Equip1Enum) do
        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item and item.IsRepairable() and item.nCurrentDurability == 0 then
            table.insert(self.tbNeedRepairableItems, nType)
        end
    end

    for _, nType in pairs(Equip2Enum) do
        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item and item.IsRepairable() and item.nCurrentDurability == 0 then
            table.insert(self.tbNeedRepairableItems, nType)
        end
    end

    for _, nType in pairs(WeaponEnum) do
        local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nType)
        if item and item.IsRepairable() and item.nCurrentDurability == 0 then
            table.insert(self.tbNeedRepairableItems, nType)
        end
    end

    UIHelper.SetVisible(self.WidgetRepair, #self.tbNeedRepairableItems > 0)
end

function UICharacterMainView:UpdateArenaMasterState()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local dwMapID = player.GetMapID()
    if IsMasterEquipMap(dwMapID) then
        UIHelper.SetVisible(self.TogSwitchOptions, false)
        UIHelper.SetVisible(self.ToggleGroupPreset, false)
        UIHelper.SetVisible(self.BtnPowerUp, false)
        UIHelper.SetVisible(self.BtnRecEquip, false)
        UIHelper.SetVisible(self.BtnMoneyStats, false)
    end
end

function UICharacterMainView:DoRepair()
    for _, nType in ipairs(self.tbNeedRepairableItems or {}) do
        RepairItem(INVENTORY_INDEX.EQUIP, nType)
    end
end

function UICharacterMainView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not g_pClientPlayer then
        return
    end
    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    local nRoleType = g_pClientPlayer.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function UICharacterMainView:UpdateHead()
    if not g_pClientPlayer then
        return
    end

    local dwID = g_pClientPlayer.dwID
    local dwForceID = g_pClientPlayer.dwForceID
    local nLevel = g_pClientPlayer.nLevel
    local uGlobalID = g_pClientPlayer.GetGlobalID()

    if not self.scriptHead then
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHeadShell, dwID)
        self.scriptHead:SetClickCallback(function()
            --
            self.personalCardScript = self.personalCardScript or UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetHeadTip, uGlobalID)
            if self.personalCardScript then
				self.personalCardScript:SetPlayerId(dwID)
                -- self.personalCardScript:OnEnter(uGlobalID)
                self.personalCardScript:OnEnter(uGlobalID)
                self.personalCardScript:ShowOwnBtn(true)
                UIHelper.SetVisible(self.personalCardScript.ImgPersonalCardNewBg, true)
                UIHelper.SetVisible(self.personalCardScript._rootNode, true)
            end
        end)
    else
        self.scriptHead:OnEnter(dwID)
    end

    UIHelper.SetString(self.LabelLevel, nLevel)
    if PlayerForceID2SchoolImg2[dwForceID] then
        UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[dwForceID])
    end
end

function UICharacterMainView:UpdateLock()
    UIHelper.SetVisible(self.WidgetLockPersonalCard, not SystemOpen.IsSystemOpen(SystemOpenDef.PersonalCard))
    UIHelper.SetVisible(self.WidgetLockOutfit, not SystemOpen.IsSystemOpen(SystemOpenDef.Accessory))
    UIHelper.SetVisible(self.WidgetLockHome, not SystemOpen.IsSystemOpen(SystemOpenDef.Homeland))
    UIHelper.SetVisible(self.WidgetLockHorse, not SystemOpen.IsSystemOpen(SystemOpenDef.Horse))
    UIHelper.SetVisible(self.WidgetQianJiXia, ItemData.CanWeaponBagOpen() and SkillData.IsUsingHDKungFu())
end

function UICharacterMainView:UnmountAllEquip(nCurEquipPageIndex)
    RemoteCallToServer("OnUnEquipAll", nCurEquipPageIndex - 1)
end

--是否显示明教兜帽
function UICharacterMainView:SetCaStateVisible(bVisible)
    UIHelper.SetVisible(self.tbTogOptions[OptionEnum.HideHood], false)

    if not g_pClientPlayer then
        return
    end

    if not APIHelper.IsHaveSecondRepresent() then
        return
    end

	local skill = g_pClientPlayer.GetKungfuMount()
	if not skill then
		return
	end

    local dwSkillID = skill.dwSkillID
    if skill.dwBelongSchool ~= BELONG_SCHOOL_TYPE.MING_JIAO then
        return
    end

    if IsBoolean(bVisible) then
        UIHelper.SetVisible(self.tbTogOptions[OptionEnum.HideHood], bVisible)
        UIHelper.LayoutDoLayout(self.WidgetAnchorMoreOper)
        return
    end

    local bIsApplyExterior = g_pClientPlayer.IsApplyExterior()
    if not bIsApplyExterior then
        return
    end

    UIHelper.SetVisible(self.tbTogOptions[OptionEnum.HideHood], true)
    UIHelper.LayoutDoLayout(self.WidgetAnchorMoreOper)
end

-- 明教兜帽的选中状态
function UICharacterMainView:SetCaStateSelect(bSelected)
    if not g_pClientPlayer then
        return
    end

    if IsBoolean(bSelected) then
        UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideHood], bSelected)
    end

    UIHelper.SetSelected(self.tbTogOptions[OptionEnum.HideHood], APIHelper.IsInSecondRepresent())
end

-- 设置Toggle 2秒内不能频繁点击
function UICharacterMainView:DisableTogCanSelect()
    Timer.DelTimer(self, self.nToggleTimerID)

    for nIndex, tog in ipairs(self.tbTogOptions) do
        UIHelper.SetCanSelect(tog, false, "操作太频繁，请稍后再试")
        UIHelper.SetTouchEnabled(tog, false)
    end

    self.nToggleTimerID = Timer.Add(self, 1.5, function()
        for nIndex, tog in ipairs(self.tbTogOptions) do
            UIHelper.SetCanSelect(tog, true)
             UIHelper.SetTouchEnabled(tog, true)
        end
    end)
end

-- 明教头像
function UICharacterMainView:UpdateMingJiaoAvatar()
    if not g_pClientPlayer then
        return
    end

    if g_pClientPlayer.dwForceID ~= FORCE_TYPE.MING_JIAO then
        return
    end

    local dwMiniAvatarID = g_pClientPlayer.dwMiniAvatarID
    local tLine = g_tTable.RoleAvatar:Search(dwMiniAvatarID)
	if tLine and tLine.nRelateID > 0 then
		g_pClientPlayer.SetMiniAvatar(tLine.nRelateID)
        Event.Dispatch(EventType.PLAYER_MINI_AVATAR_UPDATE)
	end
end

function UICharacterMainView:CheckCampEquip()
    local nCamp = PlayerData.GetPlayerCamp()
    local nCurEquipPageIndex = self.nCurEquipPageIndex
    local nBoxID = GetLogicEquipPos(nCurEquipPageIndex - 1)

    local bNeedUnEquip = false
    local tbOldUnEquipIndex = {}
    for i, nIndex in ipairs(EquipSlotEnum) do
        local item = ItemData.GetItemByPos(nBoxID, nIndex)
        if item then
            local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
            if itemInfo and not IsItemFitByCamp(itemInfo, nCamp) then
                bNeedUnEquip = true
            end
        end

        item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nIndex)
        if item then
            local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
            if itemInfo and not IsItemFitByCamp(itemInfo, nCamp) then
                table.insert(tbOldUnEquipIndex, nIndex)
            end
        end
    end

    local szMsg
    if bNeedUnEquip and #tbOldUnEquipIndex <= 0 then
        szMsg = "第%d套装备有不符合条件的装备，请检查装备条件，点击确认按钮将把<color=#ff0000>第%d套装备</c>卸载到背包中。<color=#ff0000>请确保背包拥有足够的空位！</c>"
        szMsg = string.format(szMsg, nCurEquipPageIndex, nCurEquipPageIndex)
    elseif not bNeedUnEquip and #tbOldUnEquipIndex > 0 then
        szMsg = "当前装备中有不符合条件的装备，请检查装备条件，点击确认按钮将把<color=#ff0000>当前装备中不符合条件的装备</c>卸载到背包中。<color=#ff0000>请确保背包拥有足够的空位！</c>"
    elseif bNeedUnEquip and #tbOldUnEquipIndex > 0 then
	    szMsg = "第%d套装备和当前装备中有不符合条件的装备，请检查装备条件，点击确认按钮将把<color=#ff0000>第%d套装备</c>和<color=#ff0000>当前装备中不符合条件的装备</c>卸载到背包中。<color=#ff0000>请确保背包拥有足够的空位！</c>"
        szMsg = string.format(szMsg, nCurEquipPageIndex, nCurEquipPageIndex)
    end

    if szMsg then
        UIHelper.ShowConfirm(szMsg, function ()
            if bNeedUnEquip then
                self:UnmountAllEquip(nCurEquipPageIndex)
            end

            if #tbOldUnEquipIndex > 0 then
                for _, nIndex in ipairs(tbOldUnEquipIndex) do
                    ItemData.UnEquipItem(INVENTORY_INDEX.EQUIP, nIndex)
                end
            end
        end, nil, true)
    end
end

function UICharacterMainView:UpdateTangMenBullet()
    if UIHelper.GetVisible(self.WidgetQianJiXia) then
        local nArrow, nJiGuan = ItemData.GetTangMenBulletCount()
        UIHelper.SetLabel(self.LabelQianJiXia, string.format("弩箭：%d\n机关：%d", nArrow, nJiGuan))
    end
end

return UICharacterMainView