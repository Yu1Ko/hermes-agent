UIGlobalFunction = UIGlobalFunction or {}

UIGlobalFunction["ArenaQueue.Open"] = function(nNpcID)
    UIMgr.Open(VIEW_ID.PanelPvPMatching, nNpcID)
end

UIGlobalFunction["OpenPartyRecruitPanel"] = function(nNpcID)
    --不同战场要进入不同界面
    local hNpc = GetNpc(nNpcID)
    if hNpc.dwTemplateID == 59149 then
        UIMgr.Open(VIEW_ID.PanelImpasseMatching, nNpcID)
    elseif hNpc.dwTemplateID == 65041 then
        -- 方缘音 飞火论锋
        local dwBombMapID = 415
        local dwBattlefieldMapType = BATTLEFIELD_MAP_TYPE.FBBATTLE
        UIMgr.Open(VIEW_ID.PanelFeiHuoMatching, nNpcID, dwBombMapID, dwBattlefieldMapType)
    elseif hNpc.dwTemplateID == 60212 then
        -- 曲小宝 李渡鬼域
        local dwMapID = 322
        local dwBattlefieldMapType = BATTLEFIELD_MAP_TYPE.ZOMBIEBATTLE
        UIMgr.Open(VIEW_ID.PanelFeiHuoMatching, nNpcID, dwMapID, dwBattlefieldMapType)
    elseif hNpc.dwTemplateID == 65821 then
        -- 尹修禊 列星虚境
        local dwMapID = 412
        local dwBattlefieldMapType = BATTLEFIELD_MAP_TYPE.MOBABATTLE
        UIMgr.Open(VIEW_ID.PanelLieXing, nNpcID, dwMapID, dwBattlefieldMapType)
    else
        UIMgr.Open(VIEW_ID.PanelBattleFieldInformation, nNpcID)
    end
end

UIGlobalFunction["QTEPanel_Show"] = function(tbData, bForceShow)
    QTEMgr.SetData(tbData)
end

UIGlobalFunction["OnCSRemoteCall"] = function(szEvent, arg0, arg1, arg2)
    if szEvent == "SyncPos" then
        -- TODO
    end
end

UIGlobalFunction["ActionBar.LoadExtendActionBar"] = function(dwActionBarIndex)
    LOG.INFO("UIGlobalFunction, ActionBar.LoadExtendActionBar, dwActionBarIndex = %s", tostring(dwActionBarIndex))

    ActionBarData.LoadExtendActionBar(dwActionBarIndex)
    local scene = g_pClientPlayer.GetScene()
    local dwMapID = scene and scene.dwMapID or 0
    if dwActionBarIndex == MonsterBookData.ACTION_BAR_INDEX then
        MonsterBookData.ResetActivedSkillData()
        if dwMapID ~= MonsterBookData.PLAY_MAP_ID then
            MonsterBookData.bIsPlaying = true
            MonsterBookData.Init()
            Event.Dispatch(EventType.OnEnterMonsterBookScene)
        end
    end
end

UIGlobalFunction["CloseActionBar"] = function(dwActionBarIndex)
    LOG.INFO("UIGlobalFunction, CloseActionBar ， dwActionBarIndex = %s", tostring(dwActionBarIndex))

    ActionBarData.CloseActionBar(dwActionBarIndex)
    local scene = g_pClientPlayer.GetScene()
    local dwMapID = scene and scene.dwMapID or 0
    if dwActionBarIndex == MonsterBookData.ACTION_BAR_INDEX then
        if dwMapID ~= MonsterBookData.PLAY_MAP_ID then
            MonsterBookData.bIsPlaying = false
            MonsterBookData.Init()
            Event.Dispatch(EventType.OnExitMonsterBookScene)
        end
    end
end

UIGlobalFunction["GBKToUTF8_OutputMessage"] = function(szType, szMsg, bRich)
    szMsg = UIHelper.GBKToUTF8(szMsg)
    OutputMessage(szType, szMsg, bRich)
end

UIGlobalFunction["AssistNewbieInvite.Open"] = function(tAssistInfo, bDisableSound)
    LOG.DEBUG("AssistNewbieInvite.Open")
    if AssistNewbieBase.bNeverShowHelpTip then return end

    TimelyMessagesBtnData.AddBtnInfo(TimelyMessagesType.AssistNewbie, {
        szTitle         = g_tStrings.ASSIST_NEWBIE_MENU_TITLE,
        nTotalTime 	    = 60,
        funcClickBtn    = function ()
            -- UIMgr.Open(VIEW_ID.PanelInvitationMessagePop, TimelyMessagesType.AssistNewbie)
        end,
        funcConfirm     = function ()
            RemoteCallToServer("On_Help_TryHelp", tAssistInfo.dwPlayerID)
        end,
        funcCancel      = function ()
            if not AssistNewbieBase.bNeverShowHelpTip then
                UIHelper.ShowConfirm(g_tStrings.Dungeon.STR_ASSIST_INVITE_REFUSE_TIP, function ()
                    AssistNewbieBase.bNeverShowHelpTip = true
                end)
            end
        end,
        tbParams = {
            tAssistInfo = tAssistInfo
        },
    })
end

UIGlobalFunction["NPCSpeechSounds.Open"] = function(dwID)
    Event.Dispatch("NPCSpeechSoundsOpen", dwID)
end

UIGlobalFunction["AchievementPanel.OnGetDocument"] = function(dwPlayerID, tInfo)
    Event.Dispatch("ON_GET_DOCUMENT", dwPlayerID, tInfo)
end

UIGlobalFunction["On_PQ_MidMapPQPrReturn"] = function(tPQprogres)
    Event.Dispatch("ON_MAP_UPDATE_DYNAMIC_DATA_EX", tPQprogres)
end

UIGlobalFunction["NewTrialValley.Open"] = function()
    NewTrialValley.Open()
end

UIGlobalFunction["NewTrialValley.Close"] = function()
    NewTrialValley.Close()
end

UIGlobalFunction["NewTrialValley.OpenReward"] = function(tbData)
    NewTrialValley.OpenReward(tbData)
end

UIGlobalFunction["TrialValleyReward.Close"] = function()
    NewTrialValley.CloseReward()
end

UIGlobalFunction["DaTangJiaYuan.Close"] = function()
    UIMgr.Close(VIEW_ID.PanelHome)
end

UIGlobalFunction["VagabondPanel.Open"] = function(tbSelectionInfo, nTargetType, nTargetID, nLeftCanGet)
    VagabondData.Init(tbSelectionInfo, nTargetType, nTargetID, nLeftCanGet)
end

UIGlobalFunction["VagabondPanel.ShowEnterTipWnd"] = function(bNewSave, bNumError, tPlayerState)
    if bNumError or tPlayerState == nil then
        local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_TEAM_PLAYER_NUM_ERROR..tostring(VagabondData.GetPlayerNum()))
        scriptView:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_KNOW)
        scriptView:HideButton("Cancel")
    else
        UIMgr.Open(VIEW_ID.PanelChooseConfirm, bNewSave, bNumError, tPlayerState)
    end
end

UIGlobalFunction["VagabondReward.Open"] = function(tbRewardInfo)
    UIMgr.Open(VIEW_ID.PaneleChooseReward, tbRewardInfo)
end

UIGlobalFunction["VagabondCrossMap.Open"] = function(tbMapInfos, nTargetType, nTargetID)
    UIMgr.Open(VIEW_ID.PaneleChooseMap, tbMapInfos, nTargetType, nTargetID)
end

UIGlobalFunction["VagabondCraftManage.Open"] = function(nClassificationID, tCraftLevel, nTargetType, nTargetID)
    -- UIMgr.Open(VIEW_ID.PaneleChooseReward, tbMapInfos, nTargetType, nTargetID)
    CraftManageData.Init(nClassificationID, tCraftLevel, nTargetType, nTargetID)
end

UIGlobalFunction["Challenge.Open"] = function(tChallengeInfo)
    local scriptView = UIMgr.Open(VIEW_ID.PanelArenaPop)
    if scriptView then
        scriptView:OnEnter(tChallengeInfo)
    end
end

UIGlobalFunction["Challenge.Close"] = function()
    UIMgr.Close(VIEW_ID.PanelArenaPop)
end

UIGlobalFunction["StampPlay.Open"] = function(tStampInfo, nPage, nIndex)
    --UIMgr.Close(VIEW_ID.PanelArenaPop)
    UIMgr.Open(VIEW_ID.PanelStampPop,tStampInfo, nPage, nIndex)
end

-- RemoteCallToClient(player.dwID, "CallUIGlobalFunction", "ShowFullScreenSFX", "DMD_MITAO")
UIGlobalFunction["ShowFullScreenSFX"] = function(szSfxName)
    UIHelper.ShowFullScreenSFX(szSfxName)
end

UIGlobalFunction["DomesticatePanel.Open"] = function()
    UIMgr.Open(VIEW_ID.PanelLifePage, {nDefaultCraftPanel = CRAFT_PANEL.Demosticate})
end

UIGlobalFunction["HideFullScreenSFX"] = function()
    UIHelper.HideFullScreenSFX()
end

UIGlobalFunction["OpenNPCGuidelines"] = function (dwMapID, dwIndex, dwNpcID)
    local view = UIMgr.GetViewScript(VIEW_ID.PanelGuardGuidePop)
    if not view then
        UIMgr.Open(VIEW_ID.PanelGuardGuidePop, dwMapID, dwIndex, dwNpcID)
    else
        view:OnEnter(dwMapID, dwIndex, dwNpcID)
    end

end

UIGlobalFunction["ACC_DesertStormInfo.HideTime"] = function ()
    Event.Dispatch(EventType.OnTreasureBattleFieldHideTime)
end

UIGlobalFunction["ACC_DesertStormInfo.HideInfoBar"] = function ()
    Event.Dispatch(EventType.OnTreasureBattleFieldHideInfoBar)
end

UIGlobalFunction["ACC_DesertStormInfo.HidePlayerNum"] = function ()
    Event.Dispatch(EventType.OnTreasureBattleFieldHidePlayerNum)
end

UIGlobalFunction["ACC_DesertStormInfo.UpdateFrameTime"] = function (nPublicTime)
    Event.Dispatch(EventType.OnTreasureBattleFieldUpdateFrameTime, nPublicTime)
end

UIGlobalFunction["ACC_DesertStormInfo.UpdateInfoBar"] = function (nWindProcess, nPlayerProcess)
    Event.Dispatch(EventType.OnTreasureBattleFieldUpdateInfoBar, nWindProcess, nPlayerProcess)
end

UIGlobalFunction["ACC_DesertStormInfo.UpdateFramePlayerNum"] = function (nAlivePlayer)
    Event.Dispatch(EventType.OnTreasureBattleFieldUpdateFramePlayerNum, nAlivePlayer)
end

UIGlobalFunction["ThermometerPanel.Open"] = function (nTemperature)
    GeneralProgressBarData.AddProgressBar("ThermometerPanel", 0, UIHelper.UTF8ToGBK("温度"), "", nTemperature, 100, 1)
end

UIGlobalFunction["ThermometerPanel.Close"] = function ()
    GeneralProgressBarData.DeleteProgressBar("ThermometerPanel")
end

UIGlobalFunction["ThermometerPanel.UpdateTemperature"] = function (nTemperature)
    GeneralProgressBarData.DeleteProgressBar("ThermometerPanel")
    GeneralProgressBarData.AddProgressBar("ThermometerPanel", 0, UIHelper.UTF8ToGBK("温度"), "", nTemperature, 100, 1)
end

UIGlobalFunction["FBCountDown.Open"] = function (nType, nStartTime, nEndTime)
    LOG.INFO("UIGlobalFunction, FBCountDown.Open, nType:%d, nStartTime:%d, nEndTime:%d", nType, nStartTime, nEndTime)
    FestivalActivities.UpdateFBCountDown(nType, nStartTime, nEndTime)
end

UIGlobalFunction["FBCountDown.Close"] = function ()
    LOG.INFO("UIGlobalFunction, FBCountDown.Close")
    FestivalActivities.ClearFBCountDown()
end

UIGlobalFunction["BattleField_Match"] = function (bNext, bSecond)
    BattleFieldData.Match(bNext, bSecond)
end

UIGlobalFunction["CameraCommon.SetView"] = function (dwTargetID)
    CameraCommon.SetView(dwTargetID)
end

UIGlobalFunction["OpenCloakColorChange"] = function (dwItemType, dwItemIndex, dwShowItemType, dwShowItemIndex)
    UIMgr.Open(VIEW_ID.PanelChangeCloak, dwItemType, dwItemIndex, dwShowItemType, dwShowItemIndex)
end

UIGlobalFunction["Exterior_Operator.GetFromItem"] = function (dwItemType, dwItemIndex, dwShowItemType, dwShowItemIndex)
    UIMgr.Open(VIEW_ID.PanelChangeCloak, dwItemType, dwItemIndex, dwShowItemType, dwShowItemIndex, true)
end

UIGlobalFunction["OpenMailPanel"] = function (nNpcType, dwNpcID, bPet)
    UIMgr.Open(VIEW_ID.PanelEmail, dwNpcID, bPet)
end

UIGlobalFunction["ShareBagBindingPanel.Open"] = function(...)
    UIMgr.OpenSingle(false,VIEW_ID.PanelHalfBag)
    UIMgr.Open(VIEW_ID.PanelHalfWarehouse,WareHouseType.Account)
    PlotMgr.ClosePanel(PLOT_TYPE.OLD)
end

UIGlobalFunction["DaTangJiaYuan.Open"] = function(...)
    local tbArgs = {...}
    if not UIMgr.IsViewOpened(VIEW_ID.PanelHome) then
        UIMgr.Open(VIEW_ID.PanelHome, 1, ...)
    end
end

UIGlobalFunction["HomelandLocker.Open"] = function(nPlayerID)
    UIMgr.OpenSingle(false,VIEW_ID.PanelHalfBag)
    UIMgr.Open(VIEW_ID.PanelHalfWarehouse,WareHouseType.Homeland)
    PlotMgr.ClosePanel(PLOT_TYPE.OLD)
end

UIGlobalFunction["MessageBoard.Open"] = function(dwMapID, nCopyIndex, nLandIndex)
    if UIMgr.IsViewOpened(VIEW_ID.PanelOldDialogue) then
        PlotMgr.ClosePanel(PLOT_TYPE.OLD)
    end
    UIMgr.Open(VIEW_ID.PanelMessageBoard, dwMapID, nCopyIndex, nLandIndex)
end

UIGlobalFunction["OrderPanel.Open"] = function(nOwnerID)
	HomelandIdentity.OpenPanelHomeOrder(nOwnerID)
end

UIGlobalFunction["PerfumePanel.Open"] = function()
	UIMgr.Open(VIEW_ID.PanelConfigurationPop)
end

UIGlobalFunction["FishBag.Open"] = function()
	HomelandIdentity.OpenFishBagPanel()
end

UIGlobalFunction["FoodListPanel.Open"] = function(dwOwnerID, dwNpcID)
	HomelandIdentity.OpenFoodCartPanel(dwOwnerID, dwNpcID, true)
end

UIGlobalFunction["GeneralProgressBar_Create"] = function(szName, nID, szTitle, szDiscrible, nMolecular, nDenominator, nTime)
    GeneralProgressBarData.AddProgressBar(szName, nID, szTitle, szDiscrible, nMolecular, nDenominator, nTime)
end

UIGlobalFunction["GeneralProgressBar_Close"] = function(szName)
    GeneralProgressBarData.DeleteProgressBar(szName)
end

UIGlobalFunction["GeneralProgressBar_Update"] = function(szName, nID)
    GeneralProgressBarData.UpdateProgressBar(szName, nID)
end

UIGlobalFunction["GeneralCounterSFX.RefleshCounter"] = function(dwID, nCount)
    Event.Dispatch("GeneralCounterSFX_RefleshCounter", dwID, nCount)
end

UIGlobalFunction["GeneralCounterSFX.Close"] = function()
    Event.Dispatch("GeneralCounterSFX_Close")
end

UIGlobalFunction["RemainingTimeNotify.Open"] = function(nSecond)
    Event.Dispatch("RemainingTimeNotify_Open", nSecond)
end

UIGlobalFunction["RemainingTimeNotify.Close"] = function()
    Event.Dispatch("RemainingTimeNotify_Close")
end

UIGlobalFunction["TimeBuff.Open"] = function(tTimeBuffList)
   TimeBuffData.Init(tTimeBuffList)
end

UIGlobalFunction["TimeBuff.Close"] = function()
    TimeBuffData.Close()
end

UIGlobalFunction["TimeBuff.UpdateTimeBuffList"] = function(tTimeBuffList)
    TimeBuffData.UpdateTimeBuffList(tTimeBuffList)
end

UIGlobalFunction["TimeBuff.ReInitBuffList"] = function(tTimeBuffList)
    TimeBuffData.InitTimeBuffList(tTimeBuffList)
end


UIGlobalFunction["DivinationPanel.Begin"] = function(nIndex)
    DivinationData.Begin(nIndex)
end

UIGlobalFunction["DivinationPanel.End"] = function(nIndex, bShowEndSFX)
    DivinationData.End(nIndex, bShowEndSFX)
end

UIGlobalFunction["OpenCastleFightCleanup"] = function(szProblem, tAnswer)
    UIMgr.Open(VIEW_ID.PanelAnswerPop, szProblem, tAnswer)
end

local tbPrevColorGradeParams
UIGlobalFunction["SetBalloonGray"] = function(bGray)
    -- by huqing 2024/6/11
    -- 这个功能先干掉，DX是对头顶泡泡置灰，我们确对整个场景置灰，有问题的
    -- 并且这样设置会将引擎的相关设置给弄错导致各种显示问题


    --LOG.INFO("RemoteCommand, SetBalloonGray")
    local tbColorGradeParams
    if bGray then
        tbColorGradeParams = KG3DEngine.GetColorGradeParams()
        tbPrevColorGradeParams = clone(tbColorGradeParams)
		local tableInfo = TabHelper.GetUISelfieFilterTab(4)
		for k, v in pairs(tableInfo) do
			tbColorGradeParams[k] = v
		end
		KG3DEngine.SetPostRenderVignetteEnable(true)
        tbColorGradeParams.bParamsChange = true
        KG3DEngine.SetColorGradeParams(tbColorGradeParams)
    else
        --[[if not JiangHuData.tbDefaultColorGradeParams then
            JiangHuData.tbDefaultColorGradeParams = KG3DEngine.GetColorGradeParams()
        end
        tbColorGradeParams = JiangHuData.tbDefaultColorGradeParams
		KG3DEngine.SetPostRenderVignetteEnable(false)]]--
        if tbPrevColorGradeParams then
            tbPrevColorGradeParams.bParamsChange = true
            KG3DEngine.SetColorGradeParams(tbPrevColorGradeParams)
        end
        SelfieData.ResetFilterFromStorage()
    end
end

UIGlobalFunction["TopMenu_SetHideFullHelpBtn"] = function(bHide)
    LOG.INFO("RemoteCommand, TopMenu_SetHideFullHelpBtn")
end

UIGlobalFunction["CloseNewPetSkillPanel"] = function()
    local player = GetClientPlayer()
	if not player then
		return
	end
	JiangHuData.nCurActID = player.GetPlayerIdentityManager().dwCurrentIdentityType
    if JiangHuData.nCurActID == 4 and JiangHuData.bOpenPet then
        JiangHuData.tbIdentitySkills = {}
        table.insert(JiangHuData.tbIdentitySkills, {id = 16048, level = 1}) --结束
        local tbSkills = {CanCastSkill = true, canuserchange = false, tbSkilllist = JiangHuData.tbIdentitySkills}
        IdentitySkillData.OnSwitchDynamicSkillStateBySkills(tbSkills)
    end
    if QTEMgr.IsInDynamicSkillStateBySkills() then
        QTEMgr.OnSwitchDynamicSkillStateBySkills()
    end
    Storage.CustomBtn.bHaveFellowPet = false
    Storage.CustomBtn.Dirty()
    Event.Dispatch("OnFellowPetChanged")
end
UIGlobalFunction["OpenNewPetSkillPanel"] = function()
    local player = GetClientPlayer()
	if not player then
		return
	end
    JiangHuData.bOpenPet = true
	JiangHuData.nCurActID = player.GetPlayerIdentityManager().dwCurrentIdentityType
    if JiangHuData.nCurActID == 4 then
        JiangHuData.tbIdentitySkills = {}
        table.insert(JiangHuData.tbIdentitySkills, {id = 16047, level = 1}) --开始
        local tbSkills = {CanCastSkill = true, canuserchange = false, tbSkilllist = JiangHuData.tbIdentitySkills}
        IdentitySkillData.OnSwitchDynamicSkillStateBySkills(tbSkills)
    end
    if JiangHuData.bPeFirstCall then
        TipsHelper.ShowNormalTip("快捷操作界面可开启宠物互动按钮")
        JiangHuData.bPeFirstCall = false
    end
    Storage.CustomBtn.bHaveFellowPet = true
    Storage.CustomBtn.Dirty()
    Event.Dispatch("OnFellowPetChanged")
end

UIGlobalFunction["TeamBuff.Close"] = function()
    LOG.INFO("RemoteCommand, TeamBuff.Close")
end

UIGlobalFunction["FBCountNum.Close"] = function()
    LOG.INFO("RemoteCommand, FBCountNum.Close")
end

UIGlobalFunction["OperationMode.Open"] = function()
    LOG.INFO("RemoteCommand, OperationMode.Open")
end

UIGlobalFunction["HotSpot.SetPopID"] = function()
    LOG.INFO("RemoteCommand, HotSpot.SetPopID")
end

UIGlobalFunction["OnGetFriendEffortCheck"] = function()
    LOG.INFO("RemoteCommand, OnGetFriendEffortCheck")
end

UIGlobalFunction["PlayBgMusic"] = function(szName, nOffset, nLock, bDontSetLastBGM)
    SoundMgr.PlayBgMusic(szName, nOffset, nLock, bDontSetLastBGM)
end

UIGlobalFunction["BgMusic_TryPlayLast"] = function()
    SoundMgr.PlayLastBgMusic()
end

UIGlobalFunction["BgMusic_TryPlayBack"] = function()
    SoundMgr.PlayBackBgMusic()
end

UIGlobalFunction["teach_base.finish_teach"] = function()
    LOG.INFO("RemoteCommand, teach_base.finish_teach")
end

UIGlobalFunction["TeachingAim.Open"] = function()
    LOG.INFO("RemoteCommand, TeachingAim.Open")
end

UIGlobalFunction["TeachingAim.Close"] = function()
    LOG.INFO("RemoteCommand, TeachingAim.Close")
end

UIGlobalFunction["BalanceShip.ShowBalanceShip"] = function(bShow)
    DungeonData.OnShowBalanceShip(bShow)
end

UIGlobalFunction["BalanceShip.SetShipState"] = function(nWaterProgress, bShowWeight, nLeftWeight, nRightWeight, nOverWeightSide)
    DungeonData.OnSetShipState(nWaterProgress, bShowWeight, nLeftWeight, nRightWeight, nOverWeightSide)
end

UIGlobalFunction["AssistNewbieDungeon.Open"] = function(dwQuestID, hDock, bDisableSound)
    AssistNewbieBase.ShowQuestAssistComfirm(dwQuestID)
end

UIGlobalFunction["NewOperationActivity.Open"] = function(dwID)  --等级升至14级时定位到花萼楼首充界面
    HuaELouData.Open(dwID)
end

UIGlobalFunction["TopMenu.LimitedSaleOpen"] = function(nType, tTable, bAdd, dwShowID)  --等级升至110级时打开限时购买弹窗
    --local nEndTime = GetGameWorldStartTime() + 3*24*60*60
    --local nTime = GetCurrentTime()
    --LOG.INFO("nEndTime:%d, nTime:%d", nEndTime, nTime)
    --if nTime >= nEndTime then
    --    SpecialDiscountData.LimitedSaleOpen(nType, tTable, bAdd, dwShowID)
    --end
end

UIGlobalFunction["SeasonLetter.Open"] = function()
    if SceneMgr.IsLoading() then
        Event.Reg(UIGlobalFunction, EventType.OnViewClose, function (nViewID)
            if nViewID == VIEW_ID.PanelLoading then
                Event.UnReg(UIGlobalFunction, EventType.OnViewClose)

                UIMgr.Open(VIEW_ID.PanelCareerOpenPop)
                if UIMgr.GetView(VIEW_ID.PanelHotSpotBanner) then
                    UIMgr.Close(VIEW_ID.PanelHotSpotBanner)
                end
            end
        end)
    else
        UIMgr.Open(VIEW_ID.PanelCareerOpenPop)
        if UIMgr.GetView(VIEW_ID.PanelHotSpotBanner) then
            UIMgr.Close(VIEW_ID.PanelHotSpotBanner)
        end
    end
end

UIGlobalFunction["VampireInfoPanel.Open"] = function(tVampireUIInfo, bDisableSound)
    Event.Dispatch("VampireInfoPanel_Open", tVampireUIInfo, bDisableSound)
end

UIGlobalFunction["VampireInfoPanel.UpdateNumOfPlayer"] = function(nNumOfHuman, nNumOfVampire)
    Event.Dispatch("VampireInfoPanel_UpdateNumOfPlayer", nNumOfHuman, nNumOfVampire)
end

UIGlobalFunction["VampireInfoPanel.UpdateScore"] = function(nSelfScore, nPeopleScore, nMaxPeopleScore)
    Event.Dispatch("VampireInfoPanel_UpdateScore", nSelfScore, nPeopleScore, nMaxPeopleScore)
end

UIGlobalFunction["VampireInfoPanel.UpdateSoul"] = function(nIndex, nNumerator, nDenominator, bHide)
    Event.Dispatch("VampireInfoPanel_UpdateSoul", nIndex, nNumerator, nDenominator, bHide)
end

UIGlobalFunction["VampireInfoPanel.OnRemoteKillMessage"] = function(szKiller, szBeKilled, nType, nDisplayTime)
    local szKillType
    if nType == 1 then
        szKillType = "击伤"
    else
        szKillType = "感染"
    end

    local szMessage = string.format("%s %s %s", UIHelper.GBKToUTF8(szKiller), szKillType, UIHelper.GBKToUTF8(szBeKilled))
    TipsHelper.ShowNormalTip(szMessage, false, nDisplayTime)

end

UIGlobalFunction["HotSpot.SetPopID"] = function(szPopID)
    HotSpotData.SetPopID(szPopID)
end

UIGlobalFunction["OpenFriendPraise"] = function(tInfo, nType)
    if not DungeonSettleCardData.IsShowFriendPraise(nType) then
        return
    end

    if SceneMgr.IsLoading() then
        Event.Reg(UIGlobalFunction, EventType.OnViewClose, function (nViewID)
            if nViewID == VIEW_ID.PanelLoading then
                Event.UnReg(UIGlobalFunction, EventType.OnViewClose)
                TipsHelper.ShowLikeTip(tInfo, nType)
            end
        end)
    else
        TipsHelper.ShowLikeTip(tInfo, nType)
    end
end

UIGlobalFunction["Helper_SetQuestArrow"] = function(bShow)
    Storage.Player.bShowTrace = bShow
    Storage.Player.Flush()

    Event.Dispatch("Helper_SetQuestArrow", bShow)
end

UIGlobalFunction["CommandElection.Open"] = function(_arg1)
    TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
end

UIGlobalFunction["InterludePanel.Open"] = function(nIndex)
    UIMgr.Open(VIEW_ID.PanelInterlude, nIndex)
end

UIGlobalFunction["SprintData.EndSprint"] = function(bForce)
    SprintData.EndSprint(bForce)
end

UIGlobalFunction["SprintData.EndAutoForward"] = function()
    SprintData.SetAutoForward(false)
end

UIGlobalFunction["PlotSound.Open"] = function(nSoundID)
    SwordMemoriesData.StartPlaySoundBySoundID(nSoundID)
end

UIGlobalFunction["OpenGuildFightQueuePanel"] = function(dwGuildFightNpc)
    UIMgr.Open(VIEW_ID.PanelFactionMatching, dwGuildFightNpc)
end

UIGlobalFunction["CommandSignup.OpenSignUpPage"] = function(tInfo, bDisableSound)
    UIMgr.Open(VIEW_ID.PanelFactionElectionPop, tInfo, false)
end

UIGlobalFunction["CommandSignup.OpenModifyPage"] = function(tInfo, bDisableSound)
    UIMgr.Open(VIEW_ID.PanelFactionElectionPop, tInfo, true)
end

UIGlobalFunction["CommandSignup.Close"] = function()
    UIMgr.Close(VIEW_ID.PanelFactionElectionPop)
    local view = UIMgr.GetView(VIEW_ID.PanelPVPCampCampaign)
    local scriptView = view and view.scriptView
    if scriptView then
        scriptView:ApplyCustomRankList()
    end
end

UIGlobalFunction["RougeLikeQueue.Open"] = function()
    UIMgr.Open(VIEW_ID.PanelBahuangMain)
end

UIGlobalFunction["BattleField_Base.SetMobaEquipList"] = function(tPlayerEquipList)
    BattleFieldData.SetMobaEquipList(tPlayerEquipList)
end

UIGlobalFunction["BattleField_Base.SetMobaOpenTime"] = function(nTime)
    BattleFieldData.SetMobaOpenTime(nTime)
end

UIGlobalFunction["Navigator.AddTemporaryPoint"] = function(tParamsOrMapID, tPoint, szKey, nType, szText, dwTemplateID)
    local tParams
    if type(tParamsOrMapID) == "table" then
        tParams = tParamsOrMapID
    else
        tParams = {
            dwMapID = tParamsOrMapID,
            tPoint = tPoint,
            szKey = szKey,
            nType = nType,
            dwTemplateID = dwTemplateID,
        }
    end

    if tParams then
        LOG.INFO("Navigator AddTemporaryPoint Params: dwMapID=%s, tPoint=%s, szKey=%s, nType=%s, szText=%s, dwTemplateID=%s",
            tostring(tParams.dwMapID),
            tostring(tParams.tPoint),
            tostring(tParams.szKey),
            tostring(tParams.nType),
            tostring(tParams.szText),
            tostring(tParams.dwTemplateID)
        )

        Event.Dispatch("OnRemoteAddNaviPoint", tParams.szKey, tParams.dwMapID, tParams.tPoint, tParams.nType, tParams.dwTemplateID)
    else
        LOG.INFO("Navigator AddTemporaryPoint Params: tParams is nil")
    end
end

UIGlobalFunction["Navigator.ClearTemporaryPoint"] = function(szKey)
    Event.Dispatch("OnRemoteRemoveNaviPoint", szKey)
end

UIGlobalFunction["Navigator.ClearAllTemporaryPoint"] = function()
    Event.Dispatch("OnRemoteClearAllNaviPoint")
end

UIGlobalFunction["Navigator.Remove"] = function(szKey)
    -- TODO
    Event.Dispatch("OnRemoteRemoveNaviPoint", szKey)
end

UIGlobalFunction["OpenSniperPanel"] = function(bAutolost, bNotify_server, nType, bAutoSearch)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMiniGameAim)
    if scriptView then
        scriptView:OnEnter(bAutolost, bNotify_server, nType, bAutoSearch)
    else
        UIMgr.Open(VIEW_ID.PanelMiniGameAim, bAutolost, bNotify_server, nType, bAutoSearch)
    end
end

UIGlobalFunction["CloseSniperPanel"] = function()
    UIMgr.Close(VIEW_ID.PanelMiniGameAim)
end

UIGlobalFunction["PartnerMeetbyChance.Open"] = function(tInfoList, nSelID)
    local tInfo = Table_GetPartnerNpcInfo(nSelID)

    if tInfo.bCanMorph then
        -- 普通侠客打开喝茶界面
        UIMgr.Open(VIEW_ID.PanelPartnerXunFang, tInfoList, nSelID)
    else
        -- 管家侠客打开购买页面
        UIMgr.Open(VIEW_ID.PanelPartnerBuy, tInfoList, nSelID)
    end
end

UIGlobalFunction["Partner.Open"] = function()
    UIMgr.Open(VIEW_ID.PanelPartner)
end

UIGlobalFunction["NPCSpeechSounds.Close"] = function(bAll, bDisableSound)
    Event.Dispatch(EventType.OnCloseNpcSpeechSoundsBalloon)
end

UIGlobalFunction["CommandElection.Open"] = function()
	UIMgr.Open(VIEW_ID.PanelPVPCampCampaign)
end

UIGlobalFunction["FlowerPanel.Open"] = function(tFlowerInfo, dwTargetType, dwTargetId)
	UIMgr.Open(VIEW_ID.PanelFlowerFestival, tFlowerInfo, dwTargetType, dwTargetId)
end

UIGlobalFunction["NPCRoster.Open"] = function(tFlowerInfo, dwTargetType, dwTargetId)
    UIMgr.Open(VIEW_ID.PanelYunCongJi)
end

UIGlobalFunction["CommandSignup.SetCmdNameWrongMsg"] = function(tInfo)
    local view = UIMgr.GetView(VIEW_ID.PanelFactionElectionPop)
    local scriptView = view and view.scriptView
    if scriptView then
        scriptView:SetCmdNameWrongMsg(tInfo)
    end
end

UIGlobalFunction["CampOBBase.Open"] = function()
    CampOBBaseData.Open()
end

UIGlobalFunction["CampOBBase.Close"] = function()
    CampOBBaseData.Close()
end

UIGlobalFunction["ActivityPlotPanel.Open"] = function(szPlotKey, nSeasonID, nChapterID)
    UIMgr.Open(VIEW_ID.PanelYushutuce, szPlotKey, nSeasonID, nChapterID)
end

UIGlobalFunction["WinterFestivalSkillMsg.Open"] = function(dwID)
    --UIMgr.Open(VIEW_ID.PanelYushutuce, dwID)
end

UIGlobalFunction["OrangeWeaponUpg.Open"] = function(nLevel)
    if not g_pClientPlayer then
        return
    end

    if IsRemotePlayer(g_pClientPlayer.dwID) then
        return
    end

    UIMgr.Open(VIEW_ID.PanelShenBingUpgrade, nil, nLevel)
end

UIGlobalFunction["SwitchServerDLC.Open"] = function()
    CollectionFuncList.OpenQianLiFaZhu()
end

UIGlobalFunction["GameGuidePanel.Open"] = function(szPage)
    local tPageConvert = {
        ["Page_Daily"] = COLLECTION_PAGE_TYPE.DAY,
        ["Page_FB"] = COLLECTION_PAGE_TYPE.SECRET,
        ["Page_Camp"] = COLLECTION_PAGE_TYPE.CAMP,
        ["Page_Contest"] = COLLECTION_PAGE_TYPE.ATHLETICS,
        ["Page_Leisure"] = COLLECTION_PAGE_TYPE.REST,
    }

    local nType = tPageConvert[szPage]
    if nType then
        CollectionData.OpenCollection(nType)
    else
        LOG.ERROR("GameGuidePanel.Open Error: %s", tostring(szPage))
    end
end

UIGlobalFunction["AutoNav.OnSyncNextCastleTradeMap"] = function(dwNextMapID)
    Event.Dispatch(EventType.AutoSelectSwitchMapWindow, dwNextMapID)
end

-- 列星虚境 等级提升
UIGlobalFunction["UpGradeEffect.Open"] = function(nLevel)
    TipsHelper.ShowLevelUpTip(nLevel)
end

-- 家园蓝图礼包选择蓝图界面
UIGlobalFunction["BlueprintsChoice.Open"] = function()
    if not UIMgr.GetView(VIEW_ID.PanelBlueprintChoose) then
        UIMgr.Open(VIEW_ID.PanelBlueprintChoose)
    end
end

UIGlobalFunction["ShopPanel.OpenSystemShopGroup"] = function(nGroup, nShopID)
    ShopData.OpenSystemShopGroup(nGroup, nShopID)
end

UIGlobalFunction["NPCFeeling.Open"] = function(tReturn)
    if not UIMgr.GetView(VIEW_ID.PanelXueXue) then
        UIMgr.Open(VIEW_ID.PanelXueXue, tReturn)
    end
end

UIGlobalFunction["NPCFeeling.Close"] = function()
    if UIMgr.GetView(VIEW_ID.PanelXueXue) then
        UIMgr.Close(VIEW_ID.PanelXueXue)
    end
end

UIGlobalFunction["GameGuidePanel.UpdateJoinCampState"] = function(nRecommendCamp, nDisableCamp)
    local scriptView =UIMgr.GetViewScript(VIEW_ID.PanelPvPCampJoin)
    if scriptView then
        scriptView:UpdateJoinCampState(nRecommendCamp, nDisableCamp)
    end
end

UIGlobalFunction["ExteriorSellBag.Open"] = function()
    ExteriorSellBagData.Open()
end

UIGlobalFunction["QTEPanel_HitNotify"] = function(nID)

end

UIGlobalFunction["CoinShop_Main.Open"] = function()
    if not UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
        CoinShopData.Open()
    end
end

UIGlobalFunction["CoinShop_SchoolExterior.UpdateFissionInfo"] = function(nTotalNum)
    Event.Dispatch(EventType.CoinShopSchoolExteriorUpdateFissionInfo, nTotalNum)
end

UIGlobalFunction["CloseMessageBox"] = function(szName)
    local script = UIMgr.GetViewScript(VIEW_ID.PanelNormalConfirmation)
    if script and script:GetName() == szName then
        UIMgr.Close(script)
    end
end

UIGlobalFunction["SelectCampPlanes.Open"] = function(dwMapID, bActivity, tMapList)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelCampMap)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelCampMap)
    end

    if scriptView then
        scriptView:ShowMapSelectInfo(dwMapID, bActivity, tMapList)
    end
end

UIGlobalFunction["BirthdayCelebrateCardPop.Open"] = function(nYear)
    UIMgr.Open(VIEW_ID.PanelBirthdayCardPop, nYear)
end

UIGlobalFunction["ChannelPanel.Open"] = function(dwID)
    UIMgr.Open(VIEW_ID.PanelQiXuePop)
end

UIGlobalFunction["GuildLeagueMatches.Open"] = function(dwID)
    UIMgr.Open(VIEW_ID.PanelFactionChampionship, dwID)
end

UIGlobalFunction["OpenExplorer"] = function(szURL)
    if Platform.IsMobile() then
        UIHelper.OpenWeb(szURL)
    else
        UIHelper.OpenWebWithDefaultBrowser(szURL)
    end
end

UIGlobalFunction["OpenInternetExplorer"] = function(szURL)
    -- if Platform.IsMobile() then
    --     UIHelper.OpenWeb(szURL)
    -- else
        UIHelper.OpenWebWithDefaultBrowser(szURL)
    -- end
end

UIGlobalFunction["CommandBaseData.GetPlayerInfoById"] = function(tbInfo)
    CommandBaseData.GetPlayerInfoById(tbInfo)
end

UIGlobalFunction["FancySkating.Open"] = function(dwID, dwOtherRoleID)
    if Platform.IsIos() then
        local szVersionName = GetVersionName()
        LOG.INFO("FancySkating.Open szVersionName %s", tostring(szVersionName))
        if szVersionName == "1.0.7" then
            local dialog = UIHelper.ShowConfirm("乐游记·尘世曼舞玩法需要在最新版本才可参与，请前往应用商店进行更新后再参与")
            dialog:HideCancelButton()
            return
        end
    end
    UIMgr.CloseAllPauseSceneView()
    Timer.AddFrame(UIGlobalFunction, 1, function()
       UIMgr.Open(VIEW_ID.PanelOlympics, dwID, dwOtherRoleID)
    end)
end

UIGlobalFunction["FancySkating.StartSkaingPair"] = function()
    Event.Dispatch(EventType.FancySkating_StartSkaingPair)
end

UIGlobalFunction["FancySkating.CloseSkatingPair"] = function(dwID, dwOtherRoleID)
    Event.Dispatch(EventType.FancySkating_CloseSkatingPair)
end

UIGlobalFunction["FancySkating.PairsCancel"] = function(szName)
    Event.Dispatch(EventType.FancySkating_PairsCancel, szName)
end

UIGlobalFunction["HuaZhaoPhoto.Open"] = function(nID)
    UIMgr.Open(VIEW_ID.PanelPicScroll, nID)
end

UIGlobalFunction["TongBattleTips.Open"] = function(nID)
    Event.Dispatch(EventType.ShowTongBattleTips, nID)
end

UIGlobalFunction["TongBattledragonTips.Open"] = function(nID)
    Event.Dispatch(EventType.ShowTongBattledragonTips, nID)
end

UIGlobalFunction["VideoSettingPanel.SetCameraSmoothing"] = function(bCameraSmoothing)
    CameraMgr.EnableAnimationCamera(bCameraSmoothing)
end

UIGlobalFunction["LeagueNote.Open"] = function(nRank)
    if SceneMgr.IsLoading() then
        Event.Reg(UIGlobalFunction, EventType.OnViewClose, function (nViewID)
            if nViewID == VIEW_ID.PanelLoading then
                Event.UnReg(UIGlobalFunction, EventType.OnViewClose)
                UIMgr.Open(VIEW_ID.PanelChampionshipRankPop, nRank)
            end
        end)
    else
        UIMgr.Open(VIEW_ID.PanelChampionshipRankPop, nRank)
    end
end

UIGlobalFunction["ReadMailPanel.Open"] = function(nMailID)
    UIMgr.Open(VIEW_ID.PanelMasterMail, nMailID)
end


UIGlobalFunction["Treasure_PreviewNew.Open"] = function(nBoxID, nContentType)
    local tBoxInfo = Tabel_GetTreasureBoxListByID(nBoxID)
    if tBoxInfo and tBoxInfo.nGroupID then
        if tBoxInfo.nGroupID == TREASURE_BOX_TYPE.RANDOM then
            UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, nBoxID, nContentType)
            return
        elseif tBoxInfo.nGroupID == TREASURE_BOX_TYPE.QIYU then
            UIMgr.Open(VIEW_ID.PanelQiYuTreasureBox, nBoxID, nContentType)
            return
        elseif tBoxInfo.nGroupID == TREASURE_BOX_TYPE.OPTIONAL then
            UIMgr.Open(VIEW_ID.PanelOptionalTreasureBox, nBoxID, nContentType)
            return
        end
    end
end

UIGlobalFunction["TopMenu_ShowReadMailPanelBtn"] = function(bShow)
    if bShow then
        BubbleMsgData.PushMsgWithType("ReadMailBtn", {
            szAction = function()
                UIMgr.Open(VIEW_ID.PanelMasterMail)
            end
        })
    else
        BubbleMsgData.RemoveMsg("ReadMailBtn")
    end
end
UIGlobalFunction["CloseMiddleMap"] = function()
    UIMgr.Close(VIEW_ID.PanelMiddleMap)
end

UIGlobalFunction["MiddleMap_TrackNPC"] = function(dwMapID, szName, tPoint)
    local szName = szName and UIHelper.GBKToUTF8(szName) or ""
    MapMgr.SetTracePoint(szName, dwMapID, tPoint)
end

UIGlobalFunction["ArenaCorpsPanel.Open"] = function(disablesound, peekid, szPageName)
    local tbPageName2Mode = {
        ["CheckBox_2v2"] = 1,
        ["CheckBox_3v3"] = 2,
        ["CheckBox_5v5"] = 3,
        ["CheckBox_Master"] = 5,
    }
    UIMgr.Open(VIEW_ID.PanelPvPMatching, nil, szPageName and tbPageName2Mode[szPageName], true)
end

UIGlobalFunction["JJCEquipmentDIY.Open"] = function()
    UIMgr.Open(VIEW_ID.PanelDssCustomizedSet)
end

UIGlobalFunction["MasterNote.Open"] = function(tInfo)
    UIMgr.Open(VIEW_ID.PanelDssInvitePop, tInfo)
end

UIGlobalFunction["DesertWarehouse.Open"] = function()
    UIMgr.OpenSingle(false, VIEW_ID.PanelBattleFieldXunBao)
end

UIGlobalFunction["LuckyMeetingTrace.Close"] = function()
    AdventureData.CloseTrace()
end

UIGlobalFunction["SelfieStudioBase.SetEnvPreset"] = function(dwID)
    SelfieData.SetEnvPreset(dwID)
end

UIGlobalFunction["ACC_TreasureHuntInfo.Open"] = function(dwID, nTime)
    Event.Dispatch(EventType.OnTreasureHuntInfoOpen, dwID, nTime)
end

UIGlobalFunction["ACC_TreasureHuntInfo.Close"] = function()
    Event.Dispatch(EventType.OnTreasureHuntInfoOpen)
end

UIGlobalFunction["Instrument_Main.Enter"] = function(szType)
    InstrumentData.Open(szType)
end

UIGlobalFunction["Instrument_Main.Exit"] = function()
    InstrumentData.Exit()
end

UIGlobalFunction["InstrumentData.OnWebDataSignNotify"] = function()
    MusicCodeData.OnWebDataSignNotify()
end

UIGlobalFunction["GeneralInvitation.Open"] = function(dwID)
    local tInfo = Table_GetCustomInvitation(dwID)
    if tInfo and tInfo.szPrefabName then
        local nViewID = VIEW_ID[tInfo.szPrefabName]
        if nViewID then
            UIMgr.Open(nViewID, dwID)
        end
    elseif dwID == 2 then
        UIMgr.Open(VIEW_ID.PanelChampionshipInvitePop, dwID)
    else
        UIMgr.Open(VIEW_ID.Panel130NightPop, dwID)
    end
end

UIGlobalFunction["ProgressBar.Start"] = function(key, uiid, title, endtime, interval)
    title = UIHelper.GBKToUTF8(title)
    local nSecond = (endtime - GetCurrentTime())
    local tParam = {
        szType = "Skill", -- 类型: Normal/Skill
        szFormat = title .. "(%.1f/%.1f)"  , -- 格式化显示文本
        nDuration = nSecond, -- 持续时长, 单位为秒
        bReverse = true,
    }
    TipsHelper.PlayProgressBar(tParam)
end

UIGlobalFunction["ProgressBar.Finish"] = function(key)
    TipsHelper.StopProgressBar()
end

UIGlobalFunction["SkillCDJingYuJue.Open"] = function()
    Event.Dispatch("SkillCDJingYuJue_Open")
end

UIGlobalFunction["SkillCDJingYuJue.Close"] = function()
    Event.Dispatch("SkillCDJingYuJue_Close")
end

UIGlobalFunction["MiniGame.Start"] = function(tInfo)--小游戏开始
	MiniGame.Start(tInfo)
end

UIGlobalFunction["MiniGame.OpenGuide"] = function(dwGameID)--显示小游戏指引（操作说明）
	MiniGame.OpenGuide(dwGameID)
end

UIGlobalFunction["MiniGame.CloseGuide"] = function()--关闭小游戏指引
    MiniGame.CloseGuide()
end

UIGlobalFunction["MiniGame.OpenResult"] = function(tInfo)--小游戏结算
    MiniGame.OpenResult(tInfo)
end

UIGlobalFunction["MiniGame.CloseResult"] = function()--关闭小游戏结算
    MiniGame.CloseResult()
end

UIGlobalFunction["MiniGame.OpenSelectLevel"] = function(tInfo)--打开关卡选择
    MiniGame.OpenSelectLevel(tInfo)
end

UIGlobalFunction["MiniGame.OpenJigsaw"] = function(tInfo)--打开拼图
    MiniGame.OpenJigsaw(tInfo)
end

UIGlobalFunction["MiniGame.UpdateJigsaw"] = function(tInfo)--刷新拼图
    MiniGame.UpdateJigsaw(tInfo )
end

UIGlobalFunction["MiniGame.CloseJigsaw"] = function(tInfo)--关闭拼图
    MiniGame.CloseJigsaw()
end

UIGlobalFunction["MiniGame.OpenPoetry"] = function(tInfo)--打开诗歌
	MiniGame.OpenPoetry(tInfo)
end

UIGlobalFunction["MiniGame.ClosePoetry"] = function(tInfo)--关闭诗歌
    MiniGame.ClosePoetry()
end

UIGlobalFunction["MiniGame.UpdatePoetry"] = function(tInfo)--刷新拼图
    Event.Dispatch("MiniGame_UpdatePoetry", tInfo)
end

--策划取镜头参数
UIGlobalFunction["GetCameraRTParams"] = function(nCallIndex)
	local scale, yaw, pitch = Camera_GetRTParams()
	local tInfo = {
		nCallIndex 	= nCallIndex,	--策划自定义参数，识别不同功能用
		scale 		= scale,		--镜头缩放
		yaw 		= yaw,			--水平旋转
		pitch 		= pitch,		--俯仰角
	}
	RemoteCallToServer("On_Map_GetCameraRTParams", tInfo)
end

UIGlobalFunction["Camera_TranslationOffset"] = function(x, y, z, r)
    CameraMgr.TranslationOffset(x, y, z, r)
end

UIGlobalFunction["Camera_ResetOffset"] = function(fSmoothTime)
    CameraMgr.ResetOffset(fSmoothTime)
end

UIGlobalFunction["Camera_RevertLookAt"] = function()
    local nState = GameSettingData.GetNewValue(UISettingKey.EyeTracking) and 1 or 0
    rlcmd("enable auto lookat " .. nState)
end

UIGlobalFunction["Camera_RevertAnimation"] = function()
    local bOpen = GameSettingData.GetNewValue(UISettingKey.CloseUpShot)
    CameraMgr.SetSegmentConfig(nil, nil, nil, bOpen)
end

UIGlobalFunction["Camera_EnableAnimation"] = function(bEnable)
    CameraMgr.SetSegmentConfig(nil, nil, nil, bEnable)
end

UIGlobalFunction["CueWords.Open"] = function(nKeepTime, tText, szTitle, dwID)
    Event.Dispatch(EventType.ShowCueWords, nKeepTime, tText, szTitle, dwID)
end

UIGlobalFunction["MiniGame.OpenMatch3Game"] = function()
	UIMgr.Open(VIEW_ID.PanelMatch_3)
end

UIGlobalFunction["FBShowPanel.SetView"] = function(dwPlayerID)
    Event.Dispatch(EventType.ON_OB_SET_VIEW, dwPlayerID)
end

UIGlobalFunction["MiniGame.CloseMatch3Game"] = function()
	UIMgr.Close(VIEW_ID.PanelMatch_3)
end

UIGlobalFunction["QMSoulPanel.Open"] = function(nNpcID)
    UIMgr.Open(VIEW_ID.PanelQingMing, nNpcID)
end

UIGlobalFunction["AiBodyMotionData.OnWebDataSignNotify"] = function()
    AiBodyMotionData.OnWebDataSignNotify()
end

UIGlobalFunction["OperationCenter.Open"] = function(nOperationID)
    OperationCenterData.OpenCenterView(nOperationID)
end