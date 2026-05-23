-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamMainCityMemberListCell
-- Date: 2022-11-21 17:53:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UITeamMainCityMemberListCell
local UITeamMainCityMemberListCell = class("UITeamMainCityMemberListCell")

function UITeamMainCityMemberListCell:OnEnter(dwID, bIsNpc)
    self.dwID   = dwID
    -- todo: 侠客组队界面暂时没有专门的预制，先临时使用玩家组队的预制来兼容，后续添加专门预制后转移到对应预制中
    self.bIsNpc = bIsNpc or false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()

    Timer.AddCycle(self, 0.5, function()
        self:UpdateMic()
        self:UpdateDistanceInfo()
        self:UpdateSelect()
        self:UpdateXunBaoCurrentKungfu()
    end)

    -- 没有队伍，但是通过招请侠客的方式，这里要刷新自己的血量
    Timer.DelTimer(self, self.nNoTeamTimerID)
    if not self.bIsNpc and g_pClientPlayer and dwID == g_pClientPlayer.dwID then
        if not TeamData.IsInParty() then
            self.nNoTeamTimerID = Timer.AddCycle(self, 0.2, function()
                self:UpdateLMRInfoBySelf()
            end)
        end
    end
end

function UITeamMainCityMemberListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITeamMainCityMemberListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTeamPlayer, EventType.OnClick, function (btn)
        if self.bIsNpc then
            -- todo 侠客功能临时使用该预制，后续添加专门预制后再移除这段代码
            -- 助战侠客
            local bSelected = false
            if CanSelectTarget(TARGET.NPC, self.dwID) then
                local npc = NpcData.GetNpc(self.dwID)
                if npc ~= nil then
                    Event.Dispatch(EventType.OnTargetChanged, TARGET.NPC, self.dwID)
                    SetTarget(TARGET.NPC, self.dwID)
                    bSelected = true
                end
            end
            if not bSelected then
                OutputMessage("MSG_SYS", g_tStrings.STR_MSG_PARTY_MEMBER_SELECT_FAR)
            end

            return
        end

        if not g_pClientPlayer then
            return
        end
        if self.dwID == g_pClientPlayer.dwID then
            TargetMgr.SelectSelf()
            return
        end
        local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID)
        if not info.bIsOnLine then
            return
        end

        if BattleFieldData.AllowMatchPlayer() then
            BattleFieldData.MatchPlayer(self.dwID)
        else
            local bSelected = false
            local dwPeekPlayerID = GetPeekPlayerID()
            if CanSelectTarget(TARGET.PLAYER, self.dwID) and dwPeekPlayerID ~= self.dwID then
                TargetMgr.ManualSelect(TARGET.PLAYER, self.dwID)
                local dwType, dwID = Target_GetTargetData()
                if dwType == TARGET.PLAYER and dwID == self.dwID then
                    bSelected = true
                end
            end
            if not bSelected then
                TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_MSG_PARTY_MEMBER_SELECT_FAR)
            end
        end
    end)
end

function UITeamMainCityMemberListCell:RegEvent()
    Event.Reg(self, "UPDATE_SELECT_TARGET", function()
        self:UpdateSelect()
    end)

    Event.Reg(self, "UPDATE_PLAYER_SCHOOL_ID", function(dwPlayerID, dwSchoolID)
        if not self.bIsNpc and dwPlayerID == self.dwID then
            self:UpdateInfo()
        end
    end)

    if self.bIsNpc then
        Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwID)
            if nRetCode == NPC_ASSISTED_RESULT_CODE.NPC_ASSISTED_INFO_CHANGE then
                --数据变动
                self:UpdateInfo()
            end
        end)
    end

    Event.Reg(self, "ON_UPDATE_RESCUE_TIME", function(dwID, nTime)
        if self.bIsNpc or dwID ~= self.dwID then
            return
        end

        self:UpdateRescueTime(nTime)
    end)

    Event.Reg(self, "PLAYER_ENTER_SCENE", function(nPlayerID)
        if nPlayerID ~= self.dwID then
            return
        end
        if self.dwID ~= g_pClientPlayer.dwID and (BattleFieldData.IsInXunBaoBattleFieldMap() or TreasureBattleFieldSkillData.InSkillMap()) then
            PeekOtherPlayer(self.dwID)
        end
    end)

    Event.Reg(self, EventType.UpdateStartReadyConfirm, function()
        self:UpdateReadyInfo()
    end)

    Event.Reg(self, EventType.UpdateMemberReadyConfirm, function(dwID)
        if not self.bIsNpc and dwID == self.dwID then
            self:UpdateReadyInfo()
        end
    end)
end

function UITeamMainCityMemberListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamMainCityMemberListCell:UpdateInfo()
    if self.bIsNpc then
        -- todo 侠客功能临时使用该预制，后续添加专门预制后再移除这段代码
        local tKNpc = NpcData.GetNpc(self.dwID)

        local nLevel = PartnerData.GetPartnerNpcKungfuLevel(self.dwID)

        UIHelper.SetString(self.LabelTeamPlayerName, UIHelper.GBKToUTF8(tKNpc.szName))
        UIHelper.SetString(self.LabelTeamPlayerLevel, nLevel)
        UIHelper.SetTextColor(self.LabelTeamPlayerLevel, cc.c3b(255, 207, 101))

        UIHelper.SetVisible(self.ImgTeamLeader, false)

        -- 侠客这里不显示心法，而是头像
        local tUIInfo      = Table_GetPartnerByTemplateID(tKNpc.dwTemplateID)
        local dwAssistedID = tUIInfo.dwNpcID

        local tPartnerInfo = Table_GetPartnerNpcInfo(dwAssistedID)

        local szImgPath    = tPartnerInfo.szSmallAvatarImg
        UIHelper.SetTexture(self.ImgTeamPlayerXinFa, szImgPath)

        if tKNpc.nMaxLife == 0 then
            UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100)
        else
            UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100 * tKNpc.nCurrentLife / tKNpc.nMaxLife)
        end
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlueBar, 100)

        UIHelper.SetVisible(self.ImgMic, false)

        return
    end

    UIHelper.SetVisible(self.ImgTeamPlayerXinFa, true)
    UIHelper.SetVisible(self.ImgTeamPlayerXinFa_T, false)
    self:UpdateXunBaoCurrentKungfu()

    local hTeam = GetClientTeam()
	local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)

    local szUtf8Name = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(info.szName), 1, 6)
    UIHelper.SetString(self.LabelTeamPlayerName, szUtf8Name)
    UIHelper.SetString(self.LabelTeamPlayerLevel, info.nLevel)

    UIHelper.SetVisible(self.ImgTeamLeader, hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == self.dwID)
    if info.dwForceID == 0 then
        UIHelper.SetSpriteFrame(self.ImgTeamPlayerXinFa, PlayerForceID2SchoolImg2[info.dwForceID])
    else
        PlayerData.SetMountKungfuIcon(self.ImgTeamPlayerXinFa, info.dwMountKungfuID, info.nClientVersionType)
    end

    UIHelper.SetVisible(self.ImgTeamOffLine, not info.bIsOnLine)
    UIHelper.SetVisible(self.ImgTeamDead, info.bIsOnLine and info.bDeathFlag)

    self:UpdateLMRInfo()
    self:UpdateDistanceInfo()
    self:UpdateMic()
    self:UpdateDispelMark()
    self:UpdateReadyInfo()

    if info.bIsOnLine then
        PlayerData.SetPlayerLogionSite(self.ImgLoginSite, TeamData.GetMemberClientVersionType(self.dwID), self.dwID)
    else
        UIHelper.SetVisible(self.ImgLoginSite , false)
    end
end

function UITeamMainCityMemberListCell:UpdateXunBaoCurrentKungfu()
    if not g_pClientPlayer then
        return
    end

    if not BattleFieldData.IsInXunBaoBattleFieldMap() and not TreasureBattleFieldSkillData.InSkillMap() then
        return
    end

    local hMember = GetPlayer(self.dwID)
    if not hMember then
        UIHelper.SetVisible(self.ImgTeamPlayerXinFa, not self.bHaveXunbaoKungfu)
        UIHelper.SetVisible(self.ImgTeamPlayerXinFa_T, self.bHaveXunbaoKungfu)
        return
    end

    local skillID1 = TreasureBattleFieldSkillData.GetKongfuByWeapon(self.dwID)
    if not skillID1 then
        return
    end

    local path = PlayerKungfuImg[skillID1]
    if not path then
        path = TabHelper.GetSkillIconPath(skillID1)
    end

    if path then
        self.bHaveXunbaoKungfu = true
        UIHelper.SetSpriteFrame(self.ImgTeamPlayerXinFa_T, path)
        UIHelper.SetVisible(self.ImgTeamPlayerXinFa_T, true)
        UIHelper.SetVisible(self.ImgTeamPlayerXinFa, false)
    else
        UIHelper.SetVisible(self.ImgTeamPlayerXinFa_T, false)
    end
end

function UITeamMainCityMemberListCell:UpdateLMRInfo()
    if self.bIsNpc then
        local tKNpc = NpcData.GetNpc(self.dwID)
        if tKNpc then
            if tKNpc.nMaxLife == 0 then
                UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100)
            else
                UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100 * tKNpc.nCurrentLife / tKNpc.nMaxLife)
            end
        end
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlueBar, 100)
        return
    end

    local hTeam = GetClientTeam()
	local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)
    if info.nMaxLife == 0 then
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100)
    else
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100 * info.nCurrentLife / info.nMaxLife)
    end
    if info.nMaxMana > 0 and info.nMaxMana ~= 1 then
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlueBar, 100 * info.nCurrentMana / info.nMaxMana)
    else
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlueBar, 0)
    end
end

function UITeamMainCityMemberListCell:UpdateLMRInfoBySelf()
    if not g_pClientPlayer then return end

    if g_pClientPlayer.nMaxLife == 0 then
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100)
    else
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlood, 100 * g_pClientPlayer.nCurrentLife / g_pClientPlayer.nMaxLife)
    end
    if g_pClientPlayer.nMaxMana > 0 and g_pClientPlayer.nMaxMana ~= 1 then
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlueBar, 100 * g_pClientPlayer.nCurrentMana / g_pClientPlayer.nMaxMana)
    else
        UIHelper.SetProgressBarPercent(self.SliderTeamPlayerBlueBar, 0)
    end
end

function UITeamMainCityMemberListCell:UpdateMic()
    if self.bIsNpc then
        return
    end

    if not g_pClientPlayer then
        return
    end
    local bIsSaying = GVoiceMgr.IsMemberSaying(self.dwID)
    UIHelper.SetVisible(self.ImgMic, bIsSaying)
    if bIsSaying then
        UIHelper.SetVisible(self.ImgLoginSite, false)
    else
        PlayerData.SetPlayerLogionSite(self.ImgLoginSite, TeamData.GetMemberClientVersionType(self.dwID), self.dwID)
    end
end

function UITeamMainCityMemberListCell:UpdateDistanceInfo()
    if self.bIsNpc then
        UIHelper.SetVisible(self.ImgTeamPlayerOutRange, false)
        UIHelper.SetOpacity(self._rootNode, 255)
        return
    end

    UIHelper.SetVisible(self.ImgTeamPlayerOutRange, false)
    UIHelper.SetOpacity(self._rootNode, 255)
    if not g_pClientPlayer then
        return
    end
    local hTeam = GetClientTeam()
	local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)
    if self.dwID ~= g_pClientPlayer.dwID then
        local dwPeekPlayerID = GetPeekPlayerID()
        local dwDistance = GetCharacterDistance(g_pClientPlayer.dwID, self.dwID)
        if (dwDistance == -1 or dwPeekPlayerID == self.dwID) and info.bIsOnLine then
           UIHelper.SetVisible(self.ImgTeamPlayerOutRange, true)
            UIHelper.SetOpacity(self._rootNode, 155)
        end
    end

end

function UITeamMainCityMemberListCell:UpdateDispelMark()
    if self.bIsNpc then
        return
    end

    if not g_pClientPlayer then
        UIHelper.SetActiveAndCache(self, self.ImgQuShan, false)
        return
    end

    local dwMapID = g_pClientPlayer.GetMapID()
    local _, nMapType = GetMapParams(dwMapID)
    local bDungeon = nMapType and nMapType == MAP_TYPE.DUNGEON

    local hMember = GetPlayer(self.dwID)
    if not hMember then
        UIHelper.SetActiveAndCache(self, self.WidgetDianMing, false)
        UIHelper.SetActiveAndCache(self, self.ImgQuShan, false)
        return
    end

    local bFocused = BossFocus.IsBeFocused(hMember.dwID)
    UIHelper.SetActiveAndCache(self, self.WidgetDianMing, bFocused)

    local bQuShan = false
    local tBuff = BuffMgr.GetVisibleBuff(hMember)
    for _, buff in ipairs(tBuff) do
        local bDispel = BuffMgr.Buffer_IsDebuffDispelMobile(buff.dwID, buff.nLevel)
        if bDispel then
            if bDungeon then
                if not g_pClientPlayer.IsPlayerInMyParty(buff.dwSkillSrcID) then
                    bQuShan = true
                    break
                end
            -- else
            --     if IsEnemy(g_pClientPlayer.dwID, buff.dwSkillSrcID) then
            --         bQuShan = true
            --         break
            --     end
            end
        end
    end
    UIHelper.SetActiveAndCache(self, self.ImgQuShan, bQuShan)
end

--function BuffMgr.GetMobileTeamShowInfo(hMember)
--    return {
--        {
--            dwID = 122,
--            nLevel = 1,
--        },
--        {
--            dwID = 2313,
--            nLevel = 1,
--        },
--        {
--            dwID = 24349,
--            nLevel = 1,
--        },
--        {
--            dwID = 9298,
--            nLevel = 1,
--        }
--    },false,true
--end

function UITeamMainCityMemberListCell:UpdateBuffInfo()
    if self.bIsNpc then
        return
    end

    if not g_pClientPlayer then
        return
    end

    local dwMapID = g_pClientPlayer.GetMapID()
    local _, nMapType = GetMapParams(dwMapID)
    local bDungeon = nMapType and nMapType == MAP_TYPE.DUNGEON

    local hMember = GetPlayer(self.dwID)
    if not hMember or not bDungeon then
        UIHelper.SetActiveAndCache(self, self.WidgetBuff, false)
        UIHelper.SetActiveAndCache(self, self.ImgTeamDead1, false)
        return
    end

    local tbShowBuff, bCantRebirth, bShow = BuffMgr.GetMobileTeamShowInfo(hMember)
    UIHelper.SetActiveAndCache(self, self.WidgetBuffParent, bShow)
    UIHelper.SetActiveAndCache(self, self.ImgTeamDead1, bCantRebirth)
    if bShow then
        if not self.scriptBuff then
            self.scriptBuff = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityRaidSimpleBuffList, self.WidgetBuffParent)
        end
        self.scriptBuff:UpdateRaidSimpleBuff(tbShowBuff, true)
    end
end

function UITeamMainCityMemberListCell:UpdateSelect()
    if not g_pClientPlayer then
        return
    end
    local nTarType, nTarID = g_pClientPlayer.GetTarget()
    UIHelper.SetVisible(self.ImgSelect, nTarID == self.dwID)
end

function UITeamMainCityMemberListCell:UpdateReadyInfo()
    if self.bIsNpc then
        return
    end
    if not g_pClientPlayer then
        return
    end
    UIHelper.SetVisible(self.WidgetPreparation, TeamData.GetMemberReadyConfirm(self.dwID) == RAID_READY_CONFIRM_STATE.NotYet)
end

function UITeamMainCityMemberListCell:UpdateRescueTime(nTime)
    nTime = nTime or 0
    if self.nRescueTimerID then
        UIHelper.SetVisible(self.ImgWait, false)
        UIHelper.SetVisible(self.LayoutName, true)
        Timer.DelTimer(self, self.nRescueTimerID)
        self.nRescueTimerID = nil
    end

    if self.bIsNpc then
        return
    end

    local hTeam = GetClientTeam()

    local fnCountDown = function(nRemain)
        if nRemain <= 0 then
            UIHelper.SetVisible(self.ImgWait, false)
            UIHelper.SetVisible(self.LayoutName, true)
            return
        end

        local szRemain = ""
        local nM = math.floor(nRemain / 60)
        local nS = nRemain % 60
        szRemain = string.format("%01d:%02d", nM, nS)

        local szColor = TimeLib.GetTimeColor(nRemain)
        local szTime = "待救援 ".. UIHelper.AttachTextColor(szRemain, szColor)
        UIHelper.SetRichText(self.LabelWaitTime, szTime)
    end

    if self.nRescueTime then
        local nRemain = self.nRescueTime - GetCurrentTime()
        UIHelper.SetVisible(self.ImgWait, true)
        UIHelper.SetVisible(self.LayoutName, false)
        fnCountDown(nRemain)

        self.nRescueTimerID = Timer.AddCycle(self, 1, function()
            local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)
            local bDeath = info.bDeathFlag
            nRemain = self.nRescueTime - GetCurrentTime()
            fnCountDown(nRemain)
            if nRemain <= 0 or not bDeath then
                UIHelper.SetVisible(self.ImgWait, false)
                UIHelper.SetVisible(self.LayoutName, true)
                Timer.DelTimer(self, self.nRescueTimerID)
                self.nRescueTimerID = nil
            end
        end)
    else
        UIHelper.SetVisible(self.ImgWait, false)
        UIHelper.SetVisible(self.LayoutName, true)
    end
end

return UITeamMainCityMemberListCell