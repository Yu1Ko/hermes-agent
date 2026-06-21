local tinsert = table.insert
local tconcat = table.concat
local max, min, floor, ceil, pi = math.max, math.min, math.floor, math.ceil, math.pi


g_playerHandler= g_playerHandler or {className = "g_playerHandler"}
local self = g_playerHandler

-- * get client palyer id
local m_cplayer = {}
local tbWantedPlayer = {}
function UI_GetClientPlayerID()
	return g_pClientPlayer and g_pClientPlayer.dwID
end

function UI_GetClientPlayerName()
	return g_pClientPlayer and g_pClientPlayer.szName or ""
end

function UI_GetClientPlayerGlobalID()
	return g_pClientPlayer and g_pClientPlayer.GetGlobalID()
end

function UI_GetClientPlayerCenterID()
	local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(UI_GetClientPlayerGlobalID())
	return tbRoleEntryInfo and tbRoleEntryInfo.dwCenterID or 0
end

function UI_GetPlayerMountKungfuID()
	local kungfu = g_pClientPlayer and g_pClientPlayer.GetActualKungfuMount()
	if kungfu then
		m_cplayer.dwMountKungfuID = kungfu.dwSkillID
	else
		m_cplayer.dwMountKungfuID = 0
	end
	return m_cplayer.dwMountKungfuID
end

function UI_GetPlayerForceID()
	return g_pClientPlayer and g_pClientPlayer.dwForceID or 0
end

function UI_PlayerForceIDIsZero()
	local me = GetClientPlayer()
	local bNotNoneSchoolKungfu = not IsNoneSchoolKungfu(g_pClientPlayer.GetActualKungfuMountID())

	return me.dwForceID == 0 and bNotNoneSchoolKungfu
end

function UI_GetCurrentMapID()
	if m_cplayer.dwMapID and m_cplayer.dwMapType then
		return m_cplayer.dwMapID, m_cplayer.dwMapType
	end

	local me = GetClientPlayer()
	if me then
		m_cplayer.dwMapID = me.GetMapID()
		_, m_cplayer.dwMapType = GetMapParams(m_cplayer.dwMapID)
	end
	return m_cplayer.dwMapID, m_cplayer.dwMapType
end

-- * client player is in fighting or not
function IsInFight()
	return m_cplayer.bInFight
end

-- * update client player var's value
function ClientPlayer_UpdateProperty(key, value)
	m_cplayer[key]= value
end

--==== control player ============================================================
local m_bControl
function IsInControlOtherState()
	return m_bControl
end

function CheckInControlOtherState(msg)
	if m_bControl then
		OutputMessage("MSG_ANNOUNCE_NORMAL", msg)
		OutputMessage("MSG_SYS", msg)
	end
	return m_bControl
end

function CheckShieldPanel(msg)
	if CheckInControlOtherState(msg) then
		return true
	end
end

-- * get the player be controled of client player
local function _GetControlPlayer()
	local player = GetClientPlayer()
	if player then
		return player.GetProxySkillCharacter()
	end
end

GetControlPlayer = GetClientPlayer

local function _GetControlPlayerID()
	local player = _GetControlPlayer()
	if player then
		return player.dwID
	end
	return 0
end

GetControlPlayerID = UI_GetClientPlayerID

-- * begin control the other player
function EnableControlOther(bControl)
	m_bControl = bControl
	if m_bControl then
		GetControlPlayerID = _GetControlPlayerID
		GetControlPlayer = _GetControlPlayer
	else
		GetControlPlayerID = UI_GetClientPlayerID
		GetControlPlayer = GetClientPlayer
	end
end
--==== end ============================================================

function UpdatePlayerTitleWantedEffect()
	for dwPlayerID, dwEffectID in pairs(tbWantedPlayer) do
		UpdatePlayerTitleEffect(dwPlayerID)
	end
end

function UpdatePlayerTitleEffect(dwPlayerID)
	local hTargetPlayer = GetPlayer(dwPlayerID)
	if not hTargetPlayer then	-- Player is not in the scene or offline
		return
	end

	local hPlayer = GetClientPlayer()
	local hScene = hPlayer.GetScene()
	local dwEffectID = TITLE_EFFECT_NONE

	-- 头顶特效优先级： 悬赏 > 屠杀
	if hTargetPlayer.IsOnSlay() then
		if (not hScene.bIsArenaMap) and (not Table_IsBattleFieldMap(hScene.dwMapID)) then
			dwEffectID = 50
		end
	end
	if hScene.nType == MAP_TYPE.NORMAL_MAP then
		local bSelf = dwPlayerID == hPlayer.dwID
		local bShowSelf = GameSettingData.GetNewValue(UISettingKey.ShowOwnWwantedSign)
		local bShowOther = GameSettingData.GetNewValue(UISettingKey.ShowOtherPlayerWantedSign)
		local bNotShow = (bSelf and not bShowSelf) or (not bSelf and not bShowOther)
		local nEffectID = nil
		if GetNumberBit(hTargetPlayer.nWantedTypeMask, WANTED_TYPE_CODE.PUBLIC + 1) then --被公开悬赏
			nEffectID = 47
		elseif GetNumberBit(hTargetPlayer.nWantedTypeMask, WANTED_TYPE_CODE.PRIVATE + 1) then --被私有悬赏
			nEffectID = 223
		end
		if nEffectID ~= nil then
			tbWantedPlayer[dwPlayerID] = nEffectID
			if not bNotShow then--当前悬赏可以展示
				dwEffectID = nEffectID
			end
		else
			tbWantedPlayer[dwPlayerID] = nil
		end
	end

	if hPlayer.IsInParty() or OBDungeonData.IsPlayerInOBDungeon() then	-- party mark
		local nPartyMark
        if OBDungeonData.IsPlayerInOBDungeon() then
            nPartyMark = GetClientTeam().GetMarkIndexExceptTeamID(dwPlayerID) or 0
        else
            nPartyMark = GetClientTeam().GetMarkIndex(dwPlayerID) or 0
        end
		if nPartyMark and PARTY_TITLE_MARK_EFFECT_LIST[nPartyMark] then
			dwEffectID = PARTY_TITLE_MARK_EFFECT_LIST[nPartyMark]
		end
	end

	if hTargetPlayer.nCaptionIconType > 0 then --会顶掉萌新标记，有问题找叶川和王未
		local tInfo = Table_GetCaptionIconToTitleEffect(hTargetPlayer.nCaptionIconType)
		if tInfo then
			dwEffectID = tInfo.dwEffectID
		end
	end

	SceneObject_SetTitleEffect(TARGET.PLAYER, dwPlayerID, dwEffectID)
end

function OutputPlayerTip(dwPlayerID, Rect)
	local player = GetPlayer(dwPlayerID)
	if not player then
		return
	end

	local me = GetClientPlayer()
	--如果是自己，则不显示tip
	if not IsCursorInExclusiveMode() then
		if me.dwID == dwPlayerID then
			return
		end
	end

	local t = {}
	local r, g, b = GetForceFontColor(dwPlayerID, me.dwID)
	local szTip = ""

	-- 名字
	tinsert(t, GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, player.szName), 80, r, g, b))
	-- 称号
	if player.szTitle ~= "" then
		tinsert(t, GetFormatText("<" .. player.szTitle .. ">\n", 0))
	end
	-- 帮会
	if player.dwTongID ~= 0 then
		local szName = GetTongClient().ApplyGetTongName(player.dwTongID, 1)
		if szName and szName ~= "" then
			tinsert(t, GetFormatText("[" .. szName .. "]\n", 0))
		end
	end
	-- 等级
	if player.nLevel - me.nLevel > 10 and not me.IsPlayerInMyParty(dwPlayerID) then
		tinsert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	else
		tinsert(t, GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, player.nLevel), 82))
	end
	-- 声望
	local tRepuForceInfo = Table_GetReputationForceInfo(player.dwForceID)
	if tRepuForceInfo then
		tinsert(t, GetFormatText(tRepuForceInfo.szName.."\n", 82))
	end
	-- 所在地图
	if IsParty(dwPlayerID, me.dwID) then
		local hTeam = GetClientTeam()
		local tMemberInfo = hTeam.GetMemberInfo(dwPlayerID)
		if tMemberInfo then
			local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
			if szMapName then
				tinsert(t, GetFormatText(szMapName.."\n", 82))
			end
		end
	end
	-- 阵营
	if player.bCampFlag then
		tinsert(t, GetFormatText(g_tStrings.STR_TIP_CAMP_FLAG, 163))
	end
	tinsert(t, GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[player.nCamp], 82))
	-- 调试信息
	if IsCtrlKeyDown() then
		tinsert(t, GetFormatText("\n"))
		tinsert(t, GetFormatText(FormatString(g_tStrings.TIP_PLAYER_ID, player.dwID), 102))
		tinsert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, player.dwModelID), 102))
		tinsert(t, GetFormatText(var2str(player.GetRepresentID(), "  "), 102))
	end
	-- 格式化输出
	OutputTip(tconcat(t), 345, Rect)
end

--同阵营返回true，敌对，返回false
function InteractPlayer(dwPlayerID)
	local dwClientPlayerID = GetClientPlayer().dwID
	if IsEnemy(dwClientPlayerID, dwPlayerID) then
		return false
	else
		return true
	end
end


function NeedHightlightPlayer(dwPlayerID)
	--TODO:可能会根据技能，势力，自身状态之类的条件做
	return false
end


function CanSelectPlayer(dwPlayerID)
	--自己
	local clientPlayer = GetClientPlayer()
	if clientPlayer.dwID == dwPlayerID then
		return false
	end

	return true
end

function ChangeCursorWhenOverPlayer(dwPlayerID)
	local dwClientPlayerID = GetClientPlayer().dwID
	if IsCursorInExclusiveMode() then
		return
	end

	if dwClientPlayerID == dwPlayerID then
		Cursor.Switch(CURSOR.NORMAL)
	elseif IsFakeAlly(dwPlayerID) then
		Cursor.Switch(CURSOR.NORMAL)
	elseif IsEnemy(dwClientPlayerID, dwPlayerID) then
		Cursor.Switch(CURSOR.ATTACK)
	else
		local player = GetPlayer(dwPlayerID)
		if IsParty(dwClientPlayerID, dwPlayerID) then
			Cursor.Switch(CURSOR.NORMAL)
		elseif IsAlly(dwClientPlayerID, dwPlayerID) then
			Cursor.Switch(CURSOR.NORMAL)
		else
			Cursor.Switch(CURSOR.NORMAL)
		end
	end
end

function NeedHighlightPlayerWhenOver(dwPlayerID)
	if UI_GetClientPlayerID() == dwPlayerID then
		return false
	end
	return true
end

function TradingInviteToPlayer(dwID)
	local player = GetPlayer(dwID)
	local ClientPlayer = GetClientPlayer()

	if not player then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_TRADING_TARGET_NOT_IN_GAME)
	end

	if not player.CanDialog(ClientPlayer) then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_TRADING_TOO_FAR)
	elseif IsEnemy(ClientPlayer.dwID, player.dwID) then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TRADING_ENEMY)
	else
		 if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
		 	return
		 end

		local bResult = ClientPlayer.TradingInviteRequest(dwID)
		if bResult then
			OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_TRADING_INVITE2, UIHelper.GBKToUTF8(player.szName)))
		end
	end

end


local m_tInviteToPlayer = {}
function ViewInviteToPlayer(dwPlayerID, bSilent)
	if not bSilent then
		m_tInviteToPlayer[dwPlayerID] = true
	end
	PeekOtherPlayer(dwPlayerID)
end

function OnViewInviteToPlayerRespond(nResult, dwID)
	if m_tInviteToPlayer[dwID] then
		if nResult == PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
			OpenPlayerView(dwID)
		end
		m_tInviteToPlayer[dwID] = nil
	end
end

function GetPlayerDesignation(dwPlayerID)
	local player = GetPlayer(dwPlayerID)
	if not player then
		return ""
	end

	local nPrefix = player.GetCurrentDesignationPrefix()
	local nPostfix = player.GetCurrentDesignationPostfix()
	local nGeneration = player.GetDesignationGeneration()
	local nCharacter = player.GetDesignationByname()
	local bShow = player.GetDesignationBynameDisplayFlag()
	local nForceID = player.dwForceID

	local szDesignation = ""
	local nQuality = 1
	if nPrefix ~= 0 then
		local aPrefix = Table_GetDesignationPrefixByID(nPrefix, nForceID)
		if aPrefix then
			szDesignation = szDesignation..aPrefix.szName
			nQuality = math.max(aPrefix.nQuality, nQuality)
		end
	end

	if nPostfix ~= 0 then
		local aPostfix = g_tTable.Designation_Postfix:Search(nPostfix)
		if aPostfix then
			szDesignation = szDesignation..aPostfix.szName
			nQuality = math.max(aPostfix.nQuality, nQuality)
		end
	end

	if bShow then
		local aGen = g_tTable.Designation_Generation:Search(nForceID, nGeneration)
		if aGen then
			szDesignation = szDesignation..aGen.szName
			if aGen.szCharacter and aGen.szCharacter ~= "" then
				local aCharacter = g_tTable[aGen.szCharacter]:Search(nCharacter)
				if aCharacter then
					szDesignation = szDesignation..aCharacter.szName
				end
			end
		end
	end
	return szDesignation, nQuality
end

function IsRoleMale(nRoleType)
	if nRoleType == ROLE_TYPE.STANDARD_MALE or nRoleType == ROLE_TYPE.STRONG_MALE or nRoleType == ROLE_TYPE.LITTLE_BOY then
		return true
	end
	return false
end

function IsRoleFemale(nRoleType)
	if nRoleType == ROLE_TYPE.STANDARD_FEMALE or nRoleType == ROLE_TYPE.SEXY_FEMALE or nRoleType == ROLE_TYPE.LITTLE_GIRL then
		return true
	end
	return false
end

function CheckPlayerIsRemote(dwPlayerID, szMsg)
	if not szMsg then
		szMsg = g_tStrings.STR_REMOTE_NOT_TIP
	end
	if not dwPlayerID then
		local pPlayer = GetClientPlayer()
		if not pPlayer then
			return false
		end
		dwPlayerID = pPlayer.dwID
	end
	if IsRemotePlayer(dwPlayerID) then
		if not string.is_nil(szMsg) then
			OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
			OutputMessage("MSG_SYS", szMsg.."\n")
		end
		return true
	end
	return false
end

--检测玩家是不是二内三内
function CheckPlayerKungfuID()
    local dwKungFuID = g_pClientPlayer and g_pClientPlayer.GetActualKungfuMountID()
    local tKungFuList = SkillData.GetKungFuList() or {}
    local tHDKungFuList = SkillData.GetKungFuList(true) or {}
    local bResult = true

    for k, v in ipairs(tKungFuList) do
        local nSkillID = v[1]
        if nSkillID == dwKungFuID then
            bResult = false
            break
        end
    end

    for k, v in ipairs(tHDKungFuList) do
        local nSkillID = v[1]
        if nSkillID == dwKungFuID then
            bResult = false
            break
        end
    end

	return bResult
end

function IsRoleInFakeState(pPlayer)
	if not pPlayer then
		pPlayer = GetClientPlayer()
	end
	if not pPlayer then
		return false
	end
	return pPlayer.dwFakePlayerID > 0
end

function CheckPlayerIsInFake()
	if IsRoleInFakeState() then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.FAKEING_STATE_ERROR)
        return true
	end

	return false
end

-- 公用脚本函数
-- 函数名： GetRoleType(pPlayer)
-- 函数描述：获取当前角色的体型，当玩家在伪装的时候，返回伪装的体型
-- 参数列表： pPlayer 如果为你了，则获取当前的角色
-- 返回值： 当前体现
-- 备注：
-- 示例：
function Player_GetRoleType(pPlayer)
    local nRoleType = pPlayer.nRoleType
    if IsRoleInFakeState(pPlayer) then
        nRoleType = pPlayer.nFakeRoleType
    end
    return nRoleType
end

--升级到18级, 并且未充值
--进入30分钟 被T下线的倒计时。 此时不能交接任务
function IsLimitAccount(hPlayer)
	if not hPlayer then
		return false
	end

	local hPlayer = GetClientPlayer()
	local nLevel = GetFreeMaxLevel()
	local dwFirstPoint = Login_GetExtPoint(0)

	if hPlayer.nLevel >= nLevel and hPlayer.bFreeLimitFlag and dwFirstPoint == 0 then
		return true
	else
		return false
	end
end

--账号没有充值过, 返回true
function IsNoPayAccount()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local dwFirstPoint = Login_GetExtPoint(0)

	if hPlayer.bFreeLimitFlag and dwFirstPoint == 0 then
		return true
	else
		return false
	end
end


--==== player energy ui ============================================================
local m_aAccumulateShow =
{
	{},
	{"10"},
	{"11"},
	{"11", "20"},
	{"11", "21"},
	{"11", "21", "30"},
	{"11", "21", "31"},
	{"11", "21", "31", "40"},
	{"11", "21", "31", "41"},
	{"11", "21", "31", "41", "50"},
	{"11", "21", "31", "41", "51"},
}

local  m_aAccumulateHide =
{
	{"10", "11", "20", "21", "30", "31", "40", "41", "50", "51"},
	{"11", "20", "21", "30", "31", "40", "41", "50", "51"},
	{"10", "20", "21", "30", "31", "40", "41", "50", "51"},
	{"10", "21", "30", "31", "40", "41", "50", "51"},
	{"10", "20", "30", "31", "40", "41", "50", "51"},
	{"10", "20", "31", "40", "41", "50", "51"},
	{"10", "20", "30", "40", "41", "50", "51"},
	{"10", "20", "30", "41", "50", "51"},
	{"10", "20", "30", "40", "50", "51"},
	{"10", "20", "30", "40", "51"},
	{"10", "20", "30", "40", "50"},
}

local m_nAccumulateStyle = 0
--RegisterEvent("CHANGE_ACCUMULATE_STYLE", function()
--	m_nAccumulateStyle = arg0
--end)
local m_aChanggeAccumulateSfx = {
	[0] = {
		[1] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 21}, {"ui\\Image\\UICommon\\ChangGe.UITex", 22}},
		[2] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 21}, {"ui\\Image\\UICommon\\ChangGe.UITex", 22}},
		[3] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 21}, {"ui\\Image\\UICommon\\ChangGe.UITex", 22}},
		[4] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 21}, {"ui\\Image\\UICommon\\ChangGe.UITex", 22}},
		[5] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 21}, {"ui\\Image\\UICommon\\ChangGe.UITex", 22}},
	},
	[1] = { -- 高山流水
		[1] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 10}, {"ui\\Image\\UICommon\\ChangGe.UITex", 9}},
		[2] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 10}, {"ui\\Image\\UICommon\\ChangGe.UITex", 9}},
		[3] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 10}, {"ui\\Image\\UICommon\\ChangGe.UITex", 9}},
		[4] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 10}, {"ui\\Image\\UICommon\\ChangGe.UITex", 9}},
		[5] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 10}, {"ui\\Image\\UICommon\\ChangGe.UITex", 9}},
	},
	[2] = { -- 阳春白雪
		[1] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 19}, {"ui\\Image\\UICommon\\ChangGe.UITex", 20}},
		[2] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 19}, {"ui\\Image\\UICommon\\ChangGe.UITex", 20}},
		[3] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 19}, {"ui\\Image\\UICommon\\ChangGe.UITex", 20}},
		[4] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 19}, {"ui\\Image\\UICommon\\ChangGe.UITex", 20}},
		[5] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 19}, {"ui\\Image\\UICommon\\ChangGe.UITex", 20}},
	},
	[3] = { -- 梅花三弄
		[1] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 13}, {"ui\\Image\\UICommon\\ChangGe.UITex", 12}},
		[2] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 13}, {"ui\\Image\\UICommon\\ChangGe.UITex", 12}},
		[3] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 13}, {"ui\\Image\\UICommon\\ChangGe.UITex", 12}},
		[4] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 13}, {"ui\\Image\\UICommon\\ChangGe.UITex", 12}},
		[5] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 13}, {"ui\\Image\\UICommon\\ChangGe.UITex", 12}},
	},
	[4] = { -- 平沙落雁
		[1] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 16}, {"ui\\Image\\UICommon\\ChangGe.UITex", 15}},
		[2] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 17}, {"ui\\Image\\UICommon\\ChangGe.UITex", 14}},
		[3] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 16}, {"ui\\Image\\UICommon\\ChangGe.UITex", 15}},
		[4] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 17}, {"ui\\Image\\UICommon\\ChangGe.UITex", 14}},
		[5] = {{"ui\\Image\\UICommon\\ChangGe.UITex", 16}, {"ui\\Image\\UICommon\\ChangGe.UITex", 15}},
	},
}

local m_EnergyUIFuns = {}

m_EnergyUIFuns["CangYun"] = function(hList, player)
	player = player or GetControlPlayer()

	local hImageRang = hList:Lookup("Image_Rang")
	local hTextRang = hList:Lookup("Text_Rang")

	if player.nMaxRage > 0 then
		local fRage = player.nCurrentRage / player.nMaxRage
		if player.nCurrentRage == player.nMaxRage then
			hList:Lookup("Image_Rang"):SetFrame(2)
		else
			hList:Lookup("Image_Rang"):SetFrame(1)
		end

		hImageRang:SetPercentage(fRage)

		if IsShowSelfStateValueByPercentage() then
			hTextRang:SetText(string.format("%d%%", 100 * fRage))
		else
			hTextRang:SetText(player.nCurrentRage .. "/" .. player.nMaxRage)
		end

		hList:Lookup("SFX_Rang"):SetVisible(player.nCurrentRage == player.nMaxRage)
	else
		hImageRang:SetPercentage(0)
		hTextRang:SetText("")
	end

	if hList:Lookup("Image_Sword") then
		hList:Lookup("Image_Sword"):SetVisible( (player.nPoseState == POSE_TYPE.SWORD) )
		hList:Lookup("Image_Shield"):SetVisible( (player.nPoseState == POSE_TYPE.SHIELD) )
	end

	local imgNor = hList:Lookup("Image_Sheild")
	local imgRed = hList:Lookup("Image_SheildRed")
	local imgPro = hList:Lookup("Image_SheildProgress")
	local txtNum = hList:Lookup("Text_Num")

	local hSheild = hList:Lookup("Handle_Sheild")
	if hSheild  and player.nLevel >= 40 then
		hSheild:Show()

		local imgNor = hSheild:Lookup("Image_Sheild")
		local imgRed = hSheild:Lookup("Image_SheildRed")
		local imgPro = hSheild:Lookup("Image_SheildProgress")
		local txtNum = hSheild:Lookup("Text_Num")

		local nEnergy = player.nCurrentEnergy
		imgNor:SetVisible(nEnergy > 0)
		imgRed:SetVisible(nEnergy == 0)
		txtNum:SetText(nEnergy)

		if player.nMaxEnergy > 0 then
			local fPer = nEnergy / player.nMaxEnergy
			imgPro:SetPercentage(0.1 + fPer * 0.8)

		else
			imgPro:SetPercentage(0)
		end
	elseif hSheild then
		hSheild:Hide()
	end
end

m_EnergyUIFuns["CJ"] = function(hList, player)
	player = player or GetControlPlayer()

	local hImageShort = hList:Lookup("Image_Short")
	local hTextShort = hList:Lookup("Text_Short")
	local hAniShort = hList:Lookup("Animate_Short")
	local hImageLong = hList:Lookup("Image_Long")
	local hTextLong = hList:Lookup("Text_Long")
	local hAniLong = hList:Lookup("Animate_Long")
	local szShow = nil

	if player.nMaxRage > 100 then
		hImageShort:Hide()
		hTextShort:Hide()
		hAniShort:Hide()

		hImageLong:Show()
		hTextLong:Show()
		hAniLong:Show()

		szShow = "Long"
	else
		hImageShort:Show()
		hTextShort:Show()
		hAniShort:Show()

		hImageLong:Hide()
		hTextLong:Hide()
		hAniLong:Hide()

		szShow = "Short"
	end

	if player.nMaxRage > 0 then
		local fRage = player.nCurrentRage / player.nMaxRage

		hList:Lookup("Image_"..szShow):SetPercentage(fRage)

		if IsShowSelfStateValueByPercentage() then
			hList:Lookup("Text_"..szShow):SetText(string.format("%d%%", 100 * fRage))
		else
			hList:Lookup("Text_"..szShow):SetText(player.nCurrentRage .. "/" .. player.nMaxRage)
		end
	else
		hList:Lookup("Image_"..szShow):SetPercentage(0)
		hList:Lookup("Text_"..szShow):SetText("")
	end
end

local tBombMsg = {}
local nBombTotalTime = 60
local nBombMaxDis = 3686400 --(30尺 * 64) ^ 2
m_EnergyUIFuns["TM"] = function(hList, player)
	local textNumber = hList:Lookup("Text_Energy")
	local imgEnergy = hList:Lookup("Image_Strip")
	local imgFrame = hList:Lookup("Image_Frame")
	local hBombList = hList:Lookup("Handle_ACSJ")

	player = player or GetControlPlayer();
	if not player.nMaxEnergy then
		return 1 --每帧刷新
	end
	if player.nMaxEnergy > 0 then
		local fPer = player.nCurrentEnergy / player.nMaxEnergy
		imgEnergy:SetPercentage(fPer)
		if IsShowSelfStateValueByPercentage() then
			textNumber:SetText(string.format("%d%%", 100 * fPer))
		else
			textNumber:SetText(player.nCurrentEnergy .. "/" .. player.nMaxEnergy)
		end
	else
		imgEnergy:SetPercentage(0)
		textNumber:SetText("")
	end

	local ACSJ_SKILL_BUFF_LIST_ID = 2 --唐门暗藏杀机BUFF列表
	if hBombList then
		local tBuffList, nBombID = Table_GetCustomBuffList(ACSJ_SKILL_BUFF_LIST_ID), nil
		for i, nBuffID in ipairs(tBuffList) do
			local bExist = player.IsHaveBuff(nBuffID, 1)
			if bExist then
				local tBuffInfo, nLeftTime = {}
				for j = 1, player.GetBuffCount() do
					Buffer_Get(player, j - 1, tBuffInfo)
					if tBuffInfo.dwID and tBuffInfo.dwID == nBuffID then
						local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
						local nHour, nMinute, nSecond = GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
						nLeftTime = nHour * 3600 + nMinute * 60 + nSecond
						break
					end
				end
				if nLeftTime then
					if tBombMsg[i] and tBombMsg[i].nTime >= nLeftTime then
						tBombMsg[i].nTime = nLeftTime
					else
						tBombMsg[i] = {nID = nBuffID, nTime = nLeftTime}
					end
				else
					tBombMsg[i] = nil
				end
			else
				tBombMsg[i] = nil
			end
		end

		for i, nBuffID in ipairs(tBuffList) do
			local pBomb, bFound = player.GetBomb(i - 1), false
			if pBomb then
				for _, tBomb in pairs(tBombMsg) do
					if tBomb.nBombNpcID == pBomb.dwID then
						bFound = true
						break
					end
				end
				if not bFound then
					nBombID = pBomb.dwID
				end
			end
		end
		if nBombID then
			for _, tBomb in pairs(tBombMsg) do
				if not tBomb.nBombNpcID then
					tBomb.nBombNpcID = nBombID
					break
				end
			end
		end

		for i, nBuffID in ipairs(tBuffList) do
			local hBomb = hBombList:Lookup(i - 1)
			hBomb:Hide()
			if tBombMsg[i] then
				hBomb:Show()
				hBomb:Lookup(1):SetPercentage(tBombMsg[i].nTime / nBombTotalTime)
				hBomb:Lookup(2):SetText(tostring(tBombMsg[i].nTime))
				if tBombMsg[i].nBombNpcID then
					local nDistance = CalHorizontalDistance(tBombMsg[i].nBombNpcID)
					if nDistance and nDistance <= nBombMaxDis then
						hBomb:SetAlpha(255)
					else
						hBomb:SetAlpha(100)
					end
				end
			end
		end
	end
	return 1 --每帧刷新
end

m_EnergyUIFuns["MJ"] = function(hList, player)
	player = player or GetControlPlayer()

	local hImageSunEnergy = hList:Lookup("Image_SunEnergy")
	local hImageMoonEnergy = hList:Lookup("Image_MoonEnergy")
	local bShowSunEnergy = (player.nCurrentSunEnergy > 0 or player.nCurrentMoonEnergy > 0)
						and player.nCurrentSunEnergy < 10000
	local bShowMoonEnergy = (player.nCurrentSunEnergy > 0 or player.nCurrentMoonEnergy > 0)
						and player.nCurrentMoonEnergy < 10000
	local sunPer, moonPer = 0, 0
	if player.nMaxSunEnergy ~= 0 then
		sunPer = player.nCurrentSunEnergy / player.nMaxSunEnergy
	end

	if player.nMaxMoonEnergy ~= 0 then
		moonPer = player.nCurrentMoonEnergy / player.nMaxMoonEnergy
	end

	hImageSunEnergy:SetPercentage(sunPer)
	hImageMoonEnergy:SetPercentage(moonPer)

	hList:Lookup("Text_Sun"):Show(player.nSunPowerValue == 0 and player.nCurrentSunEnergy ~= player.nMaxSunEnergy and player.nCurrentSunEnergy ~= 0)
	local nInteger = math.modf(sunPer * 100)
	if nInteger > 100 then nInteger = 100 end
	hList:Lookup("Text_Sun"):SetText(tostring(nInteger))
	hList:Lookup("Text_Moon"):Show(player.nMoonPowerValue == 0 and player.nCurrentMoonEnergy ~= player.nMaxMoonEnergy and player.nCurrentMoonEnergy ~= 0)
	nInteger = math.modf(moonPer * 100)
	if nInteger > 100 then nInteger = 100 end
	hList:Lookup("Text_Moon"):SetText(tostring(nInteger))

	hImageSunEnergy:Show(player.nSunPowerValue <= 0)
	hImageMoonEnergy:Show(player.nMoonPowerValue <= 0)
	hList:Lookup("Image_MingJiaoBG2"):Show(
		player.nMoonPowerValue <= 0 and
		player.nSunPowerValue <= 0 and
		player.nCurrentSunEnergy <= 0 and
		player.nCurrentMoonEnergy <= 0
	)
	hList:Lookup("Image_SunCao"):Show(bShowSunEnergy)
	hList:Lookup("Image_SunBG"):Show(player.nSunPowerValue > 0)
	hList:Lookup("SFX_Sun"):Show(player.nSunPowerValue > 0)

	hList:Lookup("Image_MoonCao"):Show(bShowMoonEnergy)
	hList:Lookup("Image_MoonBG"):Show(player.nMoonPowerValue > 0)
	hList:Lookup("SFX_Moon"):Show(player.nMoonPowerValue > 0)
end

m_EnergyUIFuns["SL"] = function(hList, player)
	player = player or GetControlPlayer()
	local nMaxCount = 3
	local nValue = player.nAccumulateValue
	nValue = math.max(nValue, 0)
	nValue = math.min(nValue, nMaxCount)

	local szSub = "SL"
	for i = 1, nMaxCount, 1 do
		hList:Lookup(szSub .. "_" .. i):SetVisible(i <= nValue)
	end
end

m_EnergyUIFuns["QX"] = function(hList, player)
	player = player or GetControlPlayer()

	local nMaxCount = 10
	local nValue = player.nAccumulateValue
	nValue = math.max(nValue, 0)
	nValue = math.min(nValue, nMaxCount)

	local hText = hList:Lookup("Text_Layer")
	local hImage = hList:Lookup("Image_QX_Btn")

	if nValue > 0 then
		hText:SetText(nValue)
		hText:Show()
		hImage.bChecked = true
	else
		hText:Hide()
		hImage.bChecked = false
	end

	if hImage.bClickDown then
		hImage:SetFrame(89)
	elseif hImage.bInside then
		hImage:SetFrame(86)
	elseif hImage.bChecked then
		hImage:SetFrame(88)
	else
		hImage:SetFrame(85)
	end

	local szSub = "QX"
	for i = 1, nMaxCount, 1 do
		hList:Lookup(szSub .. "_" .. i):SetVisible(i <= nValue)
	end
end

m_EnergyUIFuns["CY"] = function(hList, player)
	player = player or GetControlPlayer()
	local nMaxCount = 10
	local nValue = player.nAccumulateValue
	nValue = math.max(nValue, 0)
	nValue = math.min(nValue, nMaxCount)

	if nValue > 10 then
		nValue = 10
	end
	nValue = nValue + 1
	local szSub = "CY"
	local aShow = m_aAccumulateShow[nValue]
	local aHide = m_aAccumulateHide[nValue]
	local h
	for k, v in pairs(aShow) do
		h = hList:Lookup(szSub .. "_" .. v)
		if h then
			h:Show()
		end
	end
	for k, v in pairs(aHide) do
		h = hList:Lookup(szSub .. "_" .. v)
		if h then
			h:Hide()
		end
	end
end

local m_bOpenYZSkillHint
m_EnergyUIFuns["YZ"] = function(hList, player)
	player = player or GetControlPlayer()
	local nValue = player.nNaturePowerValue
	local nOrign = 100
	local nMax = player.nMaxNaturePowerGrid
	nValue = math.max(nValue, nOrign - nMax)
	nValue = math.min(nValue, nOrign + nMax)
	local hHot = hList:Lookup("Handle_Hot")
	local hCold = hList:Lookup("Handle_Cold")

	if not hList.nLastNaturePower then
		hList.nLastNaturePower = nOrign
	end

	if nValue > hList.nLastNaturePower then
		if hList.nLastNaturePower < nOrign then
			local nDest = math.min(nValue, nOrign) - 1
			for i = hList.nLastNaturePower,  nDest, 1 do
				local nIndex = nOrign - i
				local hSFX0 = hCold:Lookup("SFX_Cold" .. nIndex .. "_0")
				local hSFX1 = hCold:Lookup("SFX_Cold" .. nIndex .. "_1")
				hSFX1:Play()
				hSFX0:Hide()
			end
		end

		if nValue > nOrign then
			local nStartIndex = math.max(nOrign, hList.nLastNaturePower)
			for i = nStartIndex + 1, nValue, 1 do
				local nIndex = i - nOrign
				local hSFX0 = hHot:Lookup("SFX_Hot" .. nIndex .. "_0")
				local hSFX1 = hHot:Lookup("SFX_Hot" .. nIndex .. "_1")
				hSFX1:Show()
				hSFX0:Show()
				hSFX0:Play()
			end
		end
	end

	if nValue < hList.nLastNaturePower then
		if hList.nLastNaturePower > nOrign then
			local nDest = math.max(nValue, nOrign) + 1
			for i = hList.nLastNaturePower, nDest, -1 do
				local nIndex = i - nOrign
				local hSFX0 = hHot:Lookup("SFX_Hot" .. nIndex .. "_0")
				local hSFX1 = hHot:Lookup("SFX_Hot" .. nIndex .. "_1")
				hSFX1:Play()
				hSFX0:Hide()
			end
		end

		if nValue < nOrign then
			local nStartIndex = math.min(nOrign, hList.nLastNaturePower)
			for i = nStartIndex - 1, nValue, -1 do
				local nIndex = nOrign - i
				local hSFX0 = hCold:Lookup("SFX_Cold" .. nIndex .. "_0")
				local hSFX1 = hCold:Lookup("SFX_Cold" .. nIndex .. "_1")
				hSFX1:Show()
				hSFX0:Show()
				hSFX0:Play()
			end
		end
	end

	local nNeutralizationTime = 0

	if nValue > hList.nLastNaturePower and hList.nLastNaturePower < nOrign then
		nNeutralizationTime = math.min(nOrign - hList.nLastNaturePower, nValue - hList.nLastNaturePower)
	end

	if nValue < hList.nLastNaturePower and hList.nLastNaturePower > nOrign then
		nNeutralizationTime = math.min(hList.nLastNaturePower - nOrign, hList.nLastNaturePower - nValue)
	end

	local hRoot = hList:GetRoot()
	if hRoot:GetName() == "Playerbar" then
		if not m_bOpenYZSkillHint then
			YaoZongSkillHint.Open()
			m_bOpenYZSkillHint = true
		end

		if nNeutralizationTime > 0 then
			YaoZongSkillHint.PlaySFX()
		end
	end


	hList.nLastNaturePower = nValue
end

local function fnGetPercent(nNumUp, nNumDown)
	local fPer = 1
	if nNumDown and nNumDown ~= 0 then
		fPer = nNumUp / nNumDown
	end
	return fPer
end

local function GetDZStateType(nPoseState)
	if nPoseState == POSE_TYPE.SINGLEKNIFE or nPoseState == POSE_TYPE.SINGLEKNIFEIN then
		return 1
	elseif nPoseState == POSE_TYPE.DOUBLEKNIFE or nPoseState == POSE_TYPE.DOUBLEKNIFEIN then
		return 2
	end
end

m_EnergyUIFuns["DZ"] = function(hList, player)
	player = player or GetControlPlayer()

	local nNowType = GetDZStateType(player.nPoseState)
	if hList.nPoseState ~= nNowType then
		if hList.nPoseState then
			local hHandle = hList:Lookup("Handle_Switch_DZ")
			local nCount = hHandle:GetItemCount()
			hHandle:Show()
			for i = 0, nCount - 1 do
				local hSFX = hHandle:Lookup(i)
				if hSFX and hSFX:GetType() == "SFX" then
					hSFX:Play()
				end
			end
		end
		hList.nPoseState = nNowType
	end
	local nPoseState = player.nPoseState
	local hText = hList:Lookup("Text_Num_DZ")
	local hImg
	local hSingle = hList:Lookup("Handle_SingleHand")
	local hBoth = hList:Lookup("Handle_BothHand")
	hSingle:Hide()
	hBoth:Hide()
	if nNowType == 1 then
		local hHandle = hSingle
		hImg = hHandle:Lookup("Handle_ProgressDZ_S/Image_ProgressDZ_S")
		hHandle:Show()
	elseif nNowType == 2 then
		local hHandle = hBoth
		hImg = hHandle:Lookup("Handle_ProgressDZ_B/Image_ProgressDZ_B")
		hHandle:Show()
	end
	local hSFX = hList:Lookup("Handle_Progress_SFX")
	local hSFXFull = hList:Lookup("Handle_Full")
	hSFX:Hide()
	hSFXFull:Hide()
	if hText and hImg then
		local fPercent = fnGetPercent(player.nCurrentEnergy, player.nMaxEnergy)
		hText:SetRange(player.nCurrentEnergy, "/", player.nMaxEnergy)
		hImg:SetPercentage(fPercent)
		if fPercent == 1 then
			hSFXFull:Show()
		elseif fPercent ~= 0 then
			hSFX:Show()
			local hSFXPercent = hSFX:Lookup("SFX_Progress_DZ")
			local nAllW = hSFX:GetW()
			local nW = hSFXPercent:GetW()
			hSFXPercent:SetRelX(nAllW * fPercent - nW / 2)
			hSFX:FormatAllItemPos()
		end
	end
end

m_EnergyUIFuns["CG"] = function(hList, player, nAccumulateStyle)
	-- player = player or GetControlPlayer()
	-- local nMaxCount = 5
	-- local nValue = player.nAccumulateValue
	-- nValue = math.max(nValue, 0)
	-- nValue = math.min(nValue, nMaxCount)

	-- -- nAccumulateStyle = nAccumulateStyle or m_nAccumulateStyle
	-- -- local szSub = "CG"
	-- -- local tStyle = m_aChanggeAccumulateSfx[nAccumulateStyle]
	-- -- for i = 1, nMaxCount, 1 do
	-- -- 	hList:Lookup(szSub .. "_" .. i):SetAnimate(unpack(i <= nValue and tStyle[i][1] or tStyle[i][2]))
	-- -- end
	-- -- hList:Lookup("SFX_FullEnergy"):SetVisible(nValue == 5)
end

m_EnergyUIFuns["WH"] = function(hList, player)
	player = player or GetControlPlayer()
	local nMaxCount  = player.nMaxRage / 20
	local nStep  	 = 20
	local szSuffix   = "_T"
	local hListThree = hList:Lookup("Handle_WH_Three")
	local hListFive  = hList:Lookup("Handle_WH_Five")

	hList:Show()
	if nMaxCount == 3 then
		hListThree:Show()
		hListFive:Hide()
		hList = hListThree
	else
		szSuffix = "_F"
		hListThree:Hide()
		hListFive:Show()
		hList = hListFive
	end

	local hText 	 = hList:Lookup("Text_Num_WH" .. szSuffix)
	local hProgress  = hList:Lookup("Handle_ProgressWH" .. szSuffix)
	local hTotalSpot = hList:Lookup("Handle_Spot" .. szSuffix)
	local hBreakOut  = hList:Lookup("Handle_BreakOut" .. szSuffix)
	local hSFX 		 = hBreakOut:Lookup("SFX_BreakOut" .. szSuffix)
	local hTime 	 = hBreakOut:Lookup("Handle_Time" .. szSuffix)
	local hTextTime  = hTime:Lookup("Text_BreakOut" .. szSuffix)

	for i = 1, nMaxCount do
		local hSpot		   = hTotalSpot:Lookup("Handle_Spot" .. i .. szSuffix)
		local hImgSpot	   = hSpot:Lookup("Image_Spot_Bright" .. i .. szSuffix)
		local hImgProgress = hProgress:Lookup("Image_Progress" .. i .. szSuffix)
		local bShow		   = player.nCurrentRage >= nStep * i
		local fPercent     = fnGetPercent(max(player.nCurrentRage - (nStep * (i - 1)), 0), nStep)

		hImgSpot:Show(bShow)
		hImgProgress:SetPercentage(fPercent)
	end

	hText:SetText(player.nCurrentRage .. "/" .. player.nMaxRage)
	if player.IsHaveBuff(24245, 1) then

		hSFX:Show()
		hBreakOut:Show()

		if player.dwID == UI_GetClientPlayerID() then
			local tBuffTimeData = Buffer_GetTimeData(24245)
			local nLeftTime 	= floor(Buffer_GetLeftFrame(tBuffTimeData) / GLOBAL.GAME_FPS)
			hTime:Show()
			hTextTime:SetText(nLeftTime)
		end
		return 1
	elseif player.IsHaveBuff(24538, 1) then
		hSFX:Show()
		hBreakOut:Show()
		return 1
	else
		hSFX:Hide()
		hTime:Hide()
		hBreakOut:Hide()
	end
end

do
	POSE_TYPE =
	{
		SWORD  = 1,				--藏剑姿态
		SHIELD = 2,
		DOUBLE_BLADE = 1,		--霸刀姿态
		BROADSWORD = 2,
		SHEATH_KNIFE = 3,
		SWORD_DANCE = 1,		--七秀剑舞
		GAOSHANLIUSHUI = 1,		--长歌曲风
		YANGCUNBAIXUE = 2,
		MEIHUASHANNONG = 3,
		PINGSHALUOYAN = 3,
		TIANRENHEYI = 2,
		SINGLEKNIFE = 1, 		--单刀
		DOUBLEKNIFE = 2,		--双手持刀
		SINGLEKNIFEIN = 3,		--刀在鞘里，显示单刀
		DOUBLEKNIFEIN = 4,		--刀在鞘里，显示双手持刀
	}

local switchanimate = {
	["12"] = "Handle_BigKnife/SFX_DToB",
	["13"] = "Handle_QiaoKnife/SFX_DToQ",
	["21"] = "Handle_DoubleKnife/SFX_BToD",
	["23"] = "Handle_QiaoKnife/SFX_BToQ",
	["31"] = "Handle_DoubleKnife/SFX_QToD",
	["32"] = "Handle_BigKnife/SFX_QToB",
	[4 .. POSE_TYPE.BROADSWORD  ] = "Handle_BigKnife/SFX_0ToB",
	[4 .. POSE_TYPE.DOUBLE_BLADE] = "Handle_DoubleKnife/SFX_0ToD",
	[4 .. POSE_TYPE.SHEATH_KNIFE] = "Handle_QiaoKnife/SFX_0ToQ",
}
local badaoposeskill = {
	[POSE_TYPE.BROADSWORD  ] = 16168,
	[POSE_TYPE.DOUBLE_BLADE] = 16169,
	[POSE_TYPE.SHEATH_KNIFE] = 16166,
}
local badaoposedelay = {
	[4 .. POSE_TYPE.BROADSWORD  ] = 100,
	[4 .. POSE_TYPE.DOUBLE_BLADE] = 100,
	[4 .. POSE_TYPE.SHEATH_KNIFE] = 100,
	[POSE_TYPE.BROADSWORD   .. POSE_TYPE.DOUBLE_BLADE] = 450,
	[POSE_TYPE.BROADSWORD   .. POSE_TYPE.SHEATH_KNIFE] = 450,
	[POSE_TYPE.DOUBLE_BLADE .. POSE_TYPE.BROADSWORD  ] = 450,
	[POSE_TYPE.DOUBLE_BLADE .. POSE_TYPE.SHEATH_KNIFE] = 450,
	[POSE_TYPE.SHEATH_KNIFE .. POSE_TYPE.BROADSWORD  ] = 450,
	[POSE_TYPE.SHEATH_KNIFE .. POSE_TYPE.DOUBLE_BLADE] = 450,
}

m_EnergyUIFuns["BaDao"] = function(hList, player)
	player = player or GetControlPlayer()
	-- 下方能量条
	if hList.nPoseState ~= player.nPoseState then
		if hList.nPoseState then
			local sfxpath = switchanimate[hList.nPoseState .. player.nPoseState]
			if sfxpath then
				local sfx = hList:Lookup(sfxpath)
				if sfx then
					sfx:Show()
					sfx:Play()
				end
			end
		end
		hList.nPoseDelay = GetTime() + (badaoposedelay[(hList.nPoseState or 4) .. player.nPoseState] or 0)
		hList.nPoseState = player.nPoseState
	end
	local bPoseDelayReach = GetTime() > (hList.nPoseDelay or 0)
	hList:Lookup("Handle_Default"):SetVisible(player.nPoseState == 4 or player.nPoseState == 0)
	hList:Lookup("Handle_BigKnife"):SetVisible(player.nPoseState == POSE_TYPE.BROADSWORD)
	hList:Lookup("Handle_BigKnife/Handle_ProgressB"):SetVisible(player.nPoseState == POSE_TYPE.BROADSWORD and bPoseDelayReach)
	hList:Lookup("Handle_BigKnife/Handle_BigTime"):SetVisible(player.nPoseState == POSE_TYPE.BROADSWORD and bPoseDelayReach)
	hList:Lookup("Handle_QiaoKnife"):SetVisible(player.nPoseState == POSE_TYPE.SHEATH_KNIFE)
	hList:Lookup("Handle_QiaoKnife/Handle_ProgressQ"):SetVisible(player.nPoseState == POSE_TYPE.SHEATH_KNIFE and bPoseDelayReach)
	hList:Lookup("Handle_QiaoKnife/Handle_QiaoTime"):SetVisible(player.nPoseState == POSE_TYPE.SHEATH_KNIFE and bPoseDelayReach)
	hList:Lookup("Handle_DoubleKnife"):SetVisible(player.nPoseState == POSE_TYPE.DOUBLE_BLADE)
	hList:Lookup("Handle_DoubleKnife/Handle_ProgressD"):SetVisible(player.nPoseState == POSE_TYPE.DOUBLE_BLADE and bPoseDelayReach)
	hList:Lookup("Handle_DoubleKnife/Handle_DoubleTime"):SetVisible(player.nPoseState == POSE_TYPE.DOUBLE_BLADE and bPoseDelayReach)
	if player.nPoseState == POSE_TYPE.BROADSWORD then -- 大刀:2 rage
		hList:Lookup("Handle_BigKnife/Text_ValueB"):SetRange(player.nCurrentRage, "/", player.nMaxRage)
		hList:Lookup("Handle_BigKnife/Handle_ProgressB/Image_ProgressB4"):SetPercentage(fnGetPercent(player.nCurrentRage, player.nMaxRage))
		local nRedAlpha = 255 - math.floor((player.nCurrentRage / (player.nMaxRage / 1.5)) * 255)
		if nRedAlpha < 0 then nRedAlpha = 0 end
		local nYellowAlpha = 255 - math.floor(math.abs(player.nCurrentRage - (player.nMaxRage / 2)) / (player.nMaxRage / 2) * 255)
		hList:Lookup("Handle_BigKnife/Handle_ProgressB/Image_ProgressB1"):SetAlpha(nRedAlpha)
		hList:Lookup("Handle_BigKnife/Handle_ProgressB/Image_ProgressB2"):SetAlpha(math.floor(nYellowAlpha / 2))
		local hTime = hList:Lookup("Handle_BigKnife/Handle_BigTime")
		hList:Lookup("Handle_BigKnife/Handle_BigTime/SFX_BigProgress"):SetAbsX(hTime:GetAbsX() + hTime:GetW() * GetPercent(player.nCurrentRage, player.nMaxRage))
	elseif player.nPoseState == POSE_TYPE.DOUBLE_BLADE then -- 双刀:1 ene
		hList:Lookup("Handle_DoubleKnife/Text_ValueD"):SetRange(player.nCurrentEnergy, "/", player.nMaxEnergy)
		hList:Lookup("Handle_DoubleKnife/Handle_ProgressD/Image_ProgressD4"):SetPercentage(fnGetPercent(player.nCurrentEnergy, player.nMaxEnergy))
		local nRedAlpha = 255 - math.floor((player.nCurrentEnergy / (player.nMaxEnergy / 1.5)) * 255)
		if nRedAlpha < 0 then nRedAlpha = 0 end
		local nYellowAlpha = 255 - math.floor(math.abs(player.nCurrentEnergy - (player.nMaxEnergy / 2)) / (player.nMaxEnergy / 2) * 255)
		hList:Lookup("Handle_DoubleKnife/Handle_ProgressD/Image_ProgressD1"):SetAlpha(nRedAlpha)
		hList:Lookup("Handle_DoubleKnife/Handle_ProgressD/Image_ProgressD2"):SetAlpha(math.floor(nYellowAlpha / 2))
		local hTime = hList:Lookup("Handle_DoubleKnife/Handle_DoubleTime")
		hList:Lookup("Handle_DoubleKnife/Handle_DoubleTime/SFX_DoubleProgress"):SetAbsX(hTime:GetAbsX() + hTime:GetW() * (GetPercent(player.nCurrentEnergy, player.nMaxEnergy)))
	elseif player.nPoseState == POSE_TYPE.SHEATH_KNIFE then -- 鞘刀:3 sunene
		hList:Lookup("Handle_QiaoKnife/Text_ValueQ"):SetRange(player.nCurrentSunEnergy, "/", player.nMaxSunEnergy)
		hList:Lookup("Handle_QiaoKnife/Handle_ProgressQ/Image_ProgressQ4"):SetPercentage(fnGetPercent(player.nCurrentSunEnergy, player.nMaxSunEnergy))
		local nRedAlpha = 255 - math.floor((player.nCurrentSunEnergy / (player.nMaxSunEnergy / 1.5)) * 255)
		if nRedAlpha < 0 then nRedAlpha = 0 end
		local nYellowAlpha = 255 - math.floor(math.abs(player.nCurrentSunEnergy - (player.nMaxSunEnergy / 2)) / (player.nMaxSunEnergy / 2) * 255)
		hList:Lookup("Handle_QiaoKnife/Handle_ProgressQ/Image_ProgressQ1"):SetAlpha(nRedAlpha)
		hList:Lookup("Handle_QiaoKnife/Handle_ProgressQ/Image_ProgressQ2"):SetAlpha(math.floor(nYellowAlpha / 2))
		local hTime = hList:Lookup("Handle_QiaoKnife/Handle_QiaoTime")
		hList:Lookup("Handle_QiaoKnife/Handle_QiaoTime/SFX_QiaoProgress"):SetAbsX(hTime:GetAbsX() + hTime:GetW() * (GetPercent(player.nCurrentSunEnergy, player.nMaxSunEnergy)))
	end
	-- 右侧姿态列表
	hList:Lookup("Handle_SheildList"):Show(not BadaoPosture.IsOpened())
	hList:Lookup("Handle_SheildList/Handle_SheildBig"):SetVisible(player.nPoseState ~= POSE_TYPE.BROADSWORD and player.GetSkillLevel(badaoposeskill[POSE_TYPE.BROADSWORD]) ~= 0)
	hList:Lookup("Handle_SheildList/Handle_SheildQiao"):SetVisible(player.nPoseState ~= POSE_TYPE.SHEATH_KNIFE and player.GetSkillLevel(badaoposeskill[POSE_TYPE.DOUBLE_BLADE]) ~= 0)
	hList:Lookup("Handle_SheildList/Handle_SheildDouble"):SetVisible(player.nPoseState ~= POSE_TYPE.DOUBLE_BLADE and player.GetSkillLevel(badaoposeskill[POSE_TYPE.SHEATH_KNIFE]) ~= 0)
	hList:Lookup("Handle_SheildList"):FormatAllItemPos()
	hList:Lookup("Handle_SheildList/Handle_SheildBig/Text_NumB"):SetText(player.nCurrentRage)
	hList:Lookup("Handle_SheildList/Handle_SheildBig/Image_SheildProgressB"):SetPercentage(GetPercent(player.nCurrentRage, player.nMaxRage))
	hList:Lookup("Handle_SheildList/Handle_SheildDouble/Text_NumD"):SetText(player.nCurrentEnergy)
	hList:Lookup("Handle_SheildList/Handle_SheildDouble/Image_SheildProgressD"):SetPercentage(GetPercent(player.nCurrentEnergy, player.nMaxEnergy))
	hList:Lookup("Handle_SheildList/Handle_SheildQiao/Text_NumQ"):SetText(player.nCurrentSunEnergy)
	hList:Lookup("Handle_SheildList/Handle_SheildQiao/Image_SheildProgressQ"):SetPercentage(GetPercent(player.nCurrentSunEnergy, player.nMaxSunEnergy))

	return bPoseDelayReach and 0 or 1
end
end

-- local function HideTCSFX(hList)
-- 	hTCSFX1 = hList:Lookup("SFX_TC1")
-- 	hTCSFX1:Hide()

-- 	hTCSFX2 = hList:Lookup("SFX_TC2")
-- 	hTCSFX2:Hide()

-- 	hTCSFX3 = hList:Lookup("SFX_TC3")
-- 	hTCSFX3:Hide()
-- end

m_EnergyUIFuns["TC"] = function(hList, player)
	player = player or GetControlPlayer()
	local hTCSFX = hList:Lookup("SFX_TC3")
	hTCSFX:Hide()
	local _nStartX, _nStartY      = hList:Lookup("Image_TC"):GetRelPos()
	local _AddX			  		  = hList:Lookup("Image_TC"):GetSize()
	-- local fPosRage
	-- if player.nMaxRage == 0 then
	-- 	fPosRage = 1
	-- else
	-- 	fPosRage = 3 / player.nMaxRage
	-- end

	-- HideTCSFX(hList)

	-- if player.nCurrentRage >= 9  then
	-- 	hTCSFX = hList:Lookup("SFX_TC3")
	-- 	hTCSFX:Show()
	-- elseif player.nCurrentRage >= 6 and player.nCurrentRage < 9 then
	-- 	if player.nMaxRage == 6 then
	-- 		hTCSFX = hList:Lookup("SFX_TC3")
	-- 		hTCSFX:Show()
	-- 	elseif player.nMaxRage == 9 then
	-- 		hTCSFX = hList:Lookup("SFX_TC2")
	-- 		hTCSFX:Show()
	-- 	end
	-- elseif player.nCurrentRage >= 3 and player.nCurrentRage <6 then
	-- 	hTCSFX = hList:Lookup("SFX_TC1")
	-- 	hTCSFX:Show()
	-- end
	if player.nCurrentRage == player.nMaxRage then
		hTCSFX:Show()
	end

	local hTCText = hList:Lookup("Text_TC")
	hTCText:SetRange(player.nCurrentRage, " / ", player.nMaxRage)
	local fRage
	if player.nMaxRage == 0 then
		fRage = 1
	else
		fRage = player.nCurrentRage / player.nMaxRage
	end

	local hTCImgeProgress = hList:Lookup("Image_TC")
	hTCImgeProgress:SetPercentage(fRage)
	hList:FormatAllItemPos()
end

local nDivValue = 10
m_EnergyUIFuns["YT"] = function(hFrame, pPlayer)
	local nCurrentXingYun = pPlayer.nCurrentRage
	if not nCurrentXingYun then return end
	local nMaxXingYun = pPlayer.nMaxRage
	if not nMaxXingYun then return end

	local nPoseState = pPlayer.nPoseState--换皮

	local szStatus = "Normal"
	if nPoseState == POSE_TYPE.TIANRENHEYI then
		szStatus = "Therapy"
	end

	local fnHide = function(hItem, hFrame)
		if not hItem:IsVisible() then
			local nCount = hFrame:GetItemCount()
			for i = 0, nCount - 1 do
				hFrame:Lookup(i):Hide()
			end
		end
	end

	local hList = hFrame:Lookup(FormatString("Handle_<D0>", nMaxXingYun))
	if not hList then return end--刚加载会没取到或nMaxXingYun不为预期值

	fnHide(hList, hFrame)

	local hText = hList:Lookup(FormatString("Text_YZNum_<D0>", nMaxXingYun))
	hText:SetText(nCurrentXingYun .. "/" .. nMaxXingYun)

	local hLine = hList:Lookup(FormatString("Handle_Line_<D0>", nMaxXingYun))

	local hSfx = hLine:Lookup(FormatString("SFX_Line_<D0>_<D1>", nMaxXingYun, szStatus))
	fnHide(hSfx, hLine)
	hSfx:Show()

	hLine:SetW(math.floor(nCurrentXingYun / nMaxXingYun * hSfx:GetW()))

	local nValue = math.floor(nCurrentXingYun / nDivValue)
	for i = 0, nMaxXingYun / nDivValue, 2 do
		local hPoint = hList:Lookup(FormatString("Handle_Point_<D0>_<D1>", nMaxXingYun, i))
		local hSfx = hPoint:
		Lookup(FormatString("SFX_Point_<D0>_<D1>_<D2>", nMaxXingYun, i, szStatus))
		if i <= nValue and nCurrentXingYun > 0 then
			if not hSfx:IsVisible() then
				local nCount = hPoint:GetItemCount()
				for i = 0, nCount - 1 do
					hPoint:Lookup(i):Hide()
				end
				hSfx:Play()
			end
			hSfx:Show()
			hPoint:Show()
		else
			hPoint:Hide()
		end
	end

	hList:Show()
end

function PlayerEnergyUI_Update(szType, hList, player, param)
	if not player then
		return
	end
	if m_EnergyUIFuns[szType] then
		return m_EnergyUIFuns[szType](hList, player, param)
	end
end

function PlayerEnergyUI_GetUpdateFunc(szType)
	return m_EnergyUIFuns[szType]
end

--------------------------------------------------------------------------------------------
local m_tAccumulateStyle = {
	[FORCE_TYPE.CHANG_GE] = {
		[1] = "GaoShan",
		[2] = "YangChun",
		[3] = "MeiHua",
		[4] = "PingSha",
	},
}

local function InitCGMouseFunction(hSong)
	if hSong.OnItemMouseEnter then
		return
	end

	hSong.OnItemMouseEnter = function()
		if this.playerId and this.buffId then
			local player = GetPlayer(this.playerId)
			if player then
				local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum
				local nBuffCount = player.GetBuffCount()
				local buff = {}
				for i = 1, nBuffCount, 1 do
					Buffer_Get(player, i - 1, buff)
					if buff.dwID == this.buffId then
						local w, h = this:GetSize()
						local x, y = this:GetAbsPos()
						local nTime = math.floor( (buff.nLeftFrame or (buff.nEndFrame - GetLogicFrameCount())) / 16 ) + 1
						OutputBuffTip(this.playerId, buff.dwID, buff.nLevel, buff.nStackNum, Table_BuffNeedShowTime(buff.dwID, buff.nLevel), nTime, {x, y, w, h})
						return
					end
				end
			end
		end
	end

	hSong.OnItemMouseLeave = function()
		HideTip()
	end
end

local function HideAllCGHandle(hList)
	for _, szHandleSytle in ipairs(m_tAccumulateStyle[FORCE_TYPE.CHANG_GE]) do
		local hSong = hList:Lookup("Handle_" .. szHandleSytle)
		hSong:Hide()
	end
end

local m_EnergyUIChangeFuns = {}
m_EnergyUIChangeFuns["CG"] = function(hList, player, nStyle, bTarget)
	if not bTarget then
		local hPlayer = GetClientPlayer()
		if not hPlayer then
			return
		end

		local tKungfu = hPlayer.GetActualKungfuMount()
		if not tKungfu then
			return
		end
		nStyle = hPlayer.nPoseState
		if nStyle == 3 and tKungfu.dwSkillID == 10447 then	--莫问心法对应平沙落雁。下标为4
			nStyle = 4
		end
	end

	if nStyle == 0 then
		hList.bHide = true
		hList:Hide()
	else
		hList.bHide = false
		hList:Show()
		HideAllCGHandle(hList)
		local szHandleSytle = m_tAccumulateStyle[FORCE_TYPE.CHANG_GE][nStyle]
		local hSong = hList:Lookup("Handle_" .. szHandleSytle)
		InitCGMouseFunction(hSong)
		hSong:Show()
		for k, v in pairs(g_tUIConfig.CGStateBuff) do
			if v == nStyle then
				hSong.playerId = player.dwID
				hSong.buffId = k
				break
			end
		end
	end
end

function PlayerEnergyUI_ChangeStyle(szType, hList, player, nStyle, bTarget)
	if m_EnergyUIChangeFuns[szType] then
		m_EnergyUIChangeFuns[szType](hList, player, nStyle, bTarget)
	end
	return PlayerEnergyUI_Update(szType, hList, player, nStyle)
end

------SIM World

function SIM_SwitchIK(bOpen)
	if bOpen then
		local nCount = QualityMgr.GetIK()
		rlcmd("switch sim world 1")
		rlcmd("ik count " .. nCount)  --n=人数
	else
		rlcmd("ik count 0")
		rlcmd("switch sim world 0")
	end
end

function SIM_SetIKCount(nCount)
	--LOG.WARN("ik count " .. nCount)
	rlcmd("ik count " .. nCount)
end

function SIM_ChangeAnimationBlend(bOpen)
	if bOpen then
		rlcmd("enable animation blend")
	else
		rlcmd("disable animation blend")
	end
end

--RegisterEvent("SCENE_BEGIN_LOAD", function()
--	m_cplayer.dwMapID = arg0
--	_, m_cplayer.dwMapType = GetMapParams(m_cplayer.dwMapID)
--end
--)
--
--RegisterEvent("PLAYER_ENTER_SCENE", function()
--	local hPlayer = GetClientPlayer()
--	if hPlayer and hPlayer.dwID == arg0 then
--		ClientPlayer_UpdateProperty("dwPlayerID", nil)
--		ClientPlayer_UpdateProperty("bInFight", false)
--	end
--end
--)

local SINGLE_FB_BUFFID = 27896
function UI_CheckPlayerInSingleFB()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	local bInSingleFB = pPlayer.IsHaveBuff(SINGLE_FB_BUFFID, 1)
	if bInSingleFB then
		return true
	else
		return false
	end
end

function UI_PlayerInviteJoinTeam(szPlayer, tInfo)
	if not szPlayer then
		return
	end

	if UI_CheckPlayerInSingleFB() then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CANNOT_JOINTEAM_IN_SINGLEFB)
	elseif tInfo and tInfo.nType and tInfo.nParam then
		GetClientTeam().InviteJoinTeam(tInfo.nType, tInfo.nParam, szPlayer)  -- nType 1挑战发起的组队 2招募发起的组队 3镖师发起的组队
	else
		GetClientTeam().InviteJoinTeam(szPlayer)
	end
end

function UI_PlayerRespondTeamInvite(szInviter, bAgree)
	if not szInviter or bAgree == nil then
		return
	end
	if UI_CheckPlayerInSingleFB() then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CANNOT_JOINTEAM_IN_SINGLEFB)
	else
		GetClientTeam().RespondTeamInvite(szInviter, bAgree)
	end
end

function UI_GetClientPlayerBanEndTime()
	return g_pClientPlayer and g_pClientPlayer.nBanEndTime or 0
end

function UI_SetClientPlayerBanEndTime(_nBanChatEndTime)
	if IsNumber(_nBanChatEndTime) then
		self.nBanChatEndTime = _nBanChatEndTime

		Event.Reg(self, EventType.OnAccountLogout, function ()
			Event.UnReg(self, EventType.OnAccountLogout)
			self.nBanChatEndTime = nil
		end)
	end
end

function UI_IsClientPlayerBaned()
	local nBanEndTime = self.nBanChatEndTime or UI_GetClientPlayerBanEndTime()
	return nBanEndTime >= GetCurrentTime()
end
