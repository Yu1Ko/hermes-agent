local UITipsView = class("UITipsView")

local Def = {
    QuickEquipShowTime = 15,
    DefaultLiveTime = 3,
    TooLoogEventCount = 2,
    ShowNewEmotionTime = 10,
    ShowRemotePanelTime = 10,
    ShowSpecailGift = 10,
}

local TIPS_TYPE = {
    Normal = 1,
    NAchievement = 2,
    NDesignation = 3,
}

local ANI_TYPE = {
    [UNLOCK_ANITYPE.MENU] = "AniNewFeatureShow",
    [UNLOCK_ANITYPE.RIGHTTOP] = "AniNewFeatureShow2"
}

local KILL_COMBO_TIME = 7 --连杀提示 持续时间

local function Table_GetSpecialHoardSkill()
    --记录改蓄力技能全部职业都是普通技能条
    local tab = g_tTable.SpecialHoardSkill
    local count = tab:GetRowCount()
    local tRes = {}
    local t
    for i = 2, count, 1 do
        t = tab:GetRow(i)
        table.insert(tRes, t)
    end
    return tRes
end

local function IsSpecialSkill(dwSkillID)
    local bRet = false
    local tSpecialSkillList = Table_GetSpecialHoardSkill()
    for _, tSKillData in pairs(tSpecialSkillList) do
        if tSKillData.dwSkillID == dwSkillID then
            bRet = true
            break
        end
    end
    return bRet
end

local function IsMatchControlPlayerID(dwCasterID)
    local hPlayer = GetControlPlayer()
    if not hPlayer then
        return false
    end

    if hPlayer.dwID == dwCasterID then
        return true
    end

    local tKungfu = hPlayer.GetKungfuMount()
    if tKungfu and tKungfu.dwBelongSchool == BELONG_SCHOOL_TYPE.WU_XIANG then
        local pet = hPlayer.GetPet()
        if pet and pet.dwID == dwCasterID then
            return true
        end
    end

    return false
end

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITipsView:_LuaBindList()
    self.WidgetAchievementGet = self.WidgetAchievementGet --- 新成就tip - 顶部的 widget
    self.AniAchievementGet = self.AniAchievementGet --- 新成就tip - 动画
    self.LabelAchievementName = self.LabelAchievementName --- 新成就tip - 成就名称
    self.LabelAchievementPoint = self.LabelAchievementPoint --- 新成就tip - 资历点数
    self.ImgAchievementIcon = self.ImgAchievementIcon --- 新成就tip - 成就图标
    self.BtnOpenAchievement = self.BtnOpenAchievement --- 新成就tip - 点击跳转到对应成就 的按钮

    self.WidgetHintContent = self.WidgetHintContent --- moba击杀tip的挂载组件
end

function UITipsView:OnEnter(bTop)

    self.bTop = bTop
    self.NodeShowTimeList = {}
    self.CharacterHeadBuffDict = {}
    self.ArenaTopBuffDict = {}
    self:RegEvent()
    self:CloseAllTips()

    if self.bTop then
        self.scriptGetItemHint = self.scriptGetItemHint or UIHelper.AddPrefab(PREFAB_ID.WidgetGetItemHintArea, self.WidgetGetItemHintAnchor)
        self:UpdateGetItemHintVisible()
    else
        UIHelper.SetLocalZOrder(self._rootNode, 1)
    end
    self:InitRightTopTimelyHint()
    TipsHelper.UpdateAllShieldTip()

end

function UITipsView:OnExit()
    self:UnRegEvent()
    self:_StopProgressBar()
    self:StopCountDown()

    for _, v in pairs(self.tbTips or {}) do
        if v.cellPrefabPool then
            v.cellPrefabPool:Dispose()
            v.cellPrefabPool = nil
        end
    end
end

function UITipsView:RegEvent()
    if self.bTop then
        Event.Reg(self, "SYS_MSG", function(szType, dwCharacterID, dwKillerID)
            if szType == "UI_OME_DEATH_NOTIFY" and g_pClientPlayer and dwKillerID == g_pClientPlayer.dwID then
                -- 仅在没有全屏界面打开的状态下显示
                if UIMgr.GetFullPageViewCount() <= 0 then
                    local hTarget = GetPlayer(dwCharacterID)
                    if hTarget then
                        self:ShowKillHint(UIHelper.GBKToUTF8(hTarget.szName))
                    end
                end
            end
        end)

        Event.Reg(self, EventType.ShowNormalTip, function(Text, bRichText, funcTipEnd)
            -- self:ShowNormalTips(Text, bRichText)
            self:AddNormalTip(Text, bRichText, funcTipEnd)
        end, false)

        Event.Reg(self, EventType.ShowImportantTip, function(tbEvent)
            local nLiveTime = tbEvent[5] or Def.DefaultLiveTime
            if nLiveTime <= 0 then
                nLiveTime = Def.DefaultLiveTime
            end
            if TipsHelper.GetEventArrCount(TipsHelper.Def.Queue2) >= Def.TooLoogEventCount then
                -- 排队太长时, 显示时长减半
                nLiveTime = nLiveTime / 2
            end

            local tbNextTip = TipsHelper.GetNextEventTip(TipsHelper.Def.Queue2)
            if tbNextTip and TipsHelper.IsSameImportantTip(tbNextTip, tbEvent) then--当队列中下一条还是同颜色的tip，持续时间改为1秒, 且不播放隐藏动画
                nLiveTime = 1
                tbEvent.bPlayHideAnim = false
            end

            tbEvent.nEndTime = tbEvent.nStartTime + nLiveTime
            self:ShowImportantTip(tbEvent)
        end, false)

        Event.Reg(self, EventType.ShowAnnounceTip, function(tMsg)
            self:OnShowAnnounceTip(tMsg)
        end)

        Event.Reg(self, EventType.ShowEquipScore, function(tbData)
            self:OnShowEquipScore(tbData)
        end)

        Event.Reg(self, EventType.ShowLikeTip, function()
            self:OnShowLikeTip()
        end)

        Event.Reg(self, EventType.ShowInteractTip, function()
            self:OnShowInteractTip()
        end)

        Event.Reg(self, EventType.ShowTeamTip, function()
            self:OnShowTeamTip()
        end)


        Event.Reg(self, EventType.ShowOptickRecordTip, function()
            self:OnShowOptickRecordTip()
        end)

        Event.Reg(self, EventType.ShowAssistNewbieInviteTip, function()
            self:OnShowAssistNewbieInviteTip()
        end)

        Event.Reg(self, EventType.ShowMobaSurrenderTip, function()
            self:OnShowMobaSurrenderTip()
        end)

        Event.Reg(self, EventType.ShowTeamReadyConfirmTip, function()
            self:OnShowTeamReadyConfirmTip()
        end)

        Event.Reg(self, EventType.ShowRoomTip, function()
            self:OnShowRoomTip()
        end)

        Event.Reg(self, EventType.ShowTradeTip, function()
            self:OnShowTradeTip()
        end)

        Event.Reg(self, EventType.ShowMessageBubble, function()
            self:OnShowMessageBubble()
        end)

        Event.Reg(self, EventType.PlayCountDown, function(nTime, bShowStart)
            self:PlayCountDown(nTime, bShowStart)
        end)

        Event.Reg(self, EventType.StopCountDown, function()
            self:StopCountDown()
        end)

        --RemoteFunction.CountDown
        Event.Reg(self, EventType.UpdateCountDown, function(nLeftTime, szPanelName, dwDuration)
            self:UpdateCountDown(nLeftTime, szPanelName, dwDuration)
        end)
    else
        Event.Reg(self, EventType.ShowPlaceTip, function(tbEvent)
            self:ShowPlaceTip(tbEvent)
        end, false)

        Event.Reg(self, EventType.ShowQuestComplete, function(nQuestID)
            self:ShowQuestComplete(nQuestID)
        end)

        Event.Reg(self, EventType.PlayProgressBarTip, function(tParam)
            assert(tParam)
            self:OnPlayProgressBar(tParam)
        end)
        Event.Reg(self, EventType.StopProgressBarTip, function()
            self:OnStopProgressBar()
        end)

        Event.Reg(self, EventType.ShowLevelUpTip, function(nLevel)
            self:OnShowLevelUpTip(nLevel)
        end)

        Event.Reg(self, EventType.ShowNewAchievement, function(dwAchievementID)
            -- self:OnShowNewAchievement(dwAchievementID)
            self:AddNewAchievement(dwAchievementID)
        end)

        Event.Reg(self, EventType.CloseNewAchievement, function()
            self:OnCloseAchievement()
        end)

        Event.Reg(self, EventType.ShowNewDesignation, function(nID, bPrefix)
            self:AddNewDesignation(nID, bPrefix)
        end)

        Event.Reg(self, EventType.CloseNewDesignation, function()
            self:OnCloseDesignation()
        end)

        Event.Reg(self, "ON_SEASON_MISSION_COMPLATED", function(tInfo)
            self:OnSeasonMissionComplated(tInfo)
        end)

        Event.Reg(self, EventType.ShowNewFeatureTip, function(nSystemID)
            self:OnShowNewFeatureTip(nSystemID)
        end)

        Event.Reg(self, EventType.OnViewOpen, function(nViewID)
            if nViewID == VIEW_ID.PanelRevive or nViewID == VIEW_ID.PanelPlotDialogue then
                UIHelper.SetVisible(self.WidgetAnchorOperationHint, false)
            end
        end)

        Event.Reg(self, EventType.OnViewClose, function(nViewID)
            if nViewID == VIEW_ID.PanelRevive or nViewID == VIEW_ID.PanelPlotDialogue then
                self.nShowOperationHintTime = Timer.RealtimeSinceStartup()
                UIHelper.SetVisible(self.WidgetAnchorOperationHint, true)
            end
        end)

        Event.Reg(self, EventType.ShowQuickEquipTip, function(tbEquipItem)
            -- self:OnShowQuickEquipTip(dwBox, dwX)
            self:AddQuickEquipTip(tbEquipItem)
        end)

        Event.Reg(self, EventType.OnCloseQuickEquipTip, function(tbEquipItem)
            self:OnCloseQuickEquipTip()
        end)

        Event.Reg(self, EventType.OnShowNpcHeadBalloon, function(characterID, szContent, nChannel)
            self:ShowNpcHeadBalloon(characterID, szContent, nChannel)
        end)

        Event.Reg(self, "PLAYER_LEAVE_SCENE", function(dwPlayerID)
            local player = PlayerData.GetClientPlayer()
            if not player then
                return
            end

            if dwPlayerID == player.dwID then
                self.CharacterHeadBuffDict = {}
                self.ArenaTopBuffDict = {}
                self.scriptChuangYi = nil
                UIHelper.RemoveAllChildren(self.WidgetAnchorNpcHeadBuff)
                UIHelper.RemoveAllChildren(self.WidgetAnchorPlayerHeadBuff)
                UIHelper.RemoveAllChildren(self.WidgetAnchorArenaTopBuff)
            elseif dwPlayerID then
                self:HideArenaTopBuff(dwPlayerID)
            end
        end)

        Event.Reg(self, EventType.OnHideCharacterHeadBuff, function(dwPlayerID)
            self.CharacterHeadBuffDict = {}
            UIHelper.RemoveAllChildren(self.WidgetAnchorNpcHeadBuff)
            UIHelper.RemoveAllChildren(self.WidgetAnchorPlayerHeadBuff)
        end)

        Event.Reg(self, EventType.OnShowCharacterHeadBuff, function(characterID, tBuffList)
            self:ShowCharacterHeadBuff(characterID, tBuffList)
        end)

        Event.Reg(self, EventType.OnShowSpecialEnhanceBuff, function(tBuff)
            self:ShowChuangYiFoodBuff(tBuff)
        end)

        Event.Reg(self, EventType.OnShowArenaTopBuff, function(dwPlayerID)
            self:ShowArenaTopBuff(dwPlayerID)
        end)

        Event.Reg(self, EventType.OnHideArenaTopBuff, function(dwPlayerID)
            self:HideArenaTopBuff(dwPlayerID)
        end)

        Event.Reg(self, EventType.OnHideAllArenaTopBuff, function()
            self.ArenaTopBuffDict = {}
            UIHelper.RemoveAllChildren(self.WidgetAnchorArenaTopBuff)
        end)

        Event.Reg(self, EventType.OnNpcLeaveScene, function(dwCharacterID)
            if self.CharacterHeadBuffDict and self.CharacterHeadBuffDict[dwCharacterID] then
                local scriptHeadBuff = self.CharacterHeadBuffDict[dwCharacterID]
                scriptHeadBuff:HideNode(true)
                UIHelper.RemoveFromParent(scriptHeadBuff._rootNode, true)
                self.CharacterHeadBuffDict[dwCharacterID] = nil
            end
        end)

        Event.Reg(self, EventType.OnShowNpcSpeechSoundsBalloon, function(dwID)
            self:OnShowNpcVoice(dwID)
        end)

        Event.Reg(self, EventType.OnFuncSlotChanged, function(tbAction)
            Timer.DelTimer(self, self.nSprintTipTimerID)
            if tbAction then
                self.bSprintTip = true
                self:UpdateShowPlaceTipVis()
                self.nSprintTipTimerID = Timer.Add(self, SprintData.nSprintTipsShowTime, function()
                    self.bSprintTip = false
                end)
            else
                self.bSprintTip = false
            end
        end)

        Event.Reg(self, EventType.UpdateDeathNotify, function(deadID, killerID)
            --self:OnDeathNotify(deadID, killerID) --2023.12.18 暂时屏蔽
        end)

        Event.Reg(self, EventType.ShowExtractSettlement, function(tInfo)
            self:OnShowExtractSettlement(tInfo)
        end)

        Event.Reg(self, "GeneralCounterSFX_RefleshCounter", function(dwID, nCount)
            if dwID == 2 then
                -- 寻宝模式的撤离倒计时
                self:ShowExtractCounter(dwID, nCount)
            end
        end)

        Event.Reg(self, "GeneralCounterSFX_Close", function(dwID, nCount)
            self:ShowExtractCounter()
        end)

        Event.Reg(self, "RemainingTimeNotify_Open", function(nSecond)
            self:ShowExtractReaminingTime(nSecond)
        end)

        Event.Reg(self, "RemainingTimeNotify_Close", function()
            self:ShowExtractReaminingTime()
        end)

        Event.Reg(self, EventType.ShowHintSFX, function(dwID)
            self:ShowHintSFX(dwID)
        end)

        Event.Reg(self, EventType.ShowCampHint, function(nBossID)
            self:ShowCampHint(nBossID)
        end)

        Event.Reg(self, EventType.OnAccountLogout, function()
            self:ReleaseAllKillPrefab()
        end)

        Event.Reg(self, EventType.RefreshAltar, function(szAltar, tNumber, tTime, bStart)
            self:RefreshAltar(szAltar, tNumber, tTime, bStart)
        end)

        Event.Reg(self, EventType.RefreshBoss, function()
            self:RefreshBoss()
        end)

        Event.Reg(self, EventType.OnStartEvent, function()
            self:OnStartEvent()
        end)

        Event.Reg(self, EventType.ShowWinterFestivalTip, function(dwID)
            self:ShowHintWinterFestivalSkill(dwID)
        end)

        Event.Reg(self, EventType.ShowRewardHint, function(nRewardType, szText, tbItem, tbOtherReward, funcConfirm,
                                                           funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
            self:ShowRewardHint(nRewardType, szText, tbItem, tbOtherReward, funcConfirm,
                    funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
        end)

        Event.Reg(self, EventType.ShowNewEmotionTip, function(dwActionID)
            self:ShowNewEmotionTip(dwActionID)
        end)

        Event.Reg(self, EventType.OnOpenRemotePanel, function(szName, tData)
            self:OnOpenRemotePanel(szName, tData)
        end)

        -- Event.Reg(self, EventType.OnUpdateRemotePanel, function(szName, tData)
        --     self:OnUpdateRemotePanel(szName, tData)
        -- end)

        Event.Reg(self, EventType.CloseRemotePanel, function(szName)
            self:CloseRemotePanel(szName)
        end)

        Event.Reg(self, EventType.OpenSpecailGift, function(dwID)
            self:OpenSpecailGift(dwID)
        end)

        Event.Reg(self, EventType.OnMiniGameStart, function(tInfo)
            self:ShowMiniGameStart(tInfo)
        end)

        Event.Reg(self, EventType.ShowCueWords, function(nKeepTime, tText, szTitle, dwID)
            self:ShowCueWords(nKeepTime, tText, szTitle, dwID)
        end)

        Event.Reg(self, "OPEN_CROSSHAIR", function(tParam)
            self:ShowAim(tParam)
        end)

        Event.Reg(self, "CLOSE_CROSSHAIR", function()
            self:HideAim()
        end)
    end

    Event.Reg(self, "DO_SKILL_PREPARE_PROGRESS", function(nTotalFrame, dwSkillID, dwSkillLevel, dwCasterID)
        LOG.INFO("DO_SKILL_PREPARE_PROGRESS %d", dwSkillID)

        if  nTotalFrame <= 0 or not IsMatchControlPlayerID(dwCasterID) then
            return
        end

        local skillName = Table_GetSkillName(dwSkillID, dwSkillLevel)
        local szProgressBarType = "Skill"
        skillName = UIHelper.GBKToUTF8(skillName)

        local szFormat = skillName .. " (%.1f/%.2f)"
        if not SkillData.IsSkillBelongToCurrentKungFu(dwSkillID, dwSkillLevel) then
            --szFormat = skillName .. "(%.2f/%.2f)"  -- 不是玩家当前心法专属技能时的逻辑
            szProgressBarType = "Normal"
        end

        if Table_GetSkillOTActionShowType(dwSkillID, dwSkillLevel) == SKILL_OTACTION_SHOW_TYPE.Hide then
            return
        end

        local tParam = {
            szType = szProgressBarType, -- 类型: Normal/Skill
            szFormat = szFormat, -- 格式化显示文本
            nDuration = nTotalFrame / GLOBAL.GAME_FPS, -- 持续时长, 单位为秒
            dwSkillID = dwSkillID,
            dwSkillLevel = dwSkillLevel,
            bAutoCastSkill = true
        }
        TipsHelper.PlayProgressBar(tParam)
    end)

    Event.Reg(self, "DO_SKILL_CHANNEL_PROGRESS", function(nTotalFrame, dwSkillID, dwSkillLevel, dwCasterID)
        if nTotalFrame <= 0 or not IsMatchControlPlayerID(dwCasterID) then
            return
        end

        local skillName = Table_GetSkillName(dwSkillID, dwSkillLevel)
        skillName = UIHelper.GBKToUTF8(skillName)
        local tSkillInfo = TabHelper.GetUISkillMap(dwSkillID) or SkillData.GetUIDynamicSkillMap(dwSkillID, dwSkillLevel)
        local nProgressBarDirection = (tSkillInfo and tSkillInfo.nProgressBarDirection) or 0
        local bReverse = nProgressBarDirection ~= 2
        local szProgressBarType = "Skill"
        local szFormat = skillName .. " (%.1f/%.2f)"

        if nProgressBarDirection == 0 then
            return  -- 为0时不显示读条
        end

        if not SkillData.IsSkillBelongToCurrentKungFu(dwSkillID, dwSkillLevel) then
            --szFormat = skillName .. "(%.2f/%.2f)"  -- 不是玩家当前心法专属技能时的逻辑
            szProgressBarType = "Normal"
        end

        LOG.INFO("DO_SKILL_CHANNEL_PROGRESS %s %d %d", skillName, dwSkillID, dwSkillLevel)

        local tParam = {
            szType = szProgressBarType, -- 类型: Normal/Skill
            szFormat = szFormat, -- 格式化显示文本
            nDuration = nTotalFrame / GLOBAL.GAME_FPS, -- 持续时长, 单位为秒
            bReverse = bReverse,
            dwSkillID = dwSkillID,
            dwSkillLevel = dwSkillLevel,
            bAutoCastSkill = true
        }
        TipsHelper.PlayProgressBar(tParam)
    end)

    Event.Reg(self, "OT_ACTION_PROGRESS_UPDATE", function(arg0)
        if self.tDataOfProgressBar then
            self.tDataOfProgressBar.nChangedFrame = self.tDataOfProgressBar.nChangedFrame + arg0
        end
    end)

    Event.Reg(self, "DO_SKILL_HOARD_PROGRESS", function(nTotalFrame, dwSkillID, dwSkillLevel, dwCasterID)
        if IsMatchControlPlayerID(dwCasterID) then
            LOG.INFO("DO_SKILL_HOARD_PROGRESS %d %d %d", nTotalFrame, dwSkillID, dwSkillLevel)

            local hPlayer = GetControlPlayer()
            if not (hPlayer and nTotalFrame > 0) then
                return
            end
            local skillName = Table_GetSkillName(dwSkillID, dwSkillLevel)
            skillName = UIHelper.GBKToUTF8(skillName)
            local bIsSpecialSkill = IsSpecialSkill(dwSkillID)
            local szType = "Normal"

            if hPlayer and bIsSpecialSkill then
                --TODO 丐帮、长歌是否也有相应的蓄力条？端游OTActionBar.lua: 439
                if hPlayer.dwForceID == FORCE_TYPE.CANG_YUN then
                    if hPlayer.nMoveState == MOVE_STATE.ON_RUN then
                        szType = "CANGYUN_SPRIT_GROUND"
                    else
                        szType = "CANGYUN_SPRIT_SKY"
                    end
                end
            end

            local tParam = {
                szType = szType, -- 类型: Normal/Skill
                szFormat = skillName .. " (%.1f/%.2f)", -- 格式化显示文本
                nDuration = nTotalFrame / GLOBAL.GAME_FPS, -- 持续时长, 单位为秒
                dwSkillID = dwSkillID,
                dwSkillLevel = dwSkillLevel,
                bHoard = true,
            }
            TipsHelper.PlayProgressBar(tParam)
        end
    end)

    Event.Reg(self, "DO_SKILL_HOARD_SUCCESS", function(bSuccess)
        self:OnStopProgressBar()
    end)

    Event.Reg(self, "OnFightProgressNotify", function(nForceType, fPercent)
        --print("[BattleField] OnFightProgressNotify", nForceType, fPercent)
        if nForceType == "LeaveFight" then
            UIHelper.SetVisible(self.WidgetAnchorPvpHint, false)
            return
        end

        UIHelper.SetVisible(self.WidgetAnchorPvpHint, true)

        nForceType = tonumber(nForceType)
        fPercent = fPercent * 100
        if nForceType == CAMP.GOOD then
            UIHelper.SetProgressBarPercent(self.SliderLeft, fPercent)
            UIHelper.SetProgressBarPercent(self.SliderRight, 0)
        elseif nForceType == CAMP.EVIL then
            UIHelper.SetProgressBarPercent(self.SliderLeft, 0)
            UIHelper.SetProgressBarPercent(self.SliderRight, fPercent)
        end
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        self:_StopSwimBar()
        self:ReleaseAllKillPrefab()
    end)

    self:RegSwimEvent()

    Event.Reg(self, EventType.UILoadingStart, function()
        self:UpdateGetItemHintVisible()
    end)

    Event.Reg(self, EventType.UILoadingFinish, function()
        self:UpdateGetItemHintVisible()
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelVideoPlayer then
            self:UpdateGetItemHintVisible()
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelVideoPlayer then
            self:UpdateGetItemHintVisible()
        end
    end)

    Event.Reg(self, EventType.OnShieldTip, function(szEvent, tbData)
        local bClose = tbData.bClose
        if bClose then
            -- self[string.format("Close", ...)]()--关闭
        else
            local func = self[string.format("Update%sVis", szEvent)]
            if func then
                func(self)
            else
                if self.bTop then
                    self:updateTimlyHintNewAnchoreVis()
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnUnShieldTip, function(szEvent, bClose)
        if not bClose then
            local func = self[string.format("Update%sVis", szEvent)]
            if func then
                func(self)
            else
                if self.bTop then
                    self:updateTimlyHintNewAnchoreVis()
                end
            end
        end
    end)

    Event.Reg(self, "ShowMobaBattleMsg", function(szLeft, szRight, szSfxPath)
        self:ShowMobaBattleMsg(szLeft, szRight, szSfxPath)
    end)

    Event.Reg(self, EventType.ShowMobaBattleMsgGeneralMsg, function(szMsg, szBgImgPath)
        self:ShowMobaBattleMsgGeneralMsg(szMsg, szBgImgPath)
    end)

    Event.Reg(self, EventType.ShowMobaBattleMsgGeneralMsgEx, function(szMessage, szBgImgPath, szSfxPath)
        self:ShowMobaBattleMsgGeneralMsgEx(szMessage, szBgImgPath, szSfxPath)
    end)

    Event.Reg(self, EventType.ShowMobaBattleMsgOneSidedMsg, function(szMessage, szMsgBgImgPath, szImgAvatarPath, szImgAvatarFramePath, szImgAvatarFrameTailPath)
        self:ShowMobaBattleMsgOneSidedMsg(szMessage, szMsgBgImgPath, szImgAvatarPath, szImgAvatarFramePath, szImgAvatarFrameTailPath)
    end)

    Event.Reg(self, EventType.ShowMobaBattleMsgTwoSidedMsg, function(tLeftInfo, tRightInfo, aAssistKillKungfuIDs, szCenterBgImgPath, szCenterTopImgPath, szCenterBottomImgPath, szMessage, szSfxPath, szSfx2Path)
        self:ShowMobaBattleMsgTwoSidedMsg(tLeftInfo, tRightInfo, aAssistKillKungfuIDs, szCenterBgImgPath, szCenterTopImgPath, szCenterBottomImgPath, szMessage, szSfxPath, szSfx2Path)
    end)

    Event.Reg(self, EventType.ShowTongBattleTips, function(nID)
        self:ShowTongBattleTips(nID)
    end)

    Event.Reg(self, EventType.ShowTongBattledragonTips, function(nID)
        self:ShowTongBattledragonTips(nID)
    end)

    Event.Reg(self, "ON_OPENTONGWAR_BATTLEINFO_NOTIFY", function(bIsOpen, nMapLevel)
        if bIsOpen then
            self:ShowTongWarEnterTip(nMapLevel)
        end
    end)

    Event.Reg(self, EventType.ShowTreasureBattleFieldHint, function(tbData)
        self:ShowTreasureBattleFieldHint(tbData)
    end)
end

function UITipsView:RegSwimEvent()
    Event.Reg(self, EventType.OnShowSwimmingProgress, function()
        self:_StopProgressBar()
        self:_PlaySwimBar()
    end)
    Event.Reg(self, EventType.OnHideSwimmingProgress, function()
        self:OnStopProgressBar()
    end)
end

function UITipsView:UnRegEvent()
    Event.UnRegAll(self)
end

function UITipsView:CloseAllTips()
    local tbCloseTips = {}
    if self.bTop then
        for i, node in ipairs(self.tbAniNormalChild) do
            table.insert(tbCloseTips, node)
        end

        for i, node in ipairs(self.tbAniLmportantNormalChild) do
            table.insert(tbCloseTips, node)
        end
    else
        for i, node in ipairs(self.tbAniPlayHintChild) do
            table.insert(tbCloseTips, node)
        end
    end
    self:CloseTip(tbCloseTips)
end

function UITipsView:IsInitTipPrefab(nType)
    return self.tbTips and self.tbTips[nType] ~= nil
end

function UITipsView:InitTipPrefab(nType, nMaxTipNum, nPrefabID, parent, fnCanShow)
    if not self.tbTips then
        self.tbTips = {}
    end
    if self:IsInitTipPrefab(nType) then
        return
    end

    self.tbTips[nType] = {}
    self.tbTips[nType].nMaxTipNum = nMaxTipNum
    self.tbTips[nType].cellPrefabPool = PrefabPool.New(nPrefabID, nMaxTipNum)
    self.tbTips[nType].parent = parent
    self.tbTips[nType].cache = {}
    self.tbTips[nType].tbTipView = {}
    self.tbTips[nType].fnCanShow = fnCanShow
end

function UITipsView:TryAddTip(nType, tbData)

    if not self:IsInitTipPrefab(nType) then
        return
    end

    local tbTipsView = self.tbTips[nType].tbTipView
    local nTipsNum = self.tbTips[nType].nMaxTipNum
    local cellPrefabPool = self.tbTips[nType].cellPrefabPool
    local parent = self.tbTips[nType].parent
    local cache = self.tbTips[nType].cache
    local mutex = self.tbTips[nType].mutex
    local fnCanShow = self.tbTips[nType].fnCanShow

    --互斥Tips，需要等同一类型的所有Tips显示完成才能显示另一类型的Tips
    if mutex and self:IsInitTipPrefab(mutex) then
        if #tbTipsView <= 0 and #self.tbTips[mutex].tbTipView > 0 then
            table.insert(cache, tbData)
            return
        end
    end

    if fnCanShow and (not fnCanShow(self.tbTips[nType], tbData)) then
        return
    end

    if #tbTipsView == nTipsNum then
        -- local node = tbTipsView[1]._rootNode
        -- cellPrefabPool:Recycle(node)
        -- table.remove(tbTipsView, 1)
        table.insert(cache, tbData)
        return
    end

    self:AddTip(nType, tbData)
end

function UITipsView:AddTip(nType, tbData)

    local cellPrefabPool = self.tbTips[nType].cellPrefabPool
    local parent = self.tbTips[nType].parent
    local tbTipsView = self.tbTips[nType].tbTipView

    tbData.callback = function(node)
        self:RemoveTip(nType, node)
    end

    local node, scriptView = cellPrefabPool:Allocate(parent, tbData)
    table.insert(tbTipsView, scriptView)

    UIHelper.LayoutDoLayout(parent)
end

function UITipsView:NextTip(nType)
    local cache = self.tbTips[nType].cache
    if #cache >= 1 then
        local tbData = table.remove(cache, 1)
        self:AddTip(nType, tbData)
    else
        local mutex = self.tbTips[nType].mutex
        if not mutex or not self:IsInitTipPrefab(mutex) then
            return
        end

        local mutexCache = self.tbTips[mutex].cache
        if #mutexCache >= 1 then
            self:NextTip(mutex)
        end
    end
end

function UITipsView:RemoveTip(nType, node)

    local tbTipsView = self.tbTips[nType].tbTipView
    local cellPrefabPool = self.tbTips[nType].cellPrefabPool
    local parent = self.tbTips[nType].parent

    for nIndex, script in ipairs(tbTipsView) do
        if script._rootNode == node then
            table.remove(tbTipsView, nIndex)
            break
        end
    end

    cellPrefabPool:Recycle(node)

    UIHelper.LayoutDoLayout(parent)

    self:NextTip(nType)
end


function UITipsView:AddNormalTip(Text, bRichText, funcTipEnd)

    self:InitTipPrefab(TIPS_TYPE.Normal, 3, PREFAB_ID.WidgetNormalHintCell, self.LayoutNormalHint, function(tbTips, tbData)
        local tbTipsView = tbTips.tbTipView
        for index, script in ipairs(tbTipsView) do
            if script:GetText() == tbData.szText then
                return false
            end
        end
        return true
    end)

    local tbData = {}
    tbData.szText = Text
    tbData.bRichText = bRichText
    tbData.funcTipEnd = funcTipEnd
    self:TryAddTip(TIPS_TYPE.Normal, tbData)
end

function UITipsView:ShowImportantTip(tbEvent)
    -- 这里再强制判断一下是否是富文本字符串
    if not UIHelper.IsRichText(Text) then
        bRichText = false
    end

    local Color = tbEvent[2]
    local Text = tbEvent[3]
    local bRichText = tbEvent[4]

    UIHelper.SetVisible(self.WidgetInoperableHint, true)
    UIHelper.SetVisible(self.WidgetImportantNormal, true)
    UIHelper.SetVisible(self.AniLmportantNormal, true)

    local ImgImportant = nil
    if bRichText then
        ImgImportant = "ImgRichTextImportant" .. Color
    else
        ImgImportant = "ImgImportant" .. Color
    end

    local ShowNode = nil
    -- local nodes = UIHelper.GetChildren(self.AniLmportantNormal)
    for i, node in ipairs(self.tbAniLmportantNormalChild) do
        local name = tostring(node:getName())
        UIHelper.SetVisible(node, name == ImgImportant)
        if name == ImgImportant then
            ShowNode = node
            local label = UIHelper.GetChildren(node)[1]
            if label then
                if bRichText then
                    local nFontSize = label:getFontSize()
                    local nWidth = UIHelper.GetUtf8RichTextWidth(Text, label:getFontSize())
                    if nWidth > TIPS_MAX.RichText then
                        nWidth = TIPS_MAX.RichText
                    end
                    UIHelper.SetWidth(label, nWidth + 30)
                    UIHelper.SetRichText(label, Text)
                    UIHelper.SetRichTextCanClick(label, false)
                    UIHelper.LayoutDoLayout(label:getParent())
                else
                    Text = string.gsub(Text, "[\n]+$", "")
                    Text = UIHelper.LimitUtf8Len(Text, TIPS_MAX.Normal)

                    local nFontSize = label:getTTFConfig().fontSize
                    local nWidth = UIHelper.GetUtf8RichTextWidth(Text, nFontSize, nil, true) + 30
                    UIHelper.SetString(label, Text)
                    UIHelper.SetWidth(label, nWidth)
                    UIHelper.LayoutDoLayout(label:getParent())
                end
            end
        end
    end


    local Animation = { "AniLmportantNormalShow", "AniLmportantNormalHide" }--先暂时这样找，后面看从节点取

    self:PlayAnim(TipsHelper.Def.Queue2, self.AniLmportantNormal, Animation, tbEvent, ShowNode)
end

function UITipsView:ShowPlaceTip(tbEvent)
    if self.bSprintTip then
        return
    end

    local Color = tbEvent[2]
    local Text = tbEvent[3]

    UIHelper.SetVisible(self.WidgetInoperableHint, true)
    -- UIHelper.SetVisible(self.WidgetPlaceHint, true)
    self:UpdateShowPlaceTipVis()

    UIHelper.SetVisible(self.AniPlayHint, true)


    -- local nodes = UIHelper.GetChildren(self.AniPlayHint)
    local WidgetPlaceHint = "WidgetPlaceHint" .. Color
    local ShowNode = nil
    for i, node in ipairs(self.tbAniPlayHintChild) do
        local name = tostring(node:getName())
        UIHelper.SetVisible(node, name == WidgetPlaceHint)
        if name == WidgetPlaceHint then
            ShowNode = node
        end
    end
    UIHelper.SetVisible(self.LabelPlaceHint, true)
    UIHelper.SetString(self.LabelPlaceHint, Text)
    -- self:PlayPlaceTipAnim(Color)

    local Animation = "AniPlaceHintShow"
    self:PlayAnim(TipsHelper.Def.Queue2, self.AniPlayHint, Animation, tbEvent, ShowNode, self.LabelPlaceHint)

end

function UITipsView:ShowQuestComplete(nQuestID)
    if not self.scriptQuestComplete then
        self.scriptQuestComplete = UIHelper.AddPrefab(PREFAB_ID.WidgetQuestComplete, self.WidgetQuestComplete)
    end

    local anim = self.scriptQuestComplete.AniQuestCompleteHint
    UIHelper.StopAllAni(self.scriptQuestComplete)
    UIHelper.PlayAni(self.scriptQuestComplete, anim, "AniQuestCompleteHint", function()
        UIHelper.RemoveAllChildren(self.WidgetQuestComplete)
        self.scriptQuestComplete = nil
    end)
end

--播放倒计时
function UITipsView:PlayCountDown(nCountDown, bShowStart)
    if not self.scriptCountDown then
        self.scriptCountDown = UIHelper.AddPrefab(PREFAB_ID.WidgetCountDown, self.WidgetAnchorCountDown)
    end
    self.scriptCountDown:PlayCountDown(nCountDown, bShowStart)
end

function UITipsView:StopCountDown()
    if self.scriptCountDown then
        self.scriptCountDown:StopCountDown()
    end
end

--RemoteFunction.CountDown
function UITipsView:UpdateCountDown(nLeftTime, szPanelName, dwDuration)
    --print("UpdateCountDown", nLeftTime, szPanelName, dwDuration)

    --先全用通用的，其他逻辑见端游CountDownPanel.lua: 20
    if nLeftTime == "Close" then
        self:StopCountDown()
        return
    end

    if not self.scriptCountDown then
        ---@type UIWidgetCountDown
        self.scriptCountDown = UIHelper.AddPrefab(PREFAB_ID.WidgetCountDown, self.WidgetAnchorCountDown)
    end
    --- 通过远程调用触发倒计时时，如果倒计时到0，部分玩法内，触发开始的动画
    local bShowStart = BattleFieldData.IsInBattleField() or BattleFieldData.IsInMobaBattleFieldMap() or BattleFieldData.IsInTongWarFieldMap()
    self.scriptCountDown:UpdateCountDown(nLeftTime, nil, bShowStart)
end

function UITipsView:PlayAnim(nQueueIndex, AnimNode, Anim, tbEvent, ...)
    if type(Anim) ~= "table" then
        Anim = { Anim }
    end

    local tbNodes = { ... }

    local function CloseTips(bPlayHideAnim)
        if bPlayHideAnim == nil then bPlayHideAnim = true end
        if Anim[2] and bPlayHideAnim then
            UIHelper.PlayAni(self, AnimNode, Anim[2], function()
                self:CloseTip(tbNodes)
                TipsHelper.ClearCurEvent(nQueueIndex)
                TipsHelper.NextTip(nQueueIndex)
            end)
        else
            self:CloseTip(tbNodes)
            TipsHelper.ClearCurEvent(nQueueIndex)
            TipsHelper.NextTip(nQueueIndex)
        end
    end

    self:AddNodeShowTimeList(tbNodes[1])
    UIHelper.PlayAni(self, AnimNode, Anim[1], function()
        self:ReduceNodeShowTimeList(tbNodes[1])
        if self:NodeCanBeDelete(tbNodes[1]) then
            if tbEvent.nEndTime and tbEvent.bHoldOn then
                tbEvent.nTimer = Timer.AddFrameCycle(self, 1, function()
                    if Timer.RealtimeSinceStartup() >= tbEvent.nEndTime then
                        Timer.DelTimer(self, tbEvent.nTimer)
                        tbEvent.nTimer = nil
                        CloseTips(tbEvent.bPlayHideAnim)
                    end
                end)
            else
                CloseTips(tbEvent.bPlayHideAnim)
            end
        end
    end)
end

function UITipsView:CloseTip(tbNodes)
    for i, node in ipairs(tbNodes) do
        UIHelper.SetVisible(node, false)
    end
end

function UITipsView:AddNodeShowTimeList(Node)
    if not self.NodeShowTimeList[Node] then
        self.NodeShowTimeList[Node] = 1
    else
        self.NodeShowTimeList[Node] = self.NodeShowTimeList[Node] + 1
    end
end

function UITipsView:ReduceNodeShowTimeList(Node)
    self.NodeShowTimeList[Node] = self.NodeShowTimeList[Node] - 1
end

function UITipsView:NodeCanBeDelete(Node)
    return self.NodeShowTimeList[Node] == 0
end

-- 播放读条
function UITipsView:OnPlayProgressBar(tParam)
    self:_StopProgressBar()
    self:_PlayProgressBar(tParam)
end
function UITipsView:OnStopProgressBar()
    self:_StopProgressBar()
end

local tForceID2Bg = {
    --[FORCE_TYPE.CANG_YUN] = {
    --    Background = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_bg_cangyun01.png",
    --    Fill = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_bg_cangyun02.png",
    --},
    --[FORCE_TYPE.CHUN_YANG] = {
    --    Background = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgChunYangBar1.png",
    --    Fill = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgChunYangBar2.png",
    --},
    --[FORCE_TYPE.QI_XIU] = {
    --    Background = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgQiXiuBar1.png",
    --    Fill = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgQiXiuBar2.png",
    --},
    --[FORCE_TYPE.SHAO_LIN] = {
    --    Background = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgShaoLinBar1.png",
    --    Fill = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgShaoLinBar2.png",
    --},
    --[FORCE_TYPE.TIAN_CE] = {
    --    Background = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgTianCeBar1.png",
    --    Fill = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgTianCeBar2.png",
    --},
    --[FORCE_TYPE.WAN_HUA] = {
    --    Background = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgWanHuaBar1.png",
    --    Fill = "UIAtlas2_Public_PublicHint_PublicSkillProgressBar_ImgWanHuaBar2.png",
    --}
}

function UITipsView:_GetProgressTitleInfo(szStr)
    local szTitle, szFormat = string.match(szStr, "(.+)(%(.+/.+%))")
    if not szTitle then
        szTitle, szFormat = string.match(szStr, "%(.+/.+%)")
    end
    if not szTitle then
        szTitle, szFormat = string.match(szStr, ".+/.+")
    end
    if szTitle and not szFormat then
        szFormat = szTitle
        szTitle = ""
    end
    return szTitle or "", szFormat or ""
end

function UITipsView:_PlayProgressBar(tParam)
    local normalPanel = self.SliderNormalProgress:getParent()
    local skillPanel = self.SliderSkillProgress:getParent()
    local swimPanel = self.SliderSwimProgress:getParent()
    local cangyunPanel_1 = self.SliderCangyunFlyProgress1:getParent()
    local cangyunPanel_2 = self.SliderCangyunFlyProgress2:getParent()
    local bShowHoardImg = false

    UIHelper.SetVisible(normalPanel, false)
    UIHelper.SetVisible(skillPanel, false)
    UIHelper.SetVisible(swimPanel, false)
    UIHelper.SetVisible(cangyunPanel_1, false)
    UIHelper.SetVisible(cangyunPanel_2, false)

    local tData = {}
    tData.fnStop = tParam.fnStop
    tData.nStartTime = Timer.RealtimeSinceStartup()
    tData.nEndTime = tData.nStartTime + tParam.nDuration
    tData.dwSkillID = tParam.dwSkillID
    tData.dwSkillLevel = tParam.dwSkillLevel
    tData.szTitle, tData.szFormat = self:_GetProgressTitleInfo(tParam.szFormat)
    tData.bInit = false
    tData.nChangedFrame = 0 -- 用于记录OT_ACTION_PROGRESS_UPDATE发来的读条时长变更信息

    if tParam.szType == "Skill" then
        local tBarAppearance = g_pClientPlayer and tForceID2Bg[g_pClientPlayer.dwForceID]
        if tBarAppearance then
            UIHelper.SetSpriteFrame(self.ImgSkillProgressBg, tBarAppearance.Background)
            UIHelper.SetProgressBarTexture(self.SliderSkillProgress, tBarAppearance.Fill, 1)
        end

        tData.panel = skillPanel
        tData.bar = self.SliderSkillProgress
        tData.labelNum = self.LabelSkillProgressNum
        tData.labelTitle = self.LabelSkillProgressName
        tData.layout = self.LayoutSkillProgress
    elseif tParam.szType == "CANGYUN_SPRIT_GROUND" then
        tData.panel = cangyunPanel_2
        tData.bar = self.SliderCangyunFlyProgress2
    elseif tParam.szType == "CANGYUN_SPRIT_SKY" then
        tData.panel = cangyunPanel_1
        tData.bar = self.SliderCangyunFlyProgress1
    else
        --Normal
        tData.panel = normalPanel
        tData.bar = self.SliderNormalProgress
        tData.labelNum = self.LabelNormalProgressNum
        tData.labelTitle = self.LabelNormalProgressName
        tData.layout = self.LayoutNormalProgress
    end

    if tParam.bHoard then
        local tRangeHoardSkill = Table_GetRangeHoardSkill(tParam.dwSkillID)
        if tRangeHoardSkill then
            bShowHoardImg = true

            local fWidth = UIHelper.GetWidth(self.SliderNormalProgress)
            --UIHelper.SetProgressBarPercent(self.ImgHoard, (tRangeHoardSkill.fEnd - tRangeHoardSkill.fBegin) * 100)
            UIHelper.SetPositionX(self.ImgHoard, fWidth * tRangeHoardSkill.fBegin)
            UIHelper.SetWidth(self.ImgHoard, fWidth * (tRangeHoardSkill.fEnd - tRangeHoardSkill.fBegin))
        end
    end
    UIHelper.SetVisible(self.ImgHoard, bShowHoardImg)

    self.tDataOfProgressBar = tData
    tData.nCallId = Timer.AddFrameCycle(self, 1, function()
        local tData = self.tDataOfProgressBar
        if tData then
            if tData.bCompleted then
                self:_StopProgressBar()
            else
                self:_UpdateProgressBar(tParam, tData)
            end
        end
    end)
end

function UITipsView:_UpdateProgressBar(tParam, tData)
    local now = Timer.RealtimeSinceStartup()
    local nPercent, nVal

    local nFinalDuration = tParam.nDuration + (tData.nChangedFrame / GLOBAL.GAME_FPS)
    local nEndVal = nFinalDuration
    local nFinalEndFrame = tData.nEndTime + (tData.nChangedFrame / GLOBAL.GAME_FPS)
    local nStartVal = 0

    UIHelper.SetVisible(tData.panel, true)

    if now >= nFinalEndFrame then
        -- 结束
        tData.bCompleted = true
        nPercent = 1
        nVal = nEndVal
    else
        nPercent = (now - tData.nStartTime) / nFinalDuration
        nVal = nStartVal + (nEndVal - nStartVal) * nPercent
    end

    if tParam.bReverse then
        nPercent = 1 - nPercent
        nVal = nEndVal - nVal
    end

    UIHelper.SetProgressBarPercent(tData.bar, nPercent * 100)
    UIHelper.SetString(tData.labelNum,
            nVal and string.format(tData.szFormat, nVal, nEndVal) or tData.szFormat)
    if not tData.bInit then
        UIHelper.SetString(tData.labelTitle, tData.szTitle)
        UIHelper.LayoutDoLayout(tData.layout)
        tData.bInit = true
    end

    if tParam.szType == "CANGYUN_SPRIT_SKY" then
        --根据进度条段数，使对应文字变色
        local tColor_Normal = cc.c4b(215, 246, 255, 180)
        local tColor_Highlight = cc.c4b(255, 226, 110, 255)
        UIHelper.SetColor(self.LabelCangyunProgressName1, tColor_Normal)
        UIHelper.SetColor(self.LabelCangyunProgressName2, tColor_Normal)
        UIHelper.SetColor(self.LabelCangyunProgressName3, tColor_Normal)
        if nPercent < 0.525 then
            UIHelper.SetColor(self.LabelCangyunProgressName1, tColor_Highlight)
        elseif nPercent < 0.875 then
            UIHelper.SetColor(self.LabelCangyunProgressName2, tColor_Highlight)
        else
            UIHelper.SetColor(self.LabelCangyunProgressName3, tColor_Highlight)
        end
    end

    if tParam.bAutoCastSkill and tParam.dwSkillID then
        SpecialSettings.AutoCGSkillInOTABar(tParam.dwSkillID)
    end
end

function UITipsView:_StopProgressBar()
    local tData = self.tDataOfProgressBar
    if not tData then
        return
    end
    self.tDataOfProgressBar = nil

    UIHelper.SetVisible(tData.panel, false)

    local swimPanel = self.SliderSwimProgress:getParent()
    if self.tDataOfSwimBar ~= nil then
        UIHelper.SetVisible(swimPanel, true)
    end

    if tData.nCallId then
        Timer.DelTimer(self, tData.nCallId)
        tData.nCallId = nil
    end

    if tData.fnStop then
        tData.fnStop(tData.bCompleted == true)
    end
end

function UITipsView:OnShowLevelUpTip(nLevel)
    local aniParent = self.WidgetLevelUp
    assert(aniParent)

    local label = self.LabelLevelUp
    assert(label)
    UIHelper.SetString(label, tostring(nLevel))
    -- UIHelper.SetVisible(aniParent, true)
    self.bShowLevelUp = true
    self:UpdateShowLevelUpTipVis()

    local aniNode = aniParent:getChildByName("AniLevelUp")
    assert(aniNode)
    UIHelper.PlayAni(self, aniNode, "AniLevelUp", function()
        self.bShowLevelUp = false
        -- UIHelper.SetVisible(aniParent, false)
        self:UpdateShowLevelUpTipVis()
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue2)
        TipsHelper.NextTip(TipsHelper.Def.Queue2)
    end)

end

function UITipsView:OnShowNpcVoice(dwID)
    local scriptNpcVoice = UIHelper.GetBindScript(self.WidgetNpcVoice)
    if scriptNpcVoice then
        return scriptNpcVoice:OnEnter(dwID)
    end
    return false
end

function UITipsView:AddNewAchievement(dwAchievementID)
    self:InitTipPrefab(TIPS_TYPE.NAchievement, 3, PREFAB_ID.WidgetAchievementGetCell, self.LayoutAchievementGet)
    self.tbTips[TIPS_TYPE.NAchievement].mutex = TIPS_TYPE.NDesignation

    UIHelper.SetVisible(self.LayoutAchievementGet, true)
    local aAchievement = Table_GetAchievement(dwAchievementID)
    if not aAchievement or not aAchievement.bShowGetNew or aAchievement.nVisible == 0 then
        return
    end

    local szName = UIHelper.GBKToUTF8(aAchievement.szName)
    _, szName = UIHelper.TruncateString(szName, 6, "...")
    local _, nPoint = Table_GetAchievementInfo(dwAchievementID)

    local tbData = {}
    tbData.szName = szName
    tbData.nPoint = nPoint
    tbData.aAchievement = aAchievement

    self:TryAddTip(TIPS_TYPE.NAchievement, tbData)

end

function UITipsView:OnCloseAchievement()
    UIHelper.SetVisible(self.LayoutAchievementGet, false)
end

-- function UITipsView:OnShowNewAchievement(dwAchievementID)
--     local aAchievement = Table_GetAchievement(dwAchievementID)
--     if not aAchievement or not aAchievement.bShowGetNew then
--         --新手历程需要，某些成就获得不弹出这个提示
--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
--         return false
--     end

--     if aAchievement.nVisible == 0 then
--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
--         return false
--     end

--     local szName    = UIHelper.GBKToUTF8(aAchievement.szName)
--     local _, nPoint = Table_GetAchievementInfo(dwAchievementID)

--     _, szName       = UIHelper.TruncateString(szName, 6, "...")

--     UIHelper.SetString(self.LabelAchievementName, szName)
--     UIHelper.SetString(self.LabelAchievementPoint, nPoint)
--     UIHelper.SetItemIconByIconID(self.ImgAchievementIcon, aAchievement.nIconID)

--     UIHelper.BindUIEvent(self.BtnOpenAchievement, EventType.OnClick, function()
--         if not aAchievement then
--             return
--         end

--         AchievementData.ResetSearchAndFilter()

--         local a = aAchievement
--         UIMgr.Open(VIEW_ID.PanelAchievementContent, a.dwGeneral, a.dwSub, a.dwDetail, a.dwID)
--     end)

--     local aniParent = self.WidgetAchievementGet
--     assert(aniParent)
--     UIHelper.SetVisible(aniParent, true)

--     local aniNode = self.AniAchievementGet
--     assert(aniNode)
--     UIHelper.PlayAni(self, aniNode, "AniNpcVoiceShow", function()
--         aniNode.nCallId = Timer.Add(self, 5.0, function()
--             UIHelper.PlayAni(self, aniNode, "AniNpcVoiceHide", function()
--                 -- UIHelper.SetVisible(aniParent, false)
--                 -- TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--                 -- TipsHelper.NextTip(TipsHelper.Def.Queue3)
--                 self:DoCloseCurOperationHint()
--             end)
--         end)
--     end)

--     local funcCloseNewAchievement = function()
--         UIHelper.PlayAni(self, aniNode, "AniNpcVoiceHide", function()
--             UIHelper.SetVisible(aniParent, false)
--             TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--             TipsHelper.NextTip(TipsHelper.Def.Queue3)
--         end)
--     end
--     self:SetOperationHintInfo(funcCloseNewAchievement, 5)

--     UIHelper.BindUIEvent(self.BtnCloseAchievementGet, EventType.OnClick, function()
--         UIHelper.SetVisible(aniParent, false)
--         if aniNode.nCallId then
--             Timer.DelTimer(self, aniNode.nCallId)
--             aniNode.nCallId = nil
--         end

--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
-- 	end)

--     return true
-- end

function UITipsView:AddNewDesignation(nID, bPrefix)
    self:InitTipPrefab(TIPS_TYPE.NDesignation, 3, PREFAB_ID.WidgetDesignationGetCell, self.LayoutAchievementGet)
    self.tbTips[TIPS_TYPE.NDesignation].mutex = TIPS_TYPE.NAchievement

    UIHelper.SetVisible(self.LayoutAchievementGet, true)

    local aDesignation = nil
    if bPrefix then
        aDesignation = Table_GetDesignationPrefixByID(nID, UI_GetPlayerForceID())
    else
        aDesignation = g_tTable.Designation_Postfix:Search(nID)
    end
    if not aDesignation then
        return
    end

    local szTitle
    if bPrefix then
        local tInfo = GetDesignationPrefixInfo(nID)
        if tInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
            szTitle = "世界称号"
        elseif tInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
            szTitle = "战阶称号"
        else
            szTitle = "称号前缀"
        end
    else
        szTitle = "称号后缀"
    end

    local szName = UIHelper.GBKToUTF8(aDesignation.szName)
    --_, szName = UIHelper.TruncateString(szName, 6, "...")

    local tbData = {}
    tbData.nDesignationID = nID
    tbData.bPrefix = bPrefix
    tbData.szTitle = szTitle
    tbData.szName = szName
    tbData.nQuality = aDesignation.nQuality

    self:TryAddTip(TIPS_TYPE.NDesignation, tbData)
end

function UITipsView:OnCloseDesignation()
    UIHelper.SetVisible(self.LayoutAchievementGet, false)
end

function UITipsView:OnSeasonMissionComplated(tInfo)
    UIHelper.SetString(self.LabelTitleSeason, g_tStrings.STR_SEASON_PRIZE[tInfo.nType])
    UIHelper.SetString(self.LabelContentSeason, UIHelper.GBKToUTF8(tInfo.szText))
    UIHelper.SetSpriteFrame(self.ImgIconSeason, SeasonComplatedImg[tInfo.nType])

    UIHelper.BindUIEvent(self.BtnSeasonPreviewAchieved, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelOperationCenter, 130, tInfo.nType)
        UIHelper.SetVisible(self.WidgetSeasonPreviewAchieved, false)
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    UIHelper.SetVisible(self.WidgetSeasonPreviewAchieved, true)

    UIHelper.PlayAni(self, self.AniSeasonPreviewAchieved, "AniNpcVoiceShow", function()
        Timer.Add(self, 5.0, function()
            UIHelper.PlayAni(self, self.AniSeasonPreviewAchieved, "AniNpcVoiceHide", function()
                self:DoCloseCurOperationHint()
            end)
        end)
    end)

    local funcCloseSeasonMission = function()
        UIHelper.PlayAni(self, self.AniSeasonPreviewAchieved, "AniNpcVoiceHide", function()
            UIHelper.SetVisible(self.WidgetSeasonPreviewAchieved, false)
            TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
            TipsHelper.NextTip(TipsHelper.Def.Queue3)
        end)
    end
    self:SetOperationHintInfo(funcCloseSeasonMission, 5)

    return true
end

function UITipsView:OnShowNewFeatureTip(nSystemID)
    local aniParent = self.WidgetAniNewFeature
    assert(aniParent)

    local tMenu = UISystemMenuTab[nSystemID]

    self.bShowNewFeatureTip = true
    -- UIHelper.SetVisible(aniParent, true)
    self:UpdateShowNewFeatureTipVis()
    --UIHelper.SetVisible(self.WidgetAnchorRightTop, true)

    UIHelper.SetSpriteFrame(self.ImgIcon, tMenu.szIcon)
    UIHelper.SetString(self.LabelFeaturerName, tMenu.szTitle)
    UIHelper.LayoutDoLayout(self.LayoutFeaturer)

    --local aniNode = aniParent:getChildByName("AniLoop") assert(aniNode)
    UIHelper.PlayAni(self, aniParent, ANI_TYPE[tMenu.nNewFeatureAniType], function()
        -- UIHelper.SetVisible(aniParent, false)
        self.bShowNewFeatureTip = false
        self:UpdateShowNewFeatureTipVis()
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue2)
        TipsHelper.NextTip(TipsHelper.Def.Queue2)
        if tMenu.nNewFeatureAniType == UNLOCK_ANITYPE.RIGHTTOP then
            Event.Dispatch("ON_PLAY_UNLOCK_ANIMATION", tMenu.szTitle)
        end
    end)
end

-- function UITipsView:OnShowQuickEquipTip(dwBox, dwX)
--     local player = GetClientPlayer()
--     if not player then
--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
--         return false
--     end
--     local item = PlayerData.GetPlayerItem(player, dwBox, dwX)
--     if not item then
--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
--         return false
--     end
--     local node

--     node = self.WidgetQuickEquip assert(node)
--     local tScript = UIHelper.GetBindScript(node) assert(tScript)

--     node = tScript.WidgetItemIcom assert(node)
--     UIHelper.RemoveAllChildren(node)
--     local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, node) assert(tItemScript)
--     tItemScript:OnInit(dwBox, dwX)

--     -- 延时
--     UIHelper.SetVisible(tScript._rootNode, true)
--     tScript.nCallId = Timer.Add(self, Def.QuickEquipShowTime, function ()
--         -- UIHelper.SetVisible(tScript._rootNode, false)
--         -- tScript.nCallId = nil
--         self:DoCloseCurOperationHint()
--     end)

--     local funcCloseQuickEquipTip = function()
--         UIHelper.SetVisible(tScript._rootNode, false)
--         tScript.nCallId = nil
--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
--     end

--     self:SetOperationHintInfo(funcCloseQuickEquipTip, Def.QuickEquipShowTime)

--     -- 交互
--     UIHelper.BindUIEvent(tScript.BtnQuickEquip, EventType.OnClick, function()
--         UIHelper.SetVisible(tScript._rootNode, false)
--         if tScript.nCallId then
--             Timer.DelTimer(self, tScript.nCallId)
--             tScript.nCallId = nil
--         end

--         local targetBox, targetX = IsBetterBag(item)
--         if targetBox and targetX then
--             ItemData.ExchangeItem(dwBox, dwX, targetBox, targetX)
--         else
--             ItemData.EquipItem(dwBox, dwX)
--         end

--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
--     end)

--     UIHelper.BindUIEvent(tScript.BtnClose, EventType.OnClick, function()
--         UIHelper.SetVisible(tScript._rootNode, false)
--         if tScript.nCallId then
--             Timer.DelTimer(self, tScript.nCallId)
--             tScript.nCallId = nil
--         end

--         TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
--         TipsHelper.NextTip(TipsHelper.Def.Queue3)
-- 	end)

--     return true
-- end

function UITipsView:AddQuickEquipTip(tbEquipItem)


    local player = g_pClientPlayer
    if not player then
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end

    local nLayoutMaxNum = 3

    local node = self.WidgetQuickEquip
    assert(node)
    local tScript = UIHelper.GetBindScript(node)
    assert(tScript)
    UIHelper.SetVisible(tScript.BtnQuickEquip, true)

    local nDataLen = #tbEquipItem

    local parent = nDataLen <= nLayoutMaxNum and tScript.LayoutLIstLess or tScript.ScrollViewLIstMore
    assert(node)

    UIHelper.RemoveAllChildren(parent)
    for nIndex, tbData in ipairs(tbEquipItem) do
        local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, parent)
        assert(tItemScript)
        tItemScript:OnInit(tbData.dwBox, tbData.dwX)
        tItemScript:SetToggleGroupIndex(ToggleGroupIndex.TipEquipItem)
        tItemScript:SetClickCallback(function(dwBox, dwX)
            if dwBox and dwX then
                local tips, tipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, tItemScript._rootNode)
                tipsView:SetFunctionButtons({})
                tipsView:OnInit(dwBox, dwX)
            end
        end)
        tItemScript:UpdatePVPImg()
        if nDataLen > nLayoutMaxNum then
            local nY = UIHelper.GetPositionY(tItemScript._rootNode)
            UIHelper.SetPositionY(tItemScript._rootNode, nY + 30)
        end
    end

    local item = PlayerData.GetPlayerItem(player, tbEquipItem[1].dwBox, tbEquipItem[1].dwX)
    local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
    local bPackage = itemInfo.nSub == EQUIPMENT_SUB.PACKAGE

    self.bQuikeEquipShow = true

    -- UIHelper.SetVisible(tScript._rootNode, true)

    self:UpdateShowQuickEquipTipVis()

    UIHelper.SetVisible(tScript.LayoutLIstLess, nDataLen <= nLayoutMaxNum)
    UIHelper.SetVisible(tScript.ScrollViewLIstMore, nDataLen > nLayoutMaxNum)

    local szEquipTitle = string.format("获得%s件更好%s", tostring(nDataLen), bPackage and "背包" or "装备")
    local szEquipText = "立即装备"

    local bTreasureBF, bTreasureBFTitle, bTreasureBFText = TreasureBattleFieldData.GetQuickEquipInfo(item)
    if bTreasureBF then
        szEquipTitle = bTreasureBFTitle
        szEquipText = bTreasureBFText
    end

    UIHelper.SetRichText(tScript.RichTextQuickEquip, szEquipTitle)
    UIHelper.SetString(tScript.LabelQuickEquip, szEquipText)

    if nDataLen <= nLayoutMaxNum then
        UIHelper.LayoutDoLayout(tScript.LayoutLIstLess)
    else
        UIHelper.ScrollViewDoLayout(tScript.ScrollViewLIstMore)
        UIHelper.ScrollToLeft(tScript.ScrollViewLIstMore)
    end

    tScript.nCallId = Timer.Add(self, Def.QuickEquipShowTime, function()

        -- UIHelper.SetVisible(tScript._rootNode, false)
        -- tScript.nCallId = nil
        self:DoCloseCurOperationHint()
    end)

    local funcCloseQuickEquipTip = function()
        self.bQuikeEquipShow = false
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self:UpdateShowQuickEquipTipVis()
        Timer.DelTimer(self, tScript.nCallId)
        tScript.nCallId = nil
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        Event.Dispatch(Event.OnQuickEquipTipClosed)
        Event.UnReg(self, EventType.OnSceneInteractByHotkey)
    end

    local funcClick = function()
        if bTreasureBF then
            local dwBox, dwX = tbEquipItem[1].dwBox, tbEquipItem[1].dwX
            TreasureBattleFieldData.QuickEquip(item, dwBox, dwX)
        elseif bPackage then
            local dwBox, dwX = tbEquipItem[1].dwBox, tbEquipItem[1].dwX
            local targetBox, targetX = IsBetterBag(item)
            if targetBox and targetX then
                ItemData.ExchangeItem(dwBox, dwX, targetBox, targetX)
            else
                ItemData.EquipItem(dwBox, dwX)
            end
        else
            ItemData.EquipAllItem(tbEquipItem)
        end

        funcCloseQuickEquipTip()
    end

    Event.Reg(self, EventType.OnSceneInteractByHotkey, function()
        funcClick()
    end)

    self:SetOperationHintInfo(funcCloseQuickEquipTip, Def.QuickEquipShowTime)

    -- -- 交互
    UIHelper.BindUIEvent(tScript.BtnQuickEquip, EventType.OnClick, function()
        funcClick()
    end)

    UIHelper.BindUIEvent(tScript.BtnClose, EventType.OnClick, function()
        funcCloseQuickEquipTip()
    end)

    UIHelper.SetVisible(self.WidgetKeyBoardKey, true)
    local scriptView = UIHelper.GetBindScript(self.WidgetKeyBoardKey)
    scriptView:SetID(20)
    scriptView:RefreshUI()
end

function UITipsView:OnCloseQuickEquipTip()
    -- local node = self.WidgetQuickEquip
    -- assert(node)
    -- local tScript = UIHelper.GetBindScript(node)
    -- assert(tScript)
    -- TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    -- UIHelper.SetVisible(tScript._rootNode, false)
    -- Timer.DelTimer(self, tScript.nCallId)
    -- tScript.nCallId = nil

    self:DoCloseCurOperationHint()
end

function UITipsView:OnShowAnnounceTip(tMsg)
    local root = self.WidgetAnchorAnnouncement
    assert(root)
    local tScript = UIHelper.GetBindScript(root)
    assert(tScript)
    tScript:PushMsg(tMsg)
end

function UITipsView:OnShowEquipScore(tbData)
    self.scriptEquipScore = self.scriptEquipScore or UIHelper.AddPrefab(PREFAB_ID.WidgetHintTopEquipScore, self.WidgetEquipScore)
    self.scriptEquipScore:OnEnter(tbData, function()
        UIHelper.RemoveAllChildren(self.WidgetEquipScore)
        self.scriptEquipScore = nil
    end)
end

function UITipsView:ShowNpcHeadBalloon(characterID, szContent, nChannel)
    local scriptNpcHeadBalloon = UIHelper.AddPrefab(PREFAB_ID.WidgetNpcHeadBubble, self.WidgetAnchorNpcHeadBubble)
    -- NPC头顶文字
    if scriptNpcHeadBalloon then
        scriptNpcHeadBalloon:OnEnter(characterID, szContent, nChannel)
    end
end

function UITipsView:ShowCharacterHeadBuff(characterID, tBuffList)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local parent = player.dwID == characterID and self.WidgetAnchorPlayerHeadBuff or self.WidgetAnchorNpcHeadBuff

    local scriptHeadBuff = self.CharacterHeadBuffDict[characterID]
    if not scriptHeadBuff then
        scriptHeadBuff = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityHeadBuffList, parent)
        self.CharacterHeadBuffDict[characterID] = scriptHeadBuff
    end

    if scriptHeadBuff then
        UIHelper.SetOpacity(scriptHeadBuff._rootNode, 0)
        scriptHeadBuff:OnEnter(characterID, tBuffList)
    end
end

function UITipsView:ShowChuangYiFoodBuff(tBuff)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local parent = self.WidgetAnchorPlayerHeadBuff
    if not self.scriptChuangYi then
        self.scriptChuangYi = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityChuangYiBuff, parent)
    end

    if self.scriptChuangYi then
        self.scriptChuangYi:OnEnter(tBuff)
    end
end

function UITipsView:ShowArenaTopBuff(dwPlayerID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local scriptTopBuff = self.ArenaTopBuffDict[dwPlayerID]
    if not scriptTopBuff then
        scriptTopBuff = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityHeadBuffList, self.WidgetAnchorArenaTopBuff)
        self.ArenaTopBuffDict[dwPlayerID] = scriptTopBuff
    end

    if scriptTopBuff then
        UIHelper.SetOpacity(scriptTopBuff._rootNode, 0)
        scriptTopBuff:OnEnter(dwPlayerID, nil, true)
    end
end

function UITipsView:HideArenaTopBuff(dwPlayerID)
    if self.ArenaTopBuffDict and self.ArenaTopBuffDict[dwPlayerID] then
        local scriptTopBuff = self.ArenaTopBuffDict[dwPlayerID]
        scriptTopBuff:HideNode(true)
        UIHelper.RemoveFromParent(scriptTopBuff._rootNode, true)
        self.ArenaTopBuffDict[dwPlayerID] = nil
    end
end

function UITipsView:_PlaySwimBar()
    self.tDataOfSwimBar = {}

    local normalPanel = self.SliderNormalProgress and self.SliderNormalProgress:getParent()
    local skillPanel = self.SliderSkillProgress and self.SliderSkillProgress:getParent()
    local swimPanel = self.SliderSwimProgress and self.SliderSwimProgress:getParent()

    UIHelper.SetVisible(normalPanel, false)
    UIHelper.SetVisible(skillPanel, false)
    UIHelper.SetVisible(swimPanel, true)

    UIHelper.SetString(self.LabelSwimProgressName, "呼吸")

    local nPercent = UIHelper.GetProgressBarPercent(self.SliderSwimProgress) or 0
    self.nLastSwimProgress = nPercent / 100

    local swimUpdate = function()
        local hPlayer = g_pClientPlayer
        if not hPlayer or hPlayer.nDivingCount < 1 then
            self:_StopSwimBar()
            return
        end

        local nLogicLoop = GetLogicFrameCount()
        if nLogicLoop == self.nLogicLoop then
            -- 逻辑帧变化了才有意义
            return
        end
        self.nLogicLoop = nLogicLoop

        local fp = math.max(0, 1 - hPlayer.nDivingCount / hPlayer.nDivingFrame)

        SprintData.SetUnderWater(self.nLastSwimProgress > fp)
        self.nLastSwimProgress = fp

        UIHelper.SetString(self.LabelSwimProgessNum, string.format("(%s/%s)", tostring(math.floor(fp * 100)), tostring(100)))
        UIHelper.SetProgressBarPercent(self.SliderSwimProgress, fp * 100)
    end
    swimUpdate()

    self.tDataOfSwimBar.panel = swimPanel
    self.tDataOfSwimBar.nCallId = Timer.AddFrameCycle(self, 1, function()
        swimUpdate()
    end)
end

function UITipsView:InitRightTopTimelyHint()
    if not self.WidgetTimlyHintNewAnchore then
        return
    end
    if self.scriptTimelyHint then
        ---@type UITimelyHintTip
        self.scriptTimelyHint = nil
        UIHelper.RemoveAllChildren(self.WidgetTimlyHintNewAnchore)
    end
    self.scriptTimelyHint = UIHelper.AddPrefab(PREFAB_ID.WidgetTimelyHint, self.WidgetTimlyHintNewAnchore)
    -- UIHelper.SetVisible(self.scriptTimelyHint._rootNode, false)
    self.scriptTimelyHint:UpdateVisible()
end

function UITipsView:_StopSwimBar()
    SprintData.SetUnderWater(false)

    local tData = self.tDataOfSwimBar
    if not tData then
        return
    end
    self.tDataOfSwimBar = nil

    UIHelper.SetVisible(tData.panel, false)

    if tData.nCallId then
        Timer.DelTimer(self, tData.nCallId)
        tData.nCallId = nil
    end

    if tData.fnStop then
        tData.fnStop(tData.bCompleted == true)
    end
end

function OnSkillPrepareProgress()
    local hPlayer = GetControlPlayer()
    if not (hPlayer and arg0 > 0) then
        return
    end

    m_OTState = OT_STATE.ON_PREPARE
    m_nStartFrame = GetLogicFrameCount()
    m_nStartTick = GetTickCount()
    m_nTotalFrame = arg0
    m_tGCD = nil
    m_tSkill = { arg1, arg2 }
    m_OTCss = OT_CSS.NORMAL
    m_PingFrame = GetPingFrame()

    local skill = GetSkill(arg1, arg2)
    if skill then
        m_OTCss = KungfuToCSS(skill.dwBelongSchool) or OT_CSS.NORMAL
    end
    PrepareProgressBar(Table_GetSkillName(arg1, arg2), 0, arg0 / GLOBAL.GAME_FPS * 1000)
end

function UITipsView:SetOperationHintInfo(funcCloseOperationHint, nDurationTime)
    self.funcCloseOperationHint = funcCloseOperationHint
    self.nDurationTime = nDurationTime
end

--关闭界面时，补上因为复活界面打开而隐藏显示的时间
function UITipsView:DoCloseCurOperationHint()
    if self.nShowOperationHintTime then
        local nCurTime = Timer.RealtimeSinceStartup()
        local nAddTime = math.floor(self.nDurationTime - (nCurTime - self.nShowOperationHintTime))
        if nAddTime > 0 then
            --补上时间
            Timer.Add(self, nAddTime, function()
                self.funcCloseOperationHint()
            end)
        else
            self.funcCloseOperationHint()
        end
        self.nShowOperationHintTime = nil
    else
        self.funcCloseOperationHint()
    end
end



function UITipsView:OnShowLikeTip()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
        return self.scriptTimelyHint:UpdateLikeInfo()
    -- end
end

function UITipsView:OnShowInteractTip()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
        return self.scriptTimelyHint:UpdateInteractInfo()
    -- end
end

function UITipsView:OnShowMessageBubble()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
        return self.scriptTimelyHint:UpdateBubbleMsgBar()
    -- end
end

function UITipsView:OnShowTeamTip()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
        return self.scriptTimelyHint:UpdateTeamInfo()
    -- end
end

function UITipsView:OnShowOptickRecordTip()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
    return self.scriptTimelyHint:UpdateOptickRecordTipInfo()
    -- end
end

function UITipsView:OnShowAssistNewbieInviteTip()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
        return self.scriptTimelyHint:UpdateAssistNewbieInvite()
    -- end
end

function UITipsView:OnShowMobaSurrenderTip()
    return self.scriptTimelyHint:UpdateMobaSurrenderInfo()
end

function UITipsView:OnShowTeamReadyConfirmTip()
    return self.scriptTimelyHint:UpdateTeamReadyConfirmInfo()
end

function UITipsView:OnShowRoomTip()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
        return self.scriptTimelyHint:UpdateRoomInfo()
    -- end
end

function UITipsView:OnShowTradeTip()
    -- local scriptTimelyHint = UIHelper.GetBindScript(self.WidgetAnchorTimelyHint)
    -- if scriptTimelyHint then
        return self.scriptTimelyHint:UpdateTradeInfo()
    -- end
end


-- 事件处理 -- 未同步时，killerID有值，deadID为0
function UITipsView:OnDeathNotify(deadID, killerID)
    if not deadID or not killerID or not IsPlayer(deadID) then
        return
    end

    local me = GetClientPlayer()
    if not me then
        return
    end

    -- 击杀
    if killerID ~= me.dwID or deadID == killerID then
        return
    end

    local function _playAnim(szAnim, fnCallback)
        UIHelper.StopAni(self, self.WidgetKillHint, self.szKillHintAnim)
        UIHelper.PlayAni(self, self.WidgetKillHint, szAnim, fnCallback)
        self.szKillHintAnim = szAnim
    end

    if not self.nKillNum then
        self.nKillNum = 0
    end

    self.nKillNum = self.nKillNum + 1

    local szAnim
    if self.nKillNum == 1 then
        --出现动画
        UIHelper.SetVisible(self.WidgetKillHint, true)
        szAnim = "AniKillHintShow"
    else
        --文字刷新动画
        szAnim = "AniKillHintLianSha"
    end

    local szKillNum = tostring(self.nKillNum)
    UIHelper.SetString(self.LabelKill1, szKillNum)
    UIHelper.SetString(self.LabelKill2, szKillNum)
    _playAnim(szAnim)

    Timer.DelTimer(self, self.nKillComboTimerID)
    self.nKillComboTimerID = Timer.Add(self, KILL_COMBO_TIME, function()
        self.nKillNum = 0
        _playAnim("AniKillHintHide", function()
            UIHelper.SetVisible(self.WidgetKillHint, false)
        end)
    end)
end

function UITipsView:UpdateGetItemHintVisible()
    if self.bTop then
        local bVisible = true

        if SceneMgr.IsLoading() then
            bVisible = false
        elseif UIMgr.GetView(VIEW_ID.PanelVideoPlayer) then
            bVisible = false
        end

        UIHelper.SetVisible(self.WidgetGetItemHintAnchor, bVisible)
    end
end

function UITipsView:RemovePreviousMobaMessage()
    if self.scriptMobaMessage then
        UIHelper.RemoveFromParent(self.scriptMobaMessage._rootNode, true)
        self.scriptMobaMessage = nil
    end
end

function UITipsView:ShowMobaBattleMsg(szLeft, szRight, szSfxPath)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        self:RemovePreviousMobaMessage()
        ---@see UIWidgetHintPvpKill
        self.scriptMobaMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpKill, self.WidgetHintContent, szLeft, szRight, szSfxPath)
    end
end

function UITipsView:ShowMobaBattleMsgGeneralMsg(szMsg, szBgImgPath)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        self:RemovePreviousMobaMessage()
        ---@type UIHintPvpMoba
        self.scriptMobaMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpMoba, self.WidgetHintContent)
        self.scriptMobaMessage:UpdateInfoGeneralMsg(szMsg, szBgImgPath)
    end
end

function UITipsView:ShowMobaBattleMsgGeneralMsgEx(szMessage, szBgImgPath, szSfxPath)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        self:RemovePreviousMobaMessage()
        ---@type UIHintPvpMoba
        self.scriptMobaMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpMoba, self.WidgetHintContent)
        self.scriptMobaMessage:UpdateInfoGeneralMsgEx(szMessage, szBgImgPath, szSfxPath)
    end
end

function UITipsView:ShowMobaBattleMsgOneSidedMsg(szMessage, szMsgBgImgPath, szImgAvatarPath, szImgAvatarFramePath, szImgAvatarFrameTailPath)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        self:RemovePreviousMobaMessage()
        ---@type UIHintPvpMoba
        self.scriptMobaMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpMoba, self.WidgetHintContent)
        self.scriptMobaMessage:UpdateInfoOneSidedMsg(szMessage, szMsgBgImgPath, szImgAvatarPath, szImgAvatarFramePath, szImgAvatarFrameTailPath)
    end
end

function UITipsView:ShowMobaBattleMsgTwoSidedMsg(tLeftInfo, tRightInfo, aAssistKillKungfuIDs, szCenterBgImgPath, szCenterTopImgPath, szCenterBottomImgPath, szMessage, szSfxPath, szSfx2Path)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        self:RemovePreviousMobaMessage()
        ---@type UIHintPvpMoba
        self.scriptMobaMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpMoba, self.WidgetHintContent)
        self.scriptMobaMessage:UpdateInfoTwoSidedMsg(tLeftInfo, tRightInfo, aAssistKillKungfuIDs, szCenterBgImgPath, szCenterTopImgPath, szCenterBottomImgPath, szMessage, szSfxPath, szSfx2Path)
    end
end

function UITipsView:ShowMiniGameStart(tInfo)
    if not self.scriptMiniGameStart then
        self.scriptMiniGameStart = self.scriptMiniGameStart or UIHelper.AddPrefab(PREFAB_ID.WidgetGameStartHint, self.WidgetHintContent)
    end
    self.scriptMiniGameStart:OnEnter(tInfo)
end

function UITipsView:ShowCueWords(nKeepTime, tText, szTitle, dwID)
    if not self.scriptCueWord then
        self.scriptCueWord = UIHelper.AddPrefab(PREFAB_ID.WidgetHintZhuZiGuoChang, self.WidgetHintContent)
    end
    self.scriptCueWord:OnEnter(nKeepTime, tText, szTitle, dwID)
end

local tRoleType2Key = {
    [ROLE_TYPE.STANDARD_MALE] = "szMaleSoundFilePath",
    [ROLE_TYPE.STANDARD_FEMALE] = "szFemaleSoundFilePath",
    [ROLE_TYPE.STRONG_MALE] = "szMaleSoundFilePath",
    [ROLE_TYPE.SEXY_FEMALE] = "szFemaleSoundFilePath",
    [ROLE_TYPE.LITTLE_BOY] = "szBoySoundFilePath",
    [ROLE_TYPE.LITTLE_GIRL] = "szGirlSoundFilePath",
}

local function GetRoleType()
    local nRoleType = 1
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return nRoleType
    end
    nRoleType = pPlayer.nRoleType
    return nRoleType
end

function UITipsView:ShowTongBattleTips(nID)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        local tInfo = Tabel_GetTongBattleTipsInfo(nID)

        local szTips = UIHelper.GBKToUTF8(tInfo.szTips)

        local szMsg = szTips
        local szBgImgPath = tInfo.szMobileImgBgPath

        self:RemovePreviousMobaMessage()
        ---@type UIHintPvpMoba
        self.scriptMobaMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpMoba, self.WidgetHintContent)
        self.scriptMobaMessage:UpdateInfoGeneralMsg(szMsg, szBgImgPath)

        local nRoleType = GetRoleType()
        SoundMgr.PlaySound(SOUND.UI_SOUND, tInfo[tRoleType2Key[nRoleType]])
        OutputMessage("MSG_SYS", szTips .. "\n")
    end
end

function UITipsView:ShowTongBattledragonTips(nID)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        local tInfo = Tabel_GetTongBattledragonTipsInfo(nID)

        local szTips = UIHelper.GBKToUTF8(tInfo.szTips)

        local szMessage = szTips
        local szMsgBgImgPath = tInfo.szMobileMsgBgPath
        local szImgAvatarPath = tInfo.szMobileAvatarPath
        local szImgAvatarFramePath = tInfo.szMobileAvatarBgPath
        local szImgAvatarFrameTailPath = ""

        self:RemovePreviousMobaMessage()
        ---@type UIHintPvpMoba
        self.scriptMobaMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpMoba, self.WidgetHintContent)
        self.scriptMobaMessage:UpdateInfoOneSidedMsg(szMessage, szMsgBgImgPath, szImgAvatarPath, szImgAvatarFramePath, szImgAvatarFrameTailPath)

        local nRoleType = GetRoleType()
        SoundMgr.PlaySound(SOUND.UI_SOUND, tInfo[tRoleType2Key[nRoleType]])
        OutputMessage("MSG_SYS", szTips .. "\n")
    end
end

function UITipsView:ShowTongWarEnterTip(nMapLevel)
    if not self.bTop then
        UIHelper.SetVisible(self.WidgetHintContent, true)

        if self.scriptTongWarEnterTip then
            UIHelper.RemoveFromParent(self.scriptTongWarEnterTip._rootNode, true)
            self.scriptTongWarEnterTip = nil
        end

        ---@type UIHintFactionChampionship
        self.scriptTongWarEnterTip = UIHelper.AddPrefab(PREFAB_ID.WidgetHintFactionChampionship, self.WidgetHintContent, nMapLevel)
    end
end

function UITipsView:ShowTreasureBattleFieldHint(tbData)
    if self.bTop then
        return
    end
    if not self.scriptTreasureBattleFieldHint then
        self.scriptTreasureBattleFieldHint = UIHelper.AddPrefab(PREFAB_ID.WidgetChiJiHintCell, self.WidgetHintContent, tbData)
    else
        self.scriptTreasureBattleFieldHint:OnEnter(tbData)
    end
end


function UITipsView:ShowHintSFX(dwID)
    if not self.scriptHintSFX then
        self.scriptHintSFX = UIHelper.AddPrefab(PREFAB_ID.WidgetHintSfx, self.WidgetHintContent, dwID)
    else
        self.scriptHintSFX:OnEnter(dwID)
    end
end

function UITipsView:ShowCampHint(nBossID)
    if not self.scriptHintPVPOther then
        self.scriptHintPVPOther = UIHelper.AddPrefab(PREFAB_ID.WidgetHintPvpOtherHint, self.WidgetHintContent)
    end
    self.scriptHintPVPOther:ShowCampHint(nBossID)
end

function UITipsView:ShowKillHint(szName)
    local script = self:GetKillScript(PREFAB_ID.WidgetKillNormalHint)
    if script then
        script:ShowKillHint(szName, function()
            Timer.DelTimer(script, script.nBleedTimerID)
            script.nBleedTimerID = Timer.Add(script, 60, function()
                self:ReleaseOneKillPrefab(script)
            end)
        end)
    end
end

function UITipsView:RefreshAltar(szAltar,tNumber,tTime, bStart)
    if not self.scriptHintBahuang then
        self.scriptHintBahuang = UIHelper.AddPrefab(PREFAB_ID.WidgetHintContentBahuang, self.WidgetHintContent)
    end
    self.scriptHintBahuang:OnRefreshAltar(szAltar,tNumber,tTime, bStart)
end

function UITipsView:RefreshBoss()
    if not self.scriptHintBahuang then
        self.scriptHintBahuang = UIHelper.AddPrefab(PREFAB_ID.WidgetHintContentBahuang, self.WidgetHintContent)
    end
    self.scriptHintBahuang:OnRefreshBoss()
end

function UITipsView:OnStartEvent()
    if not self.scriptHintBahuang then
        self.scriptHintBahuang = UIHelper.AddPrefab(PREFAB_ID.WidgetHintContentBahuang, self.WidgetHintContent)
    end
    self.scriptHintBahuang:OnStartEvent()
end

function UITipsView:OnShowExtractSettlement(tInfo)
    if not self.scriptHintExtract then
        self.scriptHintExtract = UIHelper.AddPrefab(PREFAB_ID.WidgetHintXunbao, self.WidgetHintContent)
    end
    Timer.Add(self, 0.1, function ()
        self.scriptHintExtract:ShowExtractSettlement(tInfo)
    end)
end

function UITipsView:ShowExtractCounter(dwID, nCount)
    if not self.scriptHintExtract then
        self.scriptHintExtract = UIHelper.AddPrefab(PREFAB_ID.WidgetHintXunbao, self.WidgetHintContent)
    end
    self.scriptHintExtract:ShowExtractCounter(dwID, nCount)
end

function UITipsView:ShowExtractReaminingTime(nSecond)
    if not self.scriptHintExtract then
        self.scriptHintExtract = UIHelper.AddPrefab(PREFAB_ID.WidgetHintXunbao, self.WidgetHintContent)
    end
    self.scriptHintExtract:ShowExtractReaminingTime(nSecond)
end

function UITipsView:ShowRewardHint(nRewardType, szText, tbItem, tbOtherReward, funcConfirm,
    funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
    if not self.scriptRewardHint then
        self.scriptRewardHint = UIHelper.AddPrefab(PREFAB_ID.WidgetRewardHint, self.WidgetRewardHintAnchor, nRewardType, szText, tbItem, tbOtherReward, funcConfirm,
        funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
    else
        self.scriptRewardHint:OnEnter(nRewardType, szText, tbItem, tbOtherReward, funcConfirm,
        funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
    end
end

----------------------------对某tip进行显示隐藏的一些函数------------

function UITipsView:UpdateShowNormalTipVis()
    if self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowNormalTip)
        UIHelper.SetVisible(self.LayoutNormalHint, bVis)
    end
end

function UITipsView:UpdateShowImportantTipVis()
    if self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowImportantTip)
        UIHelper.SetVisible(self.WidgetImportantNormal, bVis)
    end
end

function UITipsView:UpdateShowEquipScoreVis()
    if self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowEquipScore)
        UIHelper.SetVisible(self.WidgetEquipScore, bVis)
    end
end

function UITipsView:UpdateShowPlaceTipVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowPlaceTip) and not self.bSprintTip
        UIHelper.SetVisible(self.WidgetPlaceHint, bVis)
    end
end

function UITipsView:UpdatePlayProgressBarTipVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.PlayProgressBarTip)
        UIHelper.SetVisible(self.WidgetProgressSkill, bVis)
    end
end

function UITipsView:UpdateShowLevelUpTipVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowLevelUpTip) and self.bShowLevelUp
        UIHelper.SetVisible(self.WidgetLevelUp, bVis)
    end
end

function UITipsView:UpdateShowNewAchievementVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowNewAchievement)
        UIHelper.SetVisible(self.WidgetAchievementGet, bVis)
    end
end

function UITipsView:UpdateShowNewDesignationVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowNewDesignation)
        UIHelper.SetVisible(self.WidgetAchievementGet, bVis)--和成就一个节点
    end
end

function UITipsView:UpdateShowQuickEquipTipVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowQuickEquipTip) and self.bQuikeEquipShow
        UIHelper.SetVisible(self.WidgetQuickEquip, bVis)
    end
end

function UITipsView:UpdatePlayCountDownVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.PlayCountDown)
        UIHelper.SetVisible(self.WidgetAnchorCountDown, bVis)
    end
end

function UITipsView:UpdateShowNewFeatureTipVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowNewFeatureTip) and self.bShowNewFeatureTip
        UIHelper.SetVisible(self.WidgetAniNewFeature, bVis)
    end
end

function UITipsView:UpdateShowLikeTipVis()
    if self.bTop then
        self:updateTimlyHintNewAnchoreVis()
    end
end

function UITipsView:UpdateShowInteractTipVis()
    if self.bTop then
        self:updateTimlyHintNewAnchoreVis()
    end
end

function UITipsView:UpdateShowTeamTipVis()
    if self.bTop then
        self:updateTimlyHintNewAnchoreVis()
    end
end

function UITipsView:UpdateShowRoomTipVis()
    if self.bTop then
        self:updateTimlyHintNewAnchoreVis()
    end
end

function UITipsView:UpdateShowTradeTipVis()
    if self.bTop then
        self:updateTimlyHintNewAnchoreVis()
    end
end

function UITipsView:UpdateShowAssistNewbieInviteTipVis()
    if self.bTop then
        self:updateTimlyHintNewAnchoreVis()
    end
end

function UITipsView:UpdateUpdateDeathNotifyVis()
    if not self.bTop then

    end
end

function UITipsView:UpdateShowQuestCompleteVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowQuestComplete)
        UIHelper.SetVisible(self.WidgetQuestComplete, bVis)
    end
end

function UITipsView:updateTimlyHintNewAnchoreVis()
    local bHide = TipsHelper.IsTipShield(EventType.ShowLikeTip) or
            TipsHelper.IsTipShield(EventType.ShowInteractTip) or
            TipsHelper.IsTipShield(EventType.ShowTeamTip) or
            TipsHelper.IsTipShield(EventType.ShowAssistNewbieInviteTip) or
            TipsHelper.IsTipShield(EventType.ShowRoomTip) or
            TipsHelper.IsTipShield(EventType.ShowTradeTip)
    UIHelper.SetVisible(self.WidgetTimlyHintNewAnchore, not bHide)
end

function UITipsView:ShowHintWinterFestivalSkill(dwID)
    if not self.scriptWinterFestival then
        self.scriptWinterFestival = UIHelper.AddPrefab(PREFAB_ID.WidgetHintContentDongZhi, self.WidgetHintContent, dwID)
    else
        self.scriptWinterFestival:OnEnter(dwID)
    end
end

function UITipsView:ShowNewEmotionTip(dwActionID)

    local node = self.WidgetQuickEquip
    assert(node)
    local tScript = UIHelper.GetBindScript(node)
    assert(tScript)
    UIHelper.SetVisible(tScript.BtnQuickEquip, true)
    UIHelper.SetString(tScript.LabelQuickEquip, "加入快捷")
    UIHelper.SetVisible(self.WidgetKeyBoardKey, false)
    UIHelper.SetVisible(tScript.LayoutLIstLess, true)
    UIHelper.SetVisible(tScript.ScrollViewLIstMore, false)

    local tEmotionData = EmotionData.GetEmotionAction(dwActionID)
    local szName = tEmotionData.szName
    local szEmotionTitle = "<color=#FFFAA3>学会新表情" .. UIHelper.GBKToUTF8(szName)
    UIHelper.SetRichText(tScript.RichTextQuickEquip, szEmotionTitle)

    local parent = tScript.LayoutLIstLess assert(parent)
    UIHelper.RemoveAllChildren(parent)
    local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, parent) assert(itemScript)
    itemScript:OnInitWithIconID(tEmotionData.nIconID)
    itemScript:SetSelectEnable(false)
    if tEmotionData.bInteract then
        UIHelper.SetVisible(itemScript.ImgDoubleMark, true)
        UIHelper.SetSpriteFrame(itemScript.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon1")
    elseif tEmotionData.bAniEdit then
        UIHelper.SetVisible(itemScript.ImgDoubleMark, true)
        UIHelper.SetSpriteFrame(itemScript.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon2")
    elseif tEmotionData.nAniType ~= 0 and EMOTION_ACTION_ANI_TYPE[tEmotionData.nAniType] then
        UIHelper.SetVisible(itemScript.ImgDoubleMark, true)
        local path = "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon" .. EMOTION_ACTION_ANI_TYPE[tEmotionData.nAniType]
        UIHelper.SetSpriteFrame(itemScript.ImgDoubleMark, path)
    else
        UIHelper.SetVisible(itemScript.ImgDoubleMark, false)
    end
    UIHelper.LayoutDoLayout(tScript.LayoutLIstLess)

    self.bShowNewEmotion = true
    self:UpdateShowNewEmotionTipVis()

    tScript.nCallId = Timer.Add(self, Def.ShowNewEmotionTime, function()
        self:DoCloseCurOperationHint()
    end)

    local funcCloseShowNewEmotionTip = function()
        self.bShowNewEmotion = false
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self:UpdateShowNewEmotionTipVis()
        Timer.DelTimer(self, tScript.nCallId)
        tScript.nCallId = nil
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end

    self:SetOperationHintInfo(funcCloseShowNewEmotionTip, Def.ShowNewEmotionTime)

    UIHelper.BindUIEvent(tScript.BtnClose, EventType.OnClick, function()
        funcCloseShowNewEmotionTip()
    end)

    UIHelper.BindUIEvent(tScript.BtnQuickEquip, EventType.OnClick, function()
        if EmotionData.IsFaviEmotionActionbFull() then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_EMOTIONACTION_DIY_BE_FULL)

            local scriptView = UIMgr.OpenSingle(false, VIEW_ID.PanelQuickOperation, 2) assert(scriptView)

            local nActionType = tEmotionData.nActionType or EmotionData.GetEmotionCommonType()
            Timer.AddFrame(self, 5, function()
                scriptView:SetBtnEditState(true)
            end)
            UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, 2, nActionType, nil, function()
                scriptView:SetBtnEditState(false)
            end)
        else
            local hPlayer = GetClientPlayer()
            hPlayer.SetMobileEmotionActionDIYInfo(true, dwActionID)

            UIMgr.OpenSingle(false, VIEW_ID.PanelQuickOperation, 2)
        end

        funcCloseShowNewEmotionTip()
    end)
end

function UITipsView:UpdateShowNewEmotionTipVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.ShowQuickEquipTip) and self.bShowNewEmotion
        UIHelper.SetVisible(self.WidgetQuickEquip, bVis)
    end
end

function UITipsView:OnOpenRemotePanel(szName, tData)
    self.szRemotePanelKey = szName
    local node = self.WidgetQuickEquip
    assert(node)
    local tScript = UIHelper.GetBindScript(node)
    assert(tScript)
    UIHelper.SetVisible(tScript.BtnQuickEquip, false)

    UIHelper.SetRichText(tScript.RichTextQuickEquip, UIHelper.GBKToUTF8(tData.szTitle))

    local parent = tScript.ScrollViewLIstMore assert(parent)
    local nCount = #tData.tItemList
    if nCount <= 3 then
        parent = tScript.LayoutLIstLess assert(parent)
    end

    UIHelper.RemoveAllChildren(parent)
    for k, v in ipairs(tData.tItemList) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, parent) assert(itemScript)
        local nTabType, nTabID = v.dwTabType, v.dwIndex
        v.nCount = v.nCount or 1
        local itemInfo = ItemData.GetItemInfo(nTabType, nTabID)

        local nBookID
        if itemInfo.nGenre == ITEM_GENRE.BOOK then
            nBookID = v.nCount
        end

        itemScript:OnInitWithTabID(nTabType, nTabID)
        itemScript:SetClickCallback(function (nTabType, nTabID)
            local _, scriptItemTips = TipsHelper.ShowItemTips(nil, nTabType, nTabID)
            if nBookID then
                scriptItemTips:SetBookID(nBookID)
                scriptItemTips:OnInitWithTabID(nTabType, nTabID)
            end

            if UIHelper.GetSelected(itemScript.ToggleSelect) then
                UIHelper.SetSelected(itemScript.ToggleSelect, false)
            end
        end)

        if itemInfo.nGenre ~= ITEM_GENRE.BOOK and v.nCount > 1 then
            itemScript:SetLabelCount(v.nCount)
        end

        if nCount > 3 then
            UIHelper.SetAnchorPoint(itemScript._rootNode, 0, 0)
        end
    end

    UIHelper.LayoutDoLayout(tScript.LayoutLIstLess)
    UIHelper.ScrollViewDoLayoutAndToTop(tScript.ScrollViewLIstMore)

    UIHelper.SetVisible(tScript.LayoutLIstLess, nCount <= 3)
    UIHelper.SetVisible(tScript.ScrollViewLIstMore, nCount > 3)

    self.bRemotePanel = true
    self:UpdateRemotePanelVis()

    tScript.nCallId = Timer.Add(self, Def.ShowRemotePanelTime, function()
        self:DoCloseCurOperationHint()
    end)

    local CloseRemotePanel = function()
        self.bRemotePanel = false
        self.szRemotePanelKey = nil
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self:UpdateRemotePanelVis()
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end

    self:SetOperationHintInfo(CloseRemotePanel, Def.ShowRemotePanelTime)

    UIHelper.BindUIEvent(tScript.BtnClose, EventType.OnClick, function()
        CloseRemotePanel()
    end)
end

function UITipsView:UpdateRemotePanelVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.OnOpenRemotePanel) and self.bRemotePanel
        UIHelper.SetVisible(self.WidgetQuickEquip, bVis)
    end
end

function UITipsView:CloseRemotePanel(szName)
    if szName == self.szRemotePanelKey then
        self.bRemotePanel = false
        self.szRemotePanelKey = nil
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self:UpdateRemotePanelVis()
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end
end

function UITipsView:OpenSpecailGift(dwID)
    local node = self.WidgetQuickEquip
    assert(node)
    local tScript = UIHelper.GetBindScript(node)
    assert(tScript)
    UIHelper.SetVisible(tScript.BtnQuickEquip, false)

    local tLine = Table_GetSpecailGift(dwID)
    if not tLine then
        return
    end

    local szContent = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tLine.szMobileTitleName), 10)
    UIHelper.SetRichText(tScript.RichTextQuickEquip, szContent)
    local tList = SplitString(tLine.szItemInfo, ";")

    local parent = tScript.ScrollViewLIstMore assert(parent)
    local nCount = #tList
    if nCount <= 3 then
        parent = tScript.LayoutLIstLess assert(parent)
    end

    UIHelper.RemoveAllChildren(parent)
    for k, v in ipairs(tList) do
        local t = SplitString(v, "|") or {}
        local nItemType, nItemIndex = tonumber(t[1] or 0) , tonumber(t[2] or 0)
        if  nItemType and nItemIndex and nItemType ~= 0 and nItemIndex ~= 0  then
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, parent) assert(itemScript)
            itemScript:OnInitWithTabID(nItemType, nItemIndex)
            itemScript:SetClickCallback(function (nTabType, nTabID)
                TipsHelper.ShowItemTips(nil, nTabType, nTabID)
                if UIHelper.GetSelected(itemScript.ToggleSelect) then
                    UIHelper.SetSelected(itemScript.ToggleSelect, false)
                end
            end)
            if nCount > 3 then
                UIHelper.SetAnchorPoint(itemScript._rootNode, 0, 0)
            end
        end
    end

    UIHelper.LayoutDoLayout(tScript.LayoutLIstLess)
    UIHelper.ScrollViewDoLayoutAndToTop(tScript.ScrollViewLIstMore)

    UIHelper.SetVisible(tScript.LayoutLIstLess, nCount <= 3)
    UIHelper.SetVisible(tScript.ScrollViewLIstMore, nCount > 3)

    self.bOpenSpecailGift = true
    self:UpdateSpecailGiftVis()

    tScript.nCallId = Timer.Add(self, Def.ShowSpecailGift, function()
        self:DoCloseCurOperationHint()
    end)

    local CloseSpecailGift = function()
        self.bOpenSpecailGift = false
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self:UpdateSpecailGiftVis()
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end

    self:SetOperationHintInfo(CloseSpecailGift, Def.ShowSpecailGift)

    UIHelper.BindUIEvent(tScript.BtnClose, EventType.OnClick, function()
        CloseSpecailGift()
    end)
end

function UITipsView:UpdateSpecailGiftVis()
    if not self.bTop then
        local bVis = not TipsHelper.IsTipShield(EventType.OpenSpecailGift) and self.bOpenSpecailGift
        UIHelper.SetVisible(self.WidgetQuickEquip, bVis)
    end
end

local tbBleedMaxMap = {
    [PREFAB_ID.WidgetKillNormalHint] = 6,
}

function UITipsView:GetKillScript(nPrefabID)
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
            script = UIHelper.AddPrefab(nPrefabID, self.WidgetHintContent)
        end
    else
        -- 如果超了，就将前面的拿出来，再放到后面去
        script = table.remove(self.tbBleedMap[nPrefabID], 1)

        if script then
            UIHelper.StopAllActions(script._rootNode)
            UIHelper.SetVisible(script._rootNode, false)
        end
    end

    Timer.DelAllTimer(script)
    table.insert(self.tbBleedMap[nPrefabID], script)

    return script
end

function UITipsView:ReleaseOneKillPrefab(script)
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

function UITipsView:ReleaseAllKillPrefab()
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

function UITipsView:ShowAim(tParam)
    self.scriptAim = self.scriptAim or UIHelper.AddPrefab(PREFAB_ID.WidgetHintCrosshair, self.WidgetAnchorCenter)
    if self.scriptAim then
        self.scriptAim:Show(tParam)
    end
end

function UITipsView:HideAim()
    if self.scriptAim then
        self.scriptAim:Hide()
    end
end

return UITipsView