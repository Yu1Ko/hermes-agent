--module("SpecialSettings", ExportExternalLib)

g_tUIConfig=
{
	["FightProgress"]= {s = "TOPRIGHT", r = "TOPRIGHT", x = -30, y = 400},

	SkillQiChang =
	{
		-- [357] = {storage = "QiChang_357", default = true, ids = {357}, szName = "化三清"},
		[358] = {storage = "QiChang_358", default = true, ids = {358}, szName = "生太极"},
		[371] = {storage = "QiChang_371", default = true, ids = {371,6911}, szName = "镇山河"},
		[363] = {storage = "QiChang_363", default = true, ids = {363}, szName = "吞日月"},
		[362] = {storage = "QiChang_362", default = true, ids = {362}, szName = "碎星辰"},
		--[361] = {storage = "QiChang_361", default = true, ids = {361}},
		[359] = {storage = "QiChang_359", default = true, ids = {359}, szName = "破苍穹"},
		-- [360] = {storage = "QiChang_360", default = true, ids = {360}},
		[15193] = {storage = "QiChang_15193", default = true, ids = {15193}, szName = "剑出鸿蒙"},
		[15187] = {storage = "QiChang_15187", default = true, ids = {15187}, szName = "行天道"},
	},
	SkillShadow = 14082,
	SkillQianJiBian = 3109,

	ShieldAddon =
	{
		["MailPlus"] = true,
		["HM_0Base"] = true,
		["HM_AchieveWiki"] = true,
		["HM_Area"] = true,
		["HM_Battle"] = true,
		["HM_Camp"] = true,
		["HM_Doodad"] = true,
		["HM_Ent"] = true,
		["HM_Force"] = true,
		["HM_Jabber"] = true,
		["HM_Locker"] = true,
		["HM_Love"] = true,
		["HM_RedName"] = true,
		["HM_Resource"] = true,
		["HM_Roll"] = true,
		["HM_Secret"] = true,
		["HM_Suit"] = true,
		["HM_Taoguan"] = true,
		["HM_Target"] = true,
		["HM_TargetFace"] = true,
		["HM_TargetList"] = true,
		["HM_TargetMon"] = true,
		["HM_Team"] = true,
		["HM_ToolBox"] = true,
		["LR_0UI"] = true,
		["LR_1Base"] = true,
		["LR_AccountStatistics"] = true,
		["LR_CopyBook"] = true,
		["LR_TLHelper"] = true,
		["LR_RaidGridEx"] = true,
		["LR_Accelerate"] = true,
		["LR_OTBar"] = true,
		["LR_HeadName"] = true,
		["LR_OTBar_Skin"] = true,
		["LR_EquipSearch"] = true,
		["LR_PickupDead"] = true,
		["LR_ShopHelper"] = true,
		["LR_GKP"] = true,
		["LR_NianShou"] = true,
		["LR_TeamHelper"] = true,
		["LR_AS_Module_Achievement"] = true,
		["LR_AS_Module_BookRd"] = true,
		["LR_AS_Module_CashFlowRecord"] = true,
		["LR_AS_Module_EquipmentRecord"] = true,
		["LR_AS_Module_FBList"] = true,
		["LR_AS_Module_ItemRecord"] = true,
		["LR_AS_Module_PlayerInfo"] = true,
		["LR_AS_Module_QY"] = true,
		["LR_AS_Module_RC"] = true,
		["LR_AS_Module_Homeland"] = true,
		["LR_BiddingHelper"] = true,
	},

	CGStateBuff = --长歌头像状态标记
	{
		[9319] = 1,
		[9320] = 2,
		[9321] = 3,
		[9322] = 4,
	},

	tLowPriorityQuest = --茶馆和门派勤修不辍，要完成n个其他任务 才能完成的任务
	{
		[8206]  = true,
		[8347]  = true,
		[8348]  = true,
		[8349]  = true,
		[8350]  = true,
		[8351]  = true,
		[8352]  = true,
		[8353]  = true,
		[8398]  = true,
		[8399]  = true,
		[8400]  = true,
		[8401]  = true,
		[8402]  = true,
		[8403]  = true,
		[8404]  = true,
		[9796]  = true,
		[9797]  = true,
		[11245]  = true,
		[11246]  = true,
		[12701]  = true,
		[12702]  = true,
		[12731]  = true,
		[12732]  = true,
		[14246] = true,
	},

	bShieldArena = false,
}

SpecialSettings = {}
local bAutoCGSkillInOTABar = true
local bStopAutoMJSkill = false
local bAutoJianWu = false

--纯阳对自身释放气场
function SpecialSettings.ApplyQiChangeToMe(QiChangConfig, bIsToMe)
	if bIsToMe == false then
		for id, info in pairs(QiChangConfig) do
			SetSkillCastToMe(info.ids, bIsToMe)
		end
	else
		for id, info in pairs(QiChangConfig) do
			SetSkillCastToMe(info.ids, GameSettingData.GetNewValue(info.storage))
		end
	end
end

--七秀自动舞剑
function IsAutoJianWu()
	return bAutoJianWu
end

function SpecialSettings.SetAutoJianWu(bAuto)
	bAutoJianWu = bAuto
end
local bInitiativeStopJianwu = false

function SpecialSettings.ChangeJianwuStatus(nSkillID)
	if nSkillID == 8670 then
		bInitiativeStopJianwu = true
	elseif nSkillID == 537 then
		bInitiativeStopJianwu = false
	end
end

-- check auto Jianwu
-- (bool) CheckAutoJianWu()
-- return  true: check successfully
-- return false: check failed (you may need to check again on the next frame)
function SpecialSettings.CheckAutoJianWu()
	local player = GetClientPlayer()
	if not player then
		return false
	end

	if not IsAutoJianWu() then
		return true
	end

	-- if player's state is not stand then return
	if player.nMoveState ~= MOVE_STATE.ON_STAND then
		return false
	end

	if player.bOnHorse then
		return false
	end


	if player.GetBuff(961,1) then
		return false
	end

	local nLevel = player.GetSkillLevel(537)
	if nLevel == 0 then
		return true
	end


	local KungfuMount = player.GetActualKungfuMount()
	if not KungfuMount then
		return false
	end


	if KungfuMount.dwSkillID ~= 10081 and KungfuMount.dwSkillID ~= 10080 then
		return true
	end

	if player.GetBuff(409,0) then
		return true
	end

	local skill = GetSkill(537, nLevel)
	-- if jianwu skill cannot cast then return
	if skill.UITestCast(player.dwID, IsSkillCastMyself(skill)) ~= SKILL_RESULT_CODE.SUCCESS then
		return false
	end

	-- player stoped Jianwu initiatively
	if bInitiativeStopJianwu then
		return true
	end

	CastSkill(537, nLevel)

	return true
end

local nCheckTime = nil
function SpecialSettings.AutoJianWu()
	if not nCheckTime then
		nCheckTime = GetCurrentTime()
		SpecialSettings.CheckAutoJianWu()
		return
	end
	local nCurrentTime = GetCurrentTime()
	if nCurrentTime - nCheckTime > 1 then
		if SpecialSettings.CheckAutoJianWu() then -- if check successfully then delay next check for 2 seconds
			nCheckTime = nCurrentTime
		end
	end
end

--明教手动施展轮
local bInMutiStageSkillState = false
local nMultiStageSkillCount = 0
local nNextSkillID = nil
local nDelayCallGCDTime = 0
local function GetGCDTime(dwSkill)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local dwLevel = hPlayer.GetSkillLevel(dwSkill)
    local skill = GetSkill(dwSkill, dwLevel)

    if not skill then
        return
    end
    local dwPublicID = skill.GetPublicCoolDown()
    if dwPublicID <= 0 then
        return
	end
	m_nTotalFrame = hPlayer.GetCDInterval(dwPublicID)
	local nTotalTime =  m_nTotalFrame / GLOBAL.GAME_FPS * 1000

    return nTotalTime
end
-- 赤日轮 幽月轮
function CheckStopAutoMJSkill()
	return bStopAutoMJSkill
end
function SpecialSettings.SetStopAutoMJSkill(bCheck)
	bStopAutoMJSkill = bCheck
end
--冥月渡心 暗步追踪
function CheckStopAutoMJSkill2()
	return bStopAutoMJSkill2
end
function SetStopAutoMJSkill2(bCheck)
    bStopAutoMJSkill2 = bCheck
end

function SetMultiStageSkillState(bIn)
	bInMutiStageSkillState = bIn
	if not bIn then
		nMultiStageSkillCount = 0
	end
end

function SetNowMultiStageSkillID(nSkillID, nCount)
	nNextSkillID = nSkillID
	nMultiStageSkillCount = nCount
end

function SpecialSettings.ChangeMultiStageSkill(nSkillID)
	if not bStopAutoMJSkill and Kungfu_GetPlayerMountType() == FORCE_TYPE.MING_JIAO then
		local tMultiStageSkillID = Table_GetMultiStageSkill(nSkillID)
		if not tMultiStageSkillID then
			SetMultiStageSkillState(false)
		elseif tMultiStageSkillID and nNextSkillID and nSkillID ~= nNextSkillID then
			SetNowMultiStageSkillID(tMultiStageSkillID.dwNowSkillID, tMultiStageSkillID.nCount)
		else
			SetMultiStageSkillState(true)
		end
	end
end

local m_nMingyueduxin = {
    FIRST_SKILL_ID    = 18629,
    NEXT_SKILL_ID     = 18630,
    BUFF_ID           = 12491,
    CD                = 2000,
    nNextUseTime      = nil,
}
function SpecialSettings.AutoMJSkillCast(nSkillID)
	if bInMutiStageSkillState and not CheckStopAutoMJSkill() then
		local tMultiStageSkillID = Table_GetMultiStageSkill(nSkillID)
		if tMultiStageSkillID and tMultiStageSkillID.dwNowSkillID ~= nNextSkillID then
			nMultiStageSkillCount = 0
			nNextSkillID = nil
		end
		if tMultiStageSkillID then
			if nMultiStageSkillCount > 0 then
				nMultiStageSkillCount = nMultiStageSkillCount - 1
					if nMultiStageSkillCount == 0 then
						bInMutiStageSkillState = false
						nNextSkillID = nil
					end
			else
				nMultiStageSkillCount = tMultiStageSkillID.nCount - 1
			end
		end
		if nMultiStageSkillCount > 0 and tMultiStageSkillID and tMultiStageSkillID.dwNowSkillID then
			local dwGCDTime = GetGCDTime(tMultiStageSkillID.dwNowSkillID)
			if dwGCDTime > 0 then
				nDelayCallGCDTime = dwGCDTime + GetTickCount()
				nNextSkillID = tMultiStageSkillID.dwNowSkillID
			else
				local mask = (tMultiStageSkillID.dwNowSkillID * (tMultiStageSkillID.dwNowSkillID % 10 + 1))
				local res = OnUseSkill(tMultiStageSkillID.dwNowSkillID, mask)
			end
		end
	end

    -- if not CheckStopAutoMJSkill2() and (nSkillID == m_nMingyueduxin.FIRST_SKILL_ID or nSkillID == m_nMingyueduxin.NEXT_SKILL_ID) then
    --     m_nMingyueduxin.nNextUseTime = GetTickCount() + m_nMingyueduxin.CD
    -- end
end

function SpecialSettings.AutoMJSKillDelayCast()
	if bInMutiStageSkillState then
		local nTime = GetTickCount()
		if nNextSkillID and nDelayCallGCDTime ~= 0 and nTime > nDelayCallGCDTime then
			local mask = (nNextSkillID * (nNextSkillID % 10 + 1))
			local res = OnUseSkill(nNextSkillID, mask)
			-- m_dwNextSkillID = nil
			nDelayCallGCDTime = 0
		end
	else
		nNextSkillID = nil
		nMultiStageSkillCount = 0
		nDelayCallGCDTime = 0
	end

    if m_nMingyueduxin.nNextUseTime then
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return
        end
        if pPlayer.IsHaveBuff(m_nMingyueduxin.BUFF_ID, 1) then
            if m_nMingyueduxin.nNextUseTime and GetTickCount() >= m_nMingyueduxin.nNextUseTime then
                local mask = (m_nMingyueduxin.NEXT_SKILL_ID * (m_nMingyueduxin.NEXT_SKILL_ID % 10 + 1))
                local res = OnUseSkill(m_nMingyueduxin.NEXT_SKILL_ID, mask)
                m_nMingyueduxin.nNextUseTime = nil
            end
        else
            m_nMingyueduxin.nNextUseTime = nil
        end
    end
end

--长歌影子放自身
function SpecialSettings.ShadowToMe(ShadowConfig, bIsToMe)
	SetSkillCastToMe(ShadowConfig, bIsToMe)
end

-- 长歌读条中自动施法（阳春白雪）
function CheckAutoCGSkillInOTABar()
	return bAutoCGSkillInOTABar
end

function SpecialSettings.SetAutoCGSkillInOTABar(bAuto)
	bAutoCGSkillInOTABar = bAuto
end
local tChangGeAutoSkill =
{
	[14137] = 15090,
	[14140] = 15090,
	[14064] = 14230,
	[14067] = 14230,
}
local nDelayAutoSkillTime = 0
-- nSkillID宫或徽
function SpecialSettings.AutoCGSkillInOTABar(nSkillID)
	if not CheckAutoCGSkillInOTABar() then
		return
	end
	if GetClientPlayer().nPoseState ~= POSE_TYPE.YANGCUNBAIXUE then
		return
	end
	local nChangGeAutoSkillID = tChangGeAutoSkill[nSkillID]
	if not nChangGeAutoSkillID then
		return
	end
	local nTime = GetTickCount()
	if nDelayAutoSkillTime <= nTime then
		nDelayAutoSkillTime = 0
	end
	if nDelayAutoSkillTime ~= 0 then
		return
	end
	local bCanUse = Skill_NotInCountDown(nChangGeAutoSkillID)
	if bCanUse then
		local mask = (nChangGeAutoSkillID * (nChangGeAutoSkillID % 10 + 1))
		local res = OnUseSkill(nChangGeAutoSkillID, mask)
		nDelayAutoSkillTime = nTime + 1000 --延迟调用
	end
end

--丐帮连击提示
function SpecialSettings.SetComboPanel(bCheck)
	Event.Dispatch(EventType.OnUpdateGaibangComboVisible, bCheck)
end

function GetComboPanel()
	return not StorageServer.GetData("CloseComboPanel")
end

-- 唐门千机变放脚下
local bInFight = false
function SpecialSettings.QianJiBianToMe(QianJiBianConfig, bIsToMe)
	SetSkillCastToMe(QianJiBianConfig, bIsToMe)
end