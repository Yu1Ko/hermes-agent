local m_ret_func = { }
local m_action = {}
local m_condition = {}
local m_help = {}
local m_break
local m_excute_cd = 1000
local m_excute_id
local m_excute_last_time
local m_last_skill_id = 0
local m_cast_skill_map
local m_bHoardDelayCast = false

local g_MacroInfo = {}
local g_nMainMacro = nil
g_PuppetSkillNameToID = {}
g_PetSkillNameToID = {}

local m_call_puppet = 3109 --qian ji bian
local try_cast

m_ret_func[1] = function(text, pattern)
    local res = {}
    res.cmd_param = string.match(text, pattern)
    if res.cmd_param ~= nil then
        res.cmd = "#"
        return res
    end
end

m_ret_func[2] = function(text, pattern)
    local res = {}
    res.cmd, res.condition, res.cmd_param = string.match(text, pattern)
    if res.cmd ~= nil and res.condition ~= nil and res.cmd_param ~= nil then
        return res
    end
end

m_ret_func[3] = function(text, pattern)
    local res = {}
    res.cmd, res.condition, res.cmd_param = string.match(text, pattern)
    if res.cmd ~= nil and res.condition ~= nil and res.cmd_param ~= nil then
        return res
    end
end

m_ret_func[4] = function(text, pattern)
    local res = {}
    res.cmd, res.cmd_param = string.match(text, pattern)
    if res.cmd ~= nil and res.cmd_param ~= nil then
        return res
    end
end

m_ret_func[5] = function(text, pattern)
    local res = {}
    res.cmd = string.match(text, pattern)
    if res.cmd ~= nil then
        return res
    end
end

local m_tPattern = {
    [1] = { pattern = "#(.+)" },
    [2] = { pattern = "/([^ ]+) +%[(.+)%] +([^ \n]+)" },
    [3] = { pattern = "/([^ ]+) +([^ ]+) +([^ ]+)" },
    [4] = { pattern = "/([^ ]+) +([^ ]+)" },
    [5] = { pattern = "/([^ \n]+) -" },
}

local function SplitLine(macro_text)
    local opts = {}
    macro_text = string.gsub(macro_text, "\r", "") -- 去除换行符在split时 \r的影响
    macro_text = macro_text .. "\n"
    for v, e in string.gmatch(macro_text, "[^\n]+") do
        table.insert(opts, v)
    end
    return opts
end

function GetMacroAction(cmd)
    return m_action[cmd]
end

function GetOptData(line_text)
    local res
    for k, v in ipairs(m_tPattern) do
        res = m_ret_func[k](line_text, v.pattern)
        if res then
            return res
        end
    end
end

local function GetCodeParam(text)
    local code = {
        "~=",
        "<=",
        ">=",
        "<",
        ">",
        "=",
    }

    text = string.gsub(text, "[ ]", "")
    for _, v in pairs(code) do
        local pos, pos_end = string.find(text, v, 1)
        if pos then
            local cmd = string.sub(text, 1, pos - 1)
            local param = string.sub(text, pos_end + 1)
            return cmd, param, v
        end
    end
end

local function GetSingleCondition(text)
    local pos = string.find(text, ":", 1)
    if pos then
        local cmd = string.sub(text, 1, pos - 1)
        local param = string.sub(text, pos + 1)
        return cmd, param
    end
    local cmd, param, code = GetCodeParam(text)
    if cmd then
        return cmd, param, code
    end
    return text
end

local function GetConditionData(param)
    --[c1,c2,c3,c4]
    ----c1==
    ------x:aa|bb|cc
    ------x<aa
    local tCode = {}
    local tRes = {}
    --local cmd, param, code
    --cmd, param, code = GetSingleCondition(v)
    local res1 = SplitString(param, "&")
    local res2
    for _, text1 in pairs(res1) do

        res2 = SplitString(text1, "|")
        table.insert(tCode, "&")

        for k, text2 in ipairs(res2) do

            table.insert(tRes, text2)
            if k ~= 1 then
                table.insert(tCode, "|")
            end
        end
    end
    return tRes, tCode
end

function Macro_GetSkill(skill_name, player)
    if not skill_name then
        return
    end
    if skill_name and type(skill_name) == "number" then
        return skill_name, player.GetSkillLevel(skill_name) -- UseMacroSkill的内置宏释放逻辑中 字符串类型的数字ID会直接转换为number 直接返回相应信息
    end

    local skill_id = g_SkillNameToID[skill_name]
    if not skill_id then
        return
    end

    if type(skill_id) == "number" then
        return skill_id, player.GetSkillLevel(skill_id)
    end

    local skill
    for _, id in pairs(skill_id) do
        local level = player.GetSkillLevel(id)
        if level > 0 then
            skill = GetSkill(id, level)
            if skill.UITestCast(player.dwID, IsSkillCastMyself(skill)) == SKILL_RESULT_CODE.SUCCESS then
                return id, level
            end
        end
    end

    skill_id = skill_id[1]
    if skill_id then
        return skill_id, player.GetSkillLevel(skill_id)
    end
end

local function GetMacroSkill(szName, pPlayer, bNoLimit)
    local nSkillID = g_PuppetSkillNameToID[szName]
    if nSkillID then
        return nSkillID, 1
    end

    nSkillID = g_PetSkillNameToID[szName]
    if nSkillID and pPlayer.dwForceID == FORCE_TYPE.WU_DU then
        return nSkillID, 1
    end

    if bNoLimit and tonumber(szName) then
        nSkillID = tonumber(szName)
        return nSkillID, pPlayer.GetSkillLevel(nSkillID)
    end

    return Macro_GetSkill(szName, pPlayer)
end

--=========================================================

--==== action cmd =========================================

local function AddCmd(key, func, help)
    m_action[key] = func

    if help then
        m_help[key] = help
    end
end

local function JudgeCondition(condition, bNoLimit)
    if not condition then
        return true
    end

    local tRes, tCode = GetConditionData(condition)
    local bJudge = true
    local cmd, param, code
    for k, v in ipairs(tRes) do
        cmd, param, code = GetSingleCondition(v)
        local bFlag = false;
        if m_condition[cmd] then
            bFlag = m_condition[cmd](param, code, nil, bNoLimit)
        end
        if tCode[k] == "&" then
            bJudge = (bJudge and bFlag)

        elseif tCode[k] == "|" then
            bJudge = (bJudge or bFlag)
        end

        if tCode[k + 1] and tCode[k + 1] == "&" and not bJudge then
            return false
        end

        if tCode[k + 1] and tCode[k + 1] == "|" and bJudge then
            return true
        end
    end
    return bJudge
end

local function FliterTarget(tData)
    local tRes = {}
    if not tData then
        return tRes
    end

    local is_player
    for _, dwID in ipairs(tData) do
        is_player = IsPlayer(dwID)
        if (is_player and CanSelectPlayer(dwID)) or (not is_player and CanSelectNpc(dwID)) then
            table.insert(tRes, dwID)
        end
    end
    return tRes
end

local function Help(key)
    local szHelp = aCommandHelp[key]
    if not szHelp or szHelp == "" then
        szHelp = g_tStrings.HELPME_HELP
    end

    if szHelp and szHelp ~= "" then
        OutputMessage("MSG_SYS", szHelp .. "\n")
    end
end

--[[
t =
{
	target = "player"  or "npc" or "all"
	min_radius = 0
	max_radius = 40
	angle = 60
	force = "enemy" or "ally"
}

min_radius = min_radius * 64
max_radius = max_radius * 64
angle = angle * 255 / 360
]]

AddCmd(
        "cast",
        function(skill_name, condition, bNoLimit)
            if JudgeCondition(condition, bNoLimit) then
                return try_cast(skill_name, nil, bNoLimit)
            end
        end
)

AddCmd(
        "fcast",
        function(skill_name, condition, bNoLimit)
            if JudgeCondition(condition, bNoLimit) then
                return try_cast(skill_name, true, bNoLimit)
            end
        end
)

AddCmd(
        "castid",
        function(skill_name, condition, bNoLimit)
            if bNoLimit and JudgeCondition(condition, bNoLimit) then
                return try_cast(skill_name, nil, bNoLimit)
            end
        end
)

AddCmd(
        "casttotarget",
        function(skill_name, condition, bNoLimit)
            if bNoLimit and JudgeCondition(condition, bNoLimit) then
                return try_cast(skill_name, nil, bNoLimit, "target")
            end
        end
)

AddCmd(
        "casttoself",
        function(skill_name, condition, bNoLimit)
            if bNoLimit and JudgeCondition(condition, bNoLimit) then
                return try_cast(skill_name, true, bNoLimit, "self")
            end
        end
)

--[[AddCmd(
"selectP",
function(param, condition)
	if not param then
		return
	end
	if not JudgeCondition(condition) then
		return
	end

	local player
	if param == "myname" then
		player = GetClientPlayer()
		SetTarget(TARGET.PLAYER, player.dwID)
		return
	end

	local players = GetNearbyPlayerList()
	for _, id in pairs(players) do
		player = GetPlayer(id)
		if player and player.szName == param then
			SetTarget(TARGET.PLAYER, player.dwID)
			return
		end
	end
end
)


AddCmd(
"selectN",
function(param, condition)
	if not param then
		return
	end

	if not JudgeCondition(condition) then
		return
	end

	local npc
	local npcs = GetNpcList()
	for _, id in pairs(npcs) do
		npc = GetNpc(id)
		if npc and npc.szName == param then
			SelectTarget(TARGET.NPC, id)
			return
		end
	end
end
)

AddCmd(
"use",
function(item_name, condition)
	if not JudgeCondition(condition) then
		return
	end

	local t = g_ItemNameToID[item_name]
	if t then
    	local dwBox, dwX = GetClientPlayer().GetItemPos(t[1], t[2])
    	if dwBox and dwX then
    		OnUseItem(dwBox, dwX)
    	end
	end
end
)

AddCmd("help", Help, g_tStrings.HELPME_HELP)

AddCmd(
"msg",
function(msg, condition)
	if not JudgeCondition(condition) then
		return
	end
	OutputMessage("MSG_ANNOUNCE_YELLOW", msg)
end

)]]--

--==== condition  =========================

--==== self =======================
local function CalcDistance2(dwSrcCharacterID, dwDstCharacterID)
    local CharacterSrc, CharacterDst = nil
    if IsPlayer(dwSrcCharacterID) then
        CharacterSrc = GetPlayer(dwSrcCharacterID)
    else
        CharacterSrc = GetNpc(dwSrcCharacterID)
    end

    if IsPlayer(dwDstCharacterID) then
        CharacterDst = GetPlayer(dwDstCharacterID)
    else
        CharacterDst = GetNpc(dwDstCharacterID)
    end

    if not CharacterSrc or not CharacterDst then
        return
    end

    local nDis = (CharacterSrc.nX - CharacterDst.nX) * (CharacterSrc.nX - CharacterDst.nX) +
            (CharacterSrc.nY - CharacterDst.nY) * (CharacterSrc.nY - CharacterDst.nY) +
            (CharacterSrc.nZ - CharacterDst.nZ) * (CharacterSrc.nZ - CharacterDst.nZ)
    return nDis
end

local function GetTarget()
    local player = GetClientPlayer()
    local dwTargetType, dwTargetID = player.GetTarget()

    if dwTargetID == 0 then
        return
    end

    if dwTargetType == TARGET.PLAYER then
        return GetPlayer(dwTargetID)
    elseif dwTargetType == TARGET.NPC then
        return GetNpc(dwTargetID)
    end
end

function CompareNumber(szCode, lh_value, rh_value)
    lh_value = tonumber(lh_value)
    rh_value = tonumber(rh_value)
    if szCode == "<" then
        return lh_value < rh_value
    elseif szCode == "<=" then
        return lh_value <= rh_value
    elseif szCode == ">" then
        return lh_value > rh_value
    elseif szCode == ">=" then
        return lh_value >= rh_value
    elseif szCode == "=" then
        return lh_value == rh_value
    elseif szCode == "~=" then
        return lh_value ~= rh_value
    end
end

local function GetBuffData(buff_name, tar, allsrc)
    if not tar then
        tar = GetClientPlayer()
    end

    local count = tar.GetBuffCount()
    local name
    local data = {}
    local self_id = UI_GetClientPlayerID()
    for k = 1, count, 1 do
        Buffer_Get(tar, k - 1, data)
        name = UIHelper.GBKToUTF8(Table_GetBuffName(data.dwID, data.nLevel))
        if name == buff_name then
            if (self_id == tar.dwID) or (data.dwSkillSrcID == self_id) or allsrc then
                return data
            end
        end
    end
end

m_condition["nearby_enemy"] = function(value, code)
    local nNum = GetAreaTargetNum(192)
    return CompareNumber(code, nNum, value)
end

m_condition["skill"] = function(param)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nSkillLevel = pPlayer.GetSkillLevel(param)
    if nSkillLevel and nSkillLevel > 0 then
        return true
    end
end

m_condition["noskill"] = function(param)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return true
    end
    local nSkillLevel = pPlayer.GetSkillLevel(param)
    if nSkillLevel and nSkillLevel > 0 then
        return
    end
    return true
end

m_condition["last_skill"] = function(value, code, ignore1, bNoLimit)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return true
    end
    local nNumberValue = bNoLimit and tonumber(value)
    local bIsEqual = nNumberValue and m_last_skill_id == nNumberValue or m_last_skill_id == value
    if code == "=" then
        return bIsEqual
    else
        return not bIsEqual
    end
end

m_condition["skill_notin_cd"] = function(param, ignore1, ignore2, bNoLimit)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return true
    end
    local nSkillID, nSkillLevel = GetMacroSkill(param, pPlayer, bNoLimit)
    return Skill_NotInCountDown(nSkillID, nSkillLevel, pPlayer)
end

m_condition["cd"] = function(param, code, tar, bNoLimit)
    if not bNoLimit then
        return
    end

    local name, value, code = GetCodeParam(param)
    local player = nil

    if tar then
        player = tar
    else
        player = GetClientPlayer()
    end

    if name and value and code then
        local skill_id, level = GetMacroSkill(name, player, bNoLimit)
        local bCool, nLeft, nTotal = player.GetSkillCDProgress(skill_id, level)
        local nCD = nLeft / GLOBAL.GAME_FPS

        value = tonumber(value)
        if not value then
            return
        end

        return CompareNumber(code, nCD, value)
    end
end

m_condition["buff"] = function(param, tar, allsrc)
    local name, value, code = GetCodeParam(param)
    if name and value and code then
        local data = GetBuffData(name, tar, allsrc)
        if data then
            value = tonumber(value)
            if not value then
                return
            end
            return CompareNumber(code, data.nStackNum, value)
        end
    else
        local data = GetBuffData(param, tar, allsrc)
        if data then
            return true
        end
    end
end

m_condition["nobuff"] = function(param, tar)
    if not GetBuffData(param, tar) then
        return true
    end
end

m_condition["bufftime"] = function(param, tar)
    local name, value, code = GetCodeParam(param)
    if name and value and code then
        local data = GetBuffData(name, tar)
        if not data then
            return
        end

        local nTime = (data.nEndFrame - GetLogicFrameCount()) / 16
        value = tonumber(value)
        if not value then
            return
        end
        return CompareNumber(code, nTime, value)
    end
end

local function GetBuffDataByID(buff_id, tar)
    if not tar then
        tar = GetClientPlayer()
    end

    local id = tonumber(buff_id)
    local count = tar.GetBuffCount()
    local data = {}
    local self_id = UI_GetClientPlayerID()
    for k = 1, count, 1 do
        data.dwID, data.nLevel, data.bCanCancel, data.nEndFrame, data.nIndex, data.nStackNum, data.dwSkillSrcID, data.bValid = tar.GetBuff(k - 1)
        if data.dwID == id then
            if (self_id == tar.dwID) or (data.dwSkillSrcID == self_id) then
                return data
            end
        end
    end
end

m_condition["buffidtime"] = function(param, code, tar, bNoLimit)
    if not bNoLimit then
        return
    end

    local name, value, code = GetCodeParam(param)
    if name and value and code then
        local data = GetBuffDataByID(name, tar)
        if not data then
            return
        end

        local nTime = (data.nEndFrame - GetLogicFrameCount()) / 16
        value = tonumber(value)
        if not value then
            return
        end
        return CompareNumber(code, nTime, value)
    end
end

m_condition["buffid"] = function(param, code, tar, bNoLimit)
    if not bNoLimit then
        return
    end

    local id, value, code = GetCodeParam(param)
    if id and value and code then
        local data = GetBuffDataByID(id, tar)
        if data then
            value = tonumber(value)
            if not value then
                return
            end
            return CompareNumber(code, data.nStackNum, value)
        end
    else
        local data = GetBuffDataByID(param, tar)
        if data then
            return true
        end
    end
end

m_condition["nobuffid"] = function(param, code, tar, bNoLimit)
    if not bNoLimit then
        return
    end

    if not GetBuffDataByID(param, tar) then
        return true
    end
end

m_condition["life"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end
    local per = tar.nCurrentLife / tar.nMaxLife
    return CompareNumber(code, per, value)
end

m_condition["mana"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end

    local per = tar.nCurrentMana / tar.nMaxMana
    return CompareNumber(code, per, value)
end

m_condition["rage"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end
    --tar.nCurrentRage / tar.nMaxRage
    return CompareNumber(code, tar.nCurrentRage, value)
end

m_condition["energy"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end
    return CompareNumber(code, tar.nCurrentEnergy, value)
end

local nNaturePowerOrigin = 100
m_condition["yaoxing"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end
    return CompareNumber(code, tar.nNaturePowerValue - nNaturePowerOrigin, value)
end

m_condition["qidian"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end
    --tar.nCurrentRage / tar.nMaxRage
    return CompareNumber(code, tar.nAccumulateValue, value)
end

m_condition["sun"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end

    local sun = tar.nCurrentSunEnergy
    if Kungfu_GetPlayerMountType() == FORCE_TYPE.MING_JIAO then
        sun = sun / 100
        if value == "moon" then
            value = tar.nCurrentMoonEnergy / 100
        end
    else
        if value == "moon" then
            value = tar.nCurrentMoonEnergy
        end
    end

    return CompareNumber(code, sun, value)
end

m_condition["sun_power"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end
    return (tar.nSunPowerValue > 0)
end

m_condition["moon"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end

    local moon = tar.nCurrentMoonEnergy
    if Kungfu_GetPlayerMountType() == FORCE_TYPE.MING_JIAO then
        moon = moon / 100
        if value == "sun" then
            value = tar.nCurrentSunEnergy / 100
        end
    else
        if value == "sun" then
            value = tar.nCurrentSunEnergy
        end
    end

    return CompareNumber(code, moon, value)
end

m_condition["moon_power"] = function(value, code, tar)
    if not tar then
        tar = GetClientPlayer()
    end
    return (tar.nMoonPowerValue > 0)
end

--[[m_condition["fight"] = function(tar)
	if not tar then
		tar = GetClientPlayer()
	end
	return tar.bFightState
end]]--

m_condition["skill_energy"] = function(param, tar, ignore, bNoLimit)
    if not tar then
        tar = GetClientPlayer()
    end

    local name, value, code = GetCodeParam(param)

    if name and value and code then
        local skill_id = GetMacroSkill(name, tar, bNoLimit)
        if not skill_id then
            return
        end

        local count, cd_id = tar.GetCDMaxCount(skill_id)
        if value == "max" then
            value = count
        end

        if count > 1 then
            local _, nCDCount = tar.GetCDLeft(cd_id)
            return CompareNumber(code, nCDCount, value)
        else
            return CompareNumber(code, 1, value)
        end
    end
end

--==== target =======================

m_condition["tbuff"] = function(param)
    local tar = GetTarget()
    if not tar then
        return
    end

    return m_condition["buff"](param, tar)
end

m_condition["tabuff"] = function(param)
    local tar = GetTarget()
    if not tar then
        return
    end

    return m_condition["buff"](param, tar, true)
end

m_condition["tnobuff"] = function(param)
    local tar = GetTarget()
    if not tar then
        return
    end
    return m_condition["nobuff"](param, tar)
end

m_condition["tbufftime"] = function(param)
    local tar = GetTarget()
    if not tar then
        return
    end
    return m_condition["bufftime"](param, tar)
end

m_condition["npclevel"] = function(value, code)
    local tar = GetTarget()
    if not tar then
        return
    end
    if IsPlayer(tar.dwID) then
        return
    end
    return CompareNumber(code, tar.nIntensity, value)
end

m_condition["target"] = function(param)
    local tar = GetTarget()
    if not tar then
        return
    end

    if param == "all" then
        return true
    end

    if IsPlayer(tar.dwID) then
        return (param == "player")
    else
        return (param == "npc")
    end
end

m_condition["notarget"] = function()
    local tar = GetTarget()
    if not tar then
        return true
    end
end

--[[
m_condition["distance"] = function(value, code)
	local player = GetClientPlayer()
	local dwTargetType, dwTargetID = player.GetTarget()
	local dis2= CalcDistance2(player.dwID, dwTargetID)
	if not dis2 then
		return false
	end

	local fChi = math.sqrt(dis2) / 64
	return CompareNumber(code, fChi, value)
end]]--


--==== pet ============================================================

local nLastTime = 0
local function TigerYellFuncFactory(nActionID)
    return function()
        local player = GetClientPlayer()
        local _, dwTargetID = player.GetTarget()
        if IsPlayer(dwTargetID) then
            return
        end
        local target = GetNpc(dwTargetID)
        if not target then
            return
        end
        if target.dwTemplateID ~= 6823 then
            return
        end
        local nCurrentTime = GetCurrentTime()
        if nCurrentTime - nLastTime <= 5 then
            return
        end
        nLastTime = nCurrentTime
        RemoteCallToServer("OnSpringTigerCommand", nActionID)
    end
end

local function RabbitJumpFuncFactory(nActionID)
    return function()
        local player = GetClientPlayer()
        local _, dwTargetID = player.GetTarget()
        if IsPlayer(dwTargetID) then
            return
        end
        local target = GetNpc(dwTargetID)
        if not target then
            return
        end
        if target.dwTemplateID ~= 10221 and target.dwTemplateID ~= 10488 and target.dwTemplateID ~= 10223 and target.dwTemplateID ~= 10417 and target.dwTemplateID ~= 10222 and target.dwTemplateID ~= 10489 then
            return
        end

        local nCurrentTime = GetCurrentTime()
        if nCurrentTime - nLastTime <= 5 then
            return
        end
        nLastTime = nCurrentTime
        RemoteCallToServer("OnSpringRabbitCommand", nActionID)
    end
end

local function DragonLightFuncFactory(nActionID)
    return function()
        local player = GetClientPlayer()
        local _, dwTargetID = player.GetTarget()
        if IsPlayer(dwTargetID) then
            return
        end
        local target = GetNpc(dwTargetID)
        if not target then
            return
        end
        if target.dwTemplateID ~= 16607 and target.dwTemplateID ~= 16608 and target.dwTemplateID ~= 16644 then
            return
        end

        local nCurrentTime = GetCurrentTime()
        if nCurrentTime - nLastTime <= 5 then
            return
        end
        nLastTime = nCurrentTime
        RemoteCallToServer("On_ChunjieDragon_DoAction", nActionID)
    end
end

local function TangMenPig(nActionID)
    return function()
        local player = GetClientPlayer()
        if not player then
            return
        end
        local _, dwTargetID = player.GetTarget()
        local target = GetNpc(dwTargetID)
        if not target then
            return
        end

        if not (target.dwTemplateID == 15549 or target.dwTemplateID == 15550 or target.dwTemplateID == 15560
                or target.dwTemplateID == 15559 or target.dwTemplateID == 15561) then
            return
        end
        RemoteCallToServer("On_TangMenPig_DoAction", nActionID)
    end
end

local nPlayedCheckTime = 0
local function Played()
    local nCurrentTime = GetCurrentTime()
    if (nCurrentTime - nPlayedCheckTime) < 1 then
        return
    end
    nPlayedCheckTime = nCurrentTime

    RemoteCallToServer("OnPlayedCheckCommand")
end

local function CreateTime()
    local nCurrentTime = GetCurrentTime()
    if (nCurrentTime - nPlayedCheckTime) < 1 then
        return
    end
    nPlayedCheckTime = nCurrentTime

    RemoteCallToServer("OnCreateTimeCheckCommand")
end

local nLastTime = 0
local function Roll(szRollNumber, szRolllow)
    local nCurrentTime = GetCurrentTime()
    if nCurrentTime - nLastTime < 2 then
        return
    end
    nLastTime = nCurrentTime
    if szRollNumber == "help" or szRollNumber == "?" or szRollNumber == "£¿" then
        OutputMessage("MSG_SYS", g_tStrings.HELPME_ROLL .. "\n")
        return
    end
    local nDefaultMin, nDefaultMax = 1, 100

    if not szRollNumber or szRollNumber == "" then
        RemoteCallToServer("ClientNormalRoll", nDefaultMin, nDefaultMax)
        return
    end
    if not szRolllow or szRolllow == "" then
        RemoteCallToServer("ClientNormalRoll", nDefaultMin, tonumber(szRollNumber))
        return
    end

    local nRolllow = tonumber(szRolllow)
    local nRollHigh = tonumber(szRollNumber)

    if nRolllow and nRollHigh and nRolllow < nRollHigh then
        RemoteCallToServer("ClientNormalRoll", nRolllow, nRollHigh)
    else
        RemoteCallToServer("ClientNormalRoll", nDefaultMin, nDefaultMax)
    end
end

local function SkillLog()
    local bOpen = GlobalEventHandler.GetOpenSkillEffectLog()
    GlobalEventHandler.SetOpenSkillEffectLog(not bOpen)
    if not bOpen then
        OutputMessage("MSG_SYS", g_tStrings.STR_SKILL_LOG .. g_tStrings.STR_SKILL_LOG1)
    else
        OutputMessage("MSG_SYS", g_tStrings.STR_SKILL_LOG .. g_tStrings.STR_SKILL_LOG2)
    end
end

local function Perf()
    if PerformanceCollect.IsOpen() then
        PerformanceCollect.Close()
    else
        PerformanceCollect.Open()
    end
end

local bRecord = false
local bReplay = false

local function RecordBegin()
    if not bRecord and not bReplay then
        rlcmd("replay -record 1")
        OutputMessage("MSG_SYS", g_tStrings.STR_REPLAY_VIDEO_BRECORD)
        bRecord = true
    end
end

local function RecordEnd()
    if bRecord then
        rlcmd("replay -record 0")
        local szFolderPath = GetStreamAdaptiveDirPath(GetFilePath("RecordDataDir"))
        rlcmd("replay -save " .. szFolderPath .. "/recorddata.record")
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_REPLAY_VIDEO_ENDRECORD, szFolderPath))
        bRecord = false
    end
end

local function ReplayBegin(szRecordFileName)
    if not bReplay and not bRecord then
        local szFolderPath = GetStreamAdaptiveDirPath(GetFilePath("RecordDataDir"))
        rlcmd("replay -load " .. szFolderPath .. "/" .. szRecordFileName)
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_REPLAY_VIDEO_LOAD_LOCAL, szFolderPath))
        rlcmd("replay -auto switch camera 1")
        rlcmd("replay -replay 1")
        rlcmd("replay -speed 2")
        OutputMessage("MSG_SYS", g_tStrings.STR_REPLAY_VIDEO_BREPLAY)
        bReplay = true
        bPause = false
    end
end

local function ReplayEnd()
    if bReplay then
        rlcmd("replay -replay 0")
        rlcmd("replay -auto switch camera 0")
        rlcmd("replay -reset camera 0")
        OutputMessage("MSG_SYS", g_tStrings.STR_REPLAY_VIDEO_ENDREPLAY)
        bReplay = false
        bPause = false
    end
end

AddCmd(g_tStrings.CHUNJIE_TIGER_COMMAND[1], TigerYellFuncFactory(10150))
AddCmd(g_tStrings.CHUNJIE_TIGER_COMMAND[2], TigerYellFuncFactory(10151))
AddCmd(g_tStrings.CHUNJIE_TIGER_COMMAND[3], TigerYellFuncFactory(10152))
AddCmd(g_tStrings.CHUNJIE_TIGER_COMMAND[4], TigerYellFuncFactory(10153))
AddCmd(g_tStrings.CHUNJIE_TIGER_COMMAND[5], TigerYellFuncFactory(10154))

AddCmd(g_tStrings.CHUNJIE_RABBIT_COMMAND[1], RabbitJumpFuncFactory(10150))
AddCmd(g_tStrings.CHUNJIE_RABBIT_COMMAND[2], RabbitJumpFuncFactory(10151))
AddCmd(g_tStrings.CHUNJIE_RABBIT_COMMAND[3], RabbitJumpFuncFactory(10152))
AddCmd(g_tStrings.CHUNJIE_RABBIT_COMMAND[4], RabbitJumpFuncFactory(10154))
AddCmd(g_tStrings.CHUNJIE_RABBIT_COMMAND[5], RabbitJumpFuncFactory(10153))

AddCmd(g_tStrings.CHUNJIE_DRAGON_COMMAND[1], DragonLightFuncFactory(10030))
AddCmd(g_tStrings.CHUNJIE_DRAGON_COMMAND[2], DragonLightFuncFactory(10031))
AddCmd(g_tStrings.CHUNJIE_DRAGON_COMMAND[3], DragonLightFuncFactory(10032))
AddCmd(g_tStrings.CHUNJIE_DRAGON_COMMAND[4], DragonLightFuncFactory(10033))
AddCmd(g_tStrings.CHUNJIE_DRAGON_COMMAND[5], DragonLightFuncFactory(10001))

AddCmd(g_tStrings.TangMenPig[1], TangMenPig(10154))
AddCmd(g_tStrings.TangMenPig[2], TangMenPig(10155))
AddCmd(g_tStrings.TangMenPig[3], TangMenPig(10156))
AddCmd(g_tStrings.TangMenPig[4], TangMenPig(10157))
AddCmd(g_tStrings.TangMenPig[5], TangMenPig(10158))

AddCmd("played", Played, g_tStrings.HELPME_PLAYED)
AddCmd(g_tStrings.COMMAND_PLAYED.PLAYED, Played, g_tStrings.HELPME_PLAYED)
AddCmd("createtime", CreateTime, g_tStrings.HELPME_CREATETIME)
AddCmd(g_tStrings.COMMAND_PLAYED.CREATETIME, CreateTime, g_tStrings.HELPME_CREATETIME)

AddCmd("roll", Roll, g_tStrings.HELPME_ROLL)
AddCmd("SkillLog", SkillLog)

AddCmd("Perf", Perf)
AddCmd("RecordBegin", RecordBegin)
AddCmd("RecordEnd", RecordEnd)
AddCmd("ReplayBegin", ReplayBegin)
AddCmd("ReplayEnd", ReplayEnd)
--========================================================

try_cast = function(skill_name, force_cast, bNoLimit, castmode)
    local player = GetClientPlayer()
    local level = 1
    local skill_id
    local is_puppet = g_PuppetSkillNameToID._puppet_open

    skill_id = g_PuppetSkillNameToID[skill_name]
    if skill_id then
        return CheckBlackListAddOnUseSkill(skill_id, 1, bNoLimit, castmode)
    end

    skill_id = g_PetSkillNameToID[skill_name]
    if skill_id then
        level = 1
    else
        skill_id, level = Macro_GetSkill(skill_name, player)
    end

    if not skill_id or (not level or level == 0) then
        return
    end

    if not force_cast and is_puppet and m_call_puppet == skill_id then
        return
    end

    if not force_cast and m_bHoardDelayCast then
        return
    end

    local ot_state = player.GetOTActionState()
    if not force_cast and (ot_state == 1 or ot_state == 2 or ot_state == 9) then
        return
    end

    local skill = GetSkill(skill_id, level)
    if skill then
        local nCastRet = CheckBlackListAddOnUseSkill(skill_id, level, bNoLimit, castmode)
        if nCastRet == SKILL_RESULT_CODE.SUCCESS then
            m_cast_skill_map = m_cast_skill_map or {}
            m_cast_skill_map[skill_id] = true
            local tRecipeKey = player.GetSkillRecipeKey(skill_id, level)
            local hSkillInfo = GetSkillInfo(tRecipeKey)
            if hSkillInfo and (hSkillInfo.CastTime > 0 or Table_IsProtectSkill(skill_id)) then
                m_break = true
            elseif skill.bIsChannelSkill then
                m_break = true
            elseif skill.bHoardSkill then
                m_bHoardDelayCast = true
                Timer.Add(SkillData, 0.1, function()
                    m_bHoardDelayCast = false
                end)
                m_break = true
            end
        end
        return nCastRet
    end
end

function GetMacro(dwID)
    local t = g_Macro[dwID]
    if t then
        return t
    end
end

function GetMacroName(dwID)
    local t = g_Macro[dwID]
    if t then
        return t.szName or ""
    end
    return ""
end

function GetMacroIcon(dwID)
    local t = g_Macro[dwID]
    if t then
        return t.nIcon or 0
    end
end

function GetMacroDesc(dwID)
    local t = g_Macro[dwID]
    if t then
        return t.szDesc
    end
    return ""
end

function GetMacroContent(dwID)
    local t = g_Macro[dwID]
    if t then
        return t.szMacro or ""
    end
    return ""
end

function IsMacroRemoved(dwID)
    local t = g_Macro[dwID]
    if not t or t.bRemoved then
        return true
    end
    return false
end

function CanUseMacro(dwID)
    if m_excute_id and m_excute_id ~= dwID and m_excute_cd + m_excute_last_time > GetTickCount() then
        return
    end
    if g_Macro[dwID] then
        return true
    end
end

local function GetTextMacroTextLen(szText)
    local len = UIHelper.GetUtf8Len(szText)
    local tsplit = string.split(szText, "\r\n")
    local nDiff = math.max(0, (#tsplit - 1))
    return len - nDiff
end

function ExcuteMacro(macro_text)
    if not macro_text or (GetTextMacroTextLen(macro_text) > 128 and not IsDebugClient()) then
        return
    end

    local res = SplitLine(macro_text)
    local opt

    m_break = false
    for _, v in ipairs(res) do
        opt = GetOptData(v)
        if opt and m_action[opt.cmd] then
            m_action[opt.cmd](opt.cmd_param, opt.condition)
            if m_break then
                return
            end
        end
    end
    return true
end

function ExcuteMacroByID(dwID)
    local macro_text = GetMacroContent(dwID)
    if macro_text and macro_text ~= "" then
        ExcuteMacro(macro_text)
        if m_excute_id ~= dwID then
            m_excute_id = dwID
            m_excute_last_time = GetTickCount()
        end
    end
end

function RemoveMacro(dwID)
    if g_Macro[dwID] then
        g_Macro[dwID] = { bRemoved = true }
    end
    local argS = arg0
    arg0 = dwID
    FireEvent("ON_REMOVE_MACRO")
    arg0 = argS
    if IsMainMacro(dwID) then
        SetMainMacro(nil)
    end

    g_Macro.Flush()
end

function AddMacro(szName, nIcon, szDesc, szMacro)
    for k, v in ipairs(g_Macro) do
        if v.bRemoved then
            v.szName = szName
            v.nIcon = nIcon
            v.szDesc = szDesc
            v.szMacro = szMacro
            v.bRemoved = nil
            return k
        end
    end

    table.insert(g_Macro, { szName = szName, nIcon = nIcon, szDesc = szDesc, szMacro = szMacro })
    g_Macro.Flush()
    return #g_Macro
end

function SetMacro(dwID, szName, nIcon, szDesc, szMacro)
    if not g_Macro[dwID] then
        return
    end
    g_Macro[dwID] = { szName = szName, nIcon = nIcon, szDesc = szDesc, szMacro = szMacro }
    g_MacroInfo[dwID] = nil
    local argS = arg0
    arg0 = dwID
    FireEvent("ON_CHANGE_MACRO")
    arg0 = argS
    g_Macro.Flush()
end

function IsMainMacro(dwID)
    return g_nMainMacro and g_nMainMacro == dwID
end

function SetMainMacro(dwID)
    g_nMainMacro = dwID
    FireUIEvent("ON_CHANGE_MAIN_MACRO", dwID)
end

function GetMainMacroID()
    return g_nMainMacro
end

function RemoveMainMacroID(dwID)
    if dwID == nil or dwID == g_nMainMacro then
        g_nMainMacro = nil
        FireUIEvent("ON_CHANGE_MAIN_MACRO", nil)
    end
end

function OutputMacroTip(dwID, Rect)
    local szName = GetMacroName(dwID)
    if not szName or szName == "" then
        return
    end
    local szTip = GetFormatText(szName .. "\n", 31)
    szTip = szTip .. GetFormatText(g_tStrings.STR_MARCO .. "\n", 106)
    local szdesc = GetMacroDesc(dwID)
    if szdesc and szdesc ~= "" then
        szTip = szTip .. GetFormatText(szdesc, 100)
    end
    OutputTip(szTip, 400, Rect)
end

function UpdateMacroCDProgress(player, box)
    local dwID = box:GetObjectData()

    if not m_excute_id or dwID == m_excute_id or m_excute_cd <= 0 then
        box:SetObjectCoolDown(false)
        return
    end

    local nLeftTime = m_excute_cd - (GetTickCount() - m_excute_last_time)
    g_MacroInfo[dwID] = g_MacroInfo[dwID] or { bCool = false }

    if nLeftTime <= 0 then
        if g_MacroInfo[dwID].bCool then
            box:SetObjectSparking(true)
        end
        box:SetObjectCoolDown(false)
        g_MacroInfo[dwID].bCool = false
        return 0
    else
        box:SetObjectCoolDown(true)
        if nLeftTime > m_excute_cd then
            nLeftTime = m_excute_cd
        end
        box:SetCoolDownPercentage((m_excute_cd - nLeftTime) / m_excute_cd)
        g_MacroInfo[dwID].bCool = true
        return nLeftTime / 1000 * 16
    end
end

function GetMacroCDProgress(dwID)
    if not m_excute_id or dwID == m_excute_id or m_excute_cd <= 0 then
        return 0, 0
    end

    local nLeftTime = m_excute_cd - (GetTickCount() - m_excute_last_time)
    nLeftTime = math.max(0, nLeftTime)
    return nLeftTime / 1000 * 16, m_excute_cd / 1000 * 16
end

--------------------------------------------------------

local m_nDelayCastFrame = 0 --释放蓄力技能后保护2帧

---@note 用于释放内置宏的函数
function UseMacroSkill(macro_text)
    local pPlayer = GetClientPlayer()
    if not pPlayer or not macro_text then
        return
    end
    if pPlayer.nMoveState == MOVE_STATE.ON_SKILL_MOVE_SRC then
        return
    end

    if m_nDelayCastFrame and m_nDelayCastFrame > 0 then
        m_nDelayCastFrame = m_nDelayCastFrame - 1
        return
    end

    local aState = pPlayer.GetOTActionState()
    if aState == CHARACTER_OTACTION_TYPE.ACTION_SKILL_HOARD then
        return  --蓄力中
    end

    local res = SplitLine(macro_text)
    local opt

    for _, v in ipairs(res) do
        opt = GetOptData(v)
        if opt and GetMacroAction(opt.cmd) then
            --判断宏是否存在
            local nSkillID, nSkillLevel = GetMacroSkill(opt.cmd_param, pPlayer, true)  -- 内置宏在此处统一获取到number形式的技能ID
            if nSkillID and nSkillLevel and nSkillID > 0 and nSkillLevel > 0 then
                --判断技能是否存在
                local pSkill = GetSkill(nSkillID, nSkillLevel)
                local nRet = GetMacroAction(opt.cmd)(nSkillID, opt.condition, true) --释放技能
                if nRet == SKILL_RESULT_CODE.SUCCESS then
                    --print("UseMacroSkill", nSkillID, nSkillLevel, v)
                    local tRecipeKey = pPlayer.GetSkillRecipeKey(nSkillID, nSkillLevel)
                    local hSkillInfo = GetSkillInfo(tRecipeKey)
                    if hSkillInfo and (hSkillInfo.CastTime > 0 or Table_IsProtectSkill(nSkillID)) then
                        break
                    elseif pSkill.bIsChannelSkill then
                        break
                    elseif pSkill.bHoardSkill then
                        m_nDelayCastFrame = 2
                        break
                    end
                end
            end
        end
    end
    return true
end

local function OnCastSkill(nSkillID, nSkillLevel)
    if m_cast_skill_map and m_cast_skill_map[nSkillID] then
        if not IsMobileSkill(nSkillID, nSkillLevel) then
            local szSkillName = Table_GetSkillName(nSkillID, nSkillLevel)
            m_last_skill_id = szSkillName and UIHelper.GBKToUTF8(szSkillName)
        else
            m_last_skill_id = nSkillID
        end
    end
end

local function OnCastSkillCaster(dwCaster, nSkillID, nSkilllLevel)
    if dwCaster == UI_GetClientPlayerID() then
        OnCastSkill(nSkillID, nSkilllLevel)
    end
end

RegisterEvent("DO_SKILL_CAST", function(szEvent)
    OnCastSkillCaster(arg0, arg1, arg2)
end)
RegisterEvent("DO_SKILL_PREPARE_PROGRESS", function(szEvent)
    OnCastSkillCaster(arg3, arg1, arg2)
end)
RegisterEvent("DO_SKILL_CHANNEL_PROGRESS", function(szEvent)
    OnCastSkillCaster(arg3, arg1, arg2)
end)
RegisterEvent("DO_SKILL_HOARD_PROGRESS", function()
    local hPlayer = g_pClientPlayer
    if hPlayer and arg3 == hPlayer.dwID then
        OnCastSkill(arg1, arg2)
    end
end)