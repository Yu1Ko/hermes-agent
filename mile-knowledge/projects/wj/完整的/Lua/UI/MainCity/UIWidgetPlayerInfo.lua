-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetPlayerInfo
-- Date: 2022-11-02
-- Desc: 角色信息栏
-- Prefab: PREFAB_ID.WidgetMainCityPlayer
-- ---------------------------------------------------------------------------------
local UIWidgetPlayerInfo = class("UIWidgetPlayerInfo")

local m_check_life = true
local m_check_mana = true

function UIWidgetPlayerInfo:OnEnter(nPlayerId, bTarget)
    self.m = {}
    self.m.bTarget = bTarget -- 是否将自身作为目标来显示
    self.m.nPlayerId = nPlayerId -- 若为nil, 默认为自身, 但需要延后获取
    self.m.nPrevLevel = g_pClientPlayer and g_pClientPlayer.nLevel or 0
    self.m.bStateChanged = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Init()

    -- 玩家进入后周期刷新
    self.m.nCallId = Timer.AddCycle(self, 0.1, function()
        self:OnUpdate()
    end)

    self:UpdateAvatar()
    --self:UpdateBuffBtnState()
end

function UIWidgetPlayerInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIHelper.ClearTouchLikeTips()

    self.m = nil
end

function UIWidgetPlayerInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCharacter, EventType.OnClick, function()
        self:PopoutMenu()
        -- 若是玩家自身信息栏
        if not self.m.bTarget then
            -- 自动选中自身
            TargetMgr.SelectSelf()
        end
    end)

    UIHelper.BindUIEvent(self.BtnBuff, EventType.OnClick, function()
        local nX = UIHelper.GetWorldPositionX(self.BtnBuff)
        local nY = UIHelper.GetWorldPositionY(self.BtnBuff)
        local tBuff = BuffMgr.GetSortedBuff(self:GetPlayer(), true)
        if TreasureBattleFieldSkillData.InSkillMap() then
            local tSkillBuffs = TreasureBattleFieldSkillData.GetSkillBuffList(self:GetPlayer())
            table.insert_tab(tBuff, tSkillBuffs)
        end
        if #tBuff > 0 then
            local tip, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip, nX, nY)
            script:UpdatePlayerInfo(self.m.nPlayerId, tBuff, true)
        end

    end)

    UIHelper.BindUIEvent(self.BtnBuff2, EventType.OnClick, function()
        local tBuff = BuffMgr.GetSortedBuff(self:GetPlayer(), true)
        if TreasureBattleFieldSkillData.InSkillMap() then
            local tSkillBuffs = TreasureBattleFieldSkillData.GetSkillBuffList(self:GetPlayer())
            table.insert_tab(tBuff, tSkillBuffs)
        end
        if #tBuff > 0 then
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetMainCityBuffContentTip,
                self.BtnBuff2,TipsLayoutDir.TOP_RIGHT)
            script:UpdatePlayerInfo(self.m.nPlayerId, tBuff, true)

            tip:SetSize(UIHelper.GetContentSize(script.ScrollViewBuffMore))
            tip:SetOffset(-100, 0)
            tip:Update()
        end
    end)

    UIHelper.BindUIEvent(self.TogVoice, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetVoiceTips, self.TogVoice)
    end)

    UIHelper.BindUIEvent(self.TogVoice2, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetVoiceTips, self.TogVoice)
    end)

    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        if not self.m.bTarget then
            Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.PLAYER, self.nMode)
        end
    end)


    UIHelper.BindUIEvent(self.BtnTargetBar, EventType.OnClick, function ()
		self:SelectTargetTarget()
   	end)
end

function UIWidgetPlayerInfo:RegEvent()
    Event.Reg(self, "ON_PLAYER_JOIN_TONG", function()
        -- ???? 可以用于刷新入口的交互状态
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self:OnPlayerLeaveScene()
    end)
    Event.Reg(self, "PLAYER_LEVEL_UP", function()
        if not self.m.bTarget then
            local nPlayerId = arg0
            if self.m.nPlayerId == nPlayerId then
                self:OnPlayerLevelUp()
            end
        end
    end)

    Event.Reg(self, "PLAYER_LEVEL_UPDATE", function()
        if not self.m.bTarget then
            local nPlayerId = arg0
            if self.m.nPlayerId == nPlayerId then
                self:OnPlayerLevelUp()
            end
        end
    end)

    Event.Reg(self, "FIGHT_HINT", function()
        if not self.m.bTarget then
            self:OnFightHint()
        end
    end)
    Event.Reg(self, EventType.PreviewAvator, function(dwID, nPlayerId)
        --头像预览
        if self.m.nPlayerId == nPlayerId and not self.m.bTarget and self.dwMiniAvatarID ~= dwID then
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayer, dwID, self.SFXPlayerIcon, self.AnimatePlayer, g_pClientPlayer.nRoleType, g_pClientPlayer.dwForceID, true, false, nil, false)
            UIHelper.UpdateAvatarFarme(self.tbImgFrameNormalBg, dwID, self.SFXFrameBgAll, self.SFXFrameBg1, self.SFXFrameBg3, false)
            self.dwMiniAvatarID = dwID
        end
    end)
    Event.Reg(self, "SET_MINI_AVATAR", function(dwID)
        self:UpdateAvatar()
    end)

    Event.Reg(self, "TARGET_MINI_AVATAR_MISC", function()
        if self.m.bTarget then
            self:UpdateAvatar()
        end
    end)

    Event.Reg(self, "CURRENT_PLAYER_FORCE_CHANGED", function()
        if g_pClientPlayer then
            g_pClientPlayer.SetMiniAvatar(0)
        end

        self:UpdateAvatar()
    end)

    -- 李渡鬼域变身时，buff会变更，在这里更新下新的头像
    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11

        if BattleFieldData.IsInZombieBattleFieldMap() and self.m.nPlayerId == owner then
            self:UpdateAvatar()
        end

        if id == SPECIAL_BUFF_ID_LIST.GROUP_RIDE_DRIVER or id == SPECIAL_BUFF_ID_LIST.GROUP_RIDE_PASSENGER then
            self:UpdateInvincible()
            self:UpdateTargetTargetInvincible()
        end
    end)

    Event.Reg(self, "OT_ACTION_PROGRESS_BREAK", function()
        if self.m.nPlayerId == nPlayerId then
            self:ActionBreak()
        end
    end)

    Event.Reg(self, EventType.OnPlayerSettingChange, function()
        self:UpdateLife(true)
        --self:UpdateMana(true)
    end)

    Event.Reg(self, EventType.OnApplicationWillEnterForeground, function()
        self:UpdateTeam()
    end)

    Event.Reg(self, "OnRequestPermissionCallback", function(nPermission, bResult)
        if nPermission == Permission.Microphone then
            self:UpdateTeam()
        end
    end)

    Event.Reg(self, "ON_NEW_PROXY_SKILL_LIST_NOTIFY", function()
        if not self.m.bTarget then
            self.m.nPlayerId = nil
            self:OnUpdate()
            self:UpdateAvatar()
        end
    end)
    
    Event.Reg(self, "ON_CLEAR_PROXY_SKILL_LIST_NOTIFY", function()
        if not self.m.bTarget then
            self.m.nPlayerId = nil
            self:OnUpdate()
            self:UpdateAvatar()
        end
    end)

end

function UIWidgetPlayerInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPlayerInfo:OnUpdate()
    local player = self:GetPlayer()

    --驭兽状态发生变化
    if player and self:IsSelf() then
        if self.m.dwPrevFakeFellowPetTemplateID == nil then
            self.m.dwPrevFakeFellowPetTemplateID = player.dwFakeFellowPetTemplateID
        elseif self.m.dwPrevFakeFellowPetTemplateID ~= player.dwFakeFellowPetTemplateID then
            self.m.bStateChanged = true
            self.m.dwPrevFakeFellowPetTemplateID = player.dwFakeFellowPetTemplateID
            self:UpdateAvatar()
        else
            self.m.bStateChanged = false
        end
    end

    if player ~= self.m.player then
        self:setVisible(player ~= nil)
        self.m.player = player
    end

    if self.m.bTarget then
        self:UpdateTargetTarget()
        self:UpdateTargetDistance()
--        self.buffScript:UpdateBuffCycle(player)
    else
        self:CloseTargetTarget()
        self:CloseTargetDistance()
    end

    self:UpdateName()
    self:UpdateLevel()
    self:UpdateLife()
    self:UpdateQiEnergy()
    --self:UpdateHead() --头像更新有事件通知
    --self:UpdateMana()
    -- self:UpdateSchool()
    self:UpdateCamp()
    self:UpdateTeam()
    self:UpdateKungfu()
    self:UpdateSlay()
    self:UpdateBattleIn()

    self:UpdateForClientPlayer()
    self:UpdateSkillProgress()
    if self.buffScript then
        self.buffScript:UpdateBuffCycle(player)
    end

end

function UIWidgetPlayerInfo:UpdateForClientPlayer()
    -- 不是自己, 跳过
    if self.m.bTarget then
        return
    end

    if not g_pClientPlayer or g_pClientPlayer.dwID ~= self.m.nPlayerId then
        return
    end

    self:DelayShowLevelUp()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPlayerInfo:OnFightHint()
    if not self:IsSelf() then
        return
    end
    local bFight = arg0
    if bFight then
        --WorldMap.bInFight = true
        --MiddleMap.bInFight = true
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_MSG_ENTER_FIGHT)

        --教学 进入战斗
        FireHelpEvent("OnEnterFight")
    else
        --WorldMap.bInFight = false
        --MiddleMap.bInFight = false
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_MSG_LEAVE_FIGHT)
    end
end

function UIWidgetPlayerInfo:UpdateBattleIn()
    local player = self:GetPlayer()
    if not player then
        return
    end

    UIHelper.SetActiveAndCache(self, self.ImgBattleIn, player.bFightState)
end

function UIWidgetPlayerInfo:OnPlayerEnterScene()
    local nPlayerID = arg0
    assert(nPlayerID)
end

function UIWidgetPlayerInfo:OnPlayerLeaveScene()
    self.m.nPlayerId = nil
end

function UIWidgetPlayerInfo:OnPlayerLevelUp()
    if self:IsSelf() then
        self.m.bLevelChanged = true
    end
end

function UIWidgetPlayerInfo:DelayShowLevelUp()
    if self.m.bLevelChanged then
        -- 是否全屏窗口挡住
        if not Global.HaveFullScreenUI() then
            self.m.bLevelChanged = nil
            local nLevel = self.m.player.nLevel
            TipsHelper.ShowLevelUpTip(nLevel)

            for i, v in ipairs(UISystemMenuTab) do
                if v.nSystemOpenID ~= 0 then
                    local tOpen = UISystemOpenTab[v.nSystemOpenID]
                    if tOpen and tOpen.nOpenLevel > 0 then
                        local nOpenLevel = tOpen.nOpenLevel
                        if self.m.nPrevLevel < nOpenLevel and nLevel >= nOpenLevel then
                            TipsHelper.ShowNewFeatureTip(i)
                        end
                    end
                end
            end
            self.m.nPrevLevel = nLevel
        end
    end
end

function UIWidgetPlayerInfo:Init()
    self:setVisible(false)
    if self.m.bTarget then
        self.buffScript = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuffList, self.WidgetMainCityBuffList)
    end
    local bTreasureBattle = BattleFieldData.IsInTreasureBattleFieldMap()
    local bMoba = BattleFieldData.IsInMobaBattleFieldMap()
    if bTreasureBattle or bMoba then
        UIHelper.AddPrefab(PREFAB_ID.WidgetEquipHintMainCity, self.WidgetPlayerOtherInfo, self.m.nPlayerId)
    end

    if self.m.bTarget or (self.m.nPlayerId and self.m.nPlayerId ~= UI_GetClientPlayerID()) then
        UIHelper.AddPrefab(PREFAB_ID.WidgetMiddleBaiZhanHint, self.WidgetPlayerOtherInfo, TARGET.PLAYER, self.m.nPlayerId, self.m.nPlayerId ~= UI_GetClientPlayerID())
    end

    if bMoba then
        --- 初始时刷新下等级
        self:UpdateLevel()
    end

    self:UpdateInvincible()
end

function UIWidgetPlayerInfo:setVisible(bVisible)
    -- local node = self._rootNode
    -- assert(node)
    -- node:setVisible(bVisible)
    UIHelper.SetActiveAndCache(self, self._rootNode, bVisible)
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
end

function UIWidgetPlayerInfo:UpdateAvatar()
    local player = self:GetPlayer()

    if not g_pClientPlayer then return end
    if not player then return end

    local bFlip = true
    if (player.dwID == g_pClientPlayer.dwID and self.m.bTarget) or player.dwID ~= g_pClientPlayer.dwID then
        bFlip = false
    end
    if player and player.dwFakeFellowPetTemplateID ~= 0 then
        UIHelper.SetTexture(self.ImgPlayer, "Resource/PlayerAvatar/chongwu.png")
    else
        if not self.dwMiniAvatarID or self.dwMiniAvatarID == 0 or self.dwMiniAvatarID ~= player.dwMiniAvatarID then
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayer, player.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayer, player.nRoleType, player.dwForceID, bFlip, true, player, false)
            UIHelper.UpdateAvatarFarme(self.tbImgFrameNormalBg, player.dwMiniAvatarID, self.SFXFrameBgAll, self.SFXFrameBg1, self.SFXFrameBg3, false)
            self.dwMiniAvatarID = player.dwMiniAvatarID
        end
    end
end

function UIWidgetPlayerInfo:UpdateName()
    local szName = self.m.player and self.m.player.szName or ""
    if self.m.player and self.m.szName ~= szName or self.m.bStateChanged then
        self.m.szName = szName
        local node = self.LabelPlayerName
        local tnode = self.LabelTargetName
        assert(node)

        local szUtf8Name = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(szName), 6)
        local szNameLen4 = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(szName), 4)

        if self.m.player and self.m.player.dwFakeFellowPetTemplateID ~= 0 then
            local tLine = Table_GetIdentityPetWord(self.m.player.dwFakeFellowPetTemplateID)
            szUtf8Name = UIHelper.GBKToUTF8(self.m.player.szName) .. g_tStrings.SKILL_DAMAGE_LOG_1 .. UIHelper.GBKToUTF8(tLine.szName)
        end

        node:setString(szUtf8Name)
        tnode:setString(szNameLen4)

        if not InteractPlayer(self.m.player.dwID) then  --敌人关系
            UIHelper.SetColor(node, cc.c3b(254, 87, 42))
            UIHelper.SetColor(tnode, cc.c3b(254, 87, 42))
        end
        if self:IsFoeRelation(self.m.player.dwID) then   --敌对关系
            UIHelper.SetColor(node, cc.c3b(231, 65, 235))
            UIHelper.SetColor(tnode, cc.c3b(231, 65, 235))
        end
    end
end

function UIWidgetPlayerInfo:UpdateLevel()
    local nLevel = self.m.player and self.m.player.nLevel or 0

    if self.m.player and BattleFieldData.IsInMobaBattleFieldMap() then
        nLevel = 1

        local nExpEffectBuffID = 14821
        local buff = self.m.player.GetBuff(nExpEffectBuffID, 0)
        if buff then
            nLevel = buff.nStackNum
        end
    end

    if self.m.nLevel ~= nLevel then
        self.m.nLevel = nLevel
        local node = self.LabelPlayerLevel
        assert(node)
        node:setString(tostring(nLevel))
    end
end

function UIWidgetPlayerInfo:UpdateLife(bForceUpdate)
    local nCurrentLife = self.m.player and self.m.player.nCurrentLife or 0
    local nMaxLife = self.m.player and self.m.player.nMaxLife or 1
    local nDamageAbsorbValue = self.m.player and self.m.player.nDamageAbsorbValue or 0
    if self.m.nCurrentLife ~= nCurrentLife or self.m.nMaxLife ~= nMaxLife
        or self.m.nDamageAbsorbValue ~= nDamageAbsorbValue or bForceUpdate == true then
        self.m.nCurrentLife = nCurrentLife
        self.m.nMaxLife = nMaxLife
        self.m.nDamageAbsorbValue = nDamageAbsorbValue

        local szLife
        if g_pClientPlayer and g_pClientPlayer.dwID ~= self.m.nPlayerId then
            szLife = UIHelper.GetStateString(nCurrentLife, nMaxLife)
        else
            szLife = UIHelper.GetSelfStateString(nCurrentLife, nMaxLife)
        end
        UIHelper.SetString(self.LabelBlood, self.szLife or szLife)

        --教学 血量低
        if nCurrentLife / nMaxLife < 0.5 and self.m.player then
            local player = GetClientPlayer()
            if player and self.m.player.dwID == player.dwID and m_check_life then
                FireHelpEvent("OnHealthLow")
                m_check_life = false
            end
        else
            m_check_life = true
        end

        -- 血条
        local hBloodBar = self.SliderBlood
        assert(hBloodBar)
        local hDamageBar = self.SliderBloodDefense
        assert(hDamageBar)
        if nDamageAbsorbValue > 0 then
            if nCurrentLife + nDamageAbsorbValue > nMaxLife then
				nMaxLife = nCurrentLife + nDamageAbsorbValue
			end

            UIHelper.SetActiveAndCache(self, hDamageBar, true)

			local fDamagePercent = 100 * (nCurrentLife + nDamageAbsorbValue) / nMaxLife
            UIHelper.SetProgressBarPercent(hDamageBar, fDamagePercent)
        else
            UIHelper.SetActiveAndCache(self, hDamageBar, false)
        end


        local fBloodPercent = 100 * nCurrentLife / nMaxLife
        UIHelper.SetProgressBarPercent(hBloodBar, fBloodPercent)

        UIHelper.SetPositionX(self.SFXBloodLight, 2.1 * fBloodPercent - 115)
    end
end

-- 26年4月版本开始废弃
function UIWidgetPlayerInfo:UpdateMana(bForceUpdate)
    local nCurrentMana = self.m.player and self.m.player.nCurrentMana or 0
    local nMaxMana = self.m.player and self.m.player.nMaxMana or 1
    if self.m.player and self.m.player.nMaxMana > 0 and self.m.player.nMaxMana ~= 1 and (self.m.nCurrentMana ~= nCurrentMana or self.m.nMaxMana ~= nMaxMana or bForceUpdate) then
        self.m.nCurrentMana = nCurrentMana
        self.m.nMaxMana = nMaxMana


        local nPercent = 100 * nCurrentMana / nMaxMana
        local szMana = UIHelper.GetSelfStateString(nCurrentMana, nMaxMana)
        UIHelper.SetString(self.LabelBlue, szMana)

        -- 蓝条
        local bar = self.SliderBlue
        assert(bar)
        UIHelper.SetProgressBarPercent(bar, nPercent)

        --教学 蓝量低
        if nCurrentMana / nMaxMana < 0.5 and self.m.player then
            local player = GetClientPlayer()
            if player and self.m.player.dwID == player.dwID and m_check_mana then
                FireHelpEvent("OnManaLow")
                m_check_mana = false
            end
        else
            m_check_mana = true
        end
    end
end

function UIWidgetPlayerInfo:UpdateQiEnergy()
    local player = self.m.player
    local szKey = self.m.bTarget and UISettingKey.ShowDouqiTarget or UISettingKey.ShowDouqi
    local bShow = player and SkillData.IsUsingHDKungFu(player.GetActualKungfuMountID()) and GameSettingData.GetNewValue(szKey) and not BattleFieldData.IsInXunBaoBattleFieldMap()
    UIHelper.SetActiveAndCache(self, self.WidgetGas, bShow)
    if not bShow then
        return
    end 
    
    local nQiRedSP = player.nCurrentQiRedSP or 0
    local nSpecialQi = player.nCurrentQiSP or 0
    local nTotalQi = nQiRedSP + nSpecialQi
    for i = 1, #self.QiControlList do
        local hQiControl = self.QiControlList[i]
        UIHelper.SetActiveAndCache(self, hQiControl, i <= nTotalQi)
    end
end

function UIWidgetPlayerInfo:UpdateCamp()
    local bVisible = UIHelper.GetVisible(self.ImgCamp)
    if self.m.player then
        if self.m.bCampFlag ~= self.m.player.bCampFlag or self.m.nCamp ~= self.m.player.nCamp or self.m.nCamp and not bVisible then
            self.m.bCampFlag = self.m.player.bCampFlag
            self.m.nCamp = self.m.player.nCamp
            CampData.SetUICampImgByPlayer(self.ImgCamp, self.m.player, true)
        end
    else
        UIHelper.SetVisible(self.ImgCamp, false)
    end
end

function UIWidgetPlayerInfo:UpdateTeam()
    local node = self.ImgTeamLeader
    assert(node)
    local hPlayer = g_pClientPlayer

    local bLeader = false
    local bVoice = false

    if not self.m.bTarget and hPlayer and hPlayer.IsInParty() then
        local hTeam = GetClientTeam()
        if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == self.m.nPlayerId then
            bLeader = true
        end
        -- if hPlayer.dwID == self.m.nPlayerId then
        --     bVoice = true
        --     if GVoiceMgr.IsOpenSpeakerAndMic() then
        --         UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Team_Team1_img_voice")
        --     elseif GVoiceMgr.IsOpenSpeakerCloseMic() then
        --         UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Team_Team1_img_voice01")
        --     else
        --         UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Team_Team1_img_voice_close")
        --     end
        -- end
    end
    node:setVisible(bLeader)

    if self.m.bVoice ~= bVoice then
        UIHelper.SetVisible(self.TogVoice, bVoice)
        UIHelper.LayoutDoLayout(self.LayoutPlayerHead)
        UIHelper.SetVisible(self.WidgetVoice2, bVoice)
        UIHelper.LayoutDoLayout(self.LayoutBuffAndVoice2)
        self.m.bVoice = bVoice
    end
end

function UIWidgetPlayerInfo:UpdateKungfu()
    UIHelper.SetVisible(self.ImgSkill, false)
    UIHelper.SetVisible(self.ImgSkill_T, false)

    -- 绝境战场-寻宝模式特判
    if BattleFieldData.IsInXunBaoBattleFieldMap() or TreasureBattleFieldSkillData.InSkillMap() then
        self:UpdateXunBaoCurrentKungfu()
        return
    end

    local node = self.ImgSkill
    local bVisible = UIHelper.GetVisible(self.ImgSkill)
    assert(node)
    if self.m.player then
        local skillID1 = self.m.player.GetActualKungfuMountID()
        local path = PlayerKungfuImg[skillID1]
        if not path then
            local path = TabHelper.GetSkillIconPath(skillID1)
        end

        if path then
            if self.m.szKungfuPath ~= path or not bVisible then
                -- UIHelper.SetTexture(node, path)
                UIHelper.SetSpriteFrame(node, path)
                UIHelper.SetVisible(node, true)
                self.m.szKungfuPath = path
            end
        else
            UIHelper.SetVisible(node, false)
        end
    end
end

function UIWidgetPlayerInfo:UpdateXunBaoCurrentKungfu()
    local node = self.ImgSkill_T
    local bVisible = UIHelper.GetVisible(self.ImgSkill_T)
    if self.m.player then
        local skillID1 = TreasureBattleFieldSkillData.GetKongfuByWeapon(self.m.nPlayerId)
        local path = PlayerKungfuImg[skillID1]
        if not path then
            path = TabHelper.GetSkillIconPath(skillID1)
        end

        if path then
            if not bVisible then
                UIHelper.SetSpriteFrame(node, path)
                UIHelper.SetVisible(node, true)
            end
        else
            UIHelper.SetVisible(node, false)
        end
    end
end

function UIWidgetPlayerInfo:UpdateHead()
    local node = self.ImgPlayer
    assert(node)
    node:setVisible(true)
end

function UIWidgetPlayerInfo:UpdateSlay()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local bOnSlay = hPlayer.IsOnSlay()
    UIHelper.SetActiveAndCache(self, self.Eff_UIheroHeadSculpture, bOnSlay)
    --if bOnSlay then
    --    local nCount = hPlayer.nSlayKillCount
    --    --Player.UpdateSlayAnimate(nCount)
    --end
end

function UIWidgetPlayerInfo:GetPlayer()
    local nPlayerId = self.m.nPlayerId
    if not nPlayerId then
        local player = GetControlPlayer()
        if player then
            nPlayerId = player.dwID
            self.m.nPlayerId = nPlayerId
            return player
        end
    else
        if GetControlPlayer() and GetControlPlayer().dwID == nPlayerId then
            return GetControlPlayer()
        end
    end
    return GetPlayer(nPlayerId)
end

function UIWidgetPlayerInfo:IsSelf()
    if not self.m.nPlayerId then
        return true
    end

    local player = g_pClientPlayer
    if player and player.dwID == self.m.nPlayerId then
        return true
    end

    return false
end

function UIWidgetPlayerInfo:PopoutMenu()
    local nX = UIHelper.GetWorldPositionX(self._rootNode) - 40
    local nY = UIHelper.GetWorldPositionY(self._rootNode) - UIHelper.GetHeight(self.BtnCharacter)

    if self:IsSelf() then
        if TeamData.IsInParty() and self.m.bTarget then
            local tbMenus = {}
            TeamData.InsertTeamPlayerMenus(tbMenus)
            TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetPlayerPop, nX, nY, self.m.nPlayerId, tbMenus)
        end
        return
    end

    --local tips = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self.WidgetPlayerTipShell, self.m.nPlayerId)
    --local tipsNode = tips._rootNode
    --UIHelper.SetTouchLikeTips(tipsNode, UIMgr.GetLayer(UILayer.Page), function ()
    --    UIHelper.RemoveFromParent(tipsNode)
    --end)

    local player = self:GetPlayer()
    if player ~= nil then
        -- 改成使用 HoverTips， 方便实现点击特定按钮后主动关闭的功能
        local _, scriptPop = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetPlayerPop, nX, nY, self.m.nPlayerId)
        if scriptPop then
            scriptPop:SetPersonalVisible()
            local personalCardScript = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, scriptPop.WidgetPersonalCardTips, player.GetGlobalID())
            if personalCardScript then
                personalCardScript:SetPlayerId(self.m.nPlayerId)
                local fnOnClickMore = function ()
                    scriptPop:SetPersonalVisible(false)
                end
                personalCardScript:UpdateOtherPlayerBtn(fnOnClickMore, nil, self.m.nPlayerId)
            end
        end
    end
end




--进度条 start
local ACTION_STATE = {
    NONE = 1,
    PREPARE = 2,
    DONE = 3,
    BREAK = 4,
    FADE = 5,
}

function UIWidgetPlayerInfo:UpdateSkillProgress()

    if self:IsSelf() then
        return
    end

    local tar = GetTargetHandle(TARGET.PLAYER, self.m.nPlayerId)
    if not tar then
        return
    end

    local bPrePare, dwID, dwLevel, fP, nType = GetSkillOTActionState(tar)
    local tSkill = (IsNumber(dwID) and dwID > 0) and GetSkill(dwID, dwLevel)
    local bar
    local node = self.LabelProgressName
    if not tSkill then
        UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
        return
    end

    if tSkill.nPrepareFrames == 0 and tSkill.nChannelFrame == 0 then
        UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
        return
    end

    local nShow = Table_GetSkillOTActionShowType(dwID, dwLevel) --表中新增默认规则显示项
    if (nShow == SKILL_OTACTION_SHOW_TYPE.ShowIfCanBreak or nShow == SKILL_OTACTION_SHOW_TYPE.Show)
            and tSkill.nBrokenRate > 0 then
        bar = self.SliderSkillProgress1
        UIHelper.SetActiveAndCache(self, self.SliderSkillProgress2, false)
    elseif nShow == SKILL_OTACTION_SHOW_TYPE.Show
            and tSkill.nBrokenRate == 0 then
        bar = self.SliderSkillProgress2
        UIHelper.SetActiveAndCache(self, self.SliderSkillProgress1, false)
    else
        UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
        return
    end

    if self.skillState ~= ACTION_STATE.PREPARE and fP * 100 > 0 and fP * 100 < 100 then
        self.skillState = ACTION_STATE.PREPARE
    elseif self.skillState == ACTION_STATE.PREPARE and fP >= 1 then
        self.skillState = ACTION_STATE.NONE
    end

    if self.skillState == ACTION_STATE.PREPARE then
        UIHelper.SetProgressBarPercent(bar, 100 * fP)
        UIHelper.SetActiveAndCache(self, bar, true)
        node:setString(UIHelper.GBKToUTF8(Table_GetSkillName(dwID, dwLevel)))
        UIHelper.SetActiveAndCache(self, node, true)
        UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, true)
    else
        UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
    end
end

function UIWidgetPlayerInfo:ActionBreak()
    self.skillState = ACTION_STATE.BREAK
end

--进度条 end

function UIWidgetPlayerInfo:IsFoeRelation(dwID)
    local tbFoeInfoList = FellowshipData.GetFoeInfo() or {}
    for k, v in ipairs(tbFoeInfoList) do
        if dwID == v.id then
            return true
        end
    end
    return false
end

-- -- TargetTarget

function UIWidgetPlayerInfo:UpdateTargetTarget()
    local hTargetTarget = nil
    local hTarget = nil
    hTarget = GetTargetHandle(TARGET.PLAYER, self.m.nPlayerId)
    if hTarget then
        hTargetTarget = GetTargetHandle(hTarget.GetTarget())
    else
        return self:CloseTargetTarget()
    end

    if hTargetTarget then
        local dwTTType, dwTTID = hTarget.GetTarget()
        UIHelper.SetActiveAndCache(self, self.WidgetTarget, true)
        UIHelper.SetActiveAndCache(self, self.LabelPlayerName, false)
        self.m.bHaveTTarget = true
        if self.m.dwTTType ~= dwTTType or self.m.dwTTID ~= dwTTID then
            self.m.dwTTType = dwTTType
            self.m.dwTTID = dwTTID
            self:UpdateTargetTargetState()
            self:UpdateTargetTargetLife()
            self:UpdateTargetTargetInvincible()
        else
            self:UpdateTargetTargetLife()
        end
    else
        return self:CloseTargetTarget()
    end
end

function UIWidgetPlayerInfo:CloseTargetTarget()
    self.m.dwTTType = nil
    self.m.dwTTID = nil
    self.m.bHaveTTarget = false
    UIHelper.SetActiveAndCache(self, self.WidgetTarget, false)
    UIHelper.SetActiveAndCache(self, self.LabelPlayerName, true)
    return
end

function UIWidgetPlayerInfo:UpdateTargetTargetState()
    local hTarget = nil
    local szName = ""
    if self.m.dwTTType == TARGET.PLAYER then
        hTarget = GetPlayer(self.m.dwTTID)
        self.m.targettarget = hTarget

        szName = UIHelper.GBKToUTF8(hTarget.szName)
        -- local nCharCount, szLimitedName = GetStringCharCountAndTopChars(szName, 4)
        -- if nCharCount > 4 then
        --     UIHelper.SetString(self.LabelTTName, szLimitedName .. "...")
        -- else
        --     UIHelper.SetString(self.LabelTTName, szName )
        -- end
        UIHelper.SetString(self.LabelTTName, szName, 4)


        UIHelper.SetVisible(self.ImgNPCTTIcon, false)
        UIHelper.RoleChange_UpdateAvatar(self.ImgTTIcon, hTarget.dwMiniAvatarID, self.SFXTTIcon, self.AnimateTTIcon, hTarget.nRoleType, hTarget.dwForceID, false, false, nil, false)
    elseif self.m.dwTTType == TARGET.NPC then
        hTarget = GetNpc(self.m.dwTTID)
        self.m.targettarget = hTarget

        szName = UIHelper.GBKToUTF8(hTarget.szName)
        -- local nCharCount, szLimitedName = GetStringCharCountAndTopChars(szName, 4)
        -- if nCharCount > 4 then
        --     UIHelper.SetString(self.LabelTTName, szLimitedName .. "...")
        -- else
        --     UIHelper.SetString(self.LabelTTName, szName )
        -- end
        UIHelper.SetString(self.LabelTTName, szName, 4)

        UIHelper.ClearAvatarState(self.ImgTTIcon, self.AnimateTTIcon, self.SFXTTIcon)
        local szImage = NpcData.GetNpcHeadImage(self.m.dwTTID)
        if szImage and szImage ~= "" then
            UIHelper.SetSpriteFrame(self.ImgNPCTTIcon, szImage)
            UIHelper.SetVisible(self.ImgNPCTTIcon, true)
        else
            UIHelper.SetVisible(self.ImgNPCTTIcon, false)
        end
    end

    local nRelation = 1 -- 友方
    if IsEnemy(self.m.dwTTID, g_pClientPlayer.dwID) then
        nRelation = 3 -- 敌方
    elseif IsNeutrality(self.m.dwTTID, g_pClientPlayer.dwID) then
        nRelation = 2 -- 中立
    end
    UIHelper.SetSpriteFrame(self.ImgTargetSmallBg, tTTagetImg[nRelation])
end

function UIWidgetPlayerInfo:UpdateTargetTargetLife()
    local nMaxLife = GetTargetMaxLife(self.m.dwTTType, self.m.dwTTID)
    local nCurrentLife = self.m.targettarget and self.m.targettarget.nCurrentLife or 0
    if self.m.dwTTType == TARGET.NPC then
        local nIntensity = self.m.targettarget and self.m.targettarget.nIntensity
        assert(nIntensity)
        if 2 == nIntensity or 6 == nIntensity then
            -- boss
            nCurrentLife = self.m.targettarget and self.m.targettarget.fCurrentLife64 or 0
        end
    end
    if self.m.nTTCurrentLife ~= nCurrentLife or self.m.nTTMaxLife ~= nMaxLife then
        self.m.nTTCurrentLife = nCurrentLife
        self.m.nTTMaxLife = nMaxLife
        local nCurVal = 100 * nCurrentLife / nMaxLife
        UIHelper.SetProgressBarPercent(self.SliderTargetBlood, nCurVal)
    end
end

function UIWidgetPlayerInfo:UpdateBuffAndVoicePosition(nMode, bShow)
    UIHelper.SetVisible(self.BtnBuff, nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and bShow)
    UIHelper.SetVisible(self.BtnBuff2, nMode == MAIN_CITY_CONTROL_MODE.SIMPLE and bShow)

    UIHelper.SetVisible(self.LayoutBuffAndVoice2, nMode == MAIN_CITY_CONTROL_MODE.SIMPLE)
    UIHelper.SetVisible(self.WidgetVoice2, nMode == MAIN_CITY_CONTROL_MODE.SIMPLE)
    self.TogVoice = self.toVoiceTogList[nMode]
    self.ImgVoice = self.tbVoiceImgList[nMode]
    Timer.AddFrame(self, 1, function ()
        if self.buffScript then
            UIHelper.RemoveFromParent(self.buffScript._rootNode)
            self.buffScript = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuffList, self.tbWidgetBuffList[nMode])
        end
    end)

end

function UIWidgetPlayerInfo:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end

function UIWidgetPlayerInfo:UpdatePrepareState(nMode, bStart)
    if not self.m.bTarget then
        UIHelper.SetVisible(self.BtnBuff, false)
        UIHelper.SetVisible(self.BtnBuff2, false)
        self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
        self.nMode = nMode
    end
end

function UIWidgetPlayerInfo:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIWidgetPlayerInfo:SelectTargetTarget()
	local hPlayer = GetClientPlayer()
	local hTarget = GetTargetHandle(hPlayer.GetTarget())
	if hTarget then
		local dwType, dwID = hTarget.GetTarget()
		if dwType == TARGET.PLAYER and dwID == hPlayer.dwID then
			SelectSelf()
		else
			SelectTarget(dwType, dwID)
		end
	end
end

function UIWidgetPlayerInfo:UpdateBuffBtnState()
    if self.m.bTarget then
        UIHelper.SetVisible(self.BtnBuff, true)
        UIHelper.SetVisible(self.BtnBuff2, true)
    else
        UIHelper.SetVisible(self.BtnBuff, false)
        UIHelper.SetVisible(self.BtnBuff2, false)
    end

end

-- -- TargetDistance Begin

function UIWidgetPlayerInfo:UpdateTargetDistance()
    if not self.m.player then return end
    if not g_pClientPlayer then return end

    local targetPos = {}
    targetPos.x, targetPos.y, targetPos.z = self.m.player.nX / 64 or 0, self.m.player.nY / 64 or 0, self.m.player.nZ / 512 or 0
    local selfPos = {}
    selfPos.x, selfPos.y, selfPos.z = g_pClientPlayer.nX / 64 or 0, g_pClientPlayer.nY / 64 or 0, g_pClientPlayer.nZ / 512 or 0

    local distance = math.sqrt((targetPos.x - selfPos.x)^2 + (targetPos.y - selfPos.y)^2 + ( targetPos.z - selfPos.z)^2)
    -- distance = math.floor(distance)
    distance = math.ceil(distance)

    local szDistance = distance .. "尺"

    if self.m.bHaveTTarget then
        UIHelper.SetActiveAndCache(self, self.ImgTargetDistance2, true)
        UIHelper.SetActiveAndCache(self, self.ImgTargetDistance, false)

        UIHelper.SetString(self.LabelTargetDistance2, szDistance)
    else
        UIHelper.SetActiveAndCache(self, self.ImgTargetDistance2, false)
        UIHelper.SetActiveAndCache(self, self.ImgTargetDistance, true)

        UIHelper.SetString(self.LabelTargetDistance, szDistance)
    end
end

function UIWidgetPlayerInfo:CloseTargetDistance()
    UIHelper.SetActiveAndCache(self, self.ImgTargetDistance2, false)
    UIHelper.SetActiveAndCache(self, self.ImgTargetDistance, false)
end

-- -- TargetDistance End

function UIWidgetPlayerInfo:UpdateInvincible()
    self.szLife = nil
    local player = self:GetPlayer()
    if not player then
        return
    end

    local bInvincible = Buff_Have(player, SPECIAL_BUFF_ID_LIST.GROUP_RIDE_PASSENGER, 1)
    UIHelper.SetVisible(self.SliderBloodInvincible, bInvincible)
    self.szLife = bInvincible and "乘客免疫" or nil
    self:UpdateLife(true)
end

function UIWidgetPlayerInfo:UpdateTargetTargetInvincible()
    if not self.m.bHaveTTarget then
        return
    end

    if self.m.dwTTType ~= TARGET.PLAYER then
        return
    end

    local hTarget = GetPlayer(self.m.dwTTID)
    if not hTarget then
        return
    end

    local bInvincible = Buff_Have(hTarget, SPECIAL_BUFF_ID_LIST.GROUP_RIDE_PASSENGER, 1)
    UIHelper.SetVisible(self.SliderTargetBloodInvincible, bInvincible)
end

return UIWidgetPlayerInfo