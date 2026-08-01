---------------------------------
-- 战斗日志 -- Created By tinymins
---------------------------------
FightLog = {}

PlayTipSound = PlayTipSound or function () end

--------------------------------------------------------------------------------------------------------------------------------------------
-- 全局战斗记录色彩配置
--------------------------------------------------------------------------------------------------------------------------------------------
local KEYWORD_LIST = {
	"NORMAL"      , -- 普通文字
	"NAME"        , -- 姓名
	"SKILL"       , -- 技能/BUFF
	"TOTAL_VALUE" , -- 总数值
	"EFFECT_VALUE", -- 有效数值
	"VALUE_TYPE"  , -- 数值类型
}
local m_tDefaultColor = {
	["MSG_SKILL_SELF_SKILL"               ] = { --"武功技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r =   0, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 130, b =   0},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_SELF_HARMFUL_SKILL"       ] = { --"伤害技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r =   0, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 130, b =   0},
		["TOTAL_VALUE" ] = {r = 255, g = 130, b =   0},
		["EFFECT_VALUE"] = {r = 255, g = 130, b =   0},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_SELF_BE_HARMFUL_SKILL"    ] = { --"受到伤害"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r =   0, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 130, b =   0},
		["TOTAL_VALUE" ] = {r = 255, g =   0, b =   0},
		["EFFECT_VALUE"] = {r = 255, g =   0, b =   0},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_SELF_BENEFICIAL_SKILL"    ] = { --"增益技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r =   0, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b =   0},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b =   0},
		["EFFECT_VALUE"] = {r = 255, g = 255, b =   0},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_SELF_BE_BENEFICIAL_SKILL" ] = { --"受到治疗"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r =   0, g = 255, b = 255},
		["SKILL"       ] = {r =   0, g = 255, b =   0},
		["TOTAL_VALUE" ] = {r =   0, g = 255, b =   0},
		["EFFECT_VALUE"] = {r =   0, g = 255, b =   0},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_SELF_BUFF"                ] = { --"增益信息"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r =   0, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b =   0},
	},
	["MSG_SKILL_SELF_DEBUFF"              ] = { --"减益信息"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g =   0, b =   0},
	},
	["MSG_SKILL_SELF_MISS"                ] = { --"未命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_SELF_FAILED"              ] = { --"运功失败"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b =   0},
	},
	["MSG_SKILL_PARTY_SKILL"              ] = { --"武功技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_PARTY_HARMFUL_SKILL"      ] = { --"伤害技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_PARTY_BE_HARMFUL_SKILL"   ] = { --"受到伤害"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_PARTY_BENEFICIAL_SKILL"   ] = { --"增益技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_PARTY_BE_BENEFICIAL_SKILL"] = { --"受到治疗"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_PARTY_BUFF"               ] = { --"增益信息"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 130, b =   0},
	},
	["MSG_SKILL_PARTY_DEBUFF"             ] = { --"减益信息"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g =   0, b =   0},
	},
	["MSG_SKILL_PARTY_MISS"               ] = { --"未命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_OTHERS_SKILL"             ] = { --"招式命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_OTHERS_HARMFUL_SKILL"     ] = { --"伤害技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_OTHERS_BENEFICIAL_SKILL"  ] = { --"增益技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_OTHERS_MISS"              ] = { --"未命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_NPC_SKILL"                ] = { --"招式命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_NPC_HARMFUL_SKILL"        ] = { --"伤害技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_NPC_BENEFICIAL_SKILL"     ] = { --"增益技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_NPC_MISS"                 ] = { --"未命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_ENEMY_SKILL"              ] = { --"招式命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_ENEMY_HARMFUL_SKILL"      ] = { --"伤害技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_ENEMY_BENEFICAL_SKILL"    ] = { --"增益技能"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
		["TOTAL_VALUE" ] = {r = 255, g = 255, b = 255},
		["EFFECT_VALUE"] = {r = 255, g = 255, b = 255},
		["VALUE_TYPE"  ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SKILL_ENEMY_MISS"               ] = { --"未命中"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
		["SKILL"       ] = {r = 255, g = 255, b = 255},
	},
	["MSG_SELF_KILL"                     ] = { --"击伤"
		["NORMAL"      ] = {r = 255, g =   0, b =   0},
		["NAME"        ] = {r = 255, g =   0, b =   0},
	},
	["MSG_SELF_DEATH"                     ] = { --"重伤"
		["NORMAL"      ] = {r = 255, g =   0, b =   0},
		["NAME"        ] = {r = 255, g =   0, b =   0},
	},
	["MSG_PARTY_KILL"                    ] = { --"击伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
	["MSG_PARTY_DEATH"                    ] = { --"重伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
	["MSG_ENEMY_KILL"                    ] = { --"击伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
	["MSG_ENEMY_DEATH"                    ] = { --"重伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
	["MSG_OTHERS_KILL"                   ] = { --"击伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
	["MSG_OTHERS_DEATH"                   ] = { --"重伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
	["MSG_NPC_KILL"                      ] = { --"击伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
	["MSG_NPC_DEATH"                      ] = { --"重伤"
		["NORMAL"      ] = {r = 255, g = 255, b = 255},
		["NAME"        ] = {r = 255, g = 255, b = 255},
	},
}
m_tKeywordColor = clone(m_tDefaultColor)
--RegisterCustomData("FightLog.m_tKeywordColor")
local m_nVersionTime = 0

local _tCol
local _tDefaultCol = { r = 255, g = 255, b = 255}
function FightLog.GetKeywordColor(szChannel, eType, bUnpack)
	_tCol = m_tKeywordColor[szChannel]
	if _tCol then
		_tCol = _tCol[eType]
	end
	if not _tCol then
		_tCol = _tDefaultCol
	end
	if SM_IsEnable() and _tCol.r == 255 and _tCol.g == 0 and _tCol.b == 0 then
		_tCol.r = 255
		_tCol.g = 126
		_tCol.b = 126;
	end
	if bUnpack then
		return _tCol.r, _tCol.g, _tCol.b
	else
		return clone(_tCol)
	end
end

function FightLog.GetKeywordColorVersionTime()
	return m_nVersionTime
end

function FightLog.SetKeywordColor(szChannel, eType, nR, nG, nB)
	if eType == "NORMAL" then
		SetMsgFontColor(szChannel, nR, nG, nB)
	end

	if SM_IsEnable() and nR == 255 and nG == 0 and nB == 0 then
		nR = 255
		nG = 126
		nB = 126;
	end

	m_nVersionTime = GetCurrentTime()
	m_tKeywordColor[szChannel][eType] = { r = nR or 255, g = nG or 255, b = nB or 255}
	FireUIEvent("ON_FIGHT_LOG_COLOR_CHANGE", szChannel, eType, nR, nG, nB)
end

function FightLog.SetDefaultKeywordColor()
	m_nVersionTime = GetCurrentTime()
	m_tKeywordColor = clone(m_tDefaultColor)
	FireEvent("ON_FIGHT_LOG_COLOR_SET_DEFAULT")
end

function FightLog.GetKeywordColorSettingMenu(szChannel, bShowTitle)
	local tKeyword = m_tKeywordColor[szChannel]
	if not tKeyword then
		return
	end
	local t = {}
	if bShowTitle then
		table.insert(t, 1, MENU_DIVIDER)
		table.insert(t, 1, {
			bDisable = true,
			szOption = g_tStrings.tChannelName[szChannel],
		})
	end
	for _, szType in ipairs(KEYWORD_LIST) do
		local tCol = tKeyword[szType]
		if tCol then
			table.insert(t, {
				bColorTable = true,
				rgb = {tCol.r, tCol.g, tCol.b},
				fnChangeColor = function(UserData, r, g, b) FightLog.SetKeywordColor(szChannel, szType, r, g, b) end,
				szOption = g_tStrings.tFightLogKeyword[szType],
			})
		end
	end
	return t
end

function FightLog.IsFightChannel(szChannel)
	return m_tDefaultColor[szChannel] ~= nil
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- 本地变量与函数
--------------------------------------------------------------------------------------------------------------------------------------------
local DAMAGE_TYPE = {
	[SKILL_RESULT_TYPE.PHYSICS_DAMAGE      ] = g_tStrings.STR_SKILL_PHYSICS_DAMAGE      ,
	[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE  ] = g_tStrings.STR_SKILL_SOLAR_MAGIC_DAMAGE  ,
	[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] = g_tStrings.STR_SKILL_NEUTRAL_MAGIC_DAMAGE,
	[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE  ] = g_tStrings.STR_SKILL_LUNAR_MAGIC_DAMAGE  ,
	[SKILL_RESULT_TYPE.POISON_DAMAGE       ] = g_tStrings.STR_SKILL_POISON_DAMAGE       ,
	[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE   ] = g_tStrings.STR_SKILL_REFLECTIED_DAMAGE   ,
}

local TRANSFER_TYPE = {
	[SKILL_RESULT_TYPE.TRANSFER_LIFE] = g_tStrings.STR_SKILL_LIFE,
	[SKILL_RESULT_TYPE.TRANSFER_MANA] = g_tStrings.STR_SKILL_MANA,
}

local function sendToChat(szContent, szMsgChannel)

	--八荒自己处理战斗信息反馈
	if BahuangData.IsInBahuangDynamic() and (szMsgChannel == "MSG_ANNOUNCE_NORMAL" or szMsgChannel == "MSG_SKILL_SELF_FAILED") then
		BahuangData.AddSkillTip(szContent)
		return
	end

	if szMsgChannel == "MSG_SYS" or szMsgChannel == "MSG_ANNOUNCE_NORMAL" or szMsgChannel == "MSG_SKILL_SELF_FAILED" then
		OutputMessage(szMsgChannel, szContent, true)
		return
	end

	dwTalkerID = 0
	nChannel = CLIENT_PLAYER_TALK_CHANNEL.FIGHT
	ChatData.Append(szContent, dwTalkerID, nChannel)
end

local function checkCanSend(szChannel)
	return ChatData.CheckFightChannelCanRecvMsg(szChannel)
end

local function IsSelfData(dwCharacter)
	local player = GetControlPlayer()
	if not player then
		return false
	end

	if player.dwID == dwCharacter then
		return true
	elseif not IsPlayer(dwCharacter) then
		local Npc = GetNpc(dwCharacter)
		if Npc and Npc.dwEmployer == player.dwID then
			return true
		end
	end
	return false
end

local function IsPartyData(dwCharacter)
	local player = GetClientPlayer()
	if not player then
		return false
	end

	if IsParty(dwCharacter, player.dwID) then
		return true
	elseif not IsPlayer(dwCharacter) then
		local Npc = GetNpc(dwCharacter)
		if Npc and Npc.dwEmployer ~= 0 then
			local hTeam = GetClientTeam()
			if hTeam and hTeam.IsPlayerInTeam(Npc.dwEmployer) then
				return true
			end
		end
	end
	return false
end

local function IsEnemyData(dwCharacter)
	local player = GetClientPlayer()
	if not player then
		return false
	end

	if not IsPlayer(dwCharacter) then
		local KNpc = GetNpc(dwCharacter)
		if KNpc and KNpc.dwEmployer ~= 0 then
			local KTarget = GetPlayer(KNpc.dwEmployer)
			return KTarget and IsEnemy(player.dwID, KTarget.dwID)
		end
	elseif IsEnemy(player.dwID, dwCharacter) then
		return true
	end
	return false
end

local function GetCharacterName(dwID) -- return szName, bNotFind, bIsPlayer, bIsSelf
	local dwSelfID = GetControlPlayer().dwID
	if IsPlayer(dwID) then
		if dwID == dwSelfID then
			return g_tStrings.STR_NAME_YOU, false, true, true
		end
		local szName
		if IsParty(dwID, dwSelfID) then
			szName = TeamData.GetTeammateName(dwID)
		end
		if not szName or szName == "" then
			local KPlayer = GetPlayer(dwID)
			if KPlayer and KPlayer.szName and KPlayer.szName ~= "" then
				szName = KPlayer.szName
			end
		end
		if szName and szName ~= "" then
			return GBKToUTF8(szName), false, true, false
		end
	else
		local KNpc = GetNpc(dwID)
		if KNpc then
			local szName = GBKToUTF8(KNpc.szName)
			if KNpc.dwEmployer and KNpc.dwEmployer ~= 0 then
				local szEmployer, bNotFind, bIsPlayer, bIsSelf = GetCharacterName(KNpc.dwEmployer)
				if bNotFind then
					szEmployer = g_tStrings.STR_SOME_BODY
				end
				if szName ~= "" then
					szName = szEmployer .. g_tStrings.STR_PET_SKILL_LOG .. szName
				else
					szName = szEmployer
				end
			end

			if szName ~= "" then
				return szName, false, false, false
			end
		end
	end
	return g_tStrings.STR_NAME_UNKNOWN, true, false, false
end

local function GetText(szText, szChannel, szType)
	szType = szType or "NORMAL"
	local r, g, b = FightLog.GetKeywordColor(szChannel, szType, true)
	return GetFormatText(szText, GetMsgFont(szChannel), r, g, b, nil, 'this.szKeywordType="' .. szType .. '";')
end

local function GetNameLink(dwID, szChannel)
	local szName, bNotFind, bIsPlayer, bIsSelf, szMsg = GetCharacterName(dwID)
	if bIsSelf then
		szMsg = GetText(szName, szChannel)
	elseif bIsPlayer then
		-- szMsg = MakeNameLink("[" .. szName .. "]", GetMsgFontString(szChannel, FightLog.GetKeywordColor(szChannel, "NAME")) ..
		-- 		' script="this.szKeywordType=\\\"NAME\\\";"', dwID)
		szMsg = string.format("[%s]", szName)
	else
		szMsg = GetText("[" .. szName .. "]", szChannel, "NAME")
	end
	return szMsg, bNotFind, bIsPlayer
end

local function GetSkillLink(dwID, dwLevel, szChannel)
	local szName = Table_GetSkillName(dwID, dwLevel)
	if not string.is_nil(szName) then
		szName = GBKToUTF8(szName)
	end

	if szName == "" then
		return "" -- 屏蔽不显示的技能比如共战
	elseif not szName then
		return GetText(g_tStrings.STR_UNKOWN_SKILL, szChannel, "SKILL")
	else
		-- return MakeSkillLink("[" .. szName .. "]", GetMsgFontString(szChannel, FightLog.GetKeywordColor(szChannel, "SKILL")), {
		-- 	skill_id = dwID,
		-- 	skill_level = dwLevel,
		-- }, 'this.szKeywordType="SKILL";')
		return GetText("[" .. szName .. "]", szChannel, "SKILL")
	end
end

local function GetBuffLink(dwID, dwLevel, szChannel)
	local szName = Table_GetBuffName(dwID, dwLevel)
	if not string.is_nil(szName) then
		szName = GBKToUTF8(szName)
	end

	if szName == "" then
		return -- 屏蔽不显示的BUFF
	elseif not szName then
		return GetText(g_tStrings.STR_UNKOWN_BUFF, szChannel, "SKILL")
	else
		return GetText("[" .. szName .. "]", szChannel, "SKILL")
	end
end

local function GetEffectLink(nType, dwID, dwLevel, szChannel)
	if nType == SKILL_EFFECT_TYPE.SKILL then
		return GetSkillLink(dwID, dwLevel, szChannel)
	elseif nType == SKILL_EFFECT_TYPE.BUFF then
		return GetBuffLink(dwID, dwLevel, szChannel)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- 获取战斗频道
--------------------------------------------------------------------------------------------------------------------------------------------
function FightLog.GetChannelOnSkillCast(dwCaster, nEffectType)
	local szChannel
	if IsSelfData(dwCaster) then
		if nEffectType == SKILL_CAST_EFFECT_TYPE.BENEFICIAL then
			szChannel = "MSG_SKILL_SELF_BENEFICIAL_SKILL"
		elseif nEffectType == SKILL_CAST_EFFECT_TYPE.HARMFUL then
			szChannel = "MSG_SKILL_SELF_HARMFUL_SKILL"
		else
			szChannel = "MSG_SKILL_SELF_SKILL"
		end
	elseif IsPartyData(dwCaster) then
		if nEffectType == SKILL_CAST_EFFECT_TYPE.BENEFICIAL then
			szChannel = "MSG_SKILL_PARTY_BENEFICIAL_SKILL"
		elseif nEffectType == SKILL_CAST_EFFECT_TYPE.HARMFUL then
			szChannel = "MSG_SKILL_PARTY_HARMFUL_SKILL"
		else
			szChannel = "MSG_SKILL_PARTY_SKILL"
		end
	elseif IsEnemyData(dwCaster) then
		if nEffectType == SKILL_CAST_EFFECT_TYPE.BENEFICIAL then
			szChannel = "MSG_SKILL_EMENY_BENEFICIAL_SKILL"
		elseif nEffectType == SKILL_CAST_EFFECT_TYPE.HARMFUL then
			szChannel = "MSG_SKILL_EMENY_HARMFUL_SKILL"
		else
			szChannel = "MSG_SKILL_EMENY_SKILL"
		end
	elseif IsPlayer(dwCaster) then
		if nEffectType == SKILL_CAST_EFFECT_TYPE.BENEFICIAL then
			szChannel = "MSG_SKILL_OTHERS_BENEFICIAL_SKILL"
		elseif nEffectType == SKILL_CAST_EFFECT_TYPE.HARMFUL then
			szChannel = "MSG_SKILL_OTHERS_HARMFUL_SKILL"
		else
			szChannel = "MSG_SKILL_OTHERS_SKILL"
		end
	else
		if nEffectType == SKILL_CAST_EFFECT_TYPE.BENEFICIAL then
			szChannel = "MSG_SKILL_NPC_BENEFICIAL_SKILL"
		elseif nEffectType == SKILL_CAST_EFFECT_TYPE.HARMFUL then
			szChannel = "MSG_SKILL_NPC_HARMFUL_SKILL"
		else
			szChannel = "MSG_SKILL_NPC_SKILL"
		end
	end
	return szChannel
end

function FightLog.GetChannelOnSkillCastRespond(dwCaster)
	return "MSG_SKILL_SELF_FAILED"
end

function FightLog.GetChannelOnReflectiedDamage(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"
	elseif IsPartyData(dwCaster) then
		szChannel = "MSG_SKILL_PARTY_BE_HARMFUL_SKILL"
	elseif IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_HARMFUL_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_BE_HARMFUL_SKILL"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_HARMFUL_SKILL"
	else
		szChannel = "MSG_SKILL_NPC_HARMFUL_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnStealLife(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_BENEFICIAL_SKILL"
	elseif IsPartyData(dwCaster) then
		szChannel = "MSG_SKILL_PARTY_BENEFICIAL_SKILL"
	elseif IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_BENEFICIAL_SKILL"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_BENEFICIAL_SKILL"
	else
		szChannel = "MSG_SKILL_NPC_BENEFICIAL_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnDamageShield(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	elseif IsPartyData(dwCaster) then
		szChannel = "MSG_SKILL_PARTY_SKILL"
	elseif IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_SKILL"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_SKILL"
	else
		szChannel = "MSG_SKILL_NPC_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnDamageAbsorb(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	elseif IsPartyData(dwCaster) then
		szChannel = "MSG_SKILL_PARTY_SKILL"
	elseif IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_SKILL"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_SKILL"
	else
		szChannel = "MSG_SKILL_NPC_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnMiss(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster)
	or IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_MISS"
	elseif IsPartyData(dwCaster) then
		szChannel = "MSG_SKILL_PARTY_MISS"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_MISS"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_MISS"
	else
		szChannel = "MSG_SKILL_NPC_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnHit(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	elseif IsPartyData(dwCaster) or IsPartyData(dwTarget) then
		szChannel = "MSG_SKILL_PARTY_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_SKILL"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_SKILL"
	else
		szChannel = "MSG_SKILL_NPC_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnShield(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) or IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	else
		szChannel = "MSG_SKILL_PARTY_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnDodge(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) or IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	else
		szChannel = "MSG_SKILL_PARTY_SKILL"
	end

	return szChannel
end

function FightLog.GetChannelOnDamageInsight(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) or IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	elseif IsPartyData(dwCaster) then
		szChannel = "MSG_SKILL_PARTY_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_SKILL"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_SKILL"
	else
		szChannel = "MSG_SKILL_NPC_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnDamageParry(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) or IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	else
		szChannel = "MSG_SKILL_PARTY_SKILL"
	end

	return szChannel
end

function FightLog.GetChannelOnDamageTransfer(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_BENEFICIAL_SKILL"
	elseif IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_BENEFICIAL_SKILL"
	elseif IsPlayer(dwCaster) then
		szChannel = "MSG_SKILL_OTHERS_BENEFICIAL_SKILL"
	else
		szChannel = "MSG_SKILL_NPC_BENEFICIAL_SKILL"
	end
	return szChannel
end

function FightLog.GetChannelOnBlock(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) or IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_SKILL"
	else
		szChannel = "MSG_SKILL_PARTY_SKILL"
	end

	return szChannel
end

function FightLog.GetChannelOnDamage(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_HARMFUL_SKILL"
	elseif IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"
	elseif IsPartyData(dwTarget) then
		szChannel = "MSG_SKILL_PARTY_BE_HARMFUL_SKILL"
	elseif IsEnemyData(dwCaster) then
		szChannel = "MSG_SKILL_ENEMY_HARMFUL_SKILL"
	else
		szChannel = "MSG_SKILL_PARTY_HARMFUL_SKILL"
	end

	return szChannel
end

function FightLog.GetChannelOnTherapy(dwCaster, dwTarget)
	local szChannel
	if IsSelfData(dwCaster) then
		szChannel = "MSG_SKILL_SELF_BENEFICIAL_SKILL"
	elseif IsSelfData(dwTarget) then
		szChannel = "MSG_SKILL_SELF_BE_BENEFICIAL_SKILL"
	elseif IsPartyData(dwTarget) then
		szChannel = "MSG_SKILL_PARTY_BE_BENEFICIAL_SKILL"
	else
		szChannel = "MSG_SKILL_PARTY_BENEFICIAL_SKILL"
	end

	return szChannel
end

function FightLog.GetChannelOnCommonHealth(dwTarget, bDecrease)
	local szChannel
	if bDecrease then
		if IsSelfData(dwTarget) then
			szChannel = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"
		elseif IsPartyData(dwTarget) then
			szChannel = "MSG_SKILL_PARTY_BE_HARMFUL_SKILL"
		elseif IsEnemyData(dwTarget) then
			szChannel = "MSG_SKILL_ENEMY_BE_HARMFUL_SKILL"
		else
			szChannel = "MSG_SKILL_OTHERS_BE_HARMFUL_SKILL"
		end
	else
		if IsSelfData(dwTarget) then
			szChannel = "MSG_SKILL_SELF_BE_BENEFICIAL_SKILL"
		elseif IsPartyData(dwTarget) then
			szChannel = "MSG_SKILL_PARTY_BE_BENEFICIAL_SKILL"
		elseif IsEnemyData(dwTarget) then
			szChannel = "MSG_SKILL_ENEMY_BE_BENEFICIAL_SKILL"
		else
			szChannel = "MSG_SKILL_OTHERS_BE_BENEFICIAL_SKILL"
		end
	end
	return szChannel
end

function FightLog.GetChannelOnDeath(dwID, dwKiller)
	local szChannel
	if IsSelfData(dwID) then
		szChannel = "MSG_SELF_DEATH"
	elseif IsSelfData(dwKiller) then
		szChannel = "MSG_SELF_KILL"
	elseif IsPartyData(dwID) then
		szChannel = "MSG_PARTY_DEATH"
	elseif IsPartyData(dwKiller) then
		szChannel = "MSG_PARTY_KILL"
	elseif IsEnemyData(dwID) then
		szChannel = "MSG_ENEMY_DEATH"
	elseif IsEnemyData(dwKiller) then
		szChannel = "MSG_ENEMY_KILL"
	elseif IsPlayer(dwID) then
		szChannel = "MSG_OTHERS_DEATH"
	elseif IsPlayer(dwKiller) then
		szChannel = "MSG_OTHERS_KILL"
	elseif dwKiller > 0 then
		szChannel = "MSG_NPC_KILL"
	else
		szChannel = "MSG_NPC_DEATH"
	end
	return szChannel
end

function FightLog.GetChannelOnBuff(dwTarget, bCanCancel)
	local szChannel
	if bCanCancel then
		if IsSelfData(dwTarget) then
			szChannel = "MSG_SKILL_SELF_BUFF"
		elseif IsPartyData(dwTarget) then
			szChannel = "MSG_SKILL_PARTY_BUFF"
		end
	else
		if IsSelfData(dwTarget) then
			szChannel = "MSG_SKILL_SELF_DEBUFF"
		elseif IsPartyData(dwTarget) then
			szChannel = "MSG_SKILL_PARTY_DEBUFF"
		end
	end
	return szChannel
end

function FightLog.GetSkillRespondText(nRespondCode)
	if AutoBattle.IsInAutoBattle() then
		return "" --自动战斗时不显示技能释放返回提示
	end

	local szMsg
	local player = GetControlPlayer()
	if (nRespondCode == SKILL_RESULT_CODE.INVALID_CAST_MODE) then
		szMsg = g_tStrings.STR_ERROR_SKILL_INVALID_CAST_MODE
		PlayTipSound("025")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_LIFE) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_LIFE
		PlayTipSound("026")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_MANA) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_MANA
		PlayTipSound("027")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_RAGE) then
		local nForceType = Kungfu_GetPlayerMountType(player)
		szMsg = g_tStrings.tNotEnoughRage[nForceType]
        if not szMsg then
            szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_RAGE
            PlayTipSound("028")
        end
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_SUN_ENERGY) then
		local nForceType = Kungfu_GetPlayerMountType(player)
		if nForceType == FORCE_TYPE.BA_DAO then
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_QIJIN
		end

		if nForceType == FORCE_TYPE.MING_JIAO then
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_SUNENERGY
		end
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_MOON_ENERGY) then
		local nForceType = Kungfu_GetPlayerMountType(player)
		if nForceType == FORCE_TYPE.MING_JIAO then
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_MOONENERGY
		end
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_ENERGY) then
		local nForceType = Kungfu_GetPlayerMountType(player)
		szMsg = g_tStrings.tNotEnoughEnergy[nForceType] or ""
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_TRAIN) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_TRAIN
		PlayTipSound("029")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_STAMINA) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_STAMINA
		PlayTipSound("030")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_ITEM) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_ITEM
		PlayTipSound("031")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_AMMO) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_AMMO
		PlayTipSound("033")
	elseif (nRespondCode == SKILL_RESULT_CODE.SKILL_NOT_READY) then
		szMsg = g_tStrings.STR_ERROR_SKILL_SKILL_NOT_READY
		PlayTipSound("058")
	elseif (nRespondCode == SKILL_RESULT_CODE.INVALID_SKILL) then
		szMsg = g_tStrings.STR_ERROR_SKILL_INVALID_SKILL
	elseif (nRespondCode == SKILL_RESULT_CODE.INVALID_TARGET) then
		szMsg = g_tStrings.STR_ERROR_SKILL_INVALID_TARGET
	elseif (nRespondCode == SKILL_RESULT_CODE.NO_TARGET) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NO_TARGET
		PlayTipSound("035")
	elseif (nRespondCode == SKILL_RESULT_CODE.TOO_CLOSE_TARGET) then
		szMsg = g_tStrings.STR_ERROR_SKILL_TOO_CLOSE_TARGET
		PlayTipSound("036")
	elseif (nRespondCode == SKILL_RESULT_CODE.TOO_FAR_TARGET) then
		szMsg = g_tStrings.STR_ERROR_SKILL_TOO_FAR_TARGET
		PlayTipSound("037")
	elseif (nRespondCode == SKILL_RESULT_CODE.OUT_OF_ANGLE) then
		szMsg = g_tStrings.STR_ERROR_SKILL_OUT_OF_ANGLE
		PlayTipSound("038")
	elseif (nRespondCode == SKILL_RESULT_CODE.TARGET_INVISIBLE) then
		szMsg = g_tStrings.STR_ERROR_SKILL_TARGET_INVISIBLE
	elseif (nRespondCode == SKILL_RESULT_CODE.WEAPON_ERROR) then
		szMsg = g_tStrings.STR_ERROR_SKILL_WEAPON_ERROR
		PlayTipSound("039")
	elseif (nRespondCode == SKILL_RESULT_CODE.WEAPON_DESTROY) then
		szMsg = g_tStrings.STR_ERROR_SKILL_WEAPON_DESTROY
		PlayTipSound("040")
	elseif (nRespondCode == SKILL_RESULT_CODE.AMMO_ERROR) then
		szMsg = g_tStrings.STR_ERROR_SKILL_AMMO_ERROR
		PlayTipSound("041")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_EQUIT_AMMO) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_EQUIT_AMMO
	elseif (nRespondCode == SKILL_RESULT_CODE.MOUNT_ERROR) then
		szMsg = g_tStrings.STR_ERROR_SKILL_MOUNT_ERROR
		PlayTipSound("042")
	elseif (nRespondCode == SKILL_RESULT_CODE.IN_OTACTION) then
		szMsg = g_tStrings.STR_ERROR_IN_OTACTION
		PlayTipSound("053")
	elseif (nRespondCode == SKILL_RESULT_CODE.ON_SILENCE) then
		szMsg = g_tStrings.STR_ERROR_SKILL_ON_SILENCE
		PlayTipSound("043")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_FORMATION_LEADER) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_FORMATION_LEADER
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_MEMBER) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_MEMBER
		PlayTipSound("044")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_START_ACCUMULATE) then
		local skill = player.GetActualKungfuMount()
		if skill and skill.dwMountType == 5 then --少林内功
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_FANJIZHI
			PlayTipSound("046")
		else
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_START_ACCUMULATE
			PlayTipSound("045")
		end
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_SUN_MOON_POWER) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_SUN_MOON_POWER
	elseif (nRespondCode == SKILL_RESULT_CODE.SKILL_ERROR) then
		szMsg = g_tStrings.STR_ERROR_SKILL_SKILL_ERROR
	elseif (nRespondCode == SKILL_RESULT_CODE.BUFF_ERROR) then
		szMsg = g_tStrings.STR_ERROR_SKILL_BUFF_ERROR
		PlayTipSound("047")
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_IN_FIGHT) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_IN_FIGHT
	elseif (nRespondCode == SKILL_RESULT_CODE.MOVE_STATE_ERROR) then
		szMsg = FormatString(g_tStrings.STR_ERROR_SKILL_MOVE_STATE_ERROR, g_tStrings.tPlayerMoveState[player.nMoveState])
	elseif (nRespondCode == SKILL_RESULT_CODE.DST_MOVE_STATE_ERROR) then
		local eTargetType, dwTargetID = player.GetTarget()
		local target

		if (eTargetType == TARGET.NPC) then
			target = GetNpc(dwTargetID)
		elseif (eTargetType == TARGET.PLAYER) then
			target = GetPlayer(dwTargetID)
		end

		if target then
			if target.nMoveState == MOVE_STATE.ON_DEATH then
				szMsg = g_tStrings.STR_ERROR_SKILL_TARGET_ON_DEATH
				PlayTipSound("048")
			else
				szMsg = FormatString(g_tStrings.STR_ERROR_SKILL_DST_MOVE_STATE_ERROR, g_tStrings.tPlayerMoveState[target.nMoveState])
			end
		else
			szMsg = g_tStrings.STR_ERROR_SKILL_UNABLE_CAST
		end
	elseif (nRespondCode == SKILL_RESULT_CODE.ERROR_BY_HORSE) then
		if player.bOnHorse then
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ON_HORSE
		else
			PlayTipSound("049")
			szMsg = g_tStrings.STR_ERROR_SKILL_ON_HORSE
		end
	elseif (nRespondCode == SKILL_RESULT_CODE.ERROR_BY_HOLD_HORSE) then
		if player.bHoldHorse then
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_HOLDING_HORSE
		else
			PlayTipSound("049")
			szMsg = g_tStrings.STR_ERROR_SKILL_HOLDING_HORSE
		end
	elseif (nRespondCode == SKILL_RESULT_CODE.BUFF_INVALID) then
		szMsg = g_tStrings.STR_ERROR_SKILL_BUFF_INVALID
	elseif (nRespondCode == SKILL_RESULT_CODE.FORCE_EFFECT) then
		szMsg = g_tStrings.STR_ERROR_SKILL_FORCE_EFFECT
		PlayTipSound("050")
	elseif (nRespondCode == SKILL_RESULT_CODE.BUFF_IMMUNITY) then
		szMsg = g_tStrings.STR_ERROR_SKILL_BUFF_IMMUNITY
		PlayTipSound("051")
	elseif (nRespondCode == SKILL_RESULT_CODE.TARGET_LIFE_ERROR) then
		szMsg = g_tStrings.STR_ERROR_SKILL_TARGET_LIFE_ERROR
	elseif (nRespondCode == SKILL_RESULT_CODE.SELF_LIFE_ERROR) then
		szMsg = g_tStrings.STR_ERROR_SKILL_SELF_LIFE_ERROR
	elseif (nRespondCode == SKILL_RESULT_CODE.MAP_BAN) then
		szMsg = g_tStrings.STR_ERROR_SKILL_MAP_BAN
		PlayTipSound("052")
	elseif (nRespondCode == SKILL_RESULT_CODE.TARGET_STEALTH) then
		szMsg = g_tStrings.STR_ERROR_SKILL_TARGET_STEALTH
	elseif (nRespondCode == SKILL_RESULT_CODE.ERROR_BY_SPRINT) then
		if player.bSprintFlag then
			szMsg = g_tStrings.STR_ERROR_SKILL_NOT_IN_SPRINT
		else
			szMsg = g_tStrings.STR_ERROR_SKILL_IN_SPRINT
		end
	elseif (nRespondCode == SKILL_RESULT_CODE.IMMUNITY_CAST_ID_MISMATCH) then
		szMsg = g_tStrings.STR_ERROR_SKILL_IMMUNITY_CAST_ID_MISMATCH
	elseif (nRespondCode == SKILL_RESULT_CODE.ALTITUDE_TOO_HIGH) then
		szMsg = g_tStrings.STR_ERROR_SKILL_ALTITUDE_TOO_HIGH
	elseif (nRespondCode == SKILL_RESULT_CODE.ALTITUDE_TOO_LOW) then
		szMsg = g_tStrings.STR_ERROR_SKILL_ALTITUDE_TOO_LOW
	elseif (nRespondCode == SKILL_RESULT_CODE.NOT_ENOUGH_SPRINT_POWER) then
		szMsg = g_tStrings.STR_ERROR_SKILL_NOT_ENOUGH_SPRINT_POWER
	elseif nRespondCode == SKILL_RESULT_CODE.SKILL_MOVE_NOT_FINISH_ERROR then
		szMsg = g_tStrings.STR_ERROR_SKILL_MOVE_NOT_FINISH_ERROR
	else
		szMsg = g_tStrings.STR_ERROR_SKILL_UNABLE_CAST
	end

	return szMsg
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- 处理战斗日志
--------------------------------------------------------------------------------------------------------------------------------------------
function FightLog.OnSkillCast(dwCaster, dwSkillID, dwLevel)
	local KSkill = GetSkill(dwSkillID, dwLevel)
	if not KSkill then
		return Log("OnSkillCast: cannot get skill(" .. dwSkillID .. ", " .. dwLevel .. ")" )
	end
	local szChannel = FightLog.GetChannelOnSkillCast(dwCaster, KSkill.nEffectType)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end

	local szMsg = table.concat({
		GetNameLink(dwCaster, szChannel),
		GetText(g_tStrings.STR_SKILL_CAST_LOG, szChannel),
		GetSkillLink(dwSkillID, dwLevel, szChannel),
		GetText(g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

function FightLog.OnSkillCastRespond(dwCaster, dwSkillID, dwLevel, nRespond)
	local szChannel = FightLog.GetChannelOnSkillCastRespond(dwCaster)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szRespond = FightLog.GetSkillRespondText(nRespond)

	local szMsg = table.concat({
		GetNameLink(dwCaster, szChannel),
		GetText(g_tStrings.STR_SKILL_CAST_RESPOND_LOG_1, szChannel),
		GetSkillLink(dwSkillID, dwLevel, szChannel),
		GetText(g_tStrings.STR_SKILL_CAST_RESPOND_LOG_2 .. g_tStrings.STR_COMMA .. szRespond .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

function FightLog.OnSkillRespond(nRespondCode)
	local szMsg = FightLog.GetSkillRespondText(nRespondCode)
	if not szMsg then
		Log("Unexpect skill respond code ("..nRespondCode..")\n")
		return
	end
	sendToChat(szMsg, "MSG_ANNOUNCE_NORMAL")

	if nRespondCode == SKILL_RESULT_CODE.FORCE_EFFECT then
		szMsg = szMsg .. g_tStrings.STR_FULL_STOP
		sendToChat(szMsg, "MSG_SKILL_SELF_FAILED")
	end
end

function FightLog.OnSkillEffectLog(dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, nCount, tResult)
	if nCount <= 2 then
		return
	end

	for _, eValueType in ipairs({
		SKILL_RESULT_TYPE.PHYSICS_DAMAGE, SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE,
		SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE, SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE,
		SKILL_RESULT_TYPE.POISON_DAMAGE
	}) do
		if tResult[eValueType] and tResult[eValueType] > 0 then
			FightLog.OnSkillDamageLog(dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, tResult)
			break
		end
	end

	local nValue = tResult[SKILL_RESULT_TYPE.THERAPY]
	if nValue and nValue > 0 then
		FightLog.OnSkillTherapyLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, bCriticalStrike, tResult)
	end

	nValue = tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE]
	if nValue and nValue > 0 then
		FightLog.OnSkillReflectiedDamageLog(dwCaster, dwTarget, nValue)
	end

	nValue = tResult[SKILL_RESULT_TYPE.STEAL_LIFE]
	if nValue and nValue > 0 then
		FightLog.OnSkillStealLifeLog(dwCaster, dwTarget, nValue)
	end

	nValue = tResult[SKILL_RESULT_TYPE.ABSORB_DAMAGE]
	if nValue and nValue > 0 then
		FightLog.OnSkillDamageAbsorbLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
	end

	nValue = tResult[SKILL_RESULT_TYPE.SHIELD_DAMAGE]
	if nValue and nValue > 0 then
		FightLog.OnSkillDamageShieldLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
	end

	nValue = tResult[SKILL_RESULT_TYPE.PARRY_DAMAGE]
	if nValue and nValue > 0 then
		FightLog.OnSkillDamageParryLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
	end

	nValue = tResult[SKILL_RESULT_TYPE.INSIGHT_DAMAGE]
	if nValue and nValue > 0 then
		FightLog.OnSkillDamageInsightLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
	end

	nValue = tResult[SKILL_RESULT_TYPE.TRANSFER_LIFE]
	if nValue and nValue > 0 then
		FightLog.nSkillDamageTransferLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue, SKILL_RESULT_TYPE.TRANSFER_LIFE)
	end

	nValue = tResult[SKILL_RESULT_TYPE.TRANSFER_MANA]
	if nValue and nValue > 0 then
		FightLog.OnSkillDamageTransferLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue, SKILL_RESULT_TYPE.TRANSFER_MANA)
	end

	nValue = tResult[SKILL_RESULT_TYPE.ABSORB_THERAPY]
	if nValue and nValue > 0 then
		FightLog.OnSkillDamageAbsorbTherapy(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
	end

    nValue = tResult[SKILL_RESULT_TYPE.SPIRIT]
    if nValue then
        FightLog.OnSkillSpiritLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue, "SPIRIT")
    end

    nValue = tResult[SKILL_RESULT_TYPE.STAYING_POWER]
    if nValue then
        FightLog.OnSkillSpiritLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue, "STAYING_POWER")
    end
end

-- 技能伤害
function FightLog.OnSkillDamageLog(dwCaster, dwTarget, bReact, nEffectType, dwID, nLevel, bCriticalStrike, tResult)
	local szChannel = FightLog.GetChannelOnDamage(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind, bCasterIsPlayer = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind, bTargetIsPlayer = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	elseif dwCaster == dwTarget then
		szTargetNameLink = GetText(g_tStrings.STR_NAME_OWN, szChannel, "NAME")
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, nLevel, szChannel)
	if not szSkillLink then
		return
	end

    local szDecoration = Table_GetSkillDecoration(dwID, nLevel)
    if bCriticalStrike or szDecoration ~= "" then
        local szText = ""
        if bCriticalStrike then
            szText = g_tStrings.STR_CS_NAME
        end
        szText = szText .. szDecoration
        szText = FormatString(g_tStrings.STR_ALL_PARENTHESES, szText)
		szSkillLink = table.concat({
			szSkillLink,
			GetText(szText, szChannel, "SKILL")
		})
    end

	local nTotalDamage = 0
	local szDamageLink = ""
	for _, szValueType in ipairs({"PHYSICS_DAMAGE", "SOLAR_MAGIC_DAMAGE", "NEUTRAL_MAGIC_DAMAGE", "LUNAR_MAGIC_DAMAGE", "POISON_DAMAGE"}) do
		local nValue = tResult[SKILL_RESULT_TYPE[szValueType]]
		if nValue and nValue > 0 then
			if szDamageLink ~= "" then
				szDamageLink = szDamageLink .. GetText(g_tStrings.STR_COMMA, szChannel)
			end
			nTotalDamage = nTotalDamage + nValue

			szDamageLink = table.concat({
				szDamageLink,
				GetText(nValue .. g_tStrings.SKILL_DAMAGE_POINT, szChannel, "TOTAL_VALUE"),
				GetText(g_tStrings["STR_SKILL_" .. szValueType] .. g_tStrings.SKILL_DAMAGE_DAMAGE, szChannel, "VALUE_TYPE")
			})
		end
	end
	local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0
	local szMsg = ""

	if not bCasterNotFind or bCasterIsPlayer then -- 未知NPC不显示释放者名字
		szMsg = table.concat({
			szCasterNameLink,
			GetText(g_tStrings.SKILL_DAMAGE_LOG_1, szChannel)
		})
	end

	szMsg = table.concat({
		szMsg,
		szSkillLink,
		GetText(g_tStrings.SKILL_DAMAGE_LOG_2, szChannel),szTargetNameLink,
		GetText(g_tStrings.SKILL_DAMAGE_LOG_3, szChannel),szDamageLink
	})

	if nTotalDamage == nEffectDamage then
		szMsg = table.concat({szMsg, GetText(g_tStrings.STR_FULL_STOP)})
	else
		szMsg = table.concat({
			szMsg,
			GetText(g_tStrings.STR_COMMA .. g_tStrings.SKILL_DAMAGE_LOG_4),
			GetText(nEffectDamage .. g_tStrings.SKILL_DAMAGE_LOG_5, szChannel, "EFFECT_VALUE"),
			GetText(g_tStrings.STR_FULL_STOP)
		})
	end

	sendToChat(szMsg, szChannel)
end


-- 伤害被反弹
function FightLog.OnSkillReflectiedDamageLog(dwCaster, dwTarget, nDamage)
	local szChannel = FightLog.GetChannelOnReflectiedDamage(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_REFLECTIED_DAMAGE_LOG_MSG_1),
		GetText(nDamage .. g_tStrings.STR_SKILL_REFLECTIED_DAMAGE_LOG_MSG_2, szChannel, "TOTAL_VALUE"),
		GetText(g_tStrings.STR_SKILL_REFLECTIED_DAMAGE_LOG_MSG_3),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_REFLECTIED_DAMAGE_LOG_MSG_4),
		szCasterNameLink,
		GetText(g_tStrings.STR_FULL_STOP)
	})

	sendToChat(szMsg, szChannel)
end

-- 普通回血 意外掉血
function FightLog.OnCommonHealthLog(dwTarget, nDeltaLife)
	local szChannel = FightLog.GetChannelOnCommonHealth(dwTarget, nDeltaLife < 0)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	local szMsg

	if nDeltaLife < 0 then
		szMsg = table.concat({
			szTargetNameLink,
			GetText(g_tStrings.STR_SKILL_COMMON_DAMAGE_LOG_MSG_1, szChannel),
			GetText((-nDeltaLife) .. g_tStrings.STR_SKILL_COMMON_DAMAGE_LOG_MSG_2, szChannel, "EFFECT_VALUE"),
			GetText(g_tStrings.STR_SKILL_COMMON_DAMAGE_LOG_MSG_3, szChannel, "VALUE_TYPE"),
			GetText(g_tStrings.STR_FULL_STOP, szChannel)
		})
	elseif nDeltaLife > 0 then
		szMsg = table.concat({
			szTargetNameLink,
			GetText(g_tStrings.STR_SKILL_COMMON_THERAPY_LOG_MSG_1, szChannel),
			GetText(nDeltaLife .. g_tStrings.STR_SKILL_COMMON_THERAPY_LOG_MSG_2, szChannel, "EFFECT_VALUE"),
			GetText(g_tStrings.STR_SKILL_COMMON_THERAPY_LOG_MSG_3, szChannel, "VALUE_TYPE"),
			GetText(g_tStrings.STR_FULL_STOP, szChannel)
		})
	else
		return
	end

	sendToChat(szMsg, szChannel)
end

-- 治疗技能
function FightLog.OnSkillTherapyLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, bCriticalStrike, tResult)
	local szChannel = FightLog.GetChannelOnTherapy(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if szCasterNameLink == nil or szTargetNameLink == nil then return end

	if bCasterNotFind and bTargetNotFind then
		return
	elseif dwCaster == dwTarget then
		szTargetNameLink = GetText(g_tStrings.STR_NAME_OWN, szChannel, "NAME")
	end

	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

    local szDecoration = Table_GetSkillDecoration(dwID, dwLevel)
    if bCriticalStrike or szDecoration ~= "" then
        local szText = ""
        if bCriticalStrike then
            szText = g_tStrings.STR_CS_NAME
        end
        szText = szText .. szDecoration
        szText = FormatString(g_tStrings.STR_ALL_PARENTHESES, szText)
        szSkillLink = table.concat({
            szSkillLink,
            GetText(szText, szChannel, "SKILL")
        })
    end

	local nTotalTherapy = tResult[SKILL_RESULT_TYPE.THERAPY] or 0
	local nEffectTherapy = tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] or 0

	local 	szMsg =  table.concat({
		szCasterNameLink,
		GetText(g_tStrings.SKILL_THERAPY_LOG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.SKILL_THERAPY_LOG_2, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.SKILL_THERAPY_LOG_3, szChannel),
		GetText(nTotalTherapy .. g_tStrings.SKILL_THERAPY_LOG_4, szChannel, "TOTAL_VALUE"),
		GetText(g_tStrings.SKILL_THERAPY_LOG_5, szChannel)
	})

	if nTotalTherapy == nEffectTherapy then
		szMsg =  table.concat({szMsg, GetText(g_tStrings.STR_FULL_STOP)})
	else
		szMsg =  table.concat({
			szMsg,
			GetText(g_tStrings.STR_COMMA .. g_tStrings.SKILL_THERAPY_LOG_6),
			GetText(nEffectTherapy .. g_tStrings.SKILL_THERAPY_LOG_7, szChannel, "EFFECT_VALUE"),
			GetText(g_tStrings.STR_FULL_STOP)
		})
	end

	sendToChat(szMsg, szChannel)
end

-- 偷取生命
function FightLog.OnSkillStealLifeLog(dwCaster, dwTarget, nHealth)
	local szChannel = FightLog.GetChannelOnStealLife(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if szCasterNameLink == nil or szTargetNameLink == nil then return end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_STEAL_LIFE_LOG_MSG_1, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_STEAL_LIFE_LOG_MSG_2, szChannel),
		GetText(nHealth .. g_tStrings.STR_SKILL_STEAL_LIFE_LOG_MSG_3, szChannel, "TOTAL_VALUE"),
		GetText(g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 攻击被吸收
function FightLog.OnSkillDamageAbsorbLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nDamage)
	local szChannel = FightLog.GetChannelOnDamageAbsorb(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if szCasterNameLink == nil or szTargetNameLink == nil then return end

	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_LOG_MSG_2, szChannel),
		GetText(nDamage .. g_tStrings.STR_SKILL_DAMAGE_ABSORB_LOG_MSG_3, szChannel, "EFFECT_VALUE"),
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_LOG_MSG_4, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_LOG_MSG_5 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 攻击被抵消
function FightLog.OnSkillDamageShieldLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nDamage)
	local szChannel = FightLog.GetChannelOnDamageShield(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_SHIELD_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_SHIELD_LOG_MSG_2, szChannel),
		GetText(nDamage .. g_tStrings.STR_SKILL_DAMAGE_SHIELD_LOG_MSG_3, szChannel, "EFFECT_VALUE"),
		GetText(g_tStrings.STR_SKILL_DAMAGE_SHIELD_LOG_MSG_4, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_SHIELD_LOG_MSG_5 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 攻击被招架(拆招)
function FightLog.OnSkillDamageParryLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nDamage)
	local szChannel = FightLog.GetChannelOnDamageParry(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_PARRY_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_PARRY_LOG_MSG_2, szChannel),
		GetText(nDamage .. g_tStrings.STR_SKILL_DAMAGE_PARRY_LOG_MSG_3, szChannel, "EFFECT_VALUE"),
		GetText(g_tStrings.STR_SKILL_DAMAGE_PARRY_LOG_MSG_4, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_PARRY_LOG_MSG_5 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 技能被识破
function FightLog.OnSkillDamageInsightLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nDamage)
	local szChannel = FightLog.GetChannelOnDamageInsight(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_INSIGHT_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_INSIGHT_LOG_MSG_2, szChannel),
		GetText(nDamage .. g_tStrings.STR_SKILL_DAMAGE_INSIGHT_LOG_MSG_3, szChannel, "EFFECT_VALUE"),
		GetText(g_tStrings.STR_SKILL_DAMAGE_INSIGHT_LOG_MSG_4, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_INSIGHT_LOG_MSG_5 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 伤害被吸收
function FightLog.OnSkillDamageTransferLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nDamage, dwTransferType)
	local szChannel = FightLog.GetChannelOnDamageTransfer(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_TRANSFER_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_TRANSFER_LOG_MSG_2, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_TRANSFER_LOG_MSG_3, szChannel),
		GetText(nDamage .. g_tStrings.STR_SKILL_DAMAGE_TRANSFER_LOG_MSG_4, szChannel, "EFFECT_VALUE"),
		GetText(TRANSFER_TYPE[dwTransferType], szChannel, "VALUE_TYPE"),
		GetText(g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 技能被格挡(抵御)
function FightLog.OnSkillBlockLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, dwDamageType)
	local szChannel = FightLog.GetChannelOnBlock(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_2, szChannel),
		GetText(DAMAGE_TYPE[dwDamageType], szChannel, "VALUE_TYPE"),
		GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_3, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_4 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

--远程弹道技能被格挡(抵御)
function FightLog.OnSkillBlockLongRangeLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel)
	local szChannel = FightLog.GetChannelOnBlock(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_2, szChannel),
		GetText(g_tStrings.STR_SKILL_LONG_RANGE_DAMAGE, szChannel, "VALUE_TYPE"),
		GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_3, szChannel),
		szTargetNameLink,GetText(g_tStrings.STR_SKILL_BLOCK_LOG_MSG_4 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 技能无效
function FightLog.OnSkillShieldLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel)
	local szChannel = FightLog.GetChannelOnShield(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_SHIELD_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_SHIELD_LOG_MSG_2, szChannel),
		szTargetNameLink,GetText(g_tStrings.STR_SKILL_SHIELD_LOG_MSG_3 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 未命中
function FightLog.OnSkillMissLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel)
	local szChannel = FightLog.GetChannelOnMiss(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_MISS_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_MISS_LOG_MSG_2 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 技能命中目标
function FightLog.OnSkillHitLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel)
	local szChannel = FightLog.GetChannelOnHit(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_HIT_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_HIT_LOG_MSG_2, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 技能被闪避
function FightLog.OnSkillDodgeLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel)
	local szChannel = FightLog.GetChannelOnDodge(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_DODGE_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_DODGE_LOG_MSG_2, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_DODGE_LOG_MSG_3 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 获得BUFF
function FightLog.OnBuffLog(dwTarget, bCanCancel, dwID, bAddOrDel, nLevel)
	local szChannel = FightLog.GetChannelOnBuff(dwTarget, bCanCancel)
	if not szChannel or not checkCanSend(szChannel)
	or not Table_BuffIsVisible(dwID, nLevel) then
		return
	end
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	local szSkillLink = GetEffectLink(SKILL_EFFECT_TYPE.BUFF, dwID, nLevel, szChannel)
	if not szSkillLink then
		return
	end
	local szMsg
	if bAddOrDel == 0 then
		szMsg = table.concat({
			szSkillLink,
			GetText(g_tStrings.STR_YOU_LOSE_SOME_EFFECT_MSG_1, szChannel),
			szTargetNameLink,
			GetText(g_tStrings.STR_YOU_LOSE_SOME_EFFECT_MSG_2 .. g_tStrings.STR_FULL_STOP, szChannel)
		})
	else
		szMsg = table.concat({
			szTargetNameLink,
			GetText(g_tStrings.STR_YOU_GET_SOME_EFFECT_MSG, szChannel),
			szSkillLink,
			GetText(g_tStrings.STR_FULL_STOP, szChannel)
		})
	end

	sendToChat(szMsg, szChannel)
end

-- 无效BUFF
function FightLog.OnBuffImmunity(dwTarget, bCanCancel, dwID, nLevel, dwCaster)
	local szChannel = FightLog.GetChannelOnBuff(dwTarget, bCanCancel)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	local szSkillLink = GetEffectLink(SKILL_EFFECT_TYPE.BUFF, dwID, nLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szSkillLink,
		GetText(g_tStrings.STR_BUFF_IMMUNITY_LOG_MSG_1, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_BUFF_IMMUNITY_LOG_MSG_2 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 重伤
function FightLog.OnDeathNotify(dwID, dwKiller)
	local szChannel = FightLog.GetChannelOnDeath(dwID, dwKiller)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwID, szChannel)
	local szKillerNameLink, bKillerNotFind = GetNameLink(dwKiller, szChannel)
	if bTargetNotFind then
		return
	end

	if szChannel == "MSG_SELF_DEATH" then
		--教学 重伤
		FireHelpEvent("OnDeath")
	elseif szChannel == "MSG_NPC_DEATH" then
		--教学 击败敌人
		--FireHelpEvent("OnKillEnemy", szKiller, dwID)
		FireHelpEvent("OnKillEnemy", szKillerNameLink, dwID)
	end

	local szMsg
	if bKillerNotFind then
		szMsg = table.concat({szTargetNameLink, GetText(g_tStrings.STR_MSG_BE_KILLED .. g_tStrings.STR_FULL_STOP, szChannel)})
	else
		szMsg = table.concat({
			szKillerNameLink,
			GetText(g_tStrings.STR_MSG_KILLED_PEOPLE, szChannel),
			szTargetNameLink,
			GetText(g_tStrings.STR_FULL_STOP)
		})
	end

	sendToChat(szMsg, szChannel)
end

-- 治疗量被吸收
function FightLog.OnSkillDamageAbsorbTherapy(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nDamage)
	local szChannel = FightLog.GetChannelOnDamageAbsorb(dwCaster, dwTarget)
	if not szChannel or not checkCanSend(szChannel) then
		return
	end
	local szCasterNameLink, bCasterNotFind = GetNameLink(dwCaster, szChannel)
	local szTargetNameLink, bTargetNotFind = GetNameLink(dwTarget, szChannel)
	if bCasterNotFind and bTargetNotFind then
		return
	end
	local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
	if not szSkillLink then
		return
	end

	local szMsg = table.concat({
		szCasterNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_THERAPY_LOG_MSG_1, szChannel),
		szSkillLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_THERAPY_LOG_MSG_2, szChannel),
		szTargetNameLink,
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_THERAPY_LOG_MSG_3, szChannel),
		GetText(nDamage .. g_tStrings.STR_SKILL_DAMAGE_ABSORB_THERAPY_LOG_MSG_4, szChannel, "EFFECT_VALUE"),
		GetText(g_tStrings.STR_SKILL_DAMAGE_ABSORB_THERAPY_LOG_MSG_5 .. g_tStrings.STR_FULL_STOP, szChannel)
	})

	sendToChat(szMsg, szChannel)
end

-- 精神耐力
function FightLog.OnSkillSpiritLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue, szKey)
    local szChannel
    if nValue < 0 then
        szChannel = FightLog.GetChannelOnDamage(dwCaster, dwTarget)
    elseif nValue > 0 then
        szChannel = FightLog.GetChannelOnTherapy(dwCaster, dwTarget)
    end
    if not szChannel or not checkCanSend(szChannel) then
        return
    end
    local szCasterNameLink, bCasterNotFind, bCasterIsPlayer = GetNameLink(dwCaster, szChannel)
    local szTargetNameLink, bTargetNotFind, bTargetIsPlayer = GetNameLink(dwTarget, szChannel)
    if bCasterNotFind and bTargetNotFind then
        return
    elseif dwCaster == dwTarget then
        szTargetNameLink = GetText(g_tStrings.STR_NAME_OWN, szChannel, "NAME")
    end
    local szSkillLink = GetEffectLink(nEffectType, dwID, dwLevel, szChannel)
    if not szSkillLink then
        return
    end
    local szEffect = ""
    if szKey == "SPIRIT" then
        szEffect = g_tStrings.SKILL_SPIRIT
    elseif szKey == "STAYING_POWER" then
        szEffect = g_tStrings.SKILL_STAYING_POWER
    end

    if nValue < 0 then
        szMsg = table.concat({
            szCasterNameLink,
            GetText(g_tStrings.SKILL_THERAPY_LOG_1, szChannel),
            szSkillLink,
            GetText(g_tStrings.SKILL_THERAPY_LOG_2, szChannel),
            szTargetNameLink,
            GetText(g_tStrings.STR_SKILL_COMMON_DAMAGE_LOG_MSG_1, szChannel),
            GetText(-nValue .. g_tStrings.SKILL_THERAPY_LOG_4, szChannel, "EFFECT_VALUE"),
            GetText(szEffect, szChannel, "VALUE_TYPE"),
            GetText(g_tStrings.STR_FULL_STOP, szChannel)
        })
    elseif nValue > 0 then
        szMsg = table.concat({
            szCasterNameLink,
            GetText(g_tStrings.SKILL_THERAPY_LOG_1, szChannel),
            szSkillLink,
            GetText(g_tStrings.SKILL_THERAPY_LOG_2, szChannel),
            szTargetNameLink,
            GetText(g_tStrings.SKILL_THERAPY_LOG_3, szChannel),
            GetText(nValue .. g_tStrings.SKILL_THERAPY_LOG_4, szChannel, "EFFECT_VALUE"),
            GetText(szEffect, szChannel, "VALUE_TYPE"),
            GetText(g_tStrings.STR_FULL_STOP, szChannel)
        })
    else
        return
    end

    sendToChat(szMsg, szChannel)
end

-- 表现通知战斗信息
function FightLog.OnRepresentFightLog(szChannel, szLog)
	szLog = GetText("[战斗回放]") .. szLog
	sendToChat(szLog, szChannel)
end
