local UIMainCityView = class("UIMainCityView")

local tbPrefabList = {
    [1] = PREFAB_ID.WidgetMainCityMiniChat2,
    [2] = PREFAB_ID.WidgetMainCityMiniChat1,
}


local tbBleedMaxMap = {
    [PREFAB_ID.WidgetBleedWhiteNormal] = 15,
    [PREFAB_ID.WidgetBleedWhiteCritical] = 8,
    [PREFAB_ID.WidgetBleedHint] = 5,
}

local tbCustomPrefabList = {
    [CUSTOM_TYPE.PLAYER] = PREFAB_ID.WidgetMainCityPlayer,
    [CUSTOM_TYPE.TARGET] = PREFAB_ID.WidgetTargetBoss,
    [CUSTOM_TYPE.CUSTOMBTN] = PREFAB_ID.WidgetMainCityLeftBottonBtn,
    [CUSTOM_TYPE.QUICKUSE] = PREFAB_ID.WidgetMainCityDragQuickUse,
    [CUSTOM_TYPE.BUFF] = PREFAB_ID.WidgetMainCityBuffList,
    [CUSTOM_TYPE.MENU] = PREFAB_ID.WidgetMainCityRightTop,
    [CUSTOM_TYPE.SKILL] = PREFAB_ID.WidgetSkillPanel,
    [CUSTOM_TYPE.CHAT] = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = PREFAB_ID.WidgetMainCityMiniChat1,
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = PREFAB_ID.WidgetMainCityMiniChat2,
    },
    [CUSTOM_TYPE.TASK] = PREFAB_ID.WidgetTaskTeam,
    [CUSTOM_TYPE.ENERGYBAR] = PREFAB_ID.WidgetSkillEnergyBar,
    [CUSTOM_TYPE.SPECIALSKILLBUFF] = PREFAB_ID.WidgetSpecialSkillBuff,
    [CUSTOM_TYPE.KILL_FEED] = PREFAB_ID.WidgetMainCityKillFeed,
}

local tbRangeTypeNode = {
    [CUSTOM_RANGE.RIGHT] = {CUSTOM_TYPE.MENU, CUSTOM_TYPE.SKILL},
    [CUSTOM_RANGE.FULL] = {CUSTOM_TYPE.CUSTOMBTN, CUSTOM_TYPE.TARGET, CUSTOM_TYPE.PLAYER, CUSTOM_TYPE.QUICKUSE, CUSTOM_TYPE.BUFF, CUSTOM_TYPE.ENERGYBAR, CUSTOM_TYPE.SPECIALSKILLBUFF, CUSTOM_TYPE.KILL_FEED},
    [CUSTOM_RANGE.CHAT] = {CUSTOM_TYPE.CHAT},
    [CUSTOM_RANGE.LEFT] = {CUSTOM_TYPE.TASK}
}

local tbCommonType = {CUSTOM_TYPE.TARGET, CUSTOM_TYPE.MENU, CUSTOM_TYPE.SKILL, CUSTOM_TYPE.ENERGYBAR, CUSTOM_TYPE.SPECIALSKILLBUFF, CUSTOM_TYPE.KILL_FEED}

function UIMainCityView:OnEnter()
    -- 动画初始化数据 -----------------------
    self.bAnimShowLeftIsPlaying = false
    self.bAnimHideLeftIsPlaying = false
    self.nLeftAnimCount = 0

    self.bAnimShowRightIsPlaying = false
    self.bAnimHideRightIsPlaying = false
    self.nRightAnimCount = 0

    self.bAnimShowBottomIsPlaying = false
    self.bAnimHideBottomIsPlaying = false
    self.nBottomAnimCount = 0

    self.bAnimShowMiddleIsPlaying = false
    self.bAnimHideMiddleIsPlaying = false
    self.nMiddleAnimCount = 0

    self.bAnimShowFullScreenIsPlaying = false
    self.bAnimHideFullScreenIsPlaying = false
    self.nFullScreenAnimCount = 0

    self.bAnimShowOtherIsPlaying = false
    self.bAnimHideOtherIsPlaying = false
    self.nOtherAnimCount = 0
    -- 动画初始化数据 -----------------------


    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end
    if not IsNumber(Storage.ControlMode.nVersion) or Storage.ControlMode.nVersion ~= CUSTOM_VERSION then
        MainCityCustomData.ResetCustomStorageData()
    end
    self.tbDefaultPosition = clone(Storage.ControlMode.tbDefaultPosition)
    self:UpdateNodeScale()
    self:InitNodeInfo()
    self:UpdateInfo()
    self:UpdateElementVisible()
    self:UpdateSprintPower()
    self:UpdateFuncSlotState()
    self:UpdateBtnQuickUseVisible()

    self:SaveChatDefaultSize()

    self:UpdateVersionInfo()
    self:UpdateCustomNodePosition(Storage.ControlMode.nMode, false)
    self:UpdateChatContentSize(Storage.ControlMode.nMode)
    self:GetFontSizeSet()   --获取各个节点的大小信息
    self:UpdateDynamicState()
    self:UpdateDXEnergyBar()
    self:UpdateDXSpecialSkillBuff()
    MainCityCustomData.InitStorageDragNodeScale()
    MainCityCustomData.UpdateMainCitySkillBoxNonVisible()
end

function UIMainCityView:OnExit()
    self.bInit = false
end

function UIMainCityView:BindUIEvent()
    --UIHelper.BindUIEvent(self.BtnQuickUse, EventType.OnClick, function()
    --    --self:SwitchQuickUseTip()
    --    local node = UIHelper.GetVisible(self.WidgetQuickUse) and self.WidgetQuickUse or UIHelper.GetVisible(self.WidgetQuickUse2) and self.WidgetQuickUse2
    --    local nX = UIHelper.GetWorldPositionX(node)
    --    local nY = UIHelper.GetWorldPositionY(node)
    --    local _, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetQuickUsedTip, nX, nY)
    --    UIHelper.SetTouchDownHideTips(script.BtnSetting, false)
    --end)
--
    --UIHelper.BindUIEvent(self.BtnQuickUse2, EventType.OnClick, function()
    --    self:SwitchQuickUseTip()
    --end)

    --UIHelper.BindUIEvent(self.BtnQuickUseBg, EventType.OnTouchBegan, function()
    --    self:TryCloseQuickUseTip()
    --end)
--
    --UIHelper.BindUIEvent(self.BtnQuickUseBg2, EventType.OnTouchBegan, function()
    --    self:TryCloseQuickUseTip()
    --end)

    UIHelper.BindUIEvent(self.BtnLeaveCustom, EventType.OnClick, function() --退出编辑
        if MainCityCustomData.bSubsidiaryCustomState then   --退出辅助界面自定义编辑
            MainCityCustomData.EnterSubsidiaryCustom(false)
        else
            self:ExitCurrentNodeCustom()
        end

    end)
end

function UIMainCityView:RegEvent()
    Event.Reg(self, EventType.OnTargetChanged, function(...)
        self:OnTargetChanged(...)
    end)
    Event.Reg(self, EventType.OnSprintFightStateChanged, function(bSprint)
        self:UpdateFuncSlotState(bSprint)
    end)
    Event.Reg(self, EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, function(bEnter, nGroupID)
        self:UpdateFuncSlotState()
        self:SwitchDynamicSkills(bEnter, nGroupID)
        if JiangHuData.GetArtistState() then
            if self.scriptArtistSkill and self.scriptArtistSkill._rootNode then
                UIHelper.SetVisible(self.scriptArtistSkill._rootNode, not bEnter)
            end
            Event.Dispatch("ON_HIDEORSHOW_MAINCITYSKILL", bEnter)
        end
    end)

    Event.Reg(self, "ON_CHANGE_IDENTITY_SKILL", function(bEnter)
        self:SwitchIdentitySkills(bEnter)
    end)

    Event.Reg(self, EventType.UpdateMarkData, function(bEnter, bForceUpdate)
        if bEnter then
            self.scriptWidgetMainCityActionBar:AddMark(bForceUpdate)
        else
            self.scriptWidgetMainCityActionBar:ExitMark()
        end
    end)

    Event.Reg(self, EventType.UpdateTreasureBattleFieldActionBar, function(bEnter, bForceUpdate)
        if bEnter then
            ---@see UIWidgetMainCityActionBar#AddTreasureBattle
            self.scriptWidgetMainCityActionBar:AddTreasureBattle(bForceUpdate)
        else
            self.scriptWidgetMainCityActionBar:ExitTreasureBattle()
        end
    end)

    Event.Reg(self, EventType.OnEnterMonsterBookScene, function()
        self.scriptWidgetMainCityActionBar:AddBaiZhan()
    end)

    Event.Reg(self, EventType.OnMonsterBookSkillChanged, function()
        self.scriptWidgetMainCityActionBar:AddBaiZhan()
    end)

    Event.Reg(self, EventType.OnExitMonsterBookScene, function()
        self.scriptWidgetMainCityActionBar:ExitBaiZhan()
    end)


    Event.Reg(self, EventType.OnSetBottomRightAnchorVisible, function(bVisible)
        self:OnSetBottomRightAnchorVisible(bVisible)
    end)
    Event.Reg(self, "SYNC_PLAYER_REVIVE", function()
        self:OnSetBottomRightAnchorVisible(false) --角色死亡隐藏右下角操作按钮
    end)
    Event.Reg(self, "PLAYER_REVIVE", function()
        self:OnSetBottomRightAnchorVisible(true) --角色复活显示右下角操作按钮
    end)

    Event.Reg(self, EventType.ResetSkillAndJoystick, function()
        self:ReloadJoystick()
        self:ReloadSkill(true)
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelRevive then
            self:OnSetBottomRightAnchorVisible(true) --角色复活显示右下角操作按钮
        elseif nViewID == VIEW_ID.PanelPostBattleOperation then
            self:OnSetBottomRightAnchorVisible(true)
        end
    end)

    Event.Reg(self, EventType.BF_OpenNewPlayerBF, function(...)
        if self.scriptPvpRightTop then
            UIHelper.RemoveFromParent(self.scriptPvpRightTop._rootNode, true)
            self.scriptPvpRightTop = nil
        end

        local tbArgs = { ... }
        self:SetupScriptPvpRightTop(PlayType.BattleField, BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE, tbArgs)
    end)
    Event.Reg(self, EventType.OnCampWarStateChanged, function(bOpen)
        local _, bIsInActivityMap = CampData.IsInActivity()
        local bIsInPvpMap = MapHelper.IsRemotePvpMap()
        if (not bIsInActivityMap or (g_pClientPlayer and g_pClientPlayer.nCamp == CAMP.NEUTRAL)) and not bIsInPvpMap then
            return
        end

        self:SwitchCampRightTopState(bOpen)
    end)
    Event.Reg(self, "LOADING_END", function()
        self:UpdateElementVisible()
        self:UpdateBtnQuickUseVisible()
        self:OnSetBottomRightAnchorVisible(not PlayerData.IsPlayerDeath())

        if JiangHuData.nActionID then
            Event.Dispatch("ON_STOP_EMOTION_ACTION")
        end

        if Platform.IsWindows() then
            self:RefreshNodePosition()
        end

        self:ReloadSkill()
        Event.Dispatch(EventType.OnDXYaoZongPlantChanged)
    end)
    Event.Reg(self, "SKILL_MISS", function(dwCasterID, dwTargetID)
        self:UpdateCombatStateText(dwCasterID, dwTargetID, g_tStrings.COMBAT_STATE_TEXT["SKILL_MISS"])
    end)
    Event.Reg(self, "SKILL_DODGE", function(dwCasterID, dwTargetID)
        self:UpdateCombatStateText(dwCasterID, dwTargetID, g_tStrings.COMBAT_STATE_TEXT["SKILL_DODGE"])
    end)
    Event.Reg(self, "REPRESENT_DODGE_TEXT", function(dwCasterID, dwTargetID)
        self:UpdateCombatStateText(dwCasterID, dwTargetID, g_tStrings.COMBAT_STATE_TEXT["REPRESENT_DODGE_TEXT"])
    end)
    Event.Reg(self, "REPRESENT_MISS_TEXT", function(dwCasterID, dwTargetID)
        self:UpdateCombatStateText(dwCasterID, dwTargetID, g_tStrings.COMBAT_STATE_TEXT["REPRESENT_MISS_TEXT"])
    end)
    Event.Reg(self, "BUFF_IMMUNITY", function(dwTargetID, dwCasterID)
        self:UpdateCombatStateText(dwCasterID, dwTargetID, g_tStrings.COMBAT_STATE_TEXT["BUFF_IMMUNITY"])
    end)
    Event.Reg(self, "REPRESENT_IMMUNITY_TEXT", function(dwTargetID, dwCasterID)
        self:UpdateCombatStateText(dwCasterID, dwTargetID, g_tStrings.COMBAT_STATE_TEXT["REPRESENT_IMMUNITY_TEXT"])
    end)
    Event.Reg(self, EventType.OnCharacterHeadTip, function(dwCharacterID, szTip, szParam, tColor)
        self:UpdateCharacterHeadTip(dwCharacterID, szTip, szParam, tColor)
    end)

    Event.Reg(self, "SKILL_EFFECT_TEXT", function(...)
        self:UpdateSkillEffectText(...)
    end)
    Event.Reg(self, "COMMON_HEALTH_TEXT", function(...)
        self:UpdateHealthText(...)
    end)
    Event.Reg(self, "REPRESENT_SKILL_EFFECT_TEXT", function(...)
        self:UpdateSkillEffectText(...)
    end)

    Event.Reg(self, "PLAYER_EXPERIENCE_UPDATE", function(...)
        self:UpdateExpBar()
    end)

    Event.Reg(self, "ON_SET_SHOW_EXP_VALUE", function(...)
        self:UpdateExpBar()
    end)

    Event.Reg(self, "SET_SHOW_VALUE_BY_PERCENTAGE", function(...)
        self:UpdateExpBar()
    end)

    Event.Reg(self, "ON_START_SHAPE_SHIFT", function()
        self:UpdateJoystickState()
    end)

    Event.Reg(self, "ON_END_SHAPE_SHIFT", function()
        self:UpdateJoystickState()
    end)

    Event.Reg(self, EventType.OnSpiritEnduranceChanged, function (...)
        self:UpdateSpiritEnduranceText(...)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityShow, function(callback)
        self:PlayShow(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityHide, function(callback)
        self:PlayHide(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityLeftShow, function(callback)
        self:PlayLeftShow(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityLeftHide, function(callback)
        self:PlayLeftHide(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityRightShow, function(callback)
        self:PlayRightShow(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityRightHide, function(callback)
        self:PlayRightHide(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityBottomShow, function(callback)
        self:PlayBottomShow(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityBottomHide, function(callback)
        self:PlayBottomHide(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityMiddleShow, function(callback)
        self:PlayMiddleShow(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityMiddleHide, function(callback)
        self:PlayMiddleHide(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityFullScreenShow, function(callback)
        self:PlayFullScreenShow(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityFullScreenHide, function(callback)
        self:PlayFullScreenHide(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityOtherShow, function(callback)
        self:PlayOtherShow(callback)
    end)

    Event.Reg(self, EventType.PlayAnimMainCityOtherHide, function(callback)
        self:PlayOtherHide(callback)
    end)

    Event.Reg(self, EventType.UpdatePartnerMorphShowState, function()
        local bShowMorph = PartnerData.bShowMorphInMainCity
        -- UIHelper.SetVisible(self.WidgetPartner, bShowMorph)
        if bShowMorph then
            self.scriptWidgetMainCityActionBar:AddPartNer()
        else
            self.scriptWidgetMainCityActionBar:ExitPartNer()
        end
    end)


    Event.Reg(self, EventType.OnFuncSlotChanged, function(tbAction)
        self:UpdateSprintTips(tbAction)
    end)

    Event.Reg(self, "ON_HIDEORSHOW_SKILLPANEL", function(bIsShow)
        --UIHelper.SetVisible(self.scriptSkill._rootNode, bIsShow)
        Event.Dispatch("ON_HIDEORSHOW_MAINCITYSKILL", bIsShow)
        UIHelper.SetVisible(self.scriptFuncSlot._rootNode, bIsShow)
        if self.scriptArtistSkill and self.scriptArtistSkill._rootNode then
            UIHelper.SetVisible(self.scriptArtistSkill._rootNode, not bIsShow)
        end
    end)

    Event.Reg(self, "ON_ADDORDEL_ARTISTSKILLPANEL", function(bIsShow)
        if bIsShow then
            self.scriptArtistSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetJiangHuBaiTaiButton, self.WidgetRightBottomAnchor)
        else
            if self.scriptArtistSkill then
                UIHelper.RemoveFromParent(self.scriptArtistSkill._rootNode)
            end
        end

    end)

    Event.Reg(self, "ON_PLAYER_START_EMOTION_ACTION", function(nActionID)
        self.scriptEmotionSmall = UIHelper.AddPrefab(PREFAB_ID.WidgetJiangHuBaiTaiButton, self.WidgetRightBottomAnchor, nActionID)
        Event.Dispatch("ON_HIDEORSHOW_MAINCITYSKILL", false)
        -- UIHelper.SetVisible(self.scriptFuncSlot._rootNode, false)
        JiangHuData.bIsArtist = true
        JiangHuData.nActionID = nActionID
        self:UpdateFuncSlotState()
    end)

    Event.Reg(self, "ON_STOP_EMOTION_ACTION", function()
        if self.scriptEmotionSmall then
            UIHelper.RemoveFromParent(self.scriptEmotionSmall._rootNode)
            self.scriptEmotionSmall = nil
        end
        Event.Dispatch("ON_HIDEORSHOW_MAINCITYSKILL", true)
        -- UIHelper.SetVisible(self.scriptFuncSlot._rootNode, true)--表情退出某些情况下会和技能界面重叠
        JiangHuData.bIsArtist = false
        JiangHuData.nActionID = nil
        self:UpdateFuncSlotState()
    end)

    Event.Reg(self, "ON_SHOW_WIDGETGIFTPOP", function(nFellowNum, nTimeSlot)
        if self.ArtistGiftscript then
            self.ArtistGiftscript:OnEnter(nFellowNum, nTimeSlot)
        else
            self.ArtistGiftscript = UIHelper.AddPrefab(PREFAB_ID.WidgetGiftPop, self.WidgetGiftPop,nFellowNum, nTimeSlot)
        end

    end)

    Event.Reg(self, "ON_HIDE_WIDGETGIFTPOP", function()
        if self.ArtistGiftscript then
            UIHelper.RemoveFromParent(self.ArtistGiftscript._rootNode)
            self.ArtistGiftscript = nil
        end
    end)

    Event.Reg(self, EventType.ShowBiaoShiTip, function(tGuradList)
        self:ShowBiaoshiPop(tGuradList)
    end)

    Event.Reg(self, "ON_HIDE_WIDGETBIAOSHIPOP", function()
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        self:HideBiaoshiPop()
    end)

    Event.Reg(self, EventType.ShowHuBiaoTip, function(dwID, szName, nCount, nCurValue, nMaxValue)
        self:ShowHuBiaoPop(dwID, szName, nCount, nCurValue, nMaxValue)
    end)

    Event.Reg(self, "ON_HIDE_WIDGETHUBIAOPOP", function()
        self:HideHuBiaoPop()
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    Event.Reg(self, EventType.FIRST_ENTER_NORMAL_DYNAMIC, function()
        self:PlayEnterDynamicAnim()
    end)

    -- Event.Reg(self, EventType.OnSceneTouchBegan, function()
    --     self.startClick = true
    --     self.nStartClickTime = Timer.RealMStimeSinceStartup()
    --     if self.nStartClickTime - self.nEndClickTime >= self.nDoubleClickSubTime then
    --         self.nClickCount = 0
    --     end
    -- end)

    -- Event.Reg(self, EventType.OnSceneTouchEnded, function()
    --     self.startClick = false
    --     self.nEndClickTime = Timer.RealMStimeSinceStartup()
    --     if self.nEndClickTime - self.nStartClickTime < self.nDoubleClickSubTime then
    --         self.nClickCount = self.nClickCount + 1
    --         if self.nClickCount == 2 then
    --             self.nClickCount = 0
    --             CameraMgr.CamaraReset()
    --         end
    --     end
    -- end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:RefreshNodePosition()
    end)

    -- Event.Reg(self, EventType.OnCameraZoom, function(nScale)
    --     if nScale <= 0.2 and not self.bInFaceState then
    --         self.bInFaceState = true
    --     elseif nScale > 0.2 and self.bInFaceState then
    --         self.bInFaceState = false
    --     end
    -- end)

    Event.Reg(self, "FOCUS_FACE_STATUS_CHANGE", function(bInFaceState)
        self.bInFaceState = bInFaceState
    end)


    Event.Reg(self, "ON_CHANGE_MAINCITYPOSITION", function(nMode)
        if nMode ~= self.nLastMode then
            self.nLastMode = nMode
            local tbWidgetItem = self.scriptTaskTeam:GetCurrentWidgetItems()
            UIHelper.RemoveFromParent(self.scriptPlayerInfo._rootNode)
            UIHelper.RemoveFromParent(self.scriptTaskTeam._rootNode)
            UIHelper.RemoveFromParent(self.scriptChat._rootNode)
            UIHelper.RemoveFromParent(self.scriptLeftBottom._rootNode)
            UIHelper.RemoveFromParent(self.scriptQuickUse._rootNode)
            UIHelper.RemoveFromParent(self.scriptBuff._rootNode)
            self.scriptPlayerInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityPlayer, self.tbWidgetPlayerInfoAnchorList[nMode])
            self.scriptPlayerInfo:UpdateBuffAndVoicePosition(nMode)
            self.scriptTaskTeam = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeam, self.tbWidgetTaskTeamAnchorList[nMode])
            self.scriptTaskTeam:UpdateWidgetItems(tbWidgetItem)
            self.scriptChat = UIHelper.AddPrefab(tbPrefabList[nMode], self.tbWidgetChatMiniList[nMode], nMode)
            self.scriptLeftBottom = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityLeftBottonBtn, self.tbWidgetLeftBottonList[nMode])
            --UIHelper.SetVisible(self.WidgetQuickUse, nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and self.scriptSkill and self.scriptSkill.bWidgetQuickUseVisible or false)
            self.scriptQuickUse = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityDragQuickUse, self.tbWidgetQuickUseList[nMode])
            self.scriptBuff = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuffList, self.tbWidgetPlayerBuffList[nMode], nil, true)

            self:UpdateCustomNodePosition(nMode, false)
            local size = Storage.ControlMode.tbChatContentSize[nMode]
            self.nChatContentWidth, self.nChatContentHeight = size.w, size.h
            self:UpdateChatContentSize(nMode)

            local tbSizeInfo = clone(Storage.ControlMode.tbMainCityNodeScaleType[nMode])
            self:UpdateCustomNodeSize(tbSizeInfo)
            self.scriptTaskTeam:UpdateNodeSize(tbSizeInfo)
            self.scriptChat:SetChatBgOpacity()
        end
    end)

    Event.Reg(self, "ON_HIDEORSHOW_LEFTBTN", function(bShow)
        UIHelper.SetVisible(self.scriptLeftBottom._rootNode, bShow)
        if Storage.ControlMode.nMode == MAIN_CITY_CONTROL_MODE.SIMPLE then
            UIHelper.SetVisible(self.scriptChat._rootNode, bShow)
        end
    end)

    Event.Reg(self, "ON_SET_NODE_POSITION_DEFAULT", function(nMode)  --恢复默认
        self:SetPositionDefault(nMode, true)
        self:SetNodePositionDefault(nMode)
        self.tbFakeNodePosition = self:GetFakeNodePosition(nMode)
        self.bPositionChanged = true

        self:ResetChatContentSize(nMode)
        local tbFakeScriptList = self:GetFakeScriptList()
        if not tbFakeScriptList or table.is_empty(tbFakeScriptList) then
            return
        end
        for k, tbScript in pairs(tbFakeScriptList) do
            tbScript:UpdateCustomNodeState(CUSTOM_BTNSTATE.ENTER)
        end
    end)

    --Event.Reg(self, EventType.OnQuickUseSuccess, function()
    --    self:TryCloseQuickUseTip()
    --end)
    Event.Reg(self, "SCENE_BEGIN_LOAD", function(nSceneID)
        self:ReleaseAllBleedPrefab()
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        self:ReleaseAllBleedPrefab()
    end)

    Event.Reg(self, "PLAYER_LEVEL_UPDATE", function (dwPlayerID)
        if g_pClientPlayer and g_pClientPlayer.dwID == dwPlayerID then
            self:UpdateBtnQuickUseVisible()
		end
    end)

    Event.Reg(self, EventType.OnSwitchQuickUseTip, function()
        if UIHelper.GetHierarchyVisible(self.BtnQuickUse) then
            self:SwitchQuickUseTip()
        end
    end)

    Event.Reg(self, "ON_CHANGE_FONT_SIZE", function (tbSizeType)
        self:UpdateCustomNodeSize(tbSizeType)
    end)

    Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function(tbFontShow, nType)
        self.tbShowFont = tbFontShow
    end)

    Event.Reg(self, "ON_ENTER_CUSTOMIZATION", function (nMode, bEnter, bSave)  --显示所有可编辑节点的按钮
        self:TryCloseQuickUseTip()
        self:SetFakeNodePositionToCurrent()
        self.nCustomMode = nMode       --编辑模式下的操作模式
        self.bCustomState = bEnter

        if bSave then
            self:SaveChatContentSize(nMode)
        end
        local bDefault = self:GetDefaultPosition(nMode)
        local bChatSizeChanged = MainCityCustomData.GetChatContentSizeChanged()
        --根据操作模式在对应copy节点下加载假节点
        for k, nNodeType in pairs(CUSTOM_TYPE) do
            --找到对应真假父节点
            local tbCurNode, tbCurFakeNode = self:GetCustomNodeByType(nNodeType, nMode)
            UIHelper.SetVisible(tbCurNode, not bEnter)   --隐藏所有真节点
            UIHelper.SetVisible(tbCurFakeNode, bEnter)
            if bEnter then
                --加载加节点
                local tbScript = self:AddCustomPrefab(nNodeType, tbCurFakeNode, nMode)
                if tbScript then
                    tbScript:UpdatePrepareState(nMode, true)
                    self:SetFakeScript(nNodeType, tbScript)
                end

                --获取当前所有假节点位置以及对应的分辨率
                self.tbFakeNodePosition = self:GetFakeNodePosition(nMode)

                local nRangeType = self:GetRangeTypeByNodeType(nNodeType)
                local ImgBlackBg = self.tbBlackBgList[nRangeType]
                local tbAnchorScript = UIHelper.GetBindScript(tbCurFakeNode)

                local fnJudgeOverLapping = function(nType)
                    self:UpdateAllNodeOverLappingState(nType)
                end
                tbAnchorScript:Init(ImgBlackBg, nNodeType, tbCurNode, fnJudgeOverLapping)
            else
                tbCurNode = self:GetCustomNodeByType(nNodeType, nMode)
                if nNodeType == CUSTOM_TYPE.TASK and not UIHelper.GetSelected(self.scriptTaskTeam.TogTask) then
                    UIHelper.SetSelected(self.scriptTaskTeam.TogTask, true)
                end
                if bSave then                 --保存操作模式下的节点位置到本地
                    if bDefault then    --保存位置为默认位置
                        if nMode == MAIN_CITY_CONTROL_MODE.CLASSIC then
                            Storage.ControlMode.tbClassicPositionInfo[nNodeType] = nil
                        elseif nMode == MAIN_CITY_CONTROL_MODE.SIMPLE then
                            Storage.ControlMode.tbSimplePositionInfo[nNodeType] = nil
                        end
                    else
                        local nPx, nPy = UIHelper.GetWorldPosition(tbCurNode)
                        if nMode == MAIN_CITY_CONTROL_MODE.CLASSIC then
                            Storage.ControlMode.tbClassicPositionInfo[nNodeType] = {["nX"] = nPx, ["nY"] = nPy}
                        elseif nMode == MAIN_CITY_CONTROL_MODE.SIMPLE then
                            Storage.ControlMode.tbSimplePositionInfo[nNodeType] = {["nX"] = nPx, ["nY"] = nPy}
                        end
                    end
                    Storage.ControlMode.Flush()
                end
                --移除所有假节点
                self:RemoveFakeScript(nNodeType)
                self.bPositionChanged = false
            end
        end
        if bEnter then
            --self:UpdateAllNodeOverLappingState(CUSTOM_BTNSTATE.ENTER)
            self:UpdateChatContentSize(nMode)
        else
            if bSave then
                self:SetStorageDefaultState(nMode, bDefault)
                if bDefault then
                    if bChatSizeChanged then
                        self:UpdateChatContentSize(nMode)
                        MainCityCustomData.SetChatContentSizeChanged(false)
                    end
                else
                    self:UpdateAfterSizeChangePosition(nMode) --保存nmode下节点位置对应的分辨率
                    self:UpdateChatContentSize(nMode)
                end
            end
        end

        UIHelper.SetVisible(self.WidgetMiddleInfo, not bEnter)
        UIHelper.SetVisible(self.WidgetJoystickAnchor, not bEnter)
    end)

    Event.Reg(self, "ON_ENTER_SINGLENODE_CUSTOM", function (nRangeType, nNodeType, nMode)  --编辑单个节点
        if MainCityCustomData.bSubsidiaryCustomState then
            return
        end
        self:EnterSingleNodeCustom(nRangeType, nNodeType, nMode)
    end)

    Event.Reg(self, "ON_END_CUSTOMIZATION", function (nMode)
        self.bCustomState = false
        --移除所有假节点
        for k, nType in pairs(CUSTOM_TYPE) do
            self:RemoveFakeScript(nType)
        end
    end)

    Event.Reg(self, "ON_TOUCH_BLANK_REGION", function ()--点击空白区域
        UIHelper.SetVisible(self.ImgHintDrag, false)
        UIHelper.SetVisible(self.LabelHintDrag, false)
        if self.nNodeType then  --有上一编辑节点， 关闭上一节点的编辑状态先，删假节点和关背景，显示真节点
            self:CloseNodeCustomState()
        end
    end)

    Event.Reg(self, "ON_EXIT_CURRENT_NODE_CUSTOM", function()
        self:ExitCurrentNodeCustom()
    end)

    Event.Reg(self, "ON_RESET_CURRENT_NODE_POSITION", function(nMode, nNodeType)   --重置节点位置和大小
        --关闭当前tip
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipsFreeSetting)
        self:ResetNodePosition(nMode, nNodeType)
        self:ResetChatContentSize(nMode, nNodeType)
        self:UpdateAllNodeOverLappingState(CUSTOM_BTNSTATE.OTHER)
        self:ShowNodeSizeSetting(nNodeType)
    end)

    Event.Reg(self, "ON_RESET_STORAGE_POSITION", function()      --恢复至本地保存位置
        local bDefault = Storage.ControlMode.tbDefaultPosition[self.nCustomMode]
        self:SetPositionDefault(self.nCustomMode, bDefault)
        self:UpdateCustomNodePosition(self.nCustomMode, false, bDefault)
        self:UpdateChatContentSize(self.nCustomMode)
        self.tbFakeNodePosition = self:GetFakeNodePosition(self.nCustomMode)
        self:UpdateAllNodeOverLappingState(CUSTOM_BTNSTATE.ENTER)
        self.bPositionChanged = false
    end)

    Event.Reg(self, EventType.OnMainCityCustomSizeChanged, function(nCustomType, nW, nH)
        if nCustomType == CUSTOM_TYPE.CHAT then
            self.nChatContentWidth = nW
            self.nChatContentHeight = nH
        end
    end)

    Event.Reg(self, "PLAYER_ENTER_SCENE", function()
        if ArenaData.IsInArena() then
            if self.scriptEmotionSmall then
                UIHelper.RemoveFromParent(self.scriptEmotionSmall._rootNode)
                self.scriptEmotionSmall = nil
            end
            Event.Dispatch("ON_HIDEORSHOW_MAINCITYSKILL", true)
            -- UIHelper.SetVisible(self.scriptFuncSlot._rootNode, true)--表情退出某些情况下会和技能界面重叠
            JiangHuData.bIsArtist = false
            self:UpdateFuncSlotState()
        end
	end)


    Event.Reg(self, EventType.OnSwitchCampRightTopState, function(bOpen, bWithTips)
        self:SwitchCampRightTopState(bOpen, bWithTips)
    end)

    Event.Reg(self, EventType.OnSetDragInfoDefault, function()
        self:InitNodePos()
    end)

    Event.Reg(self, EventType.OnUpdateQuickUseTipPosByNewPos, function (nX, nY)
        self:SwitchQuickUseTip(nX, nY)
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        if Storage.QuickUse.bTouchClose then
            self:TryCloseQuickUseTip()
        end
    end)

    Event.Reg(self, EventType.UpdateActionToySkillState, function()
        local tbToyList = ToyBoxData.GetActionToyList()
        if table.get_len(tbToyList) > 0 then
            self.scriptWidgetMainCityActionBar:AddToy()
        else
            self.scriptWidgetMainCityActionBar:ExitToy()
        end
    end)

    Event.Reg(self, EventType.OnTangMenHiddenChanged, function()
        local tbShowList = TangMenHidden.GetFlyStarList()
        if table.get_len(tbShowList) > 0 then
            self.scriptWidgetMainCityActionBar:AddTangMenHidden()
        else
            self.scriptWidgetMainCityActionBar:ExitTangMenHidden()
        end
    end)

    Event.Reg(self, EventType.OnDXTeamMarkChanged, function()
        if TeamData.GetWorldMarkOpen() then
            self.scriptWidgetMainCityActionBar:AddDXTeamMark()
        else
            self.scriptWidgetMainCityActionBar:ExitDXTeamMark()
        end
    end)

    Event.Reg(self, EventType.OnDXYaoZongPlantChanged, function()
        if SkillData.IsUsingHDKungFu() then
            local dwKungfuID = g_pClientPlayer.GetActualKungfuMountID()
            if dwKungfuID == 10626 or dwKungfuID == 10627 then
                SpecialDXSkillData.InitYaoZong()
                self.scriptWidgetMainCityActionBar:AddDXYaoZongPlant()
            else
                SpecialDXSkillData.UnInitYaoZong()
                self.scriptWidgetMainCityActionBar:ExitDXYaoZongPlant()
            end
        else
            SpecialDXSkillData.UnInitYaoZong()
            self.scriptWidgetMainCityActionBar:ExitDXYaoZongPlant()
        end
    end)

    Event.Reg(self, EventType.UpdateArenaTowerActionBar, function(bEnter)
        if bEnter then
            self.scriptWidgetMainCityActionBar:AddArenaTower()
        else
            self.scriptWidgetMainCityActionBar:ExitArenaTower()
        end
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function(dwKungFuID)
        self:ReloadSkill()
        self:UpdateDXEnergyBar()
        Event.Dispatch(EventType.OnDXTeamMarkChanged) -- todo:查看dx vk切换是否有问题
        Event.Dispatch(EventType.OnDXYaoZongPlantChanged)
        self:UpdateDXSpecialSkillBuff()
        self:UpdateNodeScale()
    end)
end

function UIMainCityView:UnRegEvent()

end

function UIMainCityView:OnUpdate()
    self:UpdateSprintPower()
    self:UpdateExtraUIState()
    local player = PlayerData.GetClientPlayer()
    if player and self.scriptBuff then
        self.scriptBuff:UpdateBuffCycle(player)
    end
end

function UIMainCityView:UpdateInfo()
    ---- 点击双击复原镜头
    -- self.nClickCount = 0
    -- self.nStartClickTime = 0
    -- self.nEndClickTime = 0
    -- self.nDoubleClickSubTime = 1000

    self.scriptJoyStick = UIHelper.AddPrefab(PREFAB_ID.WidgetPerfabJoystick, self.WidgetJoystick)
    self.scriptSkill = UIHelper.AddPrefab(SkillData.GetSkillPanelPrefabID(), self.WidgetRightBottomAnchor, false, self.WidgetSkillCancel)
    self.scriptPlayerInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityPlayer, self.tbWidgetPlayerInfoAnchorList[Storage.ControlMode.nMode])
    self.scriptPlayerInfo:UpdateBuffAndVoicePosition(Storage.ControlMode.nMode, false)
    self.scriptMainInfo = UIHelper.GetBindScript(self.WidgetMainCityInfo)
    self.scriptRightTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityRightTop, self.WidgetRightTopAnchor)
    self.scriptTaskTeam = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeam, self.tbWidgetTaskTeamAnchorList[Storage.ControlMode.nMode])
    --self.scriptGetItemHint = UIHelper.AddPrefab(PREFAB_ID.WidgetGetItemHintArea, self.WidgetGetItemHintAnchor)
    self.scriptFuncSlot = UIHelper.AddPrefab(SkillData.GetFunctionPanelPrefabID(), self.WidgetRightBottomAnchor)
    self.scriptLeftBottom = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityLeftBottonBtn, self.tbWidgetLeftBottonList[Storage.ControlMode.nMode])
    self.scriptWidgetMainCityActionBar = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityActionBar, self.WidgetActiongBar)
    UIHelper.SetVisible(self.scriptWidgetMainCityActionBar._rootNode, false)
    -- UIHelper.SetPosition(self.WidgetActiongBar, -180, -310)

    self.scriptWidgetBaiZhanHintAnchor = UIHelper.AddPrefab(PREFAB_ID.WidgetMiddleBaiZhanHint, self.WidgetBaiZhanHintAnchor)
    self.scriptWidgetBaiZhanHintAnchor.bCanMove = true
    self.scriptWidgetBaiZhanHintAnchor:OnEnter()
    UIHelper.SetVisible(self.WidgetBaiZhanHintAnchor, true)

    self.scriptChat = UIHelper.AddPrefab(tbPrefabList[Storage.ControlMode.nMode], self.tbWidgetChatMiniList[Storage.ControlMode.nMode])
    self.scriptQuickUse = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityDragQuickUse, self.tbWidgetQuickUseList[Storage.ControlMode.nMode])
    self.scriptBuff = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuffList, self.tbWidgetPlayerBuffList[Storage.ControlMode.nMode], nil, true)
    self.scriptKillFeed = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityKillFeed, self.WidgetMainCityKillFeed)
    self:UpdateExpBar()
    self:InitNodePos()
    self.scriptChat:SetChatBgOpacity()
end


function UIMainCityView:InitNodePos(szNodeName)

    local tbNodeList = {--默认世界坐标，1600 x 900下的世界坐标
        [self.WidgetActiongBar] = {620, 160},
        [self.WidgetDbm] = {1161, 885},
        [self.WidgetHurtStatistics] = {460, 750},
        [self.WidgetTeamNotice] = {460, 510}
    }

    local size = UIHelper.GetCurResolutionSize()
    for node, tbPos in pairs(tbNodeList) do
        local tbStorage = Storage.MainCityNode.tbMaincityNodePos[node:getName()]
        if tbStorage and not table.is_empty(tbStorage) and
            tbStorage.nX and tbStorage.nY and tbStorage.Width and tbStorage.Height then
            local nX, nY = tbStorage.nX, tbStorage.nY
            local nRadioX, nRadioY = size.width / tbStorage.Width, size.height / tbStorage.Height
            UIHelper.SetWorldPosition(node, nX * nRadioX, nY * nRadioY)
            if node:getName() == "WidgetActiongBar" then
                UIHelper.SetWorldPosition(self.scriptWidgetMainCityActionBar._rootNode, nX * nRadioX, nY * nRadioY)
            end
        else
            local nX, nY = table.unpack(tbPos)
            local nRadioX, nRadioY = size.width / 1600, size.height / 900
            UIHelper.SetWorldPosition(node, nX * nRadioX, nY * nRadioY)
            if node:getName() == "WidgetActiongBar" then
                UIHelper.SetWorldPosition(self.scriptWidgetMainCityActionBar._rootNode, nX * nRadioX, nY * nRadioY)
            end
        end
    end
end


function UIMainCityView:OnTargetChanged(nTargetType, nTargetId)
    -- 先清
    if self.scriptTargetInfo then
        self.scriptTargetInfo._rootNode:removeFromParent()
        self.scriptTargetInfo = nil
    end

    if self.bCustomState then
        return
    end

    if TARGET.NO_TARGET == nTargetType then
        return
    end

    -- npc
    if nTargetType == TARGET.NPC then
        local npc = GetNpc(nTargetId)
        assert(npc)
        local nIntensity = npc.nIntensity
        assert(nIntensity)
        if 2 == nIntensity or 6 == nIntensity then
            -- boss
            self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetTargetBoss, self.WidgetTargetInfoAnchor, nTargetType, nTargetId, "boss")
        elseif nIntensity >= 4 and nIntensity <= 5 then
            -- Elite
            self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetTargetElite, self.WidgetTargetInfoAnchor, nTargetType, nTargetId, "elite")
        else
            self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetTargetNormal, self.WidgetTargetInfoAnchor, nTargetType, nTargetId, "normal")
        end

        -- player
    elseif nTargetType == TARGET.PLAYER then
        self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityPlayer, self.WidgetTargetInfoAnchor, nTargetId, true)
        self.scriptTargetInfo:UpdateBuffAndVoicePosition(MAIN_CITY_CONTROL_MODE.CLASSIC, true)
    end

end

--更新气力值
function UIMainCityView:UpdateSprintPower()
    --部分地图无法使用轻功，不显示气力值
    local tbMapParams = MapHelper.GetMapParams()

    if self.bInFaceState then
        UIHelper.SetVisible(self.WidgetMiddleQLi, false)
        return
    end

    if not tbMapParams.bCanSprint then
        UIHelper.SetVisible(self.WidgetMiddleQLi, false)
        return
    end

    --2024.1.23 吃鸡战场不显示气力条
    if MapHelper.GetBattleFieldType() == BATTLEFIELD_MAP_TYPE.TREASUREBATTLE then
        UIHelper.SetVisible(self.WidgetMiddleQLi, false)
        return
    end

    local player = GetClientPlayer()
    if not player then
        UIHelper.SetVisible(self.WidgetMiddleQLi, false)
        return
    end

    --进战或载具，不显示气力
    if (not player.bSprintFlag and player.bFightState) or player.dwShapeShiftID ~= 0 then
        UIHelper.SetVisible(self.WidgetMiddleQLi, false)
        return
    end

    local function _formatSprintPower(nSprintPower, nSprintPowerMax)
        --显示数值=math.floor(数值/100)
        return math.floor(nSprintPower / 100) .. "/" .. math.floor(nSprintPowerMax / 100)
    end

    local bOnHorse = player.bOnHorse
    local nSprintPower = player.nSprintPower
    local nSprintPowerMax = player.nSprintPowerMax
    local nHorseSprintPower = player.nHorseSprintPower
    local nHorseSprintPowerMax = player.nHorseSprintPowerMax
    local bShowSprintPowerValue = GameSettingData.GetNewValue(UISettingKey.ShowSprintEnergyValue)

    local nSprintRatio = 0
    local nHorseSprintRatio = 0
    if nSprintPower < nSprintPowerMax or (bOnHorse and nHorseSprintPower < nHorseSprintPowerMax) then
        if nSprintPower >= 0 and nSprintPowerMax ~= 0 then
            nSprintRatio = nSprintPower / nSprintPowerMax
        end
        if nHorseSprintPower >= 0 and nHorseSprintPowerMax ~= 0 then
            nHorseSprintRatio = nHorseSprintPower / nHorseSprintPowerMax
        end

        UIHelper.SetVisible(self.WidgetMiddleQLi, true)
        UIHelper.SetVisible(self.WidgetQiLi, not bOnHorse)
        UIHelper.SetVisible(self.WidgetQiMaQiLi, bOnHorse)
        UIHelper.SetVisible(self.LabelQiLi, bShowSprintPowerValue)

        if not bOnHorse then
            if bShowSprintPowerValue then
                local szSprintPower = _formatSprintPower(nSprintPower, nSprintPowerMax)
                UIHelper.SetString(self.LabelQiLi, szSprintPower)
            end

            local bShowRed = nSprintRatio <= 0.2
            if bShowRed and not UIHelper.GetVisible(self.ImgQiLiRedBg) then
                --教学 轻功气力值低
                FireHelpEvent("OnSprintLow")
            end
            UIHelper.SetVisible(self.ImgQiLiBg, not bShowRed)
            UIHelper.SetVisible(self.ImgQiLiRedBg, bShowRed) --气力值少切换为显示红条

            if bShowRed then
                UIHelper.SetProgressBarPercent(self.SliderQiLiRed, nSprintRatio * 100)
            else
                UIHelper.SetProgressBarPercent(self.SliderQiLi, nSprintRatio * 100)
            end
        else
            --骑马
            if bShowSprintPowerValue then
                local szHorseSprintPower = _formatSprintPower(nHorseSprintPower, nHorseSprintPowerMax)
                UIHelper.SetString(self.LabelQiLi, szHorseSprintPower)
            end

            local bShowRed = nHorseSprintRatio <= 0.25
            UIHelper.SetVisible(self.ImgQiMaQiLiBg, not bShowRed)
            UIHelper.SetVisible(self.ImgQiMaQiLiRedBg, bShowRed) --气力值少切换为显示红条

            UIHelper.SetProgressBarPercent(self.SliderQiMaQiLi2, nSprintRatio * 100) --人气力
            if bShowRed then
                UIHelper.SetProgressBarPercent(self.SliderQiMaQiLiRed, nHorseSprintRatio * 100) --马气力 红
            else
                UIHelper.SetProgressBarPercent(self.SliderQiMaQiLi, nHorseSprintRatio * 100) --马气力
            end
        end
    else
        UIHelper.SetVisible(self.WidgetMiddleQLi, false)
    end

end

function UIMainCityView:UpdateSprintTips(tbAction)
    Timer.DelTimer(self, self.nSprintTipsTimerID)
    if not tbAction then
        UIHelper.SetVisible(self.WidgetQiLiHint, false)
        return
    end

    local szDesc = tbAction.szDesc
    local nSprintPhase = tbAction.nSprintPhase
    local nSprintMaxPhase = tbAction.nSprintMaxPhase
    local bDoubleSprint = tbAction.szSprintType == "双人"

    if not szDesc or szDesc == "" then
        UIHelper.SetVisible(self.WidgetQiLiHint, false)
        return
    end

    UIHelper.SetVisible(self.WidgetQiLiHint, true)
    UIHelper.SetString(self.LabelQiLiHint, szDesc)
    UIHelper.StopAni(self, self.WidgetQiLiHint, "AniQiLiHintShow")
    UIHelper.PlayAni(self, self.WidgetQiLiHint, "AniQiLiHintShow")
    if nSprintPhase and nSprintMaxPhase then
        UIHelper.SetVisible(self.ImgQiLiSolo, not bDoubleSprint)
        UIHelper.SetVisible(self.ImgQiLiDouble, bDoubleSprint)
        local slider = bDoubleSprint and self.SliderQiLiDouble or self.SliderQiLiSolo
        local label = bDoubleSprint and self.LabelQiLiDouble or self.LabelQiLiSolo
        local nPercent = nSprintMaxPhase > 0 and 100 * nSprintPhase / nSprintMaxPhase or 100
        UIHelper.SetProgressBarPercent(slider, nPercent)
        UIHelper.SetString(label, nSprintPhase .. "/" .. nSprintMaxPhase)
        UIHelper.SetVisible(label, nSprintMaxPhase > 1)
    else
        UIHelper.SetVisible(self.ImgQiLiSolo, false)
        UIHelper.SetVisible(self.ImgQiLiDouble, false)
    end

    self.nSprintTipsTimerID = Timer.Add(self, SprintData.nSprintTipsShowTime, function()
        UIHelper.SetVisible(self.WidgetQiLiHint, false)
    end)
end

function UIMainCityView:UpdateFuncSlotState(bSprint)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if bSprint == nil then
        bSprint = SprintData.GetViewState()
    end

    local bCanCastSkill = QTEMgr.CanCastSkill()
    local bHorseDynamic = QTEMgr.IsHorseDynamic()

    UIHelper.SetVisible(self.scriptFuncSlot._rootNode, ((bSprint and bHorseDynamic) or (bSprint and bCanCastSkill)) and not JiangHuData.bIsArtist)
end

--根据玩法类型决定界面上需要显示哪些元素
function UIMainCityView:UpdateElementVisible()
    --部分地图无法使用轻功，不显示气力值
    local tbMapParams = MapHelper.GetMapParams()
    UIHelper.SetVisible(self.WidgetMiddleQLi, tbMapParams.bCanSprint and (not self.bInFaceState))

    local nBattleFieldType = MapHelper.GetBattleFieldType()
    local bIsInActivityTime, bIsInActivityMap = CampData.IsInActivity()
    local bIsInPvpMap = MapHelper.IsRemotePvpMap()
    local bInCampWar = (bIsInActivityTime and bIsInActivityMap and g_pClientPlayer and g_pClientPlayer.nCamp ~= CAMP.NEUTRAL) or bIsInPvpMap
    self.bCampRightTopState = false

    if self.scriptPvpRightTop and nBattleFieldType ~= BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE then
        UIHelper.RemoveFromParent(self.scriptPvpRightTop._rootNode, true)
        self.scriptPvpRightTop = nil
    end

    if nBattleFieldType then
        if nBattleFieldType ~= BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE then
            self:SetupScriptPvpRightTop(PlayType.BattleField, nBattleFieldType)
        end
        self.scriptRightTopInfo:SetVisible(false)
        self.scriptMainInfo:SetVisible(false)
        if self.scriptPvpRightTop then
            self.scriptPvpRightTop:SetVisible(true)
        end
    elseif ArenaData.IsInArena() then
        self:SetupScriptPvpRightTop(PlayType.Arena)
        self.scriptRightTopInfo:SetVisible(false)
        self.scriptMainInfo:SetVisible(false)
        if self.scriptPvpRightTop then
            self.scriptPvpRightTop:SetVisible(true)
        end
    elseif bInCampWar then
        self:SwitchCampRightTopState(true)
    elseif ActivityData.IsJingHuaMap() then --镜花梦影
        self:SetupScriptPvpRightTop(PlayType.JingHua)
        self.scriptRightTopInfo:SetVisible(false)
        self.scriptMainInfo:SetVisible(false)
        if self.scriptPvpRightTop then
            self.scriptPvpRightTop:SetVisible(true)
        end
    else
        self.scriptRightTopInfo:SetVisible(true)
        self.scriptMainInfo:SetVisible(true)
        if self.scriptPvpRightTop then
            self.scriptPvpRightTop:SetVisible(false)
        end
    end

    -- 根据本次启动客户端后的配置，决定是否显示共鸣组件
    local bShowMorph = PartnerData.bShowMorphInMainCity
    -- UIHelper.SetVisible(self.WidgetPartner, bShowMorph)
    if bShowMorph then
        self.scriptWidgetMainCityActionBar:AddPartNer()
    else
        self.scriptWidgetMainCityActionBar:ExitPartNer()
    end

    self:UpdateJoystickState()
end

--设置右上角pvp script
function UIMainCityView:SetupScriptPvpRightTop(nPlayType, nSubType, tbArgs, bForceEnter)
    self.scriptPvpRightTop = self.scriptPvpRightTop or UIHelper.AddPrefab(PREFAB_ID.WidgetPvpRightTop, self.WidgetRightTopAnchor)
    if bForceEnter or (self.scriptPvpRightTop.nPlayType ~= nPlayType or self.scriptPvpRightTop.nSubType ~= nSubType) then
        self.scriptPvpRightTop:OnEnter(nPlayType, nSubType, tbArgs)
    end
end

function UIMainCityView:SwitchCampRightTopState(bOpen, bWithTips)
    self.bCampRightTopState = bOpen
    if bOpen then
        self:SetupScriptPvpRightTop(PlayType.CampWar)
    end
    self.scriptRightTopInfo:SetVisible(not bOpen)
    self.scriptMainInfo:SetVisible(not bOpen)
    if self.scriptPvpRightTop then
        self.scriptPvpRightTop:SetVisible(bOpen)
        if bOpen then
            self.scriptPvpRightTop:UpdateMapSize()
        end
    end

    if bWithTips then
        local szTip
        if bOpen then
            local bIsInPvpMap = MapHelper.IsRemotePvpMap()
            if bIsInPvpMap then
                szTip = "主界面右上区域已切换为阵营状态"
            else
                szTip = "主界面右上区域已切换为攻防状态"
            end
        else
            szTip = "主界面右上区域已切换为常规状态"
        end
        TipsHelper.ShowNormalTip(szTip)
    end
end

function UIMainCityView:GetCampRightTopState()
    return self.bCampRightTopState
end

function UIMainCityView:OnSetBottomRightAnchorVisible(bVisible)
    if self.nCheckRightBottomVisibleTimerID then
        Timer.DelTimer(self, self.nCheckRightBottomVisibleTimerID)
        self.nCheckRightBottomVisibleTimerID = nil
    end

    if UIMgr.IsViewOpened(VIEW_ID.PanelPostBattleOperation) and bVisible then
        return
    end

    LOG.WARN("---1----UIMainCityView:OnSetBottomRightAnchorVisible bVisible:%s", tostring(bVisible))
    if g_pClientPlayer and g_pClientPlayer.dwForceID ~= 1 then
        LOG.WARN("---2----UIMainCityView:OnSetBottomRightAnchorVisible bVisible:%s", tostring(bVisible))
        ---少林不隐藏技能
        --UIHelper.SetVisible(self.WidgetRightBottomAnchor, bVisible)

        UIHelper.SetVisible(self.scriptSkill.WidgetSkill, bVisible)
        UIHelper.SetVisible(self.scriptSkill.WidgetMobaShop, bVisible or BattleFieldData.IsInMobaBattleFieldMap())

        UIHelper.SetVisible(self.scriptFuncSlot.WidgetRightBottonFunctionSlot, bVisible)
    elseif not g_pClientPlayer then
        LOG.WARN("---3----UIMainCityView:OnSetBottomRightAnchorVisible bVisible:%s", tostring(bVisible))
        self.nCheckRightBottomVisibleTimerID = Timer.Add(self, 1, function()
            self:OnSetBottomRightAnchorVisible(bVisible)
        end)
    end
end

function UIMainCityView:UpdateExtraUIState()
    if self.bCustomState then
        return
    end
    local nMode = self.nLastMode or Storage.ControlMode.nMode
    local bQuickUseVisible = nMode == MAIN_CITY_CONTROL_MODE.CLASSIC -- and self.scriptSkill and self.scriptSkill.bWidgetQuickUseVisible or false
    local bQuickUseVisible2 = nMode == MAIN_CITY_CONTROL_MODE.SIMPLE -- and self.scriptSkill and self.scriptSkill.bWidgetQuickUseVisible or false
    UIHelper.SetVisible(self.WidgetQuickUse, bQuickUseVisible)
    UIHelper.SetVisible(self.WidgetQuickUse2, bQuickUseVisible2)
end

local function IsSkillTextVisible(dwCasterID, dwTargetID, nDamageType, szHint)
    if BahuangData.IsInBaHuangMap() and BahuangData.IsHideSkillText() then
        return false
    end
    local nBattleInfo
    if PlayerData.IsMeOrMyEmployee(dwCasterID) then
        nBattleInfo = BATTLE_INFO.ACTIVE_ATTACK
    elseif PlayerData.IsMeOrMyEmployee(dwTargetID) then
        nBattleInfo = BATTLE_INFO.DAMAGED
    else
        return false
    end
    if nDamageType then
        if nDamageType == SKILL_RESULT_TYPE.PHYSICS_DAMAGE
            or nDamageType == SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE
            or nDamageType == SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE
            or nDamageType == SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE
            or nDamageType == SKILL_RESULT_TYPE.POISON_DAMAGE
            or nDamageType == SKILL_RESULT_TYPE.REFLECTIED_DAMAGE then
            return GetGameSetting(SettingCategory.BattleInfo, nBattleInfo, "伤害值")
        end
        if nDamageType == SKILL_RESULT_TYPE.THERAPY
            or nDamageType == SKILL_RESULT_TYPE.STEAL_LIFE then
            return GetGameSetting(SettingCategory.BattleInfo, nBattleInfo, "治疗值")
        end
        if nDamageType == SKILL_RESULT_TYPE.ABSORB_DAMAGE or
                nDamageType == SKILL_RESULT_TYPE.ABSORB_THERAPY then
            return GetGameSetting(SettingCategory.BattleInfo, nBattleInfo, "化解")
        end
        if nDamageType == SKILL_RESULT_TYPE.PARRY_DAMAGE then
            return GetGameSetting(SettingCategory.BattleInfo, nBattleInfo, "拆招")
        end
    end
    if szHint then
        return GetGameSetting(SettingCategory.BattleInfo, nBattleInfo, szHint)
    end
    return false
end

function UIMainCityView:UpdateCombatStateText(dwCasterID, dwTargetID, szEvent)
    --print(dwCasterID, dwTargetID, szEvent)
    if not IsSkillTextVisible(dwCasterID, dwTargetID, false, szEvent) then
        return
    end
    local script = self:GetBleedScript(PREFAB_ID.WidgetBleedHint)
    script:UpdateCombatStateInfo(dwCasterID, dwTargetID, szEvent, function()
        Timer.DelTimer(script, script.nBleedTimerID)
        script.nBleedTimerID = Timer.Add(script, 60, function()
            self:ReleaseOneBleedPrefab(script)
        end)
    end)
end

function UIMainCityView:UpdateSkillEffectText(dwCasterID, dwTargetID, bCriticalStrike, nDamageType, nDamage, dwSkillID, dwLevel, nEffectType)
    --print(dwCasterID, dwTargetID, bCriticalStrike, nDamageType, nDamage, dwSkillID, dwLevel, nEffectType)
    if not IsSkillTextVisible(dwCasterID, dwTargetID, nDamageType, false) then
        return
    end

    if bCriticalStrike then
        local script = self:GetBleedScript(PREFAB_ID.WidgetBleedWhiteCritical)
        script:UpdateCriticalInfo(dwCasterID, dwTargetID, nDamageType, nDamage, dwSkillID, dwLevel, nEffectType, function()
            Timer.DelTimer(script, script.nBleedTimerID)
            script.nBleedTimerID = Timer.Add(script, 60, function()
                self:ReleaseOneBleedPrefab(script)
            end)
        end)
    else
        local script = self:GetBleedScript(PREFAB_ID.WidgetBleedWhiteNormal)
        script:UpdateInfo(dwCasterID, dwTargetID, nDamageType, nDamage, dwSkillID, dwLevel, nEffectType, function()
            Timer.DelTimer(script, script.nBleedTimerID)
            script.nBleedTimerID = Timer.Add(script, 60, function()
                self:ReleaseOneBleedPrefab(script)
            end)
        end)
    end
end

function UIMainCityView:UpdateSpiritEnduranceText(dwCasterID, dwTargetID, bSpirit, nDelta)
    if not MonsterBookData.bIsPlaying then
        return
    end

    local script = self:GetBleedScript(PREFAB_ID.WidgetBleedWhiteNormal)
    script.bDebugMark = true
    script:UpdateSpiritEnduranceInfo(dwCasterID, dwTargetID, bSpirit, nDelta, function()
        Timer.DelTimer(script, script.nBleedTimerID)
        script.nBleedTimerID = Timer.Add(script, 60, function()
            self:ReleaseOneBleedPrefab(script)
        end)
    end)
end

function UIMainCityView:UpdateHealthText(dwTargetID, nDeltaLife)
    local nPlayerID = g_pClientPlayer and g_pClientPlayer.dwID or -1
    if dwTargetID ~= nPlayerID then
        return
    end
    local nDamageType = SKILL_RESULT_TYPE.THERAPY
    if nDeltaLife == 0 then
        return
    elseif nDeltaLife < 0 then
        nDamageType = -1
        --nDeltaLife = -nDeltaLife
    end
    --if not IsSkillTextVisible(-2, dwTargetID, nDamageType, false) then
    --    return
    --end

    local script = self:GetBleedScript(PREFAB_ID.WidgetBleedWhiteNormal)
    script:UpdateHealthInfo(dwTargetID, nDeltaLife, nDamageType, function()
        Timer.DelTimer(script, script.nBleedTimerID)
        script.nBleedTimerID = Timer.Add(script, 60, function()
            self:ReleaseOneBleedPrefab(script)
        end)
    end)
end

-- 头顶文字
function UIMainCityView:UpdateCharacterHeadTip(dwCharacterID, szTip, szParam, tColor)
    local script = self:GetBleedScript(PREFAB_ID.WidgetBleedHint)
    script:UpdateCharacterHeadTip(dwCharacterID, szTip, szParam, tColor, function()
        Timer.DelTimer(script, script.nBleedTimerID)
        script.nBleedTimerID = Timer.Add(script, 60, function()
            self:ReleaseOneBleedPrefab(script)
        end)
    end)
end

function UIMainCityView:UpdateExpBar()
    local player = PlayerData.GetClientPlayer()
    local nLevel = PlayerData.GetPlayerLevel(player)
    local nCurExp = PlayerData.GetPlayerExperience(player)
    local nRoleType = PlayerData.GetPlayerRoleType(player)

    local tbLevelUP = GetLevelUpData(nRoleType, nLevel)
    local nMaxExp = tbLevelUP['Experience']

    UIHelper.SetProgressBarPercent(self.SliderExp, 100 * nCurExp / nMaxExp)
end

function UIMainCityView:UpdateJoystickState()
    local bAimMode = CameraMgr.CheckAimMode()

    --载具瞄准状态下不显示摇杆
    UIHelper.SetVisible(self.scriptJoyStick._rootNode, not bAimMode)
end

-- ===========================================================================
-- 左侧信息显示区域
-- ===========================================================================

--是否存在Item
function UIMainCityView:HasWidgetItem(szKey)
    return self.scriptTaskTeam:HasWidgetItem(szKey)
end

--当前正在实际显示的Item的key
function UIMainCityView:GetCurWidgetItem()
    return self.scriptTaskTeam:GetCurWidgetItem()
end

--当前正在优先显示的Item的key
function UIMainCityView:GetPriorityWidgetItem()
    return self.scriptTaskTeam:GetPriorityWidgetItem()
end



-- ===========================================================================
-- 动画
-- ===========================================================================
function UIMainCityView:PlayShow(callback)
    self:PlayLeftShow(callback)
    self:PlayRightShow()
    self:PlayBottomShow()
    self:PlayMiddleShow()
    self:PlayOtherShow()
end

function UIMainCityView:PlayHide(callback)
    self:PlayLeftHide(callback)
    self:PlayRightHide()
    self:PlayBottomHide()
    self:PlayMiddleHide()
    self:PlayOtherHide()
end

function UIMainCityView:PlayLeftShow(callback)
    self.nLeftAnimCount = self.nLeftAnimCount - 1

    if self.bAnimShowLeftIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nLeftAnimCount > 0 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimShowLeftIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniLeftShow")
    UIHelper.StopAni(self, self.AniAll, "AniLeftHide")
    UIHelper.PlayAni(self, self.AniAll, "AniLeftShow", function()
        Lib.SafeCall(callback)
        self.bAnimShowLeftIsPlaying = false
    end)
end

function UIMainCityView:PlayLeftHide(callback)
    self.nLeftAnimCount = self.nLeftAnimCount + 1

    if self.bAnimHideLeftIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nLeftAnimCount > 1 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimHideLeftIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniLeftShow")
    UIHelper.StopAni(self, self.AniAll, "AniLeftHide")
    UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function()
        Lib.SafeCall(callback)
        self.bAnimHideLeftIsPlaying = false
    end)
end

function UIMainCityView:PlayRightShow(callback)
    self.nRightAnimCount = self.nRightAnimCount - 1

    if self.bAnimShowRightIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nRightAnimCount > 0 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimShowRightIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniRightShow")
    UIHelper.StopAni(self, self.AniAll, "AniRightHide")
    UIHelper.PlayAni(self, self.AniAll, "AniRightShow", function()
        Lib.SafeCall(callback)
        self.bAnimShowRightIsPlaying = false
    end)
end

function UIMainCityView:PlayRightHide(callback)
    self.nRightAnimCount = self.nRightAnimCount + 1

    if self.bAnimHideRightIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nRightAnimCount > 1 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimHideRightIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniRightShow")
    UIHelper.StopAni(self, self.AniAll, "AniRightHide")
    UIHelper.PlayAni(self, self.AniAll, "AniRightHide", function()
        Lib.SafeCall(callback)
        self.bAnimHideRightIsPlaying = false
    end)
end

function UIMainCityView:PlayBottomShow(callback)
    self.nBottomAnimCount = self.nBottomAnimCount - 1

    if self.bAnimShowBottomIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nBottomAnimCount > 0 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimShowBottomIsPlaying = true
    UIHelper.StopAni(self, self.AniAll, "AniBottomShow")
    UIHelper.StopAni(self, self.AniAll, "AniBottomHide")
    UIHelper.PlayAni(self, self.AniAll, "AniBottomShow", function()
        Lib.SafeCall(callback)
        self.bAnimShowBottomIsPlaying = false
    end)
end

function UIMainCityView:PlayBottomHide(callback)
    self.nBottomAnimCount = self.nBottomAnimCount + 1

    if self.bAnimHideBottomIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nBottomAnimCount > 1 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimHideBottomIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniBottomShow")
    UIHelper.StopAni(self, self.AniAll, "AniBottomHide")
    UIHelper.PlayAni(self, self.AniAll, "AniBottomHide", function()
        Lib.SafeCall(callback)
        self.bAnimHideBottomIsPlaying = false
    end)
end

function UIMainCityView:PlayMiddleShow(callback)
    self.nMiddleAnimCount = self.nMiddleAnimCount - 1

    if self.bAnimShowMiddleIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nMiddleAnimCount > 0 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimShowMiddleIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniMiddleInfoShow")
    UIHelper.StopAni(self, self.AniAll, "AniMiddleInfoHide")
    UIHelper.PlayAni(self, self.AniAll, "AniMiddleInfoShow", function()
        Lib.SafeCall(callback)
        self.bAnimShowMiddleIsPlaying = false
    end)
end

function UIMainCityView:PlayMiddleHide(callback)
    self.nMiddleAnimCount = self.nMiddleAnimCount + 1

    if self.bAnimHideMiddleIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nMiddleAnimCount > 1 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimHideMiddleIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniMiddleInfoShow")
    UIHelper.StopAni(self, self.AniAll, "AniMiddleInfoHide")
    UIHelper.PlayAni(self, self.AniAll, "AniMiddleInfoHide", function()
        Lib.SafeCall(callback)
        self.bAnimHideMiddleIsPlaying = false
    end)
end

function UIMainCityView:PlayFullScreenShow(callback)
    self.nFullScreenAnimCount = self.nFullScreenAnimCount - 1

    if self.bAnimShowFullScreenIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nFullScreenAnimCount > 0 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimShowFullScreenIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniFullScreenHide")
    UIHelper.StopAni(self, self.AniAll, "AniFullScreenShow")
    UIHelper.PlayAni(self, self.AniAll, "AniFullScreenShow", function()
        Lib.SafeCall(callback)
        self.bAnimShowFullScreenIsPlaying = false
    end)
end

function UIMainCityView:PlayFullScreenHide(callback)
    self.nFullScreenAnimCount = self.nFullScreenAnimCount + 1

    if self.bAnimHideFullScreenIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nFullScreenAnimCount > 1 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimHideFullScreenIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniFullScreenShow")
    UIHelper.StopAni(self, self.AniAll, "AniFullScreenHide")
    UIHelper.PlayAni(self, self.AniAll, "AniFullScreenHide", function()
        Lib.SafeCall(callback)
        self.bAnimHideFullScreenIsPlaying = false
    end)
end

function UIMainCityView:PlayOtherShow(callback)
    self.nOtherAnimCount = self.nOtherAnimCount - 1

    if self.bAnimShowOtherIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nOtherAnimCount > 0 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimShowOtherIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniFullShow")
    UIHelper.StopAni(self, self.AniAll, "AniFullHide")
    UIHelper.PlayAni(self, self.AniAll, "AniFullShow", function()
        Lib.SafeCall(callback)
        self.bAnimShowOtherIsPlaying = false
    end)
end

function UIMainCityView:PlayOtherHide(callback)
    self.nOtherAnimCount = self.nOtherAnimCount + 1

    if self.bAnimHideOtherIsPlaying then
        Lib.SafeCall(callback)
        return
    end

    if self.nOtherAnimCount > 1 then
        Lib.SafeCall(callback)
        return
    end

    self.bAnimHideOtherIsPlaying = true

    UIHelper.StopAni(self, self.AniAll, "AniFullShow")
    UIHelper.StopAni(self, self.AniAll, "AniFullHide")
    UIHelper.PlayAni(self, self.AniAll, "AniFullHide", function()
        Lib.SafeCall(callback)
        self.bAnimHideOtherIsPlaying = false
    end)
end


function UIMainCityView:ShowBiaoshiPop(tGuradList)
    if JiangHuData.bConflictPageExist == true then
        return
    end
    JiangHuData.bFirstListOpen = false
    if JiangHuData.scriptBiaoShi then
        JiangHuData.scriptBiaoShi:OnEnter(tGuradList)
    else
        JiangHuData.scriptBiaoShi = UIHelper.AddPrefab(PREFAB_ID.WidgetBiaoShiPop, self.WidgetGiftPop, tGuradList)
    end
end

function UIMainCityView:HideBiaoshiPop()
    if JiangHuData.scriptBiaoShi then
        UIHelper.RemoveFromParent(JiangHuData.scriptBiaoShi._rootNode)
        JiangHuData.scriptBiaoShi = nil
    end
end

function UIMainCityView:ShowHuBiaoPop(dwID, szName, nCount, nCurValue, nMaxValue)
    if JiangHuData.scriptHuBiao then
        JiangHuData.scriptHuBiao:OnEnter(dwID, szName, nCount, nCurValue, nMaxValue)
    else
        JiangHuData.scriptHuBiao = UIHelper.AddPrefab(PREFAB_ID.WidgetHuBiaoPop, self.WidgetGiftPop, dwID, szName, nCount, nCurValue, nMaxValue)
    end
end

function UIMainCityView:HideHuBiaoPop()
    if JiangHuData.scriptHuBiao then
        UIHelper.RemoveFromParent(JiangHuData.scriptHuBiao._rootNode)
        JiangHuData.scriptHuBiao = nil
    end
end

-- ===========================================================================
-- 身份
-- ===========================================================================


function UIMainCityView:SwitchIdentitySkills(bEnter)
    if bEnter then
        self.scriptWidgetMainCityActionBar:AddDynamicSkill(false)
    else
        self.scriptWidgetMainCityActionBar:ExitDynamicSkill(false)
    end
end


-- ===========================================================================
-- 动态技能
-- ===========================================================================

function UIMainCityView:UpdateDynamicState()
    if QTEMgr.IsInDynamicSkillState() then
        self:SwitchDynamicSkills(true, QTEMgr.GetCurGroupID())
    end
end

function UIMainCityView:SwitchDynamicSkills(bEnter, nGroupID)
    if bEnter then
        local bCanCastSkill = QTEMgr.CanCastSkill()
        local bHorseDynamic = QTEMgr.IsHorseDynamic(nGroupID)
        if bHorseDynamic then
            if self.bInCanCastDynamicSkills then
                self:SwitchCanCastDynamicSkills(false)
            end
        elseif bCanCastSkill then
            self:SwitchCanCastDynamicSkills(true, nGroupID)
        else
            if UIMgr.IsViewVisible(VIEW_ID.PanelQuickOperation) then
                UIMgr.Close(VIEW_ID.PanelQuickOperation)
            end
            if self.bInCanCastDynamicSkills then
                self:SwitchCanCastDynamicSkills(false)
            end
        end
    else
        if self.bInCanCastDynamicSkills then
            self:SwitchCanCastDynamicSkills(false)
        end
    end
    Event.Dispatch(EventType.OnHideSkillCancel)
end

function UIMainCityView:PlayEnterDynamicAnim()
    UIHelper.PlayAni(self, self.AniAll, "AniRightBottomHide", function()
        UIHelper.PlayAni(self, self.AniAll, "AniRightBottomShow")
    end)
end

function UIMainCityView:GetSkillCanCelScript()
    if self.scriptSkill then
        return self.scriptSkill:GetSkillCanCelScript()
    end
    return nil
end

function UIMainCityView:GetSkillDirectionScript()
    if self.scriptSkill then
        return self.scriptSkill:GetSKillDirectionScript()
    end
    return nil
end

function UIMainCityView:SwitchCanCastDynamicSkills(bEnter, nGroupID)
    self.bInCanCastDynamicSkills = bEnter
    if bEnter then
        self.scriptWidgetMainCityActionBar:AddDynamicSkill(true)
    else
        self.scriptWidgetMainCityActionBar:ExitDynamicSkill(true)
    end
end

function UIMainCityView:SwitchQuickUseTip(nX, nY)
    if self.QuickUseScript and UIHelper.GetVisible(self.QuickUseScript._rootNode) then
        self:TryCloseQuickUseTip()
    else
        self:OpenQuickUseTip(nX, nY)
    end
end

function UIMainCityView:OpenQuickUseTip(nX, nY)
    --UIHelper.SetVisible(self.BtnQuickUseBg, true)
    --UIHelper.SetVisible(self.BtnQuickUseBg2, true)

    self.QuickUseScript = self.QuickUseScript or UIHelper.AddPrefab(PREFAB_ID.WidgetQuickUsedTip, self.WidgetQuickUseTips1)
    local tips = HoverTips.New(self.QuickUseScript._rootNode)
    tips:Show(nX, nY)
    self.QuickUseScript:TrySetVisible(true)
end

function UIMainCityView:TryCloseQuickUseTip()
    if self.QuickUseScript then
        local bTipsState = self.QuickUseScript:GetItemTipsState()
        if bTipsState then
            self.QuickUseScript:SetItemTipsState(false)
        else
            self.QuickUseScript:TrySetVisible(false)
        end
    end
end

function UIMainCityView:GetBleedScript(nPrefabID)
    if not self.tbBleedMap then self.tbBleedMap = {} end
    if not self.tbBleedMap[nPrefabID] then self.tbBleedMap[nPrefabID] = {} end
    local nMax = tbBleedMaxMap[nPrefabID]
    local nCount = #self.tbBleedMap[nPrefabID]

    local script = nil

    if nCount < nMax then
        -- 如果没有超过，就先从之前创建了并且播放完动画的里面去找
        for i = 1, nCount do
            local tmpScript = self.tbBleedMap[nPrefabID][i]
            if tmpScript and not tmpScript.bIsPlaying then
                script = tmpScript
                table.remove(self.tbBleedMap[nPrefabID], i)
                break
            end
        end

        -- 如果都在播动画，那就直接创建一个
        if not script then
            script = UIHelper.AddPrefab(nPrefabID, self.WidgetBleedAnchor)
        end
    else
        -- 如果超了，就将前面的拿出来，再放到后面去
        script = table.remove(self.tbBleedMap[nPrefabID], 1)

        if script then
            UIHelper.StopAllActions(script._rootNode)
            UIHelper.SetVisible(script._rootNode, false)
        end
    end

    Timer.DelTimer(script, script.nBleedTimerID)
    table.insert(self.tbBleedMap[nPrefabID], script)

    return script
end

function UIMainCityView:ReleaseOneBleedPrefab(script)
    if not self.tbBleedMap then return end
    if not script then return end

    local nPrefabID = script._nPrefabID
    if not nPrefabID then return end
    if not self.tbBleedMap[nPrefabID] then return end

    for k, v in ipairs(self.tbBleedMap[nPrefabID] or {}) do
        if v._rootNode == script._rootNode then
            table.remove(self.tbBleedMap[nPrefabID], k)
            UIHelper.RemoveFromParent(script._rootNode)
            break
        end
    end
end

function UIMainCityView:ReleaseAllBleedPrefab()
    if not self.tbBleedMap then return end

    for nPrefabID, tbScriptList in pairs(self.tbBleedMap) do
        for k, script in ipairs(tbScriptList or {}) do
            if script then
                UIHelper.RemoveFromParent(script._rootNode)
            end
        end
    end

    self.tbBleedMap = nil
end

function UIMainCityView:UpdateBtnQuickUseVisible()
    local bTreasureBF = BattleFieldData.IsInTreasureBattleFieldMap()
    --UIHelper.SetVisible(self.BtnQuickUse, g_pClientPlayer.nLevel >= 102 and not bTreasureBF)
    UIHelper.SetVisible(self.tbWidgetQuickUseList[Storage.ControlMode.nMode], g_pClientPlayer.nLevel >= 102 and not bTreasureBF)
end

function UIMainCityView:UpdateNodeScale()
    local nDevice = MainCityCustomData.GetDeviceType()
    local tbSizeClassicInfo = Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.CLASSIC]
    local tbSizeSimpleInfo = Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.SIMPLE]
    local tbNodeList = {
        ["nMap"] = {self.WidgetRightTopAnchor, self.WidgetRightTopMapCopy},
        ["nSkill"] = {self.WidgetRightBottomAnchor, self.WidgetRightBottomSkillCopy},
        ["nChat"] = {self.tbWidgetChatMiniList[1], self.tbWidgetChatMiniList[2], self.tbCustomChatList[1], self.tbCustomChatList[2]},
        ["nLeftBottom"] = {self.tbWidgetLeftBottonList[1], self.tbWidgetLeftBottonList[2], self.tbCustomLeftBottonList[1], self.tbCustomLeftBottonList[2]},
        ["nQuickuse"] = {self.tbWidgetQuickUseList[1], self.tbWidgetQuickUseList[2], self.tbCustomQuickUseList[1], self.tbCustomQuickUseList[2]},
        ["nBuff"] = {self.tbWidgetPlayerBuffList[1], self.tbWidgetPlayerBuffList[2], self.tbCustomPlayerBuffList[1], self.tbCustomPlayerBuffList[2]},
        ["nPlayer"] = {self.tbWidgetPlayerInfoAnchorList[1], self.tbWidgetPlayerInfoAnchorList[2], self.tbCustomPlayerInfoAnchorList[1], self.tbCustomPlayerInfoAnchorList[2]},
        ["nTarget"] = {self.WidgetTargetInfoAnchorCopy, self.WidgetTargetInfoAnchor},
        ["nTeam"] = {self.BtnClassicSelectZone, self.BtnSimpleSelectZone},
        ["nEnergyBar"] = {self.WidgetSkillEnergyBar, self.WidgetSkillEnergyBarCopy},
        ["nSpecialSkillBuff"] = {self.WidgetSpecialSkillBuff, self.WidgetSpecialSkillBuffCopy},
        ["nDxSkill"] = {self.WidgetRightBottomAnchor, self.WidgetRightBottomSkillCopy},
        ["nKillFeed"] = {self.WidgetMainCityKillFeed, self.WidgetMainCityKillFeedCopy},
    }

    MainCityCustomData.UpdateFontSizeTabByOverLap(self)
    local tbDefaultClassic = TabHelper.GetUIFontSizeTab(DEVICE_NAME[nDevice], MAIN_CITY_CONTROL_MODE.CLASSIC)
    local tbDefaultSimple = TabHelper.GetUIFontSizeTab(DEVICE_NAME[nDevice], MAIN_CITY_CONTROL_MODE.SIMPLE)

    for k, nScale in pairs(tbSizeClassicInfo) do
        if nScale == 0 then
            tbSizeClassicInfo[k] = tbDefaultClassic[k]
        end
    end

    for k, nScale in pairs(tbSizeSimpleInfo) do
        if nScale == 0 then
            tbSizeSimpleInfo[k] = tbDefaultSimple[k]
        end
    end

    local szRemoveSkillType = SkillData.IsUsingHDKungFu() and "nSkill" or "nDxSkill"
    tbNodeList[szRemoveSkillType] = nil

    local tbSizeInfo = Storage.ControlMode.nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and tbSizeClassicInfo or Storage.ControlMode.nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and tbSizeSimpleInfo
    --local tbDefaultScale = Storage.ControlMode.nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and tbDefaultClassic or Storage.ControlMode.nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and tbDefaultSimple
    for k, tbNodeInfo in pairs(tbNodeList) do
        local nScale = tbSizeInfo[k] or 1
        for k, node in pairs(tbNodeInfo) do
            UIHelper.SetScale(node, nScale, nScale)
        end
    end
end


function UIMainCityView:UpdateCustomMaincityInfo(nRangeType, nNodeType, nMode, bStart)
    local tbCurNode, tbCurFakeNode = self:GetCustomNodeByType(nNodeType, nMode)
    local tbFakeScript = self:GetFakeScriptByType(nNodeType)
    if not tbFakeScript then
        return
    end
    if bStart then  --点击选中了一个widget
        --显示大小模块提示
        self:ShowNodeSizeSetting(nNodeType)
        --设置当前模块层级
        self:UpdateNodeZOrder(nRangeType, nNodeType, nMode)
        self.nRangeType = nRangeType
        self.nNodeType = nNodeType
        self.nCustomMode = nMode
        local ImgBlackBg = self.tbBlackBgList[nRangeType]
        UIHelper.SetVisible(ImgBlackBg, bStart)

        tbFakeScript:UpdateCustomState()
        if nNodeType == CUSTOM_TYPE.SKILL then
            UIHelper.SetVisible(tbFakeScript.BoxNon1, false)
            UIHelper.SetVisible(tbFakeScript.BoxNon, false)
        end
        UIHelper.SetLocalZOrder(tbFakeScript._rootNode, -1)
        self:UpdateAllNodeOverLappingState(CUSTOM_BTNSTATE.OTHER)
        local fnDragStart = function(nX, nY)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipsFreeSetting)
        end
        local fnDragMoved = function(nX, nY)
            self:UpdateAllNodeOverLappingState(CUSTOM_BTNSTATE.OTHER)
            if nNodeType == CUSTOM_TYPE.SKILL then
                local nWx, nWy = UIHelper.GetWorldPosition(tbCurNode)
                UIHelper.SetWorldPosition(self.WidgetRightBottomAnchor, nWx, nWy)
            end
            self.bPositionChanged = true
            self:SetPositionDefault(nMode, false)
        end
        local fnDragEnd = function(nX, nY)
            --显示大小模块提示
            self:ShowNodeSizeSetting(nNodeType)
            --self.tbFakeNodePosition = self:GetFakeNodePosition(nMode)
            --获得当前编辑节点位置
            local nX, nY = UIHelper.GetWorldPosition(tbCurFakeNode)
            self.tbFakeNodePosition[nNodeType] = {["nX"] = nX, ["nY"] = nY}
        end
        local tbAnchorScript = UIHelper.GetBindScript(tbCurFakeNode)
        UIHelper.SetVisible(tbAnchorScript.BtnSelectZone, true)
        tbAnchorScript:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd, tbCurNode, nNodeType, tbFakeScript)

        if nNodeType == CUSTOM_TYPE.CHAT then
            self:BindChatDragSize(true)
        end
    end

end

function UIMainCityView:UpdateCustomNodePosition(nMode, bEdit, bDefaultPosition)  --更新nmode模式下已保存的位置
    local bDefault = self:GetDefaultPosition(nMode)
    if bDefault or bDefaultPosition then
        self:SetNodePositionDefault(nMode)
        return
    end
    local size = UIHelper.GetCurResolutionSize()
    self:GetCurrentFrameSize(nMode)
    local nWidth = size.width
    local nHeight = size.height
    local nRatioX = nWidth / self.nWidth
    local nRatioY = nHeight / self.nHeight
    local tbPositionInfo = nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and clone(Storage.ControlMode.tbClassicPositionInfo) or nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and clone(Storage.ControlMode.tbSimplePositionInfo)
    if bEdit then   --编辑状态拿当前改分辨率前假节点的位置，而非已保存节点位置
        --tbPositionInfo = self:GetEditStateNodePosition(nMode)
        tbPositionInfo = self.tbFakeNodePosition
        nRatioX = nWidth / tbPositionInfo.nWidth
        nRatioY = nHeight / tbPositionInfo.nHeight
    end
    for k, nNodeType in pairs(CUSTOM_TYPE) do
        local tbNodePosition = tbPositionInfo[nNodeType]
        local tbNode, tbFakeNode = self:GetCustomNodeByType(nNodeType, nMode)
        if tbNodePosition then
            local nNewX = tbNodePosition.nX * nRatioX
            local nNewY = tbNodePosition.nY * nRatioY
            UIHelper.SetWorldPosition(tbNode, nNewX, nNewY)
            UIHelper.SetWorldPosition(tbFakeNode, nNewX, nNewY)
            if bEdit then
                self.tbFakeNodePosition[nNodeType] = {["nX"] = nNewX, ["nY"] = nNewY}
                self.tbFakeNodePosition.nWidth = nWidth
                self.tbFakeNodePosition.nHeight = nHeight
            end
        else
            --假节点刷过去
            local nX, nY = UIHelper.GetWorldPosition(tbNode)
            UIHelper.SetWorldPosition(tbFakeNode, nX * nRatioX, nY * nRatioY)
        end
    end
end

function UIMainCityView:UpdateChatContentSize(nMode, bFromSizeChange, bReSet)
    local scriptChat = self.bCustomState and self:GetFakeScriptByType(CUSTOM_TYPE.CHAT) or self.scriptChat
    if not scriptChat then return end
    if not self.scriptChat and bReSet then return end

    local w, h = self.nChatContentWidth, self.nChatContentHeight

    if not bFromSizeChange then
        local size = Storage.ControlMode.tbChatContentSize[nMode]
        w, h = size.w, size.h
    end

    if not w or not h then
        --Storage.ControlMode.tbChatBtnSelectSize[nMode].nWidth
        --w, h = UIHelper.GetContentSize(UIHelper.GetParent(scriptChat._rootNode))
        w, h = Storage.ControlMode.tbChatBtnSelectSize[nMode].nWidth, Storage.ControlMode.tbChatBtnSelectSize[nMode].nHeigh
    end

    if w and h then
        self.nChatContentWidth = w
        self.nChatContentHeight = h

        UIHelper.SetContentSize(scriptChat._rootNode, w, h)
        UIHelper.WidgetFoceDoAlign(scriptChat)
        if bReSet then
            UIHelper.SetContentSize(self.scriptChat._rootNode, w, h)
            UIHelper.WidgetFoceDoAlign(self.scriptChat)
        end

        if self.bCustomState then
            local tbCurNode, tbCurFakeNode = self:GetCustomNodeByType(CUSTOM_TYPE.CHAT, nMode)
            local tbAnchorScript = UIHelper.GetBindScript(tbCurFakeNode)
            if tbAnchorScript then
                UIHelper.SetContentSize(tbAnchorScript.BtnSelectZone, w, h)
            end
        end
    end

    scriptChat:OnEnter(nMode)
    if bReSet then
        self.scriptChat:OnEnter()
    end
end

function UIMainCityView:ResetChatContentSize(nMode, nNodeType)
    if nNodeType ~= nil and nNodeType ~= CUSTOM_TYPE.CHAT then return end

    Storage.ControlMode.tbChatContentSize[nMode].w = nil
    Storage.ControlMode.tbChatContentSize[nMode].h = nil
    Storage.ControlMode.Flush()

    self:UpdateChatContentSize(nMode, nil, true)
end

function UIMainCityView:SaveChatContentSize()
    local scriptChat = self:GetFakeScriptByType(CUSTOM_TYPE.CHAT)
    if scriptChat then
        local nMode = self.nCustomMode
        local w, h = UIHelper.GetContentSize(scriptChat._rootNode)
        Storage.ControlMode.tbChatContentSize[nMode] = {w = w, h = h}
        Storage.ControlMode.Flush()
    end
end

function UIMainCityView:BindChatDragSize(bBind)
    local nType = CUSTOM_TYPE.CHAT

    local oneScript = self:GetFakeScriptByType(nType)
    if oneScript then
        local btnLong = oneScript.BtnLong
        local btnWide = oneScript.BtnWide

        UIHelper.SetVisible(btnLong, bBind)
        UIHelper.SetVisible(btnWide, bBind)

        local tbCurNode, tbCurFakeNode = self:GetCustomNodeByType(nType, self.nCustomMode)
        local tbAnchorScript = UIHelper.GetBindScript(tbCurFakeNode)
        if tbAnchorScript then
            if bBind then
                local ImgBlackBg = self.tbBlackBgList[CUSTOM_RANGE.CHAT]
                tbAnchorScript:BindDragSize(nType, btnLong, false, oneScript, ImgBlackBg, self.nCustomMode)
                tbAnchorScript:BindDragSize(nType, btnWide, true, oneScript, ImgBlackBg, self.nCustomMode)
            else
                tbAnchorScript:UnBindDragSize(nType, btnLong, false, oneScript)
                tbAnchorScript:UnBindDragSize(nType, btnWide, true, oneScript)
            end
        end
    end
end

function UIMainCityView:InitNodeInfo()
    self.tbFakeNodeList = {
        [CUSTOM_TYPE.PLAYER] = {
            [1] = self.tbCustomPlayerInfoAnchorList,
            [2] = self.tbWidgetPlayerInfoAnchorList
        },
        [CUSTOM_TYPE.CUSTOMBTN] = {
            [1] = self.tbCustomLeftBottonList,
            [2] = self.tbWidgetLeftBottonList,
        },
        [CUSTOM_TYPE.TARGET] = {
            [1] = self.WidgetTargetInfoAnchorCopy,
            [2] = self.WidgetTargetInfoAnchor
        },
        [CUSTOM_TYPE.QUICKUSE] = {
            [1] = self.tbCustomQuickUseList,
            [2] = self.tbWidgetQuickUseList
        },
        [CUSTOM_TYPE.BUFF] = {
            [1] = self.tbCustomPlayerBuffList,
            [2] = self.tbWidgetPlayerBuffList
        },
        [CUSTOM_TYPE.MENU] = {
            [1] = self.WidgetRightTopMapCopy,
            [2] = self.WidgetRightTopAnchor
        },
        [CUSTOM_TYPE.SKILL] = {
            [1] = self.WidgetRightBottomSkillCopy,
            [2] = self.WidgetRightBottomAnchor
        },
        [CUSTOM_TYPE.CHAT] = {
            [1] = self.tbCustomChatList,
            [2] = self.tbWidgetChatMiniList
        },
        [CUSTOM_TYPE.TASK] = {
            [1] = self.tbCustomTaskAnchorList,
            [2] = self.tbWidgetTaskTeamAnchorList
        },
        [CUSTOM_TYPE.ENERGYBAR] = {
            [1] = self.WidgetSkillEnergyBarCopy,
            [2] = self.WidgetSkillEnergyBar
        },
        [CUSTOM_TYPE.SPECIALSKILLBUFF] = {
            [1] = self.WidgetSpecialSkillBuffCopy,
            [2] = self.WidgetSpecialSkillBuff
        },
        [CUSTOM_TYPE.KILL_FEED] = {
            [1] = self.WidgetMainCityKillFeedCopy,
            [2] = self.WidgetMainCityKillFeed
        }
    }
end

function UIMainCityView:CloseNodeCustomState()
    local ImgBlackBg = self.tbBlackBgList[self.nRangeType]
    UIHelper.SetVisible(ImgBlackBg, false)  --关黑背景

    local tbCurFakeNode = nil
    if table.contain_value(tbCommonType, self.nNodeType) then
        tbCurFakeNode = self.tbFakeNodeList[self.nNodeType][1]
        if self.nNodeType == CUSTOM_TYPE.SKILL then
            local tbFakeScript = self:GetFakeScriptByType(CUSTOM_TYPE.SKILL)
            UIHelper.SetVisible(tbFakeScript.BoxNon1, true)
            UIHelper.SetVisible(tbFakeScript.BoxNon, true)
        end
    else
        tbCurFakeNode = self.tbFakeNodeList[self.nNodeType][1][self.nCustomMode]
    end

    local tbAnchorScript = UIHelper.GetBindScript(tbCurFakeNode)
    UIHelper.SetVisible(tbAnchorScript.BtnSelectZone, false)
    tbAnchorScript:UnBindMoveFunction() --取消绑定拖动

    if self.bCustomState and self.nNodeType == CUSTOM_TYPE.CHAT then
        self:BindChatDragSize(false)
    end

    self.nNodeType = nil
    self:UpdateAllNodeOverLappingState(CUSTOM_BTNSTATE.ENTER)
end

function UIMainCityView:SaveNodePosition()  --分别保存经典和精简模式下的所有节点的默认位置以及对应的分辨率
    for k, nNodeType in pairs(CUSTOM_TYPE) do
        local tbCurClassicNode
        local tbCurSimpleNode
        if table.contain_value(tbCommonType, nNodeType) then
            tbCurClassicNode = self.tbFakeNodeList[nNodeType][2]
            tbCurSimpleNode = self.tbFakeNodeList[nNodeType][2]
        else
            tbCurClassicNode = self.tbFakeNodeList[nNodeType][2][MAIN_CITY_CONTROL_MODE.CLASSIC]
            tbCurSimpleNode = self.tbFakeNodeList[nNodeType][2][MAIN_CITY_CONTROL_MODE.SIMPLE]
        end
        local nClassicX, nClassicY = UIHelper.GetWorldPosition(tbCurClassicNode)
        local nSimpleX, nSimpleY = UIHelper.GetWorldPosition(tbCurSimpleNode)
        Storage.ControlMode.tbDefaultClassicPositionInfo[nNodeType] = {["nX"] = nClassicX, ["nY"] = nClassicY}
        Storage.ControlMode.tbDefaultSimplePositionInfo[nNodeType] = {["nX"] = nSimpleX, ["nY"] = nSimpleY}
    end
    local tbCurSize = UIHelper.GetCurResolutionSize()
    Storage.ControlMode.tbDefaultClassicSize = tbCurSize
    Storage.ControlMode.tbDefaultSimpleSize = tbCurSize

    Storage.ControlMode.Flush()
end

function UIMainCityView:GetImgSelectZonePositionInfo(nNodeType, nScaleX) --获得节点位置信息，用于判断重叠
    local nMx1, nMy1, width, height, tbScript
    local tbFakeScriptList = self:GetFakeScriptList()
    if not tbFakeScriptList or table.is_empty(tbFakeScriptList) then
        return
    end

    for k, node in pairs(tbFakeScriptList) do
        if k == nNodeType then
            tbScript = node
            width, height = UIHelper.GetContentSize(node.ImgSelectZone)
            width, height = width * nScaleX, height * nScaleX
            local nx1, ny1 = UIHelper.GetWorldPosition(node.ImgSelectZone)
            nMx1, nMy1 = nx1 - width / 2, ny1 + height / 2
            if nNodeType == CUSTOM_TYPE.CUSTOMBTN then
                nMx1, nMy1 = nx1 , ny1 + height
            elseif nNodeType == CUSTOM_TYPE.QUICKUSE then
                nMx1, nMy1 = nx1 - width / 2 , ny1 + height / 2
            elseif nNodeType == CUSTOM_TYPE.MENU then
                nMx1, nMy1 = nx1 - width , ny1
            elseif nNodeType == CUSTOM_TYPE.TASK then
                nMx1, nMy1 = nx1 , ny1
                --local nScaleX = UIHelper.GetScaleX(node.ImgSelectZone)
                --width, height = width * nScaleX, height * nScaleX
            elseif nNodeType == CUSTOM_TYPE.CHAT then
                nMx1, nMy1 = nx1 - width / 2 , ny1 + height / 2
                if self.nCustomMode == MAIN_CITY_CONTROL_MODE.SIMPLE then
                    nMx1, nMy1 = nx1 , ny1 + height
                end
            elseif nNodeType == CUSTOM_TYPE.ENERGYBAR or nNodeType == CUSTOM_TYPE.SPECIALSKILLBUFF then
                nMx1, nMy1 = nx1 - width, ny1 + height
            end
        end
    end
    return nMx1, nMy1, width, height, tbScript
end

local tbAllowOverlapType = {    --允许重叠检测的节点类型
    CUSTOM_TYPE.SPECIALSKILLBUFF
}

function UIMainCityView:UpdateAllNodeOverLappingState(nState)
    if not nState then
        nState = CUSTOM_BTNSTATE.OTHER
    end

    local tbNode = self:GetFakeScriptList()
    if not tbNode or table.is_empty(tbNode) then
        return
    end
    if not SkillData.IsEnergyShow() then
        tbNode[CUSTOM_TYPE.ENERGYBAR] = nil
    end

    if not SkillData.IsDXSpecialSkillBuffShow() then
        tbNode[CUSTOM_TYPE.SPECIALSKILLBUFF] = nil
    end

    --遍历每个节点之间的重叠状态
    local tbNodeList = {}

    for nNodeType1 = 1, #tbNode do
        for nNodeType2 = nNodeType1 + 1, #tbNode do
            local tbScript1 = tbNode[nNodeType1]
            local tbScript2 = tbNode[nNodeType2]
            if tbScript1 and tbScript2 and not table.contain_value(tbAllowOverlapType, nNodeType1) and not table.contain_value(tbAllowOverlapType, nNodeType2) then
                local tbCurNode, tbFakeNode = self:GetCustomNodeByType(nNodeType2, self.nCustomMode)
                local nScaleX = UIHelper.GetScaleX(tbCurNode)
                if nNodeType2 == CUSTOM_TYPE.TASK then
                    local script = UIHelper.GetBindScript(tbFakeNode)
                    nScaleX = UIHelper.GetScaleX(script.BtnSelectZone)
                end
                local nMx1, nMy1, width, height = self:GetImgSelectZonePositionInfo(nNodeType2, nScaleX)
                if MainCityCustomData.GetNodeOverLapping(nMx1, nMy1, width, height, tbScript1.ImgSelectZone) then
                    if not table.contain_key(tbNodeList, nNodeType1) then
                        table.insert(tbNodeList, nNodeType1, tbScript1)
                    end
                    if not table.contain_key(tbNodeList, nNodeType2) then
                        table.insert(tbNodeList, nNodeType2, tbScript2)
                    end
                end
            end
        end
    end

    for key, v in pairs(CUSTOM_TYPE) do
        if tbNode[v] then
            if not table.is_empty(tbNodeList) and table.contain_key(tbNodeList, v) then
                tbNode[v]:UpdateCustomNodeState(CUSTOM_BTNSTATE.CONFLICT)
            else
                if v == self.nNodeType then
                    tbNode[v]:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
                else
                    tbNode[v]:UpdateCustomNodeState(nState)
                end
            end
        end
    end
end

function UIMainCityView:IsExistOverLapping()
    local result = false
    local tbFakeScriptList = self:GetFakeScriptList()
    if not tbFakeScriptList or table.is_empty(tbFakeScriptList) then
        return false
    end
    for k, tbScript in pairs(tbFakeScriptList) do
        if tbScript.nState == CUSTOM_BTNSTATE.CONFLICT then
            result = true
            return result
        end
    end
    return result
end

function UIMainCityView:EnterSingleNodeCustom(nRangeType, nNodeType, nMode)
    UIHelper.SetVisible(self.BtnLeaveCustom, true)
    UIHelper.SetVisible(self.ImgHintDrag, true)
    UIHelper.SetVisible(self.LabelHintDrag, true)
    local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelHintSelectMode)
    UIHelper.SetVisible(tbScript._rootNode, false)
    if self.nNodeType then  --有上一编辑节点， 关闭上一节点的编辑状态先，关背景
        self:CloseNodeCustomState()
    end
    self:UpdateCustomMaincityInfo(nRangeType, nNodeType, nMode, true)  --进入nNodeType的编辑状态，加载黑色背景
end

function UIMainCityView:GetEditStateNodePosition(nMode)
    local tbPositionInfo = {}
    for k, nNodeType in pairs(CUSTOM_TYPE) do
        --获得该模式下该节点的真假父节点，然后分别设置保存的位置信息
        local tbCurNode, tbFakeNode = self:GetCustomNodeByType(nNodeType, nMode)
        local npx, npy = UIHelper.GetWorldPosition(tbFakeNode)
        tbPositionInfo[nNodeType] = {["nX"] = npx, ["nY"] = npy}
    end
    return tbPositionInfo
end

function UIMainCityView:ShowNodeSizeSetting(nNodeType)
    --local tbDefaultPosition = self.nCustomMode == MAIN_CITY_CONTROL_MODE.CLASSIC and Storage.ControlMode.tbDefaultClassicPositionInfo[nNodeType] or self.nCustomMode == MAIN_CITY_CONTROL_MODE.SIMPLE and Storage.ControlMode.tbDefaultSimplePositionInfo[nNodeType]
    local tbNode, tbFakeNode = self:GetCustomNodeByType(nNodeType, self.nCustomMode)
    local tbScript = UIHelper.GetBindScript(tbFakeNode)
    local nDevice = MainCityCustomData.GetDeviceType()
    local tips, itemTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetTipsFreeSetting, tbScript.BtnSelectZone, self.tbFontSizeType, nNodeType, nDevice, self.tbShowFont, self.nCustomMode)
    Timer.AddFrame(self, 2, function ()
        local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(itemTips.ImgTipsBg)
        tips:SetSize(nTipsWidth, nTipsHeight)
        tips:Update()
    end)

    if nNodeType == CUSTOM_TYPE.CHAT then
        local tbFakeScript = self:GetFakeScriptByType(nNodeType)
        local nOpacity = UIHelper.GetOpacity(tbFakeScript.ImgBg)
        itemTips:UpdateAlphaSettingInfo(nOpacity)
    end
    local tipsScript = UIMgr.GetViewScript(VIEW_ID.PanelHoverTips)
    if tipsScript and tipsScript._scriptBG then
        tipsScript._scriptBG:SetSwallowTouches(false)
    end
end

function UIMainCityView:GetFontSizeSet()
    local nMode = Storage.ControlMode.nMode
    self.tbFontSizeType = clone(Storage.ControlMode.tbMainCityNodeScaleType[nMode])
    local nDevice = MainCityCustomData.GetDeviceType()
    local tbDefaultScaleInfo = TabHelper.GetUIFontSizeTab(DEVICE_NAME[nDevice], Storage.ControlMode.nMode)
    for k, nSize in pairs(self.tbFontSizeType) do
        if nSize == 0 then
            local nDefaultSize = tbDefaultScaleInfo[k]
            self.tbFontSizeType[k] = nDefaultSize
            Storage.ControlMode.tbMainCityNodeScaleType[nMode][k] = nDefaultSize
        end
    end
    Storage.ControlMode.Dirty()
    self.tbShowFont = clone(Storage.ControlMode.tbFontShow)
end

function UIMainCityView:ExitCurrentNodeCustom()
    UIHelper.SetVisible(self.BtnLeaveCustom, false)
    Event.Dispatch("ON_TOUCH_BLANK_REGION")
    --打开自定义界面
    local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelHintSelectMode)
    if tbScript then
        UIHelper.SetVisible(tbScript._rootNode, true)
    end
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipsFreeSetting)
end

function UIMainCityView:UpdateCustomNodeSize(tbSizeType)
    local tbNode = {
        ["nSkill"] = {self.WidgetRightBottomAnchor, self.WidgetRightBottomSkillCopy},
        ["nMap"] = {self.WidgetRightTopAnchor, self.WidgetRightTopMapCopy},
        ["nLeftBottom"] = {self.tbWidgetLeftBottonList[1], self.tbWidgetLeftBottonList[2], self.tbCustomLeftBottonList[1], self.tbCustomLeftBottonList[2]},
        ["nChat"] = {self.tbWidgetChatMiniList[1], self.tbWidgetChatMiniList[2], self.tbCustomChatList[1], self.tbCustomChatList[2]},
        ["nQuickuse"] = {self.tbWidgetQuickUseList[1], self.tbWidgetQuickUseList[2], self.tbCustomQuickUseList[1], self.tbCustomQuickUseList[2]},
        ["nBuff"] = {self.tbWidgetPlayerBuffList[1], self.tbWidgetPlayerBuffList[2], self.tbCustomPlayerBuffList[1], self.tbCustomPlayerBuffList[2]},
        ["nPlayer"] = {self.tbWidgetPlayerInfoAnchorList[1], self.tbWidgetPlayerInfoAnchorList[2], self.tbCustomPlayerInfoAnchorList[1], self.tbCustomPlayerInfoAnchorList[2]},
        ["nTarget"] = {self.WidgetTargetInfoAnchorCopy, self.WidgetTargetInfoAnchor},
        ["nTeam"] = {self.BtnClassicSelectZone, self.BtnSimpleSelectZone},
        ["nEnergyBar"] = {self.WidgetSkillEnergyBar, self.WidgetSkillEnergyBarCopy},
        ["nSpecialSkillBuff"] = {self.WidgetSpecialSkillBuff, self.WidgetSpecialSkillBuffCopy},
        ["nDxSkill"] = {self.WidgetRightBottomAnchor, self.WidgetRightBottomSkillCopy},
        ["nKillFeed"] = {self.WidgetMainCityKillFeed, self.WidgetMainCityKillFeedCopy},
    }

    local szRemoveSkillType = SkillData.IsUsingHDKungFu() and "nSkill" or "nDxSkill"
    tbNode[szRemoveSkillType] = nil

    for szType, nodeList in pairs(tbNode) do
        local nScale = tbSizeType[szType]
        for k, node in pairs(nodeList) do
            if nScale then
                UIHelper.SetScale(node, nScale, nScale)
            end
        end
    end
    self.tbFontSizeType = tbSizeType
end

function UIMainCityView:GetCustomNodeByType(nNodeType, nMode)
    local tbNodeData = self.tbFakeNodeList[nNodeType]
    if not tbNodeData then return nil, nil end

    if table.contain_value(tbCommonType, nNodeType) then
        return tbNodeData[2], tbNodeData[1]
    end

    return tbNodeData[2] and tbNodeData[2][nMode], tbNodeData[1] and tbNodeData[1][nMode]
end

function UIMainCityView:ResetNodePosition(nMode, nNodeType)
    local tbPositionInfo = nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and Storage.ControlMode.tbDefaultClassicPositionInfo[nNodeType] or nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and Storage.ControlMode.tbDefaultSimplePositionInfo[nNodeType]
    local tbDefaultSize = nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and Storage.ControlMode.tbDefaultClassicSize or nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and Storage.ControlMode.tbDefaultSimpleSize
    local tbCurSize = UIHelper.GetCurResolutionSize()
    local nRatioX = tbCurSize.width / tbDefaultSize.width
    local nRatioY = tbCurSize.height / tbDefaultSize.height
    local tbNode, tbFakeNode = self:GetCustomNodeByType(nNodeType, nMode)
    UIHelper.SetWorldPosition(tbNode, tbPositionInfo.nX * nRatioX, tbPositionInfo.nY * nRatioY)
    UIHelper.SetWorldPosition(tbFakeNode, tbPositionInfo.nX * nRatioX, tbPositionInfo.nY * nRatioY)
    self.tbFakeNodePosition = self:GetFakeNodePosition(nMode)
end

function UIMainCityView:UpdateNodeZOrder(nRangeType, nNodeType, nMode)
    for k, node in pairs(self.tbAnchoreWidgetList) do
        UIHelper.SetLocalZOrder(node, k == nRangeType and 1 or 0)
    end
    UIHelper.SetLocalZOrder(self.ImgHintDrag, 2)

    for k, tbTypeList in pairs(tbRangeTypeNode) do
        if nRangeType == k then
            for i, nType in pairs(tbTypeList) do
                local _, tbFakeNode = self:GetCustomNodeByType(nType, nMode)
                UIHelper.SetLocalZOrder(tbFakeNode, 0)
            end
        end
    end
    local imgBg = self.tbBlackBgList[nRangeType]
    UIHelper.SetLocalZOrder(imgBg, 1)
    local _, tbCurFakeNode = self:GetCustomNodeByType(nNodeType, nMode)
    UIHelper.SetLocalZOrder(tbCurFakeNode, 2)
end

function UIMainCityView:GetCurrentFrameSize(nMode)
    local tbStorageSize = nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and Storage.ControlMode.tbClassicSize
                            or nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and Storage.ControlMode.tbSimpleSize
    local size = tbStorageSize or UIHelper.GetCurResolutionSize()
    self.nWidth = size.width
    self.nHeight = size.height
end

function UIMainCityView:UpdateAfterSizeChangePosition(nMode)
    local tbCurSize = UIHelper.GetCurResolutionSize()
    if nMode == MAIN_CITY_CONTROL_MODE.CLASSIC then
        Storage.ControlMode.tbClassicSize = tbCurSize
    else
        Storage.ControlMode.tbSimpleSize = tbCurSize
    end
    Storage.ControlMode.Flush()
end

function UIMainCityView:GetFakeNodePosition(nMode)
    local tbPosition = {}
    local size = UIHelper.GetCurResolutionSize()
    tbPosition["nWidth"] = size.width
    tbPosition["nHeight"] = size.height
    for k, nNodeType in pairs(CUSTOM_TYPE) do
        local tbFakeNode
        if table.contain_value(tbCommonType, nNodeType) then
            tbFakeNode = self.tbFakeNodeList[nNodeType][1]
        else
            tbFakeNode = self.tbFakeNodeList[nNodeType][1][nMode]
        end
        local nX, nY = UIHelper.GetWorldPosition(tbFakeNode)
        tbPosition[nNodeType] = {["nX"] = nX, ["nY"] = nY}
    end
    return tbPosition
end

function UIMainCityView:GetRangeTypeByNodeType(nType)
    local nResult = nil
    for k, tbTypeList in pairs(tbRangeTypeNode) do
        if table.contain_value(tbTypeList, nType) then
            nResult = k
            return nResult
        end
    end
    return nResult
end

function UIMainCityView:UpdateNodeOffset()
    local tbOffsetNode = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = {
            [CUSTOM_TYPE.CHAT] = {
                szName = "nChat",
                szType = "nChatOffset",
                tbNodeList = {
                    self.tbWidgetChatMiniList[2],
                    self.tbCustomChatList[2]
                }
            },
            [CUSTOM_TYPE.BUFF] = {
                szName = "nBuff",
                szType = "nBuffOffset",
                tbNodeList = {
                    self.tbWidgetPlayerBuffList[2],
                    self.tbCustomPlayerBuffList[2]
                }
            },
            [CUSTOM_TYPE.TASK] = {
                szName = "nTask",
                szType = "nTaskOffset",
                tbNodeList = {
                    self.tbWidgetTaskTeamAnchorList[2],
                    self.tbCustomTaskAnchorList[2]
                }
            },
            [CUSTOM_TYPE.QUICKUSE] = {
                szName = "nQuickuse",
                szType = "nQuickuseOffset",
                tbNodeList = {
                    self.tbWidgetQuickUseList[2],
                    self.tbCustomQuickUseList[2]
                }
            },
            [CUSTOM_TYPE.ENERGYBAR] = { --能量条在两种操作模式下位置一样
                szName = "nEnergyBar",
                szType = "nEnergyBarOffset",
                tbNodeList = {
                    self.WidgetSkillEnergyBar,
                    self.WidgetSkillEnergyBarCopy
                }
            },
        },
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = {
            [CUSTOM_TYPE.PLAYER] = {
                szName = "nPlayer",
                szType = "nPlayerOffset",
                tbNodeList = {
                    self.tbWidgetPlayerInfoAnchorList[1],
                    self.tbCustomPlayerInfoAnchorList[1]
                }
            },
            [CUSTOM_TYPE.QUICKUSE] = {
                szName = "nQuickuse",
                szType = "nQuickuseOffset",
                tbNodeList = {
                    self.tbWidgetQuickUseList[1],
                    self.tbCustomQuickUseList[1]
                }
            },
            [CUSTOM_TYPE.BUFF] = {
                szName = "nBuff",
                szType = "nBuffOffset",
                tbNodeList = {
                    self.tbWidgetPlayerBuffList[1],
                    self.tbCustomPlayerBuffList[1]
                }
            },
            [CUSTOM_TYPE.CUSTOMBTN] = {
                szName = "nLeftBottom",
                szType = "nLeftBottomOffset",
                tbNodeList = {
                    self.tbWidgetLeftBottonList[1],
                    self.tbCustomLeftBottonList[1]
                }
            }
        }
    }
    local tbSizeClassicInfo = Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.CLASSIC]
    local tbSizeSimpleInfo = Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.SIMPLE]
    local nDevice = MainCityCustomData.GetDeviceType()
    for nMode, tbModeOffsetType in pairs(tbOffsetNode) do
        local tbDefaultSize = TabHelper.GetUIFontSizeTab(DEVICE_NAME[nDevice], nMode)
        if tbDefaultSize then
            local tbSizeIndex = {
                [tbDefaultSize.nBigSize] = 1,
                [tbDefaultSize.nMediumSize] = 2,
                [tbDefaultSize.nSmallSize] = 3,
                [tbDefaultSize.nMiniSize] = 4,
            }
            local tbSizeInfo = nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and tbSizeClassicInfo or nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and tbSizeSimpleInfo
            for nType, tbData in pairs(tbModeOffsetType) do
                local szType = tbData.szType or ""
                local szName = tbData.szName or ""
                local tbNodeList = tbData.tbNodeList or {}

                local szOffsetNum = tbDefaultSize[szType] or ""
                local tOffsetNum = SplitString(szOffsetNum, ",")
                local nOffsetNumX = tonumber(tOffsetNum[1]) or 0
                local nOffsetNumY = tonumber(tOffsetNum[2]) or 0

                local nScaleX = tbSizeInfo[tbData.szName] or 1
                local nCount = (tbSizeIndex[nScaleX] or 1) - 1
                local nOffsetX, nOffsetY = nCount * nOffsetNumX, nCount * nOffsetNumY
                nOffsetY = MainCityCustomData.UpdateIOSChatOffSetY(nMode, szName, nOffsetY)

                for k, node in pairs(tbNodeList) do
                    local nX, nY = UIHelper.GetPosition(node)
                    nX = nX or 0
                    nY = nY or 0
                    UIHelper.SetPosition(node, nX + nOffsetX, nY + nOffsetY)
                end
            end
        end
    end
end

function UIMainCityView:IsRightTopVisible()
    return UIHelper.GetVisible(self.WidgetAniRightTop)
end

function UIMainCityView:IsHideRightAnimPlaying()
    return self.bAnimHideRightIsPlaying
end

function UIMainCityView:IsShowRightAnimPlaying()
    return self.bAnimShowRightIsPlaying
end

function UIMainCityView:SetNodePositionDefault(nMode)    --恢复默认
    Timer.DelTimer(self, self.nSetDefaultTimerID)
    self.nSetDefaultTimerID = Timer.AddFrame(self, 1, function ()
        UIHelper.WidgetFoceDoAlign(self)    --刷挂靠
        self:UpdateNodeOffset() --部分节点偏移处理
        self:SetFakeNodePositionToCurrent() --假节点刷到真节点位置
        --保存默认位置
        self:SaveNodePosition()
   end)
end

function UIMainCityView:SetStorageDefaultState(nMode, bDefault)
    Storage.ControlMode.tbDefaultPosition[nMode] = bDefault
    Storage.ControlMode.Flush()
end

function UIMainCityView:GetStorageDefaultState(nMode)
    return clone(Storage.ControlMode.tbDefaultPosition[nMode])
end

function UIMainCityView:GetDefaultPosition(nMode)
    nMode = nMode or Storage.ControlMode.nMode
    return self.tbDefaultPosition and self.tbDefaultPosition[nMode]
end

function UIMainCityView:SetPositionDefault(nMode, bDefault)
    nMode = nMode or Storage.ControlMode.nMode
    self.tbDefaultPosition[nMode] = bDefault
end

function UIMainCityView:SetFakeNodePositionToCurrent() --显示假节点前将所有假节点刷到对应真节点位置
    for nType, tbNodeData in pairs(self.tbFakeNodeList) do
        local tbFakeNode = tbNodeData[1]
        local tbNode = tbNodeData[2]
        if IsTable(tbFakeNode) then
            for k, node in pairs(tbNode) do
                local nX, nY = UIHelper.GetWorldPosition(node)
                UIHelper.SetWorldPosition(tbFakeNode[k], nX, nY)
            end
        else
            local nX, nY = UIHelper.GetWorldPosition(tbNode)
            UIHelper.SetWorldPosition(tbFakeNode, nX, nY)
        end
    end
end

function UIMainCityView:SaveChatDefaultSize()
    --保存聊天拖动按钮默认大小
    for nMode, v in pairs(Storage.ControlMode.tbChatBtnSelectSize) do
        local tbNode, tbFakeNode = self:GetCustomNodeByType(CUSTOM_TYPE.CHAT, nMode)
        local tbScript = UIHelper.GetBindScript(tbFakeNode)
        if tbScript then
            local nWidth, nHeight = UIHelper.GetContentSize(tbScript.BtnSelectZone)
            Storage.ControlMode.tbChatBtnSelectSize[nMode] = {["nWidth"] = nWidth, ["nHeigh"] = nHeight}
        end
    end
    Storage.ControlMode.Flush()
end

function UIMainCityView:UpdateVersionInfo()
    if Storage.ControlMode.tbVersion.nChat ~= CUSTOM_MODULE_VERSION.CHAT then
        for nMode, tbInfo in pairs(Storage.ControlMode.tbChatBtnSelectSize) do
            local nDefaultWidth = tbInfo.nWidth
            local nDefaultHeight = tbInfo.nHeigh
            local tbSize = Storage.ControlMode.tbChatContentSize[nMode]
            if not table.is_empty(tbSize) and (tbSize.w < nDefaultWidth or tbSize.h < nDefaultHeight) then
                Storage.ControlMode.tbChatContentSize[nMode] = {w = nDefaultWidth, h = nDefaultHeight}
            end
        end
        Storage.ControlMode.tbVersion.nChat = CUSTOM_MODULE_VERSION.CHAT
        Storage.ControlMode.Flush()
    end
    if Storage.ControlMode.tbVersion.nLeftBottom ~= CUSTOM_MODULE_VERSION.CUSTOMBTN then
        local tbLeftBtnDefaultPos = Storage.ControlMode.tbDefaultSimplePositionInfo[CUSTOM_TYPE.CUSTOMBTN]
        local tbCurBtnDefaultPos = Storage.ControlMode.tbSimplePositionInfo[CUSTOM_TYPE.CUSTOMBTN]
        if tbLeftBtnDefaultPos and tbCurBtnDefaultPos and tbLeftBtnDefaultPos.nX == tbCurBtnDefaultPos.nX and tbLeftBtnDefaultPos.nY == tbCurBtnDefaultPos.nY then
            Storage.ControlMode.tbSimplePositionInfo[CUSTOM_TYPE.CUSTOMBTN] = nil
        end
        Storage.ControlMode.tbVersion.nLeftBottom = CUSTOM_MODULE_VERSION.CUSTOMBTN
        Storage.ControlMode.Flush()
    end
    if not Storage.ControlMode.tbVersion.nDxSkill then
        Storage.ControlMode.tbVersion.nDxSkill = 0
        local nClassicSkill = clone(Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.CLASSIC]["nSkill"]) or 0
        local nSimpleSkill = clone(Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.SIMPLE]["nSkill"]) or 0
        Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.CLASSIC]["nDxSkill"] = nClassicSkill
        Storage.ControlMode.tbMainCityNodeScaleType[MAIN_CITY_CONTROL_MODE.SIMPLE]["nDxSkill"] = nSimpleSkill
    end
end

function UIMainCityView:ReloadJoystick()
    if not Platform.IsMobile() then
        return
    end

    if self.scriptJoyStick then
        UIHelper.RemoveFromParent(self.scriptJoyStick._rootNode)
    end
    self.scriptJoyStick = UIHelper.AddPrefab(PREFAB_ID.WidgetPerfabJoystick, self.WidgetJoystick)
end

function UIMainCityView:ReloadSkill(bForce)
    if not self.scriptSkill then
        return
    end

    if bForce or SkillData.GetSkillPanelPrefabID() ~= self.scriptSkill._nPrefabID then
        UIHelper.RemoveFromParent(self.scriptSkill._rootNode)
        self.scriptSkill = UIHelper.AddPrefab(SkillData.GetSkillPanelPrefabID(), self.WidgetRightBottomAnchor, false, self.WidgetSkillCancel)
        -- 重载功能按键
        local bOldState = SprintData.GetViewState()
        if self.scriptFuncSlot then
            UIHelper.RemoveFromParent(self.scriptFuncSlot._rootNode)
        end
        self.scriptFuncSlot = UIHelper.AddPrefab(SkillData.GetFunctionPanelPrefabID(), self.WidgetRightBottomAnchor)

        SprintData.SetViewState(bOldState, true)

        Event.Dispatch(EventType.OnHideSkillCancel)
    end
end

function UIMainCityView:UpdateDXEnergyBar()
    local bShowDxBar = SkillData.IsEnergyShow()
    local dwKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local tCangJianKungFuDict = { [10144] = 1, [10145] = 1 }
    local bIsCangJian = tCangJianKungFuDict[dwKungFuID]
    local bIsLastCangJian = self.energyScript and tCangJianKungFuDict[self.energyScript.dwKungFuID]
    local bChangeEnergyBar = not (bIsCangJian and bIsLastCangJian)
    if bChangeEnergyBar and self.energyScript then
        UIHelper.RemoveAllChildren(self.WidgetSkillEnergyBar)
        self.energyScript = nil
    end

    if bShowDxBar and not self.energyScript then
        self.energyScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillEnergyBar, self.WidgetSkillEnergyBar)
    end
end

function UIMainCityView:UpdateDXSpecialSkillBuff()
    local bShowSpecialBuff = SkillData.IsDXSpecialSkillBuffShow()
    if self.tbSkilBuffScript then
        UIHelper.RemoveAllChildren(self.WidgetSpecialSkillBuff)
        self.tbSkilBuffScript = nil
    end

    if bShowSpecialBuff then
        self.tbSkilBuffScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSpecialSkillBuff, self.WidgetSpecialSkillBuff)
    end
end

function UIMainCityView:RefreshNodePosition()
    --刷一遍位置到假节点
    local layerMain = UIMgr.GetLayer(UILayer.Main)
	if Platform.IsWindows() or Platform.IsMac() then UIHelper.SetOpacity(layerMain, 0) end

    Timer.DelTimer(self, self.nSizeChangeUpdateTimerID)
    local nMode = self.nLastMode or Storage.ControlMode.nMode
    local bDefault = self:GetDefaultPosition(nMode)
    self.nSizeChangeUpdateTimerID = Timer.Add(self, 0.06, function ()
        if Platform.IsWindows() or Platform.IsMac() then UIHelper.SetOpacity(layerMain, 255) end

        if bDefault then
            self:SetNodePositionDefault(nMode)
        else
            if not self.bCustomState then   --非编辑状态
                self:UpdateCustomNodePosition(nMode, false)
                self:UpdateChatContentSize(nMode, true)
            else    --编辑状态
                --把真节点刷到当前假节点位置
                self:UpdateCustomNodePosition(self.nCustomMode, true)
                self:UpdateChatContentSize(self.nCustomMode, true)
                self:UpdateAllNodeOverLappingState(CUSTOM_BTNSTATE.ENTER)
            end
        end
    end)
end

function UIMainCityView:SetFakeScript(nNodeType, tbScript)
    if not nNodeType or not tbScript then
        return
    end

    if not self.tbFakeScriptList  then
        self.tbFakeScriptList = {}
    end

    self.tbFakeScriptList[nNodeType] = tbScript
end

function UIMainCityView:GetFakeScriptByType(nNodeType)
    return self.tbFakeScriptList and self.tbFakeScriptList[nNodeType] or nil
end

function UIMainCityView:GetFakeScriptList()
    return self.tbFakeScriptList or {}
end

function UIMainCityView:RemoveFakeScript(nNodeType)
    if not nNodeType then
        return
    end

    local tbFakeScript = self:GetFakeScriptByType(nNodeType)
    if not tbFakeScript then
        return
    end

    -- TODO 泄漏问题 WidgetMainCityRightTop
    -- if nNodeType == 6 then
    --     self.tbFakeScriptList[nNodeType]._rootNode:release()
    -- end

    UIHelper.RemoveFromParent(tbFakeScript._rootNode)
end

function UIMainCityView:AddCustomPrefab(nNodeType, tbCurFakeNode, nMode)
    if not nNodeType or not tbCurFakeNode or not nMode then
        return
    end

    local nPrefabID = tbCustomPrefabList[nNodeType]
    if nNodeType == CUSTOM_TYPE.CHAT then
        nPrefabID = nPrefabID[nMode]
    elseif nNodeType == CUSTOM_TYPE.SKILL then
        nPrefabID = SkillData.GetSkillPanelPrefabID()
    end

    if nNodeType == CUSTOM_TYPE.ENERGYBAR and not SkillData.IsUsingHDKungFu() then
        return
    end

    if nNodeType == CUSTOM_TYPE.SPECIALSKILLBUFF and not SkillData.IsDXSpecialSkillBuffShow() then
        return
    end

    if not nPrefabID then
        return
    end

    local tbScript = nil
    local tbCommonType = {CUSTOM_TYPE.SKILL, CUSTOM_TYPE.BUFF, CUSTOM_TYPE.TASK, CUSTOM_TYPE.MENU, CUSTOM_TYPE.ENERGYBAR, CUSTOM_TYPE.SPECIALSKILLBUFF, CUSTOM_TYPE.KILL_FEED}

    if nNodeType == CUSTOM_TYPE.TARGET then
        tbScript = UIHelper.AddPrefab(nPrefabID, tbCurFakeNode, nil, nil, "boss", true) --造一个加的来改位置
    elseif table.contain_value(tbCommonType, nNodeType) then
        tbScript = UIHelper.AddPrefab(nPrefabID, tbCurFakeNode, true)
    elseif nNodeType == CUSTOM_TYPE.CHAT then
        tbScript = UIHelper.AddPrefab(nPrefabID, tbCurFakeNode, nMode)
        tbScript:SetChatBgOpacity()
    else
        tbScript = UIHelper.AddPrefab(nPrefabID, tbCurFakeNode)
    end

    return tbScript
end

return UIMainCityView
