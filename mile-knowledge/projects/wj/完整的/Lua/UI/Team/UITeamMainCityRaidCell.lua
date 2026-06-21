-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamMainCityRaidCell
-- Date: 2022-11-21 17:53:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local BLOOD_COLOR = {
    [KUNGFU_POSITION.DPS] = "UIAtlas2_MainCity_MainCity1_Teambg_frame_dps.png",
    [KUNGFU_POSITION.T] = "UIAtlas2_MainCity_MainCity1_Teambg_frame_tank.png",
    [KUNGFU_POSITION.Heal] = "UIAtlas2_MainCity_MainCity1_Teambg_frame_cure.png",
}

---@class UITeamMainCityRaidCell
local UITeamMainCityRaidCell = class("UITeamMainCityRaidCell")

function UITeamMainCityRaidCell:OnEnter(dwID, bIsNpc)
    if dwID then
        self.dwID   = dwID
        self.bIsNpc = bIsNpc or false
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if self.dwID then
        self:UpdateInfo()
        Timer.DelTimer(self, self.nTimerID)
        self.nTimerID = Timer.AddCycle(self, 0.5, function()
            self:UpdateMic()
            self:UpdateDistanceInfo()
            self:UpdateSelect()
            self:UpdateXunBaoCurrentKungfu()
            self:UpdateLMRInfoBySelf()
        end)
    end
end

function UITeamMainCityRaidCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITeamMainCityRaidCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTeamMore, EventType.OnClick, function (btn)
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

        if self.fnOnClickCallBack then
            self.fnOnClickCallBack(self.dwID)
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

function UITeamMainCityRaidCell:RegEvent()
    Event.Reg(self, "UPDATE_SELECT_TARGET", function()
        self:UpdateSelect()
    end)

    Event.Reg(self, "UPDATE_PLAYER_SCHOOL_ID", function(dwPlayerID, dwSchoolID)
        if not self.bIsNpc and dwPlayerID == self.dwID then
            self:UpdateInfo()
        end
    end)

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

function UITeamMainCityRaidCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamMainCityRaidCell:UpdateInfo()
    if self.bIsNpc then
        -- todo 侠客功能临时使用该预制，后续添加专门预制后再移除这段代码
        local tKNpc = NpcData.GetNpc(self.dwID)
        local szUtf8Name = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(tKNpc.szName), 1, 6)
        UIHelper.SetString(self.LabelTeamName, szUtf8Name)

        UIHelper.SetVisible(self.ImgTeamIcon, false)

        -- 侠客这里不显示心法，而是头像
        local tUIInfo      = Table_GetPartnerByTemplateID(tKNpc.dwTemplateID)
        local dwAssistedID = tUIInfo.dwNpcID

        local tPartnerInfo = Table_GetPartnerNpcInfo(dwAssistedID)

        ---@see PartnerKungfuIndexToImg
        local nKungfuIndex = tPartnerInfo.nKungfuIndex
        local tPartnerKungfuIndexToPosition = {
            [1] = KUNGFU_POSITION.DPS,
            [2] = KUNGFU_POSITION.T,
            [3] = KUNGFU_POSITION.Heal,
            [4] = KUNGFU_POSITION.DPS, --- 目前只有月嘉禾是这个类别（辅助），在团队面板先当做输出职业看待
        }
        local nPosition = tPartnerKungfuIndexToPosition[nKungfuIndex]

        UIHelper.PreloadSpriteFrame(BLOOD_COLOR[nPosition])
        self.ProgressBlood:loadTexture(BLOOD_COLOR[nPosition], 1)

        local szImgPath    = tPartnerInfo.szSmallAvatarImg
        UIHelper.SetTexture(self.ImgTeamPlayerXinFa, szImgPath)

        UIHelper.SetVisible(self.ImgOffLine, false)
        UIHelper.SetVisible(self.ImgDead, false)

        local dwPlayerID = tKNpc.dwEmployer
        PlayerData.SetPlayerLogionSite(self.ImgLoginSite, TeamData.GetMemberClientVersionType(dwPlayerID), dwPlayerID)

        if tKNpc.nMaxLife == 0 then
            UIHelper.SetProgressBarPercent(self.ProgressBlood, 100)
        else
            UIHelper.SetProgressBarPercent(self.ProgressBlood, 100 * tKNpc.nCurrentLife / tKNpc.nMaxLife)
        end
        UIHelper.SetProgressBarPercent(self.ProgressBlueBar, 100)

        UIHelper.SetVisible(self.ImgMic, false)

        return
    end

    UIHelper.SetVisible(self.ImgTeamPlayerXinFa, true)
    UIHelper.SetVisible(self.ImgTeamPlayerXinFa_T, false)
    self:UpdateXunBaoCurrentKungfu()

    local hTeam = GetClientTeam()
	local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)

    local szUtf8Name = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(info.szName), 1, 6)
    UIHelper.SetString(self.LabelTeamName, szUtf8Name)

    UIHelper.SetSpriteFrame(self.ImgTeamIcon, "UIAtlas2_Public_PublicIcon_PublicIcon1_img_captain.png")
    UIHelper.SetVisible(self.ImgTeamIcon, hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == self.dwID)
    local dwHDKungfuID
    if TabHelper.IsHDKungfuID(info.dwMountKungfuID) then
        dwHDKungfuID = info.dwMountKungfuID
    else
        dwHDKungfuID = TabHelper.GetHDKungfuID(info.dwMountKungfuID)
    end
    local nPosition = PlayerKungfuPosition[dwHDKungfuID] or KUNGFU_POSITION.DPS
    UIHelper.PreloadSpriteFrame(BLOOD_COLOR[nPosition])
    self.ProgressBlood:loadTexture(BLOOD_COLOR[nPosition], 1)
    -- UIHelper.SetSpriteFrame(self.ImgTeamPlayerXinFa, PlayerKungfuImg[info.dwMountKungfuID])
    if info.dwForceID == 0 then
        UIHelper.SetSpriteFrame(self.ImgTeamPlayerXinFa, PlayerForceID2SchoolImg2[info.dwForceID])
    else
        PlayerData.SetMountKungfuIcon(self.ImgTeamPlayerXinFa, info.dwMountKungfuID, info.nClientVersionType)
    end

    UIHelper.SetVisible(self.ImgOffLine, not info.bIsOnLine)
    UIHelper.SetVisible(self.ImgDead, info.bIsOnLine and info.bDeathFlag)

    PlayerData.SetPlayerLogionSite(self.ImgLoginSite, TeamData.GetMemberClientVersionType(self.dwID), self.dwID)

    self:UpdateLMRInfo()
    self:UpdateMic()
    self:UpdateDistanceInfo()
    self:UpdateDispelMark()
    self:UpdateBuffInfo()
    self:UpdateGroupRide()
    self:UpdateSelect()
    self:UpdateReadyInfo()
end

function UITeamMainCityRaidCell:UpdateXunBaoCurrentKungfu()
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

function UITeamMainCityRaidCell:UpdateLMRInfo()
    if self.bIsNpc then
        local tKNpc = NpcData.GetNpc(self.dwID)
        if tKNpc then
            if tKNpc.nMaxLife == 0 then
                UIHelper.SetProgressBarPercent(self.ProgressBlood, 100)
            else
                UIHelper.SetProgressBarPercent(self.ProgressBlood, 100 * tKNpc.nCurrentLife / tKNpc.nMaxLife)
            end
        end
        UIHelper.SetProgressBarPercent(self.ProgressBlueBar, 100)
        return
    end

    local hTeam = GetClientTeam()
	local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)
    if info.nMaxLife == 0 then
        UIHelper.SetProgressBarPercent(self.ProgressBlood, 100)
    else
        UIHelper.SetProgressBarPercent(self.ProgressBlood, 100 * info.nCurrentLife / info.nMaxLife)
    end
    if info.nMaxMana > 0 and info.nMaxMana ~= 1 then
        UIHelper.SetProgressBarPercent(self.ProgressBlueBar, 100 * info.nCurrentMana / info.nMaxMana)
    else
        UIHelper.SetProgressBarPercent(self.ProgressBlueBar, 0)
    end
end

function UITeamMainCityRaidCell:UpdateLMRInfoBySelf()
    if not g_pClientPlayer then return end
    if self.dwID ~= g_pClientPlayer.dwID then return end
    if self.bIsNpc then return end
    if TeamData.IsInParty() then return end

    if g_pClientPlayer.nMaxLife == 0 then
        UIHelper.SetProgressBarPercent(self.ProgressBlood, 100)
    else
        UIHelper.SetProgressBarPercent(self.ProgressBlood, 100 * g_pClientPlayer.nCurrentLife / g_pClientPlayer.nMaxLife)
    end
    if g_pClientPlayer.nMaxMana > 0 and g_pClientPlayer.nMaxMana ~= 1 then
        UIHelper.SetProgressBarPercent(self.ProgressBlueBar, 100 * g_pClientPlayer.nCurrentMana / g_pClientPlayer.nMaxMana)
    else
        UIHelper.SetProgressBarPercent(self.ProgressBlueBar, 0)
    end
end

function UITeamMainCityRaidCell:UpdateMic()
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

function UITeamMainCityRaidCell:UpdateDistanceInfo()
    UIHelper.SetOpacity(self._rootNode, 255)
    if self.bIsNpc then
        return
    end

    if not g_pClientPlayer then
        return
    end
    local hTeam = GetClientTeam()
    local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)
    if self.dwID ~= g_pClientPlayer.dwID then
        local dwPeekPlayerID = GetPeekPlayerID()
        local dwDistance = GetCharacterDistance(g_pClientPlayer.dwID, self.dwID)
        if (dwDistance == -1 or dwPeekPlayerID == self.dwID) and info.bIsOnLine then
            UIHelper.SetOpacity(self._rootNode, 155)
            self:UpdateGroupRide()
        end
    end
end

function UITeamMainCityRaidCell:UpdateDispelMark()
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

function UITeamMainCityRaidCell:UpdateBuffInfo()
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
        UIHelper.SetActiveAndCache(self, self.WidgetBuffParent, false)
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
        self.scriptBuff:UpdateRaidSimpleBuff(tbShowBuff)
    end
end

function UITeamMainCityRaidCell:UpdateSelect()
    if not g_pClientPlayer then
        return
    end
    local nTarType, nTarID = g_pClientPlayer.GetTarget()
    UIHelper.SetVisible(self.ImgSelect, nTarID == self.dwID)
end

function UITeamMainCityRaidCell:UpdateFakeInfo(nIndex)
    if not g_pClientPlayer then
        return
    end
    UIHelper.SetString(self.LabelTeamName, string.format("队友%d", nIndex))
    UIHelper.SetSpriteFrame(self.ImgTeamPlayerXinFa, PlayerKungfuImg[g_pClientPlayer.GetActualKungfuMountID()])
    UIHelper.SetVisible(self.ImgMic, false)
end

function UITeamMainCityRaidCell:UpdateReadyInfo()
    if self.bIsNpc then
        return
    end
    if not g_pClientPlayer then
        return
    end
    UIHelper.SetVisible(self.WidgetPreparation, TeamData.GetMemberReadyConfirm(self.dwID) == RAID_READY_CONFIRM_STATE.NotYet)
end

------------------------------Room------------------------------
function UITeamMainCityRaidCell:UpdateRoomInfo(tPlayerInfo, bOffline, bNotInRaid)
    local szUtf8Name = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(tPlayerInfo.szName), 1, 6)
    UIHelper.SetString(self.LabelTeamName, szUtf8Name)

    local dwHDKungfuID
    if TabHelper.IsHDKungfuID(tPlayerInfo.dwKungfuID) then
        dwHDKungfuID = tPlayerInfo.dwKungfuID
    else
        dwHDKungfuID = TabHelper.GetHDKungfuID(tPlayerInfo.dwKungfuID)
    end

    local nPosition = PlayerKungfuPosition[dwHDKungfuID] or KUNGFU_POSITION.DPS
    UIHelper.PreloadSpriteFrame(BLOOD_COLOR[nPosition])
    self.ProgressBlood:loadTexture(BLOOD_COLOR[nPosition], 1)
    if tPlayerInfo.dwForceID == 0 then
        UIHelper.SetSpriteFrame(self.ImgTeamPlayerXinFa, PlayerForceID2SchoolImg2[tPlayerInfo.dwForceID])
    else
        PlayerData.SetMountKungfuIcon(self.ImgTeamPlayerXinFa, tPlayerInfo.dwKungfuID, tPlayerInfo.nClientVersionType)
    end
    -- UIHelper.SetSpriteFrame(self.ImgTeamPlayerXinFa, PlayerKungfuImg[tPlayerInfo.dwKungfuID])


    PlayerData.SetPlayerLogionSite(self.ImgLoginSite, tPlayerInfo.nClientVersionType)

    UIHelper.SetVisible(self.ImgMic, false)
    UIHelper.SetEnable(self.BtnTeamMore, false)

    UIHelper.SetVisible(self.ImgOutRange, bNotInRaid)
    UIHelper.SetVisible(self.ImgOffLine, bOffline)

    UIHelper.SetSpriteFrame(self.ImgTeamIcon, "UIAtlas2_Public_PublicIcon_PublicIcon1_img_captain.png")
    UIHelper.SetVisible(self.ImgTeamIcon, tPlayerInfo.szGlobalID == RoomData.GetRoomOwner())
    UIHelper.SetVisible(self.ProgressBlueBar, false)
    UIHelper.SetVisible(self.ImgBlueBarBg, false)

    if bNotInRaid then
        UIHelper.SetOpacity(self._rootNode, 255)
    end
end

function UITeamMainCityRaidCell:UpdateRescueTime(nTime)
    nTime = nTime or 0
    if self.nRescueTimerID then
        UIHelper.SetVisible(self.ImgWait, false)
        UIHelper.SetVisible(self.LabelTeamName, true)
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
            UIHelper.SetVisible(self.LabelTeamName, true)
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

    local nRemain = nTime - GetCurrentTime()
    if nRemain > 0 then
        UIHelper.SetVisible(self.ImgWait, true)
        UIHelper.SetVisible(self.LabelTeamName, false)
        fnCountDown(nRemain)

        self.nRescueTimerID = Timer.AddCycle(self, 1, function()
            local info = TeamData.GetMemberInfoEvenNotInTeamForSelf(self.dwID, hTeam)
            local bDeath = info.bDeathFlag
            nRemain = nTime - GetCurrentTime()
            fnCountDown(nRemain)
            if nRemain <= 0 or not bDeath then
                UIHelper.SetVisible(self.ImgWait, false)
                UIHelper.SetVisible(self.LabelTeamName, true)
                Timer.DelTimer(self, self.nRescueTimerID)
                self.nRescueTimerID = nil
            end
        end)
    else
        UIHelper.SetVisible(self.ImgWait, false)
        UIHelper.SetVisible(self.LabelTeamName, true)
    end
end

local function GetRideState(hPlayer)
    if not hPlayer then
        return
    end

    local tDriver = {}
    Buffer_GetByID(hPlayer, SPECIAL_BUFF_ID_LIST.GROUP_RIDE_DRIVER, 1, tDriver)
    if tDriver.dwID then
        return { bDriver = true, dwDriverID = hPlayer.dwID }
    end

    local tPassenger = {}
    Buffer_GetByID(hPlayer, SPECIAL_BUFF_ID_LIST.GROUP_RIDE_PASSENGER, 1, tPassenger)
    if tPassenger.dwID then
        return { bPassenger = true, dwDriverID = tPassenger.dwSkillSrcID }
    end
end

function UITeamMainCityRaidCell:UpdateGroupRide()
    local hMember = GetPlayer(self.dwID)
    if not hMember then
        return
    end

    local tTargetState = GetRideState(hMember)
    if tTargetState then
        local hClientPlayer = GetClientPlayer()
        local tMyState      = GetRideState(hClientPlayer)
        local bSameVehicle  = false
        if tMyState and tTargetState.dwDriverID == tMyState.dwDriverID then
            bSameVehicle = true
        end
        UIHelper.SetVisible(self.ImgHorseBloodFrame, tTargetState.bPassenger or false)
        local szImgPath
        if tTargetState.bDriver and bSameVehicle then
            szImgPath = "UIAtlas2_MainCity_MainCity1_img_HorseOwner_My"
        elseif tTargetState.bDriver and not bSameVehicle then
            szImgPath = "UIAtlas2_MainCity_MainCity1_img_HorseOwner_Other"
        elseif tTargetState.bPassenger and bSameVehicle then
            szImgPath = "UIAtlas2_MainCity_MainCity1_img_HorsePassenger_My"
        elseif tTargetState.bPassenger and not bSameVehicle then
            szImgPath = "UIAtlas2_MainCity_MainCity1_img_HorsePassenger_Other"
        end
        if szImgPath then
            UIHelper.SetVisible(self.ImgHorse, true)
            UIHelper.SetSpriteFrame(self.ImgHorse, szImgPath)
        else
            UIHelper.SetVisible(self.ImgHorse, false)
        end
    else
        UIHelper.SetVisible(self.ImgHorse, false)
        UIHelper.SetVisible(self.ImgHorseBloodFrame, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

function UITeamMainCityRaidCell:SetOnClickCallBack(fnCallBack)
    self.fnOnClickCallBack = fnCallBack
end

return UITeamMainCityRaidCell