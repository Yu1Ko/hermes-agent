
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetTargetInfo
-- Date: 2022-11-14
-- Desc: 选中目标信息栏
-- Perfab: PREFAB_ID.WidgetTargetBoss, PREFAB_ID.WidgetTargetElite, PREFAB_ID.WidgetTargetNormal
-- ---------------------------------------------------------------------------------
local UIWidgetTargetInfo = class("UIWidgetTargetInfo")

local Def = {
	HideLevel = 10,
	StanceBg = {
		normal = "UIAtlas2_MainCity_MainCityLifebar_img_lifbar_little0",
		elite = "UIAtlas2_MainCity_MainCityLifebar_img_lifbar_middle0",
		boss = "UIAtlas2_MainCity_MainCityLifebar_img_lifebar_large0",
	}
}

function UIWidgetTargetInfo:OnEnter(nTargetType, nTargetId, szType, bCustom)
	self.m = {}
	self.m.nTargetType = nTargetType
	self.m.nTargetId = nTargetId
	self.m.szType = szType
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self.bEnableInvincible = DungeonData.IsInDungeon()
	if bCustom then
		self:UpdateCustomInfo()
	else
		self:Init()
		self:UpdateManaSetting()
		self:OnUpdate()

		Timer.DelTimer(self, self.nSkillProgressCallId)
		self.nSkillProgressCallId = Timer.AddFrameCycle(self, 1, function ()
			self:UpdateSkillProgress()
			self.buffScript:UpdateBuffCycle(self:GetTarget())
			self:UpdateTargetTarget()
			self:UpdateTargetSkillProgress()
			self:UpdateTargetDistance()
		end)
	end
end

function UIWidgetTargetInfo:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self:ClearCall()

	if self.nSkillProgressCallId then
		Timer.DelTimer(self, self.nSkillProgressCallId)
		self.nSkillProgressCallId = nil
	end

	self.m = nil
end

function UIWidgetTargetInfo:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnMenu, EventType.OnClick, function()
		--UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self._rootNode, dwTargetPlayerId)
	end)
	UIHelper.BindUIEvent(self.BtnBuff, EventType.OnClick, function()
		local nX = UIHelper.GetWorldPositionX(self.BtnBuff)
		local nY = UIHelper.GetWorldPositionY(self.BtnBuff)
		local tBuff = BuffMgr.GetVisibleBuff(self:GetTarget(), true)
		if #tBuff > 0 then
			local _, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip, nX, nY)
			script:UpdateNpcInfo(self.m.nTargetId, tBuff, true)
		end
	end)

	UIHelper.BindUIEvent(self.BtnTarget, EventType.OnClick, function ()
		local player = GetClientPlayer()
		if not player then return end
		--local hTeam = GetClientTeam()
		--local dwMark = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)
		--if dwMark ~= player.dwID then return end
		-- UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self._rootNode, self.m.nTargetId)
		local npc = GetNpc(self.m.nTargetId)
		local szName = UIHelper.GBKToUTF8(npc.szName)
		if string.is_nil(szName) then
			return
		end
		TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetNPCPop, self.BtnTarget, TipsLayoutDir.BOTTOM_CENTER, self.m.nTargetId)
        -- TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetTipTargetgetMark, self.BtnTarget, TipsLayoutDir.BOTTOM_CENTER, self.m.nTargetId)
   	end)

	UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.TARGET, self.nMode)
	end)

	UIHelper.BindUIEvent(self.BtnTargetBar, EventType.OnClick, function ()
		self:SelectTargetTarget()
   	end)

	UIHelper.BindUIEvent(self.BtnMark1, EventType.OnClick, function()
		TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnMark1, "共享击杀和掉落")
	end)
end

function UIWidgetTargetInfo:RegEvent()
	Event.Reg(self, "NPC_STATE_UPDATE", function ()
		local nTargetId = arg0
		if nTargetId == self.m.nTargetId then
			self:OnUpdate()
		end
	end)
	Event.Reg(self, "UPDATE_SELECT_TARGET", function ()
		self:OnUpdate()
	end)
	Event.Reg(self, "PLAYER_LEVEL_UP", function ()
		-- 玩家等级变化会相对影响target血量显示
		self:OnUpdate()
	end)
	Event.Reg(self, "NPC_LEAVE_SCENE", function ()
		local nNpcId = arg0
		self:OnTargetLeaveScene(TARGET.NPC, nNpcId)
	end)
	Event.Reg(self, "DOODAD_LEAVE_SCENE", function ()
		local nDoodadId = arg0
		self:OnTargetLeaveScene(TARGET.DOODAD, nDoodadId)
	end)
	Event.Reg(self, "OT_ACTION_PROGRESS_BREAK", function ()
		local nTargetId = arg0
		if nTargetId == self.m.nTargetId then
			self:ActionBreak()
		end
	end)
	Event.Reg(self, EventType.OnTargetSettingChange, function()
		self:UpdateLife(true)
	end)

    if self.m.nTargetType == TARGET.NPC and PartnerData.IsPartnerNpc(self.m.nTargetId) then
        local tKNpc       = NpcData.GetNpc(self.m.nTargetId)
        if tKNpc then
            local dwPlayerId = tKNpc.dwEmployer

            local tUIInfo = Table_GetPartnerByTemplateID(tKNpc.dwTemplateID)
            local dwPartnerID   = tUIInfo.dwNpcID

            Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwID)
                if not Partner_IsSelfPlayer(dwPlayerId) and dwPlayerId == dwID then
                    -- 查看他人侠客时dwID为对应玩家ID
                    if nRetCode == NPC_ASSISTED_RESULT_CODE.OTHER_PLAYER_NPC_ASSISTED_SIMPLE_LIST_SYNC_OVER then
                        -- 更新其他玩家的某个侠客详细信息结束
                        self:UpdateLevel()
                    end
                end
            end)
        end
    end

	Event.Reg(self, EventType.OnTargetBossManaBarChange, function()
		self:UpdateManaSetting()
		self:UpdateMana(true)
	end)
	Event.Reg(self, "BUFF_UPDATE", function()
		if arg4 == SPECIAL_BUFF_ID_LIST.GROUP_RIDE_DRIVER or arg4 == SPECIAL_BUFF_ID_LIST.GROUP_RIDE_PASSENGER then
			self:UpdateInvincible()
			self:UpdateTargetTargetInvincible()
		end
	end)
end

function UIWidgetTargetInfo:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end

function UIWidgetTargetInfo:OnUpdate()
	local target = self:GetTarget()
	if not target then return end
	self.m.target = target


	self:UpdateName()
	self:UpdateLevel()
	self:UpdateLife()
	self:UpdateHead()
	self:UpdateMana()
	self:UpdateRelation()
	self:UpdateOtherExp()
    self:UpdateInvincible()
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTargetInfo:Init()
	self.buffScript = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuffList, self.WidgetMainCityBuffList)
	if MonsterBookData.bIsPlaying and self.WidgetPlayerOtherInfo then
		self.WidgetBaizhanHint = self.WidgetBaizhanHint or UIHelper.AddPrefab(PREFAB_ID.WidgetMiddleBaiZhanHint, self.WidgetPlayerOtherInfo, self.m.nTargetType, self.m.nTargetId, true)
	end
end

function UIWidgetTargetInfo:UpdateName()
	local szName = self.m.target and self.m.target.szName or ""
	local player = g_pClientPlayer

	if self.m.szName ~= szName then
		self.m.szName = szName
		local node = self.LabelTargetName assert(node)

		if self.m.szType == "boss" then
			UIHelper.SetString(node, UIHelper.GBKToUTF8(szName), 5)
		else
			UIHelper.SetString(node, UIHelper.GBKToUTF8(szName), 4)
		end


		if szName == nil or szName == '' then
			local tar = GetTargetHandle(self.m.nTargetType, self.m.nTargetId)
			node:setString(UIHelper.GBKToUTF8(tar.szName))
		end

		if IsEnemy(self.m.nTargetId, player.dwID) then -- 我是目标的敌人
			UIHelper.SetColor(self.LabelTargetName, cc.c3b(254, 87, 42))
		elseif IsNeutrality(self.m.nTargetId, player.dwID) then	--中立
			UIHelper.SetColor(self.LabelTargetName, cc.c3b(255, 226, 110))
		end
	end
	UIHelper.LayoutDoLayout(self.Layout)
end

function UIWidgetTargetInfo:UpdateRelation()
	local player = g_pClientPlayer
	local nRelation = 3 -- 友方
	if IsEnemy(self.m.nTargetId, player.dwID) then -- 我是目标的敌人
		nRelation = 1 -- 敌方
	elseif IsNeutrality(self.m.nTargetId, player.dwID) then
		nRelation = 2 -- 中立
	end

	if self.m.nRelation ~= nRelation then
		self.m.nRelation = nRelation
		UIHelper.SetSpriteFrame(self.ImgTargetBg, Def.StanceBg[self.m.szType] .. nRelation .. ".png")
	end
end

function UIWidgetTargetInfo:UpdateOtherExp()
	if self.m.nTargetType == TARGET.NPC then
		local player = g_pClientPlayer
		local npc = GetNpc(self.m.nTargetId)
		local bNotMine = npc.dwDropTargetPlayerID ~= 0 and npc.dwDropTargetPlayerID ~= player.dwID and not player.IsPlayerInMyParty(npc.dwDropTargetPlayerID)
		local bShare = npc.bCanShareLootListByQuestEvent
		local bShow = (not bShare) and (bNotMine)
		UIHelper.SetVisible(self.BtnMark2, bShow)
		UIHelper.SetVisible(self.BtnMark1, bShare)
	else
		UIHelper.SetVisible(self.BtnMark2, false)
		UIHelper.SetVisible(self.BtnMark1, false)
	end
end

function UIWidgetTargetInfo:UpdateLevel()
	local nLevel = self.m.target and self.m.target.nLevel or 0
	if nLevel == 0 then
		local tar = GetTargetHandle(self.m.nTargetType, self.m.nTargetId)
		nLevel = tar.nLevel
	end
	local player = GetClientPlayer()
	if not player then return end

	local bHide = nLevel - player.nLevel >= Def.HideLevel
	self.m.bHideLevel = bHide

    -- 侠客NPC使用其心法等级
    if self.m.nTargetType == TARGET.NPC and PartnerData.IsPartnerNpc(self.m.nTargetId) then
        nLevel = PartnerData.GetPartnerNpcKungfuLevel(self.m.nTargetId)
        UIHelper.SetTextColor(self.LabelTargetLevel, cc.c3b(255, 207, 101))
    end

	UIHelper.SetVisible(self.LabelTargetLevel, not bHide)
	UIHelper.SetVisible(self.ImgQuestion, bHide)
	if not bHide then
		if self.m.nLevel ~= nLevel and nLevel ~= 0 then
			self.m.nLevel = nLevel

			local node = self.LabelTargetLevel assert(node)

			node:setString(tostring(nLevel))
		elseif nLevel == 0 then
			self.m.nLevel = nLevel
			UIHelper.SetVisible(self.LabelTargetLevel, false)
		end
	end

end

function UIWidgetTargetInfo:UpdateLife(bForceUpdate)
	local nCurrentLife = self.m.target and self.m.target.nCurrentLife or 0
	local nMaxLife = self.m.target and self.m.target.nMaxLife or 1
	local nDamageAbsorbValue = self.m.target and self.m.target.nDamageAbsorbValue or 0
	if self.m.szType == "boss" then
		nCurrentLife = self.m.target and self.m.target.fCurrentLife64 or 0 -- nCurrentLife
		nMaxLife = self.m.target and self.m.target.fMaxLife64 or 0 --GetTargetMaxLife(TARGET.NPC, self.m.nTargetId)
	end

	if self.m.nCurrentLife ~= nCurrentLife or self.m.nMaxLife ~= nMaxLife or bForceUpdate
		or self.m.nDamageAbsorbValue ~= nDamageAbsorbValue then
		self.m.nCurrentLife = nCurrentLife
		self.m.nMaxLife = nMaxLife
		self.m.nDamageAbsorbValue = nDamageAbsorbValue

		local sz = UIHelper.GetStateString(nCurrentLife, nMaxLife)
		if self.m.bHideLevel then
			sz = "????/????"
		end
		local node = self.LabelBlood assert(node)
		node:setString(self.szLife or sz)

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

		-- 血条
		if self.m.szType == "boss" then
			self:UpdateBossLifeBar(nCurrentLife, nMaxLife)
		else
			local nCurVal = 100 * nCurrentLife / nMaxLife
			UIHelper.SetProgressBarPercent(self.SliderBloodBar, nCurVal)
			if self.m.szType == "elite" then
				UIHelper.SetPositionX(self.SFXBloodLight, 2.61 * nCurVal - 140)
			elseif self.m.szType == "normal" then
				UIHelper.SetPositionX(self.SFXBloodLight, 2 * nCurVal - 110)
			end
			-- 拖影
			self:UpdateLifeShadow(nCurVal)
		end
	end
end

function UIWidgetTargetInfo:UpdateMana(bForceUpdate)
	local nCurrentMana = self.m.target and self.m.target.nCurrentMana or 0
	local nMaxMana = self.m.target and self.m.target.nMaxMana or 1
	if self.m.nCurrentMana ~= nCurrentMana or self.m.nMaxMana ~= nMaxMana or bForceUpdate then
		self.m.nCurrentMana = nCurrentMana
		self.m.nMaxMana = nMaxMana


		-- 蓝条
		local bar = self.SliderManaBar assert(bar)
		local nPercent = 100 * nCurrentMana / nMaxMana
		UIHelper.SetProgressBarPercent(bar, nPercent)

		if self.m.bShowBossManaPercent then
			local szPercent = tonumber(string.format("%.1f", nPercent)) .. "%"
			UIHelper.SetString(self.LabelMana, szPercent)
		end
	end
end

function UIWidgetTargetInfo:UpdateManaSetting()
	if self.m.szType == "boss" then
		self.m.bShowBossManaPercent = GameSettingData.GetNewValue(UISettingKey.TargetBossManaBarDisplay)
		UIHelper.SetVisible(self.LabelMana, self.m.bShowBossManaPercent)
	else
		self.m.bShowBossManaPercent = false
	end
end

function UIWidgetTargetInfo:ClearCall()
	if self.m.nCallId then
		Timer.DelTimer(self, self.m.nCallId)
		self.m.nCallId = nil
	end
end

function UIWidgetTargetInfo:UpdateLifeShadow(nEndVal)
	local bar = self.SliderBloodShadow

	local nCurVal = self.m.bLifeShadowInited and UIHelper.GetProgressBarPercent(bar) or 0
	self.m.bLifeShadowInited = true
	if nCurVal < nEndVal then
		UIHelper.SetProgressBarPercent(bar, nEndVal)
		self:ClearCall()
		return
	end
	self:ClearCall()
	self.m.nCallId = Timer.AddFrameCycle(self, 1, function ()
		if not self.m then return end
		local nCurVal = UIHelper.GetProgressBarPercent(bar)
		local nDelta = nEndVal - nCurVal
		if math.abs(nDelta) < 0.1 then
			UIHelper.SetProgressBarPercent(bar, nEndVal)
			self:ClearCall()
			return
		end
		local nDeltaTime = Timer.FixedDeltaTime()*9
		nCurVal = nCurVal + nDelta * nDeltaTime
		UIHelper.SetProgressBarPercent(bar, nCurVal)
	end)
end

function UIWidgetTargetInfo:UpdateBossLifeBar(nCurrentLife, nMaxLife)
	local bar, bar1 = self.SliderBloodBar, self.SliderBloodBar1
	local nCurVal = 0

	-- 分三段
	local nLife = 0
	local nStep = 0
	local nSection = math.floor(nMaxLife / 3)
	---- 从第一段开始绘制
	if nCurrentLife > nSection * 2 then
		-- 绘制第一段
		nLife = math.min(nCurrentLife - nSection * 2, nSection)
		nCurVal = 100 * nLife / nSection
		UIHelper.SetProgressBarTexture(bar, "UIAtlas2_MainCity_MainCityLifebar_img_state_red03.png", 1)
		UIHelper.SetProgressBarPercent(bar, nCurVal)
		UIHelper.SetPositionX(self.SFXBloodLight, 3.2 * nCurVal - 170)
		-- 绘制第二段
		UIHelper.SetProgressBarTexture(bar1, "UIAtlas2_MainCity_MainCityLifebar_img_state_red02.png", 1)
		UIHelper.SetProgressBarPercent(bar1, 100)
		UIHelper.SetVisible(bar1, true)
	else
		-- 从第二段开始绘制
		if nCurrentLife > nSection then
			nLife = nCurrentLife - nSection
			nCurVal = 100 * nLife / nSection
			UIHelper.SetProgressBarTexture(bar, "UIAtlas2_MainCity_MainCityLifebar_img_state_red02.png", 1)
			UIHelper.SetProgressBarPercent(bar, nCurVal)
			UIHelper.SetPositionX(self.SFXBloodLight, 3.2 * nCurVal - 170)
			-- 绘制第三段
			UIHelper.SetProgressBarTexture(bar1, "UIAtlas2_MainCity_MainCityLifebar_img_state_red01.png", 1)
			UIHelper.SetProgressBarPercent(bar1, 100)
			UIHelper.SetVisible(bar1, true)
		-- 只绘制第三段
		else
			nLife = nCurrentLife
			nCurVal = 100 * nLife / nSection
			UIHelper.SetProgressBarTexture(bar, "UIAtlas2_MainCity_MainCityLifebar_img_state_red01.png", 1)
			UIHelper.SetProgressBarPercent(bar, nCurVal)
			UIHelper.SetPositionX(self.SFXBloodLight, 3.2 * nCurVal - 170)
			UIHelper.SetVisible(bar1, false)
		end
	end

	-- 拖影
	self:UpdateLifeShadow(nCurVal)
end

function UIWidgetTargetInfo:UpdateHead()
	local node = self.ImgTargetBoss
	if not node then return end

	if self.m.szHeadFrameName then return end

	if self.m.nTargetType == TARGET.NPC then
		local szFrameName = NpcData.GetNpcHeadImage(self.m.nTargetId)
		self.m.szHeadFrameName = szFrameName
		UIHelper.SetSpriteFrame(node, szFrameName, true)
		node:setVisible(true)
	end
end

function UIWidgetTargetInfo:GetTarget()
	if self.m.nTargetType == TARGET.NPC then
		return GetNpc(self.m.nTargetId)
	elseif self.m.nTargetType == TARGET.DOODAD then
		return GetDoodad(self.m.nTargetId)
	end
end

function UIWidgetTargetInfo:OnTargetLeaveScene(nType, nId)
	if self.m.nTargetType == nType and self.m.nTargetId == nId then
		Event.Dispatch(EventType.OnTargetChanged, TARGET.NO_TARGET, 0)
	end
end

--进度条
local ACTION_STATE =
{
	NONE = 1,
	PREPARE = 2,
	DONE = 3,
	BREAK = 4,
	FADE = 5,
}

local SKILL_OTACTION_SHOW_TYPE =
{
	ShowIfCanBreak = 0,
	Show = 1,
	Hide = 2,
}

function UIWidgetTargetInfo:UpdateSkillProgress()
	--local tar = GetTargetHandle(self.m.nTargetType, self.m.nTargetId)
	--if not tar then
	--	return
	--end

	local bPrePare, dwID, dwLevel, fP, nType = GetSkillOTActionState(self.m.target)
	local tSkill = dwID > 0 and GetSkill(dwID, dwLevel)
	local bar
	local node = self.LabelProgressName
	if not tSkill then
		UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
		UIHelper.SetActiveAndCache(self, self.WidgetBaiZhanProgress, false)
		return
	end

	-- if tSkill.nPrepareFrames == 0 and tSkill.nChannelFrame == 0 then
	-- 	UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
	-- 	UIHelper.SetActiveAndCache(self, self.WidgetBaiZhanProgress, false)
	-- 	return
	-- end

	-- local nShow = Table_GetSkillOTActionShowType(dwID, dwLevel) --表中新增默认规则显示项
	-- if (nShow == SKILL_OTACTION_SHOW_TYPE.ShowIfCanBreak  or nShow == SKILL_OTACTION_SHOW_TYPE.Show)
	-- 			 and tSkill.nBrokenRate > 0 then
	if tSkill.nBrokenRate > 0 then
		bar = self.SliderSkillProgress1
		UIHelper.SetActiveAndCache(self, self.SliderSkillProgress2, false)
	elseif tSkill.nBrokenRate == 0 then
	-- elseif nShow == SKILL_OTACTION_SHOW_TYPE.Show
	-- 			and tSkill.nBrokenRate == 0 then
		bar = self.SliderSkillProgress2
		UIHelper.SetActiveAndCache(self, self.SliderSkillProgress1, false)
	else
		UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
		UIHelper.SetActiveAndCache(self, self.WidgetBaiZhanProgress, false)
		return
	end

	if self.skillState ~= ACTION_STATE.PREPARE and fP*100 > 0 and fP*100 < 100 then
		self.skillState = ACTION_STATE.PREPARE
	elseif self.skillState == ACTION_STATE.PREPARE and fP >= 1 then
		self.skillState = ACTION_STATE.NONE
	end

	if self.skillState == ACTION_STATE.PREPARE then
		UIHelper.SetProgressBarPercent(bar, 100*fP)
		UIHelper.SetProgressBarPercent(self.SliderSkillProgressBaiZhan, 100*fP)
		UIHelper.SetActiveAndCache(self, bar, true)

		local szSkillName = UIHelper.GBKToUTF8(Table_GetSkillName(dwID, dwLevel))
		node:setString(szSkillName)
		UIHelper.SetString(self.LabelProgressNameBaiZhan, szSkillName)
		UIHelper.SetActiveAndCache(self, node, true)

		local tSkillInfo = Table_GetSkill(dwID, dwLevel) or { nInterruptIcon = -1}
		UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, tSkillInfo.nInterruptIcon ~= 10)
		UIHelper.SetActiveAndCache(self, self.WidgetBaiZhanProgress, tSkillInfo.nInterruptIcon == 10)
	else
		UIHelper.SetActiveAndCache(self, self.WidgetSkillProgress, false)
		UIHelper.SetActiveAndCache(self, self.WidgetBaiZhanProgress, false)
	end
end

function UIWidgetTargetInfo:ActionBreak()
	self.skillState = ACTION_STATE.BREAK
end

-- TargetTarget

function UIWidgetTargetInfo:UpdateTargetTarget()
	local hTargetTarget = nil
	local hTarget = nil
	hTarget = GetTargetHandle(self.m.nTargetType, self.m.nTargetId)
	if hTarget then
		hTargetTarget = GetTargetHandle(hTarget.GetTarget())
	else
		return self:CloseTargetTarget()
	end

	if hTargetTarget then
		local dwTTType, dwTTID = hTarget.GetTarget()
		UIHelper.SetActiveAndCache(self, self.WidgetTargetBar, true)
		if self.m.dwTTType ~= dwTTType or self.m.dwTTID ~= dwTTID then
			self.m.dwTTType = dwTTType
			self.m.dwTTID = dwTTID
			self.m.bHaveTTarget = true
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

function UIWidgetTargetInfo:CloseTargetTarget()
	self.m.dwTTType = nil
	self.m.dwTTID = nil
	self.m.bHaveTTarget = false
	UIHelper.SetActiveAndCache(self, self.WidgetTargetBar, false)
	return
end

function UIWidgetTargetInfo:UpdateTargetTargetState()
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

		UIHelper.SetVisible(self.ImgTTNPCIcon, false)
		UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, hTarget.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, hTarget.nRoleType, hTarget.dwForceID, false)
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

		UIHelper.ClearAvatarState(self.ImgPlayerIcon, self.AnimatePlayerIcon, self.SFXPlayerIcon)
		local szImage = NpcData.GetNpcHeadImage(self.m.dwTTID)
		if szImage and szImage ~= "" then
            UIHelper.SetSpriteFrame(self.ImgTTNPCIcon, szImage)
            UIHelper.SetVisible(self.ImgTTNPCIcon, true)
		else
			UIHelper.SetVisible(self.ImgTTNPCIcon, false)
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

function UIWidgetTargetInfo:UpdateTargetTargetLife()
	local nMaxLife = GetTargetMaxLife(self.m.dwTTType, self.m.dwTTID)
	local nCurrentLife = self.m.targettarget and self.m.targettarget.nCurrentLife or 0

	if self.m.dwTTType == TARGET.NPC then
        local nIntensity = self.m.targettarget and self.m.targettarget.nIntensity
        assert(nIntensity)
        if 2 == nIntensity or 6 == nIntensity then
            -- boss
            nCurrentLife = self.m.targettarget and self.m.targettarget.fCurrentLife64 or 0
			nMaxLife = self.m.targettarget and self.m.targettarget.fMaxLife64 or 0
        end
    end

	if self.m.nTTCurrentLife ~= nCurrentLife or self.m.nTTMaxLife ~= nMaxLife then
		self.m.nTTCurrentLife = nCurrentLife
		self.m.nTTMaxLife = nMaxLife
		local nCurVal = 100 * nCurrentLife / nMaxLife
		UIHelper.SetProgressBarPercent(self.SliderBlood, nCurVal)
	end
end

function UIWidgetTargetInfo:UpdateTargetSkillProgress()
    if not self.m.bHaveTTarget then
        return
    end
    
    local tar = GetTargetHandle(self.m.dwTTType, self.m.dwTTID)
    if not tar then
        return
    end

    local bPrePare, dwID, dwLevel, fP, nType = GetSkillOTActionState(tar)
    local tSkill = (IsNumber(dwID) and dwID > 0) and GetSkill(dwID, dwLevel)
    local bar
    if not tSkill then
        UIHelper.SetActiveAndCache(self, self.WidgetTargetSkillProgress, false)
        return
    end

    if tSkill.nPrepareFrames == 0 and tSkill.nChannelFrame == 0 then
        UIHelper.SetActiveAndCache(self, self.WidgetTargetSkillProgress, false)
        return
    end

    local nShow = Table_GetSkillOTActionShowType(dwID, dwLevel) --表中新增默认规则显示项
    if (nShow == SKILL_OTACTION_SHOW_TYPE.ShowIfCanBreak or nShow == SKILL_OTACTION_SHOW_TYPE.Show)
            and tSkill.nBrokenRate > 0 then
        bar = self.SliderTargetSkillProgress1
        UIHelper.SetActiveAndCache(self, self.SliderTargetSkillProgress2, false)
    elseif nShow == SKILL_OTACTION_SHOW_TYPE.Show
            and tSkill.nBrokenRate == 0 then
        bar = self.SliderTargetSkillProgress2
        UIHelper.SetActiveAndCache(self, self.SliderTargetSkillProgress1, false)
    else
        UIHelper.SetActiveAndCache(self, self.WidgetTargetSkillProgress, false)
        return
    end

    if self.targetSkillState ~= ACTION_STATE.PREPARE and fP * 100 > 0 and fP * 100 < 100 then
        self.targetSkillState = ACTION_STATE.PREPARE
    elseif self.targetSkillState == ACTION_STATE.PREPARE and fP >= 1 then
        self.targetSkillState = ACTION_STATE.NONE
    end

    if self.targetSkillState == ACTION_STATE.PREPARE then
        UIHelper.SetProgressBarPercent(bar, 100 * fP)
        UIHelper.SetActiveAndCache(self, bar, true)
        UIHelper.SetActiveAndCache(self, node, true)
        UIHelper.SetActiveAndCache(self, self.WidgetTargetSkillProgress, true)
    else
        UIHelper.SetActiveAndCache(self, self.WidgetTargetSkillProgress, false)
    end
end

function UIWidgetTargetInfo:UpdateCustomInfo()
	UIHelper.SetVisible(self.ImgQuestion, false)
	UIHelper.SetSpriteFrame(self.ImgTargetBoss, "UIAtlas2_Public_PublicSchool_PublicSchool_TargetFrame47 (5)")
end

function UIWidgetTargetInfo:UpdatePrepareState(nMode, bStart)
	self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
	self.nMode = nMode
end

function UIWidgetTargetInfo:UpdateCustomState()
	self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end

function UIWidgetTargetInfo:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
	self.nState = nState
end

function UIWidgetTargetInfo:SelectTargetTarget()
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

-- -- TargetDistance Begin

function UIWidgetTargetInfo:UpdateTargetDistance()
    local targetPos = {}
    targetPos.x, targetPos.y, targetPos.z = self.m.target.nX / 64 or 0, self.m.target.nY / 64 or 0, self.m.target.nZ / 512 or 0
    local selfPos = {}
    selfPos.x, selfPos.y, selfPos.z = g_pClientPlayer.nX / 64 or 0, g_pClientPlayer.nY / 64 or 0, g_pClientPlayer.nZ / 512 or 0

    local distance = math.sqrt((targetPos.x - selfPos.x)^2 + (targetPos.y - selfPos.y)^2 + ( targetPos.z - selfPos.z)^2)
    -- distance = math.floor(distance)
	distance = math.ceil(distance)

    local szDistance = distance .. "尺"

	UIHelper.SetActiveAndCache(self, self.ImgTargetDistance, true)
	UIHelper.SetString(self.LabelTargetDistance, szDistance)
end

-- -- TargetDistance End

function UIWidgetTargetInfo:UpdateInvincible()
	local bInvincible = false
	self.szLife = nil
	if self.m and self.m.target then
		if self.m.nTargetType == TARGET.NPC then
			bInvincible = self.bEnableInvincible and self.m.target.bInvincible
		elseif self.m.nTargetType == TARGET.PLAYER then
			bInvincible = Buff_Have(self.m.target, SPECIAL_BUFF_ID_LIST.GROUP_RIDE_PASSENGER, 1)
			self.szLife = bInvincible and "乘客免疫" or nil
			self:UpdateLife(true)
		end
	end
	UIHelper.SetVisible(self.SliderBloodInvincible, bInvincible)
end

function UIWidgetTargetInfo:UpdateTargetTargetInvincible()
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

return UIWidgetTargetInfo