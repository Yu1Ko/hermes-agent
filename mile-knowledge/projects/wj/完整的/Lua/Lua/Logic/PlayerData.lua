PlayerData = PlayerData or {className = "PlayerData"}
local self = PlayerData
local registerEvents



function PlayerData.Init()
    PlayerData.CriticalStrikeParam          = 9.985 --会心
    PlayerData.CriticalDamagePowerParam     = 3.679 --会效
    PlayerData.ToughnessParam               = 9.985 --御劲
    PlayerData.DecriticalDamagePowerParam   = 1.521 --化劲
    PlayerData.HitValueParam                = 7.644 --命中
    PlayerData.DodgeParam                   = 4.628 --闪避
    PlayerData.ParryParam                   = 5.432 --招架
    PlayerData.StrainParam                  = 6.734 --无双
    PlayerData.PhysicsShieldParam           = 6.364 --外防
    PlayerData.MagicShieldParam             = 6.364 --内防
    PlayerData.OvercomeParam                = 11.412 --破防
    PlayerData.HasteParam                   = 10.610 --急速
    PlayerData.ToughnessDecirDamageCof      = 2.784 --御劲效果
    PlayerData.SurplusParam                 = 7.421 --破招伤害
    PlayerData.nPlayerNum                   = 0

    self.tPlayers = {}

    registerEvents()
end

function PlayerData.UnInit()
    Event.UnRegAll(self)
end

function PlayerData.OnPlayerEnter(nPlayerID)
    self.tPlayers[nPlayerID] = GetPlayer(nPlayerID)
    self.nPlayerNum = self.nPlayerNum + 1
end

function PlayerData.OnPlayerLeave(nPlayerID)
    self.tPlayers[nPlayerID] = nil
    self.nPlayerNum = self.nPlayerNum - 1
end

function PlayerData.OnReload()
    Event.UnRegAll(self)
    registerEvents()
end

function PlayerData.GetClientPlayer()
    return g_pClientPlayer
end

---comment 获取Player的数量
---@return integer
function PlayerData.GetPlayerNum()
    return self.nPlayerNum
end

---comment 获取角色对象
---@param nPlayerID number
---@return pPlayer userdata
function PlayerData.GetPlayer(nPlayerID)
    return self.tPlayers[nPlayerID]
end

---comment 获取客户端场景中的所有角色
---@return table {nPlayerID = pPlayer, ...}
function PlayerData.GetAllPlayer()
    return self.tPlayers
end

function PlayerData.GetPlayerID(player)
    player = player or g_pClientPlayer
    return player.dwID
end

function PlayerData.GetPlayerName(player)
    player = player or g_pClientPlayer
    return player.szName
end

function PlayerData.GetPlayerLevel(player)
    player = player or g_pClientPlayer
    return player and player.nLevel or 0
end

function PlayerData.GetPlayerExperience(player)
    player = player or g_pClientPlayer
    return player and player.nExperience or 0
end

function PlayerData.GetPlayerRoleType(player)
    player = player or g_pClientPlayer
    return player and player.nRoleType or 0
end

function PlayerData.GetPlayerForceID(player, bSchool)
    if bSchool then
        local dwSchoolID = PlayerData.GetMountBelongSchoolID(player)
        local dwForceID  = Table_SchoolToForce(dwSchoolID)
        return dwForceID
    end
    player = player or GetClientPlayer()
    if not player then return end

    local nForceID = player.dwForceID
    return nForceID or 0
end

function PlayerData.GetPlayerMountKungfuID(player)
    player = player or g_pClientPlayer

    if not player then
        return
    end

    local kungfu = player.GetKungfuMount()
    if kungfu then
        return kungfu.dwSkillID
    else
        return 0
    end
end


function PlayerData.GetMountBelongSchoolID(player)
    local dwBelongSchoolID = 0
	player = player or g_pClientPlayer

    if not player then
        return
    end
	local tKungfu = player.GetKungfuMount()
	if tKungfu then
		dwBelongSchoolID = tKungfu.dwBelongSchool
	end
	return dwBelongSchoolID
end

function PlayerData.GetMountBelongSchoolName()
	local dwBelongSchoolID = PlayerData.GetMountBelongSchoolID()
	local szSchoolName = Table_GetSkillSchoolName(dwBelongSchoolID, true)
	return szSchoolName
end

function PlayerData.GetPlayerCamp(player)
    player = player or g_pClientPlayer

    return player and player.nCamp or CAMP.NEUTRAL
end

function PlayerData.GetPlayerBaseEquipScore(player)
    player = player or g_pClientPlayer

    return player and player.GetBaseEquipScore() or 0
end

function PlayerData.GetPlayerStrengthEquipScore(player)
    player = player or g_pClientPlayer

    return player and player.GetStrengthEquipScore() or 0
end

function PlayerData.GetPlayerMountsEquipScore(player)
    player = player or g_pClientPlayer

    return player and player.GetMountsEquipScore() or 0
end

function PlayerData.GetPlayerTotalEquipScore(player)
    player = player or g_pClientPlayer

    local nScores = 0

    if player then
        local nBaseScores = PlayerData.GetPlayerBaseEquipScore(player)
        local nStrengthScores = PlayerData.GetPlayerStrengthEquipScore(player)
        local nStoneScores = PlayerData.GetPlayerMountsEquipScore(player)
        nScores =  nBaseScores + nStrengthScores + nStoneScores
    end

    return nScores
end

function PlayerData.GetPlayerKillPoints(player)
    player = player or g_pClientPlayer

    local nPoints = 0

    if player then
        nPoints = player.nCurrentKillPoint
    end

    return nPoints
end

function PlayerData.GetPlayerSprintPower(player)
    player = player or g_pClientPlayer

    local nSprintPower = player.nSprintPower
    if nSprintPower < 0 then
        nSprintPower = 0
    end
    local nSprintPowerMax = player.nSprintPowerMax
    if nSprintPowerMax == 0 then
        nSprintPowerMax = 1
    end

    local nHorseSprintPower = player.nHorseSprintPower
    if nHorseSprintPower < 0 then
        nHorseSprintPower = 0
    end

    local nHorseSprintPowerMax = player.nHorseSprintPowerMax
    if nHorseSprintPowerMax == 0 then
        nHorseSprintPowerMax = 1
    end

    local bOnHorse = player.bOnHorse

    return bOnHorse, nSprintPower, nSprintPowerMax, nHorseSprintPower, nHorseSprintPowerMax
end

function PlayerData.GetPlayerItem(player, nBox, nX)
    player = player or g_pClientPlayer
    local item = player.GetItem(nBox, nX)

    return item
end

function PlayerData.HideHat(bHide)
    if g_pClientPlayer then
        g_pClientPlayer.HideHat(bHide)
    end
    CustomData.Dirty(CustomDataType.Global)
end

function PlayerData.GetShowInfo(player)
    player = player or g_pClientPlayer
    if not player then
        return {}
    end
    local tKungfu = player.GetActualKungfuMount()
    if not tKungfu then
        return {}
    end

    local tLine = Table_GetCharInfoShow(tKungfu.dwSkillID)
    if not tLine then
        return {}
    end
    return tLine
end

local function GetAttackTip()
    local player = GetClientPlayer()
    local szAttackTip = FormatString(
        g_tStrings.MSG_SOLAR_NEUTRAL_LUNAR_POISON_ATTACK_POWER,
        player.nSolarAttackPowerBase,
		player.nNeutralAttackPowerBase,
		player.nLunarAttackPowerBase,
		player.nPoisonAttackPowerBase,
		player.nSolarAttackPower,
		player.nNeutralAttackPower,
		player.nLunarAttackPower,
		player.nPoisonAttackPower,
		player.nPhysicsAttackPowerBase,
		player.nPhysicsAttackPower,
		player.nMeleeWeaponDamageBase,
		player.nMeleeWeaponDamageBase+player.nMeleeWeaponDamageRand,
		player.nMeleeWeaponDamageBase+math.floor(player.nMeleeWeaponDamageRand/2)
    )
    return szAttackTip
end

function PlayerData.GetCofValue(player)
    player = player or g_pClientPlayer
    local nCof = 1
    if player.nLevel <= 15 then
        nCof = 50
    elseif player.nLevel <=90 then
        nCof = 4 * player.nLevel -10
    elseif player.nLevel <=95 then
        nCof = 85 * player.nLevel - 7300
    elseif player.nLevel <=100 then
        nCof = 185 * player.nLevel - 16800
    elseif player.nLevel <=110 then
        nCof = 205 * player.nLevel - 18800
    elseif player.nLevel <=120 then
		nCof = 450 * player.nLevel - 45750
	else
		nCof = 1155 * player.nLevel - 130350
    end
    return nCof
end

function PlayerData.GetCriticalStrike(player)
    player = player or g_pClientPlayer
    local tInfo = PlayerData.GetShowInfo()
    local nCof = PlayerData.GetCofValue()

    if tInfo.bShowPhysics2 then
        return player.nPhysicsCriticalStrikeBaseRate + 10000 * player.nPhysicsCriticalStrike / PlayerData.CriticalStrikeParam / nCof
    elseif tInfo.bShowSolar2 then
        return player.nSolarCriticalStrikeBaseRate + 10000 * player.nSolarCriticalStrike / PlayerData.CriticalStrikeParam / nCof
    elseif tInfo.bShowNeutral2 then
        return player.nNeutralCriticalStrikeBaseRate + 10000 * player.nNeutralCriticalStrike / PlayerData.CriticalStrikeParam / nCof
    elseif tInfo.bShowLunar2 then
        return player.nLunarCriticalStrikeBaseRate + 10000 * player.nLunarCriticalStrike / PlayerData.CriticalStrikeParam / nCof
    elseif tInfo.bShowPoison2 then
        return player.nPoisonCriticalStrikeBaseRate + 10000 * player.nPoisonCriticalStrike / PlayerData.CriticalStrikeParam / nCof
    else
        return 0
    end

end

function PlayerData.GetOverCome(player)
    player = player or g_pClientPlayer
    local tInfo = PlayerData.GetShowInfo()
    local nCof = PlayerData.GetCofValue()
    if tInfo.bShowPhysics1 then
        return player.nPhysicsOvercome / PlayerData.OvercomeParam / nCof
    elseif tInfo.bShowSolar1 then
        return player.nSolarOvercome / PlayerData.OvercomeParam / nCof
    elseif tInfo.bShowNeutral1 then
        return player.nNeutralOvercome / PlayerData.OvercomeParam / nCof
    elseif tInfo.bShowLunar1 then
        return player.nLunarOvercome / PlayerData.OvercomeParam / nCof
    elseif tInfo.bShowPoison1 then
        return player.nPoisonOvercome / PlayerData.OvercomeParam / nCof
    else
        return 0
    end

end

function PlayerData.GetHit(player)
    player = player or g_pClientPlayer
    local tInfo = PlayerData.GetShowInfo()
    local nCof = PlayerData.GetCofValue()
    if tInfo.bShowPhysics2 then
        return player.nPhysicsHitBaseRate + 10000 * player.nPhysicsHitValue / PlayerData.HitValueParam / nCof
    elseif tInfo.bShowSolar2 then
        return player.nSolarHitBaseRate + 10000 * player.nSolarHitValue / PlayerData.HitValueParam / nCof
    elseif tInfo.bShowNeutral2 then
        return player.nNeutralHitBaseRate + 10000 * player.nNeutralHitValue / PlayerData.HitValueParam / nCof
    elseif tInfo.bShowLunar2 then
        return player.nLunarHitBaseRate + 10000 * player.nLunarHitValue / PlayerData.HitValueParam / nCof
    elseif tInfo.bShowPoison2 then
        return player.nPoisonHitBaseRate + 10000 * player.nPoisonHitValue / PlayerData.HitValueParam / nCof
    else
        return 0
    end

end

local function GetHitValueTip()
    local player = GetClientPlayer()
    local nCof = PlayerData.GetCofValue()

    local nPhysicsHitRate = player.nPhysicsHitBaseRate / 100 + 100 * player.nPhysicsHitValue / PlayerData.HitValueParam / nCof
    local nPhysicsHitRateAdd = KeepTwoByteFloat(100 * player.nPhysicsHitValue / PlayerData.HitValueParam / nCof).."%"
    local nSolarHitRate = player.nSolarHitBaseRate / 100 + 100 * player.nSolarHitValue / PlayerData.HitValueParam / nCof
    local nSolarHitRateAdd = KeepTwoByteFloat(100 * player.nSolarHitValue / PlayerData.HitValueParam / nCof).."%"
    local nNeutralHitRate = player.nNeutralHitBaseRate / 100 + 100 * player.nNeutralHitValue / PlayerData.HitValueParam / nCof
    local nNeutralHitRateAdd = KeepTwoByteFloat(100 * player.nNeutralHitValue / PlayerData.HitValueParam / nCof).."%"
    local nLunarHitRate = player.nLunarHitBaseRate / 100 + 100 * player.nLunarHitValue / PlayerData.HitValueParam / nCof
    local nLunarHitRateAdd = KeepTwoByteFloat(100 * player.nLunarHitValue / PlayerData.HitValueParam / nCof).."%"
    local nPoisonHitRate = player.nPoisonHitBaseRate / 100 + 100 * player.nPoisonHitValue / PlayerData.HitValueParam / nCof
    local nPoisonHitRateAdd = KeepTwoByteFloat(100 * player.nPoisonHitValue / PlayerData.HitValueParam / nCof).."%"

    local szPhysicsHitRate0   = string.sub(string.format("%.2f",KeepTwoByteFloat(nPhysicsHitRate)), 1, 5).."%"
    local szSolarHitRateBase0   = string.sub(string.format("%.2f",KeepTwoByteFloat(nSolarHitRate)), 1, 5).."%"
    local szNeutralHitRateBase0 = string.sub(string.format("%.2f",KeepTwoByteFloat(nNeutralHitRate)), 1, 5).."%"
    local szLunarHitRateBase0   = string.sub(string.format("%.2f",KeepTwoByteFloat(nLunarHitRate)), 1, 5).."%"
    local szPoisonHitRateBase0  = string.sub(string.format("%.2f",KeepTwoByteFloat(nPoisonHitRate)), 1, 5).."%"

    szTip = FormatString(g_tStrings.MSG_PHYSICS_HIT_VALUE, player.nPhysicsHitValue, nPhysicsHitRateAdd)
    szTip = szTip .. FormatString(g_tStrings.MSG_SOLAR_RATEBase, player.nSolarHitValue, nSolarHitRateAdd)
    szTip = szTip .. FormatString(g_tStrings.MSG_NEUTRAL_RATEBase, player.nNeutralHitValue, nNeutralHitRateAdd)
    szTip = szTip .. FormatString(g_tStrings.MSG_LUNAR_RATEBase, player.nLunarHitValue, nLunarHitRateAdd)
    szTip = szTip .. FormatString(g_tStrings.MSG_POISON_RATEBase, player.nPoisonHitValue, nPoisonHitRateAdd)

    -- szTip = szTip .. GetFormatImage("ui/Image/UICommon/PqUI2.UITex", 17)
    -- szTip = szTip .. g_tStrings.MSG_SOLAR_NEUTRAL_LUNAR_POISON_HIT_VALUE_RATETip_MOBILE
    szTip = szTip ..FormatString(g_tStrings.MSG_SOLAR_NEUTRAL_LUNAR_POISON_HIT_VALUE_RATETip_MOBILE,
                                    szPhysicsHitRate0 , szSolarHitRateBase0, szNeutralHitRateBase0, szLunarHitRateBase0,szPoisonHitRateBase0)
    return szTip
end

local function GetCriticalStrikeTip()
    local player = PlayerData.GetClientPlayer()
    local nCof = PlayerData.GetCofValue()

    local nPhysicsCriticalStrikeRate = KeepTwoByteFloat(player.nPhysicsCriticalStrikeBaseRate/100 + 100 * player.nPhysicsCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nPhysicsCriticalStrikeRateAdd = KeepTwoByteFloat(100 * player.nPhysicsCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nSolarCriticalStrikeRate = KeepTwoByteFloat(player.nSolarCriticalStrikeBaseRate/100 + 100 * player.nSolarCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nSolarCriticalStrikeRateAdd = KeepTwoByteFloat(100 * player.nSolarCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nNeutralCriticalStrikeRate = KeepTwoByteFloat(player.nNeutralCriticalStrikeBaseRate/100 + 100 * player.nNeutralCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nNeutralCriticalStrikeRateAdd = KeepTwoByteFloat(100 * player.nNeutralCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nLunarCriticalStrikeRate = KeepTwoByteFloat(player.nLunarCriticalStrikeBaseRate/100 + 100 * player.nLunarCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nLunarCriticalStrikeRateAdd = KeepTwoByteFloat(100 * player.nLunarCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nPoisonCriticalStrikeRate = KeepTwoByteFloat(player.nPoisonCriticalStrikeBaseRate/100 + 100 * player.nPoisonCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local nPoisonCriticalStrikeRateAdd = KeepTwoByteFloat(100 * player.nPoisonCriticalStrike / PlayerData.CriticalStrikeParam / nCof).."%"
    local szText = FormatString(
        g_tStrings.MSG_SOLAR_NEUTRAL_LUNAR_POISON_CRITICALSTRIKE_VALUE_RATE,
        nSolarCriticalStrikeRate, player.nSolarCriticalStrike, nSolarCriticalStrikeRateAdd,
        nNeutralCriticalStrikeRate, player.nNeutralCriticalStrike, nNeutralCriticalStrikeRateAdd,
        nLunarCriticalStrikeRate, player.nLunarCriticalStrike, nLunarCriticalStrikeRateAdd,
        nPoisonCriticalStrikeRate, player.nPoisonCriticalStrike, nPoisonCriticalStrikeRateAdd,
        nPhysicsCriticalStrikeRate, player.nPhysicsCriticalStrike, nPhysicsCriticalStrikeRateAdd
    )

    return szText
end

local function GetCriticalStrikeDamageTip()
    local player = PlayerData.GetClientPlayer()
    local nCof = PlayerData.GetCofValue()

    local nUnlimitCriticalDamagePowerKiloNumRate = KeepTwoByteFloat(100 * player.nUnlimitCriticalDamagePowerKiloNumRate / 1024)
    local nPhysicsCriticalDamageRateAdd = KeepTwoByteFloat(math.min(100 * player.nPhysicsCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,125)).."%"
    local nSolarCriticalDamageRateAdd = KeepTwoByteFloat(math.min(100 * player.nSolarCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,125)).."%"
    local nNeutralCriticalDamageRateAdd = KeepTwoByteFloat(math.min(100 * player.nNeutralCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,125)).."%"
    local nLunarCriticalDamageRateAdd = KeepTwoByteFloat(math.min(100 * player.nLunarCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,125)).."%"
    local nPoisonCriticalDamageRateAdd = KeepTwoByteFloat(math.min(100 * player.nPoisonCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,125)).."%"
    local nPhysicsCriticalDamageRateFinal = KeepTwoByteFloat(math.min(175 + 100 * player.nPhysicsCriticalDamagePowerBaseKiloNumRate / 1024 + 100 *  player.nPhysicsCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,300)) + nUnlimitCriticalDamagePowerKiloNumRate.."%"
    local nSolarCriticalDamageRateFinal = KeepTwoByteFloat(math.min(175 + 100 * player.nSolarCriticalDamagePowerBaseKiloNumRate / 1024 + 100 * player.nSolarCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,300)) + nUnlimitCriticalDamagePowerKiloNumRate.."%"
    local nNeutralCriticalDamageRateFinal = KeepTwoByteFloat(math.min(175 + 100 * player.nNeutralCriticalDamagePowerBaseKiloNumRate / 1024 + 100 * player.nNeutralCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,300)) + nUnlimitCriticalDamagePowerKiloNumRate.."%"
    local nLunarCriticalDamageRateFinal = KeepTwoByteFloat(math.min(175 + 100 * player.nLunarCriticalDamagePowerBaseKiloNumRate / 1024 + 100 * player.nLunarCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,300)) + nUnlimitCriticalDamagePowerKiloNumRate.."%"
    local nPoisonCriticalDamageRateFinal = KeepTwoByteFloat(math.min(175 + 100 * player.nPoisonCriticalDamagePowerBaseKiloNumRate / 1024 + 100 * player.nPoisonCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof,300)) + nUnlimitCriticalDamagePowerKiloNumRate.."%"
	local szUnlimitCriticalDamagePowerKiloNumRate = nUnlimitCriticalDamagePowerKiloNumRate.."%"

    local szText = FormatString(
        g_tStrings.MSG_SOLAR_NEUTRAL_LUNAR_POISON_CRITICALSTRIKE_DAMAGE_POWER,
        player.nSolarCriticalDamagePower, nSolarCriticalDamageRateAdd,
        player.nNeutralCriticalDamagePower, nNeutralCriticalDamageRateAdd,
        player.nLunarCriticalDamagePower, nLunarCriticalDamageRateAdd,
        player.nPoisonCriticalDamagePower, nPoisonCriticalDamageRateAdd,
        "300%",
        player.nPhysicsCriticalDamagePower, nPhysicsCriticalDamageRateAdd,
        nPhysicsCriticalDamageRateFinal,nSolarCriticalDamageRateFinal,
        nNeutralCriticalDamageRateFinal,nLunarCriticalDamageRateFinal,
        nPoisonCriticalDamageRateFinal,
        szUnlimitCriticalDamagePowerKiloNumRate
    )

    return szText
end

local function GetOvercomeTip()
    local player = GetClientPlayer()
    local nCof = PlayerData.GetCofValue()
    local szTip = FormatString(g_tStrings.MSG_PHYSICS_OVERCOME_DOWN, KeepTwoByteFloat(100 * player.nPhysicsOvercome / PlayerData.OvercomeParam / nCof).."%", player.nPhysicsOvercomeBase, player.nPhysicsOvercome) .. "\n"
    szTip = szTip .. FormatString(g_tStrings.MSG_SOLAR_OVERCOME_DOWN, KeepTwoByteFloat(100 * player.nSolarOvercome / PlayerData.OvercomeParam / nCof).."%", player.nSolarOvercomeBase, player.nSolarOvercome) .. "\n"
    szTip = szTip .. FormatString(g_tStrings.MSG_NEUTRAL_OVERCOME_DOWN, KeepTwoByteFloat(100 * player.nNeutralOvercome / PlayerData.OvercomeParam / nCof).."%", player.nNeutralOvercomeBase, player.nNeutralOvercome) .. "\n"
    szTip = szTip .. FormatString(g_tStrings.MSG_LUNAR_OVERCOME_DOWN, KeepTwoByteFloat(100 * player.nLunarOvercome / PlayerData.OvercomeParam / nCof).."%", player.nLunarOvercomeBase, player.nLunarOvercome) .. "\n"
    szTip = szTip .. FormatString(g_tStrings.MSG_POISON_OVERCOME_DOWN, KeepTwoByteFloat(100 * player.nPoisonOvercome / PlayerData.OvercomeParam / nCof).."%", player.nPoisonOvercomeBase, player.nPoisonOvercome)
    return szTip
end

function PlayerData.GetCriticalStrikeDamage(player)
    player = player or g_pClientPlayer
    local tInfo = PlayerData.GetShowInfo()
    local nCof = PlayerData.GetCofValue()
    if tInfo.bShowPhysics2 then
        return player.nPhysicsCriticalDamagePowerBaseKiloNumRate/10 + 100 * player.nPhysicsCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof
    elseif tInfo.bShowSolar2 then
        return player.nSolarCriticalDamagePowerBaseKiloNumRate/10 + 100 * player.nSolarCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof
    elseif tInfo.bShowNeutral2 then
        return player.nNeutralCriticalDamagePowerBaseKiloNumRate/10 + 100 * player.nNeutralCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof
    elseif tInfo.bShowLunar2 then
        return player.nLunarCriticalDamagePowerBaseKiloNumRate/10 + 100 * player.nLunarCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof
    elseif tInfo.bShowPoison2 then
        return player.nPoisonCriticalDamagePowerBaseKiloNumRate/10 + 100 * player.nPoisonCriticalDamagePower / PlayerData.CriticalDamagePowerParam / nCof
    else
        return 0
    end
end

function PlayerData.GetAttackPower(player)
    player = player or g_pClientPlayer
    local tInfo = PlayerData.GetShowInfo()
    local nCof = PlayerData.GetCofValue()
    if tInfo.bShowPhysics1 then
        return player.nPhysicsAttackPower/10
    elseif tInfo.bShowSolar1 then
        return player.nSolarAttackPower/12
    elseif tInfo.bShowNeutral1 then
        return player.nNeutralAttackPower/12
    elseif tInfo.bShowLunar1 then
        return player.nLunarAttackPower/12
    elseif tInfo.bShowPoison1 then
        return player.nPoisonAttackPower/12
    else
        return 0
    end

end

function PlayerData.GetRunSpeed(player)
    player = player or GetClientPlayer()
    if player.bSprintFlag then
        return player.nRunSpeed
    end

    local nRunSpeed = math.max(player.nRunSpeed, player.nMinRunSpeed)
    nRunSpeed = math.min(nRunSpeed, player.nMaxRunSpeed)
    return nRunSpeed
end

function PlayerData.GetPVXAllRound(player)
    player = player or GetClientPlayer()
    local nPVXAllRound = 0
    if not player then
        return nPVXAllRound
    end

    nPVXAllRound = player.nPVXAllRound
    return nPVXAllRound
end

local function GetBuffListTemp(obj)
    if not obj then
        return
    end
    local tbuff = {}
    local nBuffCount = obj.GetBuffCount()
    if nBuffCount and nBuffCount > 0 then
        local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid
        for i = 1, nBuffCount, 1 do
            dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = obj.GetBuff(i - 1)
            table.insert(tbuff,{['dwID'] = dwID,['nLevel'] = nLevel,['bCanCancel'] = bCanCancel,['nEndFrame'] = nEndFrame,['nIndex'] = nIndex,['nStackNum'] = nStackNum,['dwSkillSrcID'] = dwSkillSrcID,['bValid'] = bValid})
        end
    end
    return tbuff
end

function PlayerData.GetPVXAllRoundTip(player)
    player = player or GetClientPlayer()
    local tzlxf = {
        [10176] = {"Heal"}, --补天
        [10080] = {"Heal"}, --云裳
        [10028] = {"Heal"}, --离经
        [10448] = {"Heal"}, --相知
        [10626] = {"Heal"}, --灵素
        [100655] = {"Heal"}, --移动端_补天
        [100409] = {"Heal"}, --移动端_云裳
        [100411] = {"Heal"}, --移动端_离经
        [101125] = {"Heal"}, --移动端_相知
        [101374] = {"Heal"}, --移动端_灵素
        }
    local szTip

    if tzlxf[player.GetKungfuMountID()] then
		local nPVXTherapyAllRound = math.floor(player.nPVXAllRound/4)
        local tBuffList = GetBuffListTemp(GetClientPlayer())
		szTip = FormatString(g_tStrings.MSG_PVXAll_ROUND_TIPS2Heal, nPVXTherapyAllRound, player.nPVXAllRound)
	else
		local pz = math.floor(player.nPVXAllRound/2)
		local ws = math.floor(player.nPVXAllRound*3/2)

		szTip = FormatString(g_tStrings.MSG_PVXAll_ROUND_TIPS, pz, ws, player.nPVXAllRound)
	end

    return szTip
end

function PlayerData.GetAttribValue(player)
    player = player or g_pClientPlayer

    local nCof = PlayerData.GetCofValue(player)

    local fnProcessHit = function(szAttr)
        local szHitBaseRate = "n" .. szAttr .. "HitBaseRate"
        local szHitValue = "n" .. szAttr .. "HitValue"
        return player[szHitBaseRate] + 10000 * player[szHitValue] / PlayerData.HitValueParam / nCof
    end

    local fnProcessCriticalStrike = function(szAttr)
        local szHitBaseRate = "n" .. szAttr .. "CriticalStrikeBaseRate"
        local szHitValue = "n" .. szAttr .. "CriticalStrike"
        return player[szHitBaseRate] + 10000 *player[szHitValue] / PlayerData.CriticalStrikeParam / nCof
    end

    local fnProcessCriticalDamage = function(szAttr)
        local szRate = "n" .. szAttr .. "CriticalDamagePowerBaseKiloNumRate"
        local szValue = "n" .. szAttr .. "CriticalDamagePower"

        local fUnlimitCriticalDamagePowerKiloNumRate = KeepTwoByteFloat(100 * player.nUnlimitCriticalDamagePowerKiloNumRate / 1024)
        local fBase = math.min(player[szRate]/10 + 175 + 100 * player[szValue] / PlayerData.CriticalDamagePowerParam / nCof, 300)
        return fBase + fUnlimitCriticalDamagePowerKiloNumRate
    end

    local fnProcessMagicShield = function(szAttr)
        local szShield = "n" .. szAttr .. "MagicShield"
        return math.max(0,math.min(100 * player[szShield] /(PlayerData.MagicShieldParam * nCof + player[szShield]) , 75))
    end

    local tbValue =
    {
        --base
        player.nCurrentVitality, --体质
        player.nCurrentSpirit,   --根骨
        player.nCurrentStrength, --力道
        player.nCurrentAgility,  --身法
        player.nCurrentSpunk,    --元气

        player.nTherapyPower,--治疗量

        -- 攻击力
        player.nPhysicsAttackPower,
        fnProcessHit("Physics"),
        fnProcessCriticalStrike("Physics"),
        fnProcessCriticalDamage("Physics"),

        player.nSolarAttackPower,
        fnProcessHit("Solar"),
        fnProcessCriticalStrike("Solar"),
        fnProcessCriticalDamage("Solar"),

        player.nNeutralAttackPower,
        fnProcessHit("Neutral"),
        fnProcessCriticalStrike("Neutral"),
        fnProcessCriticalDamage("Neutral"),

        player.nLunarAttackPower,
        fnProcessHit("Lunar"),
        fnProcessCriticalStrike("Lunar"),
        fnProcessCriticalDamage("Lunar"),

        player.nPoisonAttackPower,
        fnProcessHit("Poison"),
        fnProcessCriticalStrike("Poison"),
        fnProcessCriticalDamage("Poison"),

        --加速
        math.max(100*player.nCurrentHasteRate/1024),

        --破防
        string.format("%.2f", (100 * player.nPhysicsOvercome / PlayerData.OvercomeParam / nCof)).."%",
        string.format("%.2f", (100 * player.nSolarOvercome / PlayerData.OvercomeParam / nCof)).."%",
        string.format("%.2f", (100 * player.nNeutralOvercome / PlayerData.OvercomeParam / nCof)).."%",
        string.format("%.2f", (100 * player.nLunarOvercome / PlayerData.OvercomeParam / nCof)).."%",
        string.format("%.2f", (100 * player.nPoisonOvercome / PlayerData.OvercomeParam / nCof)).."%",

        --无双
        10000 * player.nStrain / PlayerData.StrainParam / nCof + player.nStrainRate/1024 * 10000,

        --破招
        player.nSurplusValue,

        --外功防御
        math.max(0,math.min(100 * player.nPhysicsShield / (PlayerData.PhysicsShieldParam * nCof + player.nPhysicsShield), 75)),

        --内功防御
        math.max(
            fnProcessMagicShield("Solar"),
            fnProcessMagicShield("Neutral"),
            fnProcessMagicShield("Lunar"),
            fnProcessMagicShield("Poison")
        ),

        player.nDodgeBaseRate + 10000 * player.nDodge / (PlayerData.DodgeParam * nCof + player.nDodge), --闪躲
        player.nParryBaseRate + 10000 * player.nParry / (PlayerData.ParryParam * nCof + player.nParry), --招架
        player.nParryValue,--拆招
        player.nToughnessBaseRate + 10000 * player.nToughness / PlayerData.ToughnessParam / nCof, --御劲
        math.min(player.nDecriticalDamagePowerBaseKiloNumRate /1024*10000 + 10000 * player.nDecriticalDamagePower / (PlayerData.DecriticalDamagePowerParam * nCof + player.nDecriticalDamagePower), 8000), --化劲

        player.nLifeReplenish * (1024 + player.nLifeReplenishCoefficient) / 1024 + player.nLifeReplenishExt + player.nMaxLife * player.nLifeReplenishPercent / 1024, --气血回转
        player.nManaReplenish * (1024 + player.nManaReplenishCoefficient) / 1024 + player.nManaReplenishExt + player.nMaxMana * player.nManaReplenishPercent / 1024, --内力回转
        PlayerData.GetRunSpeed(player),--跑速

        PlayerData.GetPVXAllRound(player),--全能
    }

    return tbValue
end

function PlayerData.GetAttackAndToughScore()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local nAttackScore = 100
    local nToughScore = 200
    local nTherapyScore = 300
    local nCof = PlayerData.GetCofValue(player)

    local nHitRate = PlayerData.GetHit(player)/10000										--	命中
    local nCriticalStrikeRate = PlayerData.GetCriticalStrike(player)/10000				--	会心
    local nCriticalStrikeDamageRate = PlayerData.GetCriticalStrikeDamage(player)/100		--	会效
    local nOverComeRate = PlayerData.GetOverCome(player)									--	破防
    local nAttackPower = PlayerData.GetAttackPower(player) * 10								--	攻击AP
    local nStrainRate = player.nStrain / PlayerData.StrainParam / nCof				--	无双
    local nSurPlusToAP = player.nSurplusValue * PlayerData.SurplusParam /10 /3				--	破招转攻击力
    local nHasetRate = math.max(player.nCurrentHasteRate/1024, math.min(player.nHasteRateBasePercentAdd / 1024 + player.nHasteBase / PlayerData.HasteParam / nCof, 0.25))										--	急速
--	 Output(nHitRate,nCriticalStrikeRate,nCriticalStrikeDamageRate,nOverComeRate,nAttackPower,nStrainRate,nHasetRate)
    --计算攻击评分
    nAttackScorePVE = (nAttackPower + nSurPlusToAP) * 1.3*( 1 + nCriticalStrikeRate * ( 0.75 + nCriticalStrikeDamageRate)) * ( 1 + nOverComeRate) * ( 1 + nHasetRate) * ( 1 + nStrainRate)
    nAttackScorePVP = nAttackPower * 1.3 * ( 1 + nCriticalStrikeRate * ( 0.75 + nCriticalStrikeDamageRate)) * ( 1 + nOverComeRate) * ( 1 + nHasetRate)
    local nTherapyValue = player.nTherapyPower
    nTherapyScore = nTherapyValue * ( 1 + nCriticalStrikeRate * ( 0.75 + nCriticalStrikeDamageRate)) * ( 1 + nHasetRate)
    local nMaxLife = player.nMaxLife/10
    local nPhysicsShield = math.min(player.nPhysicsShield / (PlayerData.PhysicsShieldParam * nCof + player.nPhysicsShield), 0.75)
    local nMagicShield = math.min(player.nSolarMagicShield / (PlayerData.MagicShieldParam * nCof + player.nSolarMagicShield), 0.75)
    local nDodgeRate = player.nDodge / (PlayerData.DodgeParam * nCof + player.nDodge)
    local nParryRate = player.nParry / (PlayerData.ParryParam * nCof + player.nParry)
    local nParryValueEffect = math.min(player.nParryValue/nMaxLife/0.2,1)
    local nToughnessRate = math.min(player.nToughnessBaseRate/10000 + player.nToughness / PlayerData.ToughnessParam / nCof,0.3)
    local nDecriticalDamagePowerRate = player.nDecriticalDamagePowerBaseKiloNumRate /1024 + math.min(player.nDecriticalDamagePower / (PlayerData.DecriticalDamagePowerParam * nCof + player.nDecriticalDamagePower), 0.75)

    --计算坚韧评分
    nToughScorePVE = 0.7 * nMaxLife/(1 - nPhysicsShield) / (1 - nMagicShield) /  (1 - nDodgeRate) / (1 - nParryRate * nParryValueEffect) *(1+ 0.15*2.5)/( 1+ (0.15- nToughnessRate)*2.5 * (1 - nToughnessRate/PlayerData.ToughnessParam * PlayerData.ToughnessDecirDamageCof))
    nToughScorePVP = 0.7 * nMaxLife/(1 - nPhysicsShield) / (1 - nMagicShield) /  (1 - nDodgeRate) / (1 - nParryRate * nParryValueEffect) / ( 1 - nDecriticalDamagePowerRate)*(1+ 0.3*2.1)/( 1+ (0.3- nToughnessRate)*2.1 * (1 - nToughnessRate/PlayerData.ToughnessParam * PlayerData.ToughnessDecirDamageCof))

    return math.floor(nAttackScorePVP), math.floor(nToughScorePVP), math.floor(nTherapyScore), math.floor(nAttackScorePVE), math.floor(nToughScorePVE), math.floor(nTherapyScore)
end


local function InsertAttackValue1(tbInfo, nIndex, bTherapyMainly, tbValue)
        if not bTherapyMainly then
            table.insert(tbInfo, {
                nType = 2,
                szName = g_tStrings.PLAYER_ATTRIB_NAME.ATTACK,
                szValue = tostring(tbValue[nIndex]),
                szTip = GetAttackTip(),
            })
        end
end


local function InsertAttackValue2(tbInfo, nIndex, tbValue)
    local szHitValue = string.format("%.2f", (tbValue[nIndex]/100)).."%"
    table.insert(tbInfo, {
        nType = 2,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.HIT,
        szValue = szHitValue,
        szTip = GetHitValueTip(),
    })

    local szCriticalStrike = string.format("%.2f", (tbValue[nIndex + 1]/100)).."%"
    table.insert(tbInfo, {
        nType = 2,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.CRITICALSTRIKE,
        szValue = szCriticalStrike,
        szTip = GetCriticalStrikeTip()
    })

    local szCriticalStrikeDamage = string.format("%.2f", (tbValue[nIndex + 2])).."%"
    table.insert(tbInfo, {
        nType = 2,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.CRITICALSTRIKE_DAMAGE,
        szValue = szCriticalStrikeDamage,
        szTip = GetCriticalStrikeDamageTip()
    })
end

local function InsertAttackValue(szAttr, tbInfo, nIndex, tbValue, tbConfig)
    if tbConfig[szAttr .. "1"] then
        InsertAttackValue1(tbInfo, nIndex, tbConfig.bTherapyMainly, tbValue)
    end
    nIndex = nIndex + 1

    if tbConfig[szAttr .. "2"] then
        InsertAttackValue2(tbInfo, nIndex, tbValue)
    end
    nIndex = nIndex + 3

    return nIndex
end


local function InsertOvercome(szAttr, tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    if not tbAttribShowConfig.bTherapyMainly and tbAttribShowConfig[szAttr .. "1"] then
        table.insert(tbInfo, {
            nType = 2,
            szName = g_tStrings.PLAYER_ATTRIB_NAME.OVERCOME,
            szValue = tostring(tbAttribValue[nIndex]),
            szTip = GetOvercomeTip()
        })
    end
    nIndex = nIndex + 1
    return nIndex
end

function PlayerData.GetAttribInfo(player)
    player = player or g_pClientPlayer

    local tbAttribShowConfig = PlayerData.GetShowInfo(player)
    local tbAttribValue = PlayerData.GetAttribValue(player)
    local nCof = PlayerData.GetCofValue()
    local tbInfo = {}

    table.insert(tbInfo, {
        nType = 1,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.VITALITY,
        szValue = tostring(tbAttribValue[1]),
        szTip = FormatString(g_tStrings.MSG_LIFE_UP, player.nVitalityBase, player.nCurrentVitality, player.nCurrentVitality * 10, player.nMaxLifeBase, player.nMaxLife),
    })

    table.insert(tbInfo, {
        nType = 1,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.SPIRIT,
        szValue = tostring(tbAttribValue[2]),
        szTip = FormatString(g_tStrings.MSG_SPIRIT_UP, player.nSpiritBase, player.nCurrentSpirit, math.floor(player.nCurrentSpirit * 0.9 + 0.5)),
    })

    table.insert(tbInfo, {
        nType = 1,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.STRENGTH,
        szValue = tostring(tbAttribValue[3]),
        szTip = FormatString(g_tStrings.MSG_PHYSICS_UP, player.nStrengthBase, player.nCurrentStrength, math.floor(player.nCurrentStrength * 0.163 + 0.5), math.floor(player.nCurrentStrength * 0.3 + 0.5)),
    })

    table.insert(tbInfo, {
        nType = 1,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.AGILITY,
        szValue = tostring(tbAttribValue[4]),
        szTip = FormatString(g_tStrings.MSG_AGILITY_UP, player.nAgilityBase, player.nCurrentAgility, math.floor(player.nCurrentAgility * 0.9 + 0.5)),
    })

    table.insert(tbInfo, {
        nType = 1,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.SPUNK,
        szValue = tostring(tbAttribValue[5]),
        szTip = FormatString(g_tStrings.MSG_MAGIC_MANA_REPLENISH_UP, player.nSpunkBase, player.nCurrentSpunk, math.floor(player.nCurrentSpunk * 0.181 + 0.5), math.floor(player.nCurrentSpunk * 0.3 + 0.5)),
    })

    local tDXXinFaFangDaQiShuZhi = {
        [10026]={3,math.floor(player.nCurrentStrength*1.8),math.floor(player.nCurrentStrength*0.28)},    --傲血战意
        [10268]={3,math.floor(player.nCurrentStrength*1.73),math.floor(player.nCurrentStrength*0.54)},    --笑尘诀
        [10224]={3,math.floor(player.nCurrentStrength*1.69),math.floor(player.nCurrentStrength*0.69)},    --惊羽诀
        [10464]={3,math.floor(player.nCurrentStrength*1.76),math.floor(player.nCurrentStrength*0.41)},    --北傲诀
        [10698]={3,math.floor(player.nCurrentStrength*1.8),math.floor(player.nCurrentStrength*0.28)},    --孤锋诀

        [10144]={4,math.floor(player.nCurrentAgility*1.8),math.floor(player.nCurrentAgility*0.28)},    --问水诀
        [10145]={4,math.floor(player.nCurrentAgility*1.8),math.floor(player.nCurrentAgility*0.28)},    --山居剑意
        [10390]={4,math.floor(player.nCurrentAgility*1.88),math.floor(player.nCurrentAgility*0.11),math.floor(player.nCurrentAgility*1)},    --分山劲
        [10585]={4,math.floor(player.nCurrentAgility*1.73),math.floor(player.nCurrentAgility*0.54)},    --隐龙诀
        [10533]={4,math.floor(player.nCurrentAgility*1.76),math.floor(player.nCurrentAgility*0.41)},    --凌海诀
        [10015]={4,math.floor(player.nCurrentAgility*1.69),math.floor(player.nCurrentAgility*0.68)},    --太虚剑意
        [10756]={4,math.floor(player.nCurrentAgility*1.69),math.floor(player.nCurrentAgility*0.68)},    --山海心诀

        [10175]={2,math.floor(player.nCurrentSpirit*2.03),math.floor(player.nCurrentSpirit*0.2)},    --毒经
        [10081]={2,math.floor(player.nCurrentSpirit*2),math.floor(player.nCurrentSpirit*0.29)},    --冰心诀
        [10447]={2,math.floor(player.nCurrentSpirit*1.96),math.floor(player.nCurrentSpirit*0.4)},    --莫问
        [10014]={2,math.floor(player.nCurrentSpirit*1.9),math.floor(player.nCurrentSpirit*0.61)},    --紫霞功
        [10627]={2,math.floor(player.nCurrentSpirit*1.93),math.floor(player.nCurrentSpirit*0.5)},    --无方
        [10821]={2,math.floor(player.nCurrentSpirit*1.93),math.floor(player.nCurrentSpirit*0.5)},    --无相楼

        [10021]={5,math.floor(player.nCurrentSpunk*2.03),math.floor(player.nCurrentSpunk*0.2)},    --花间游
        [10242]={5,math.floor(player.nCurrentSpunk*1.99),math.floor(player.nCurrentSpunk*0.3)},    --焚影圣诀
        [10003]={5,math.floor(player.nCurrentSpunk*1.96),math.floor(player.nCurrentSpunk*0.4)},    --易筋经
        [10225]={5,math.floor(player.nCurrentSpunk*1.9),math.floor(player.nCurrentSpunk*0.62)},    --天罗诡道
        [10615]={5,math.floor(player.nCurrentSpunk*1.93),math.floor(player.nCurrentSpunk*0.5)},    --太玄经
        [10786]={5,math.floor(player.nCurrentSpunk*1.95),math.floor(player.nCurrentSpunk*0.45)},    --周天功

        [10176]={2,math.floor(player.nCurrentSpirit*3.34)},    --补天诀
        [10080]={2,math.floor(player.nCurrentSpirit*3.16),math.floor(player.nCurrentSpirit*0.38)},    --云裳心经
        [10028]={2,math.floor(player.nCurrentSpirit*2.98),math.floor(player.nCurrentSpirit*0.74)},    --离经易道
        [10448]={2,math.floor(player.nCurrentSpirit*3.07),math.floor(player.nCurrentSpirit*0.56)},    --相知
        [10626]={2,math.floor(player.nCurrentSpirit*3.24),math.floor(player.nCurrentSpirit*0.2)},    --灵素

        [10062]={1,math.floor(player.nCurrentVitality*2.2),math.floor(player.nCurrentVitality*0.18),math.floor(player.nCurrentVitality*1.75),math.floor(player.nCurrentVitality*0.04)},    --铁牢律
        [10002]={1,math.floor(player.nCurrentVitality*2.2),math.floor(player.nCurrentVitality*0.18),math.floor(player.nCurrentVitality*1.75),math.floor(player.nCurrentVitality*0.05)},    --洗髓经
        [10243]={1,math.floor(player.nCurrentVitality*2.2),math.floor(player.nCurrentVitality*0.18),math.floor(player.nCurrentVitality*1.75),math.floor(player.nCurrentVitality*0.05)},    --明尊琉璃体
        [10389]={1,math.floor(player.nCurrentVitality*2.2),math.floor(player.nCurrentVitality*0.18),math.floor(player.nCurrentVitality*2.25),math.floor(player.nCurrentVitality*0.04)},    --铁骨衣

    }
    local tDXXinFaNeiLiShuZhi = {
        [10026]={math.floor(player.nCurrentVitality*1.5)},    --傲血战意
        [10268]={math.floor(player.nCurrentVitality*1.5)},    --笑尘诀
        [10698]={math.floor(player.nCurrentVitality*1.5)},    --孤锋诀
        [10585]={math.floor(player.nCurrentVitality*1.5)},    --隐龙诀
        [10533]={math.floor(player.nCurrentVitality*1.5)},    --凌海诀
        [10015]={math.floor(player.nCurrentVitality*1.5)},    --太虚剑意
        [10756]={math.floor(player.nCurrentVitality*1.5)},    --山海心诀
        [10175]={math.floor(player.nCurrentVitality*1.5)},    --毒经
        [10081]={math.floor(player.nCurrentVitality*1.5)},    --冰心诀
        [10447]={math.floor(player.nCurrentVitality*1.5)},    --莫问
        [10014]={math.floor(player.nCurrentVitality*1.5)},    --紫霞功
        [10627]={math.floor(player.nCurrentVitality*1.5)},    --无方
        [10021]={math.floor(player.nCurrentVitality*1.5)},    --花间游
        [10003]={math.floor(player.nCurrentVitality*1.5)},    --易筋经
        [10615]={math.floor(player.nCurrentVitality*1.5)},    --太玄经
        [10786]={math.floor(player.nCurrentVitality*1.5)},    --周天功
        [10821]={math.floor(player.nCurrentVitality*1.5)},    --无相楼
        [10176]={math.floor(player.nCurrentVitality*2.25)},    --补天诀
        [10080]={math.floor(player.nCurrentVitality*2.25)},    --云裳心经
        [10028]={math.floor(player.nCurrentVitality*2.25)},    --离经易道
        [10448]={math.floor(player.nCurrentVitality*2.25)},    --相知
        [10626]={math.floor(player.nCurrentVitality*2.25)},    --灵素
        [10062]={math.floor(player.nCurrentVitality*0.75)},    --铁牢律
        [10002]={math.floor(player.nCurrentVitality*0.75)},    --洗髓经

    }
    local XinFaID = PlayerData.GetPlayerMountKungfuID(player)
    if tDXXinFaFangDaQiShuZhi[XinFaID] then
        local i= tDXXinFaFangDaQiShuZhi[XinFaID][1]
        if XinFaID == 10176 then
            tbInfo[i].szTip = tbInfo[i].szTip .. GetFormatText("\n" .. FormatString(g_tStrings.tDXXinFaZhuShuXingJiaCheng[XinFaID][2],tDXXinFaFangDaQiShuZhi[XinFaID][2]))
        elseif XinFaID == 10390 then
            tbInfo[i].szTip = tbInfo[i].szTip .. GetFormatText("\n" .. FormatString(g_tStrings.tDXXinFaZhuShuXingJiaCheng[XinFaID][2],tDXXinFaFangDaQiShuZhi[XinFaID][2],tDXXinFaFangDaQiShuZhi[XinFaID][3],tDXXinFaFangDaQiShuZhi[XinFaID][4]))
        elseif i == 1 then
            tbInfo[i].szTip = tbInfo[i].szTip .. GetFormatText("\n" .. FormatString(g_tStrings.tDXXinFaZhuShuXingJiaCheng[XinFaID][2],tDXXinFaFangDaQiShuZhi[XinFaID][2],tDXXinFaFangDaQiShuZhi[XinFaID][3],tDXXinFaFangDaQiShuZhi[XinFaID][4],tDXXinFaFangDaQiShuZhi[XinFaID][5]))
        else
            tbInfo[i].szTip = tbInfo[i].szTip .. GetFormatText("\n" .. FormatString(g_tStrings.tDXXinFaZhuShuXingJiaCheng[XinFaID][2],tDXXinFaFangDaQiShuZhi[XinFaID][2],tDXXinFaFangDaQiShuZhi[XinFaID][3]))
        end
    end
    -- if tDXXinFaNeiLiShuZhi[XinFaID] then
    --     tbInfo[1].szTip = tbInfo[1].szTip .. GetFormatText("\n" .. FormatString(g_tStrings.tDXXinFaTiZhiZhuanNeiLi[XinFaID][1],tDXXinFaNeiLiShuZhi[XinFaID][1]))
    -- end

    local nIndex = 6
    if tbAttribShowConfig.bShowTherapy then
        local szHps = KeepOneByteFloat(player.nTherapyPower / 10)
        local TherapyPowerBaseWithPVX = player.nTherapyPowerBase
		local tzlxf = {
            [10176] = {"Heal"}, --补天
            [10080] = {"Heal"}, --云裳
            [10028] = {"Heal"}, --离经
            [10448] = {"Heal"}, --相知
            [10626] = {"Heal"}, --灵素
            [100655] = {"Heal"}, --移动端_补天
            [100409] = {"Heal"}, --移动端_云裳
            [100411] = {"Heal"}, --移动端_离经
            [101125] = {"Heal"}, --移动端_相知
            [101374] = {"Heal"}, --移动端_灵素
		}

		if tzlxf[player.GetActualKungfuMountID()] then
			TherapyPowerBaseWithPVX=math.floor(TherapyPowerBaseWithPVX + player.nPVXAllRound * player.nTherapyPVXCof/1024 )
		end
        table.insert(tbInfo, {
            nType = 2,
            szName = g_tStrings.PLAYER_ATTRIB_NAME.THERAPY,
            szValue = tostring(tbAttribValue[nIndex]),
            szTip = FormatString(g_tStrings.MSG_THERAPY_PER_SECOND_UP, szHps, TherapyPowerBaseWithPVX),
        })
    end
    nIndex = nIndex + 1

    nIndex = InsertAttackValue("bShowPhysics", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertAttackValue("bShowSolar", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertAttackValue("bShowNeutral", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertAttackValue("bShowLunar", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertAttackValue("bShowPoison", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)

    local szSpeedValue = string.format("%.2f", (tbAttribValue[nIndex])).."%"
    local nCurrentHasteRate =  KeepTwoByteFloat(100 * (math.min(player.nHasteRateBasePercentAdd / 1024 + player.nHasteBase / PlayerData.HasteParam / nCof, 0.25))).."%"
    local nTimeReduceRate = KeepTwoByteFloat(100-100/(1 + math.max(player.nCurrentHasteRate/1024))).."%"
    local nHasteBaseRate = KeepTwoByteFloat(100 * math.min(player.nHasteBase / PlayerData.HasteParam / nCof, 0.25)).."%"
    local nHasteAddRate = KeepTwoByteFloat(100 * player.nHasteRateBasePercentAdd / 1024 ).."%"
    local nTotalHasteRate = KeepTwoByteFloat(100*player.nCurrentHasteRate/1024).."%"
    local szSpeedTip = FormatString(
        g_tStrings.MSG_SKILL_CAST_SPEED_UP,
        player.nHasteBase, nHasteBaseRate, nHasteAddRate,
        nCurrentHasteRate, "25%", nTotalHasteRate,
        nTotalHasteRate, nTimeReduceRate
    )
    table.insert(tbInfo, {
        nType = 2,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.SPEED,
        szValue = szSpeedValue,
        szTip = szSpeedTip,
    })
    nIndex = nIndex + 1

    nIndex = InsertOvercome("bShowPhysics", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertOvercome("bShowSolar", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertOvercome("bShowNeutral", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertOvercome("bShowLunar", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)
    nIndex = InsertOvercome("bShowPoison", tbInfo, nIndex, tbAttribValue, tbAttribShowConfig)

    local szTrainValue = string.format("%.2f", (tbAttribValue[nIndex] / 100)).."%"
    table.insert(tbInfo, {
        nType = 2,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.STRAIN,
        szValue = szTrainValue,
        szTip = FormatString(g_tStrings.MSG_STRAIN_VALUE, player.nStrain, szTrainValue)
    })
    nIndex = nIndex + 1

	-- local dwKungfuID = player.GetKungfuMountID() or 0
    -- local szSurplusTip = Table_GetSurTip(dwKungfuID)
	-- szSurplusTip = string.gsub(szSurplusTip, "<SURVALUE>", player.nSurplusValue)
	-- szSurplusTip = string.gsub(szSurplusTip, "<SUR (%-?%d+%.*%d*)>", function(fParam) return math.floor(fParam * player.nSurplusValue * PlayerData.SurplusParam) end)
    -- szSurplusTip = UIHelper.GBKToUTF8(szSurplusTip)
    -- szSurplusTip = string.pure_text(szSurplusTip)
    local szSurplusTip = FormatString(g_tStrings.MSG_SURPLUS_VALUE_MOBILE, player.nSurplusValue)
    table.insert(tbInfo, {
        nType = 2,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.SURPLUS,
        szValue = tbAttribValue[nIndex],
        szTip = szSurplusTip
    })
    nIndex = nIndex + 1

    local szPhysicsShield =  string.format("%.2f", (tbAttribValue[nIndex])).."%"
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.PHYSICS_SHIELD,
        szValue = szPhysicsShield,
        szTip = FormatString(g_tStrings.MSG_PHYSICS_DAMAGE_DWON, player.nPhysicsShield, szPhysicsShield, player.nPhysicsShieldBase, "75%")
    })

    local szMagicShield = string.format("%.2f", (tbAttribValue[nIndex + 1])).."%"
    local szSloarShield = KeepTwoByteFloat(math.max(0,math.min(100 * player.nSolarMagicShield / (PlayerData.MagicShieldParam * nCof + player.nSolarMagicShield), 75))).."%"
    local szNeutralShield = KeepTwoByteFloat(math.max(0,math.min(100 * player.nNeutralMagicShield / (PlayerData.MagicShieldParam * nCof + player.nNeutralMagicShield), 75))).."%"
    local szLunarShield = KeepTwoByteFloat(math.max(0,math.min(100 * player.nLunarMagicShield / (PlayerData.MagicShieldParam * nCof + player.nLunarMagicShield), 75))).."%"
    local szPoisonShield = KeepTwoByteFloat(math.max(0,math.min(100 * player.nPoisonMagicShield / (PlayerData.MagicShieldParam * nCof + player.nPoisonMagicShield), 75))).."%"
    local szMagicShieldTip = FormatString(g_tStrings.MSG_SOLAR_MAGIC_DAMAGE_DWON, player.nSolarMagicShield, szSloarShield, player.nSolarMagicShieldBase, "75%")
    szMagicShieldTip = szMagicShieldTip  .. FormatString(g_tStrings.MSG_NEUTRAL_MAGIC_DAMAGE_DWON, player.nNeutralMagicShield, szNeutralShield, player.nNeutralMagicShieldBase, "75%")
    szMagicShieldTip = szMagicShieldTip  .. FormatString(g_tStrings.MSG_LUNAR_MAGIC_DAMAGE_DWON, player.nLunarMagicShield, szLunarShield, player.nLunarMagicShieldBase, "75%")
    szMagicShieldTip = szMagicShieldTip  .. FormatString(g_tStrings.MSG_POISON_DAMAGE_DWON_Mobile, player.nPoisonMagicShield, szPoisonShield, player.nPoisonMagicShieldBase, "75%")
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.MAGIC_SHIELD,
        szValue = szMagicShield,
        szTip = szMagicShieldTip,
    })
    nIndex = nIndex + 2

    local nDodgeRateAdd = KeepTwoByteFloat(100 * player.nDodge / (PlayerData.DodgeParam * nCof + player.nDodge)).."%"
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.DODGE,
        szValue = string.format("%.2f", (tbAttribValue[nIndex] / 100)).."%",
        szTip = FormatString(g_tStrings.MSG_DODGE_VALUE, player.nDodge, nDodgeRateAdd),
    })

    local nParryRateAdd = KeepTwoByteFloat(100 * player.nParry / (PlayerData.ParryParam * nCof + player.nParry)).."%"
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.COUNTERACT,
        szValue = string.format("%.2f", (tbAttribValue[nIndex + 1] / 100)).."%",
        szTip = FormatString(g_tStrings.MSG_PARRY_VALUE, player.nParry, nParryRateAdd, player.nParryBase),
    })

    local nParryValue = math.floor(player.nParryValue)
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.DEFENCE,
        szValue = tostring(math.floor(tbAttribValue[nIndex + 2])),
        szTip = FormatString(g_tStrings.MSG_DAMAGE_DOWN_AFTER_SUCCEED_PARRY, nParryValue, nParryValue, player.nParryValueBase),
    })

    local nToughnessRateAdd = KeepTwoByteFloat(100 * player.nToughness / PlayerData.ToughnessParam / nCof).."%"
    local nToughnessDeCriticalDamageRateAdd = KeepTwoByteFloat(math.min(100 * player.nToughness / PlayerData.ToughnessDecirDamageCof / nCof, 60)).."%"
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.TOUGHNESS,
        szValue = string.format("%.2f", (tbAttribValue[nIndex + 3] / 100)).."%",
        szTip = FormatString(g_tStrings.MSG_TOUGHNESS_VALUE, player.nToughness, nToughnessRateAdd, nToughnessDeCriticalDamageRateAdd),
    })

    local szDecriticalDamagePowerKiloNumRateAddHalf = string.format("%.2f", (tbAttribValue[nIndex + 4] / 100)).."%"
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.HUAJING,
        szValue = szDecriticalDamagePowerKiloNumRateAddHalf,
        szTip = FormatString(g_tStrings.MSG_HUAJING_VALUE, player.nDecriticalDamagePower, szDecriticalDamagePowerKiloNumRateAddHalf, "85%")
    })

    nIndex = nIndex + 5

    local nLifeReplenishOufOfFight = math.floor(player.nLifeReplenish * (1024 + player.nLifeReplenishCoefficient) / 1024 + player.nLifeReplenishExt + player.nMaxLife * player.nLifeReplenishPercent / 1024)
    local nLifeReplenishInFight = math.floor(player.nLifeReplenish * player.nLifeReplenishCoefficient / 1024 + player.nLifeReplenishExt + player.nMaxLife * player.nLifeReplenishPercent / 1024)
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.LIFE_REPLENISH,
        szValue = tostring(math.floor(tbAttribValue[nIndex])),
        szTip = FormatString(g_tStrings.MSG_LIFE_REPLENISH_UP_PER_SECOND, nLifeReplenishOufOfFight, nLifeReplenishInFight)
    })

    local nManaReplenishInFight = player.nManaReplenish * player.nManaReplenishCoefficient / 1024 + player.nManaReplenishExt + player.nMaxMana * player.nManaReplenishPercent / 1024
    local nManaReplenishOufOfFight = player.nManaReplenish + nManaReplenishInFight
    nManaReplenishInFight = math.floor(nManaReplenishInFight)
    nManaReplenishOufOfFight = math.floor(nManaReplenishOufOfFight)
    table.insert(tbInfo, {
        nType = 3,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.MANA_REPLENISH,
        szValue = tostring(math.floor(tbAttribValue[nIndex + 1])),
        szTip = FormatString(g_tStrings.MSG_MANA_REPLENISH_UP_PER_SECOND, nManaReplenishOufOfFight, nManaReplenishInFight)
    })

    nIndex = nIndex + 2

    local nRunSpeed = PlayerData.GetRunSpeed(g_pClientPlayer)
    table.insert(tbInfo, {
        nType = 4,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.RUN_SPEED,
        szValue = tbAttribValue[nIndex],
        szTip = FormatString(g_tStrings.MSG_RUN_SPEED_PER_SECOND, KeepOneByteFloat(nRunSpeed * 16 / 64))
    })

    table.insert(tbInfo, {
        nType = 4,
        szName = g_tStrings.PLAYER_ATTRIB_NAME.PVXALL_ROUND,
        szValue = tbAttribValue[nIndex + 1],
        szTip = PlayerData.GetPVXAllRoundTip(g_pClientPlayer)
    })
    nIndex = nIndex + 2

    return tbInfo
end

function PlayerData.GetAttribShowConfig(player)
    if Storage.Player.AttribShowConfig and IsTable(Storage.Player.AttribShowConfig) then
        return Storage.Player.AttribShowConfig
    end

    local tbConfig = {}
    local tbKungfu = player.GetActualKungfuMount()
    if tbKungfu and tbKungfu.dwSkillID then
        tbConfig = TabHelper.GetUICharacterInfoMainAttribShowTab(tbKungfu.dwSkillID)
        if table_is_empty(tbConfig) then
            tbConfig = TabHelper.GetUICharacterInfoMainAttribShowTab(0)
        end
    end

    return tbConfig
end

function PlayerData.SetAttribShowConfig(player, tbStorageConfig)
    Storage.Player.AttribShowConfig = tbStorageConfig
    Storage.Player.Dirty()
end

function PlayerData.IsMystiqueRecipeRead(item, bItemInfo) --提升技能属性的秘籍
    local player = GetClientPlayer()
    local bRead = false;
    local tInfo
    local dwID = nil
    if bItemInfo then
        dwID = item.dwID
    else
        dwID = item.dwIndex
    end
    tInfo = TabHelper.GetUISkillRecipeInfo(dwID)
    if not tInfo then
        LOG.ERROR("秘笈表 \\UI\\Scheme\\Case\\SkillRecipeTable.txt 缺少 ID = %d 请联系相关策划补上～～～～～～～～～～", dwID)
        return false
    end
    local dwSkillID = tInfo.SkillID
    local dwSkillLevel = player.GetSkillLevel(dwSkillID);

    if dwSkillLevel == 0 then
        dwSkillLevel = 1
    end

    local dwRecipeID, dwRecipeLevel = tInfo.RecipeID, tInfo.RecipeLevel
    local tRecipeList = player.GetSkillRecipeList(dwSkillID, dwSkillLevel)
    if tRecipeList then
        for _, tRecipe in ipairs(tRecipeList) do
            if tRecipe and tRecipe.recipe_id and tRecipe.recipe_level
            and tRecipe.recipe_id == dwRecipeID and tRecipe.recipe_level == dwRecipeLevel then
                bRead = true
                break
            end
        end
    end
    return bRead;
end

function PlayerData.SetSchoolImg(img, player, nType)
    player = player or GetClientPlayer()
    if not player then return end

    local nForceID = player.dwForceID
    if not nForceID then return end

    local szImgName = PlayerForceID2SchoolImg[nForceID]
    if nType == 2 then
        szImgName = PlayerForceID2SchoolImg2[nForceID]
    end

    if not szImgName then return end

    UIHelper.SetSpriteFrame(img, szImgName)
end

function PlayerData.IsSelf(dwID)
    local bResult = false
    if g_pClientPlayer and dwID then
        if IsNumber(dwID) then
            if g_pClientPlayer.dwID == dwID then
                bResult = true
            end
        else
            local player = dwID
            if g_pClientPlayer.dwID == player.dwID then
                bResult = true
            end
        end
    end
    return bResult
end

---comment 是否当前玩家的雇员
---@param npcID integer npcID
---@return boolean
function PlayerData.IsMyEmployee(npcID)
    if IsPlayer(npcID) then
        return false
    end

    local pNpc = NpcData.GetNpc(npcID)
    if not pNpc then
        return false
    end

    local dwEmployerID = pNpc.dwEmployer
    if dwEmployerID == 0 then
        return false
    elseif IsPlayer(dwEmployerID) then
        local pPlayer = GetControlPlayer()
        return pPlayer and dwEmployerID == pPlayer.dwID
    else
        return PlayerData.IsMyEmployee(dwEmployerID)
    end
end

function PlayerData.IsMeOrMyEmployee(nCharacterID)
    local pPlayer = GetControlPlayer()
    if pPlayer and pPlayer.dwID == nCharacterID then
        return true
    end
    return PlayerData.IsMyEmployee(nCharacterID)
end

function PlayerData.SetPlayerLogionSite(imgLoginSite , nClientVersionType ,targetID)
    local bShowSite = false
    if not PlayerData.tbSiteIconPath then
        PlayerData.tbSiteIconPath =
        {
            [CLIENT_VERSION_TYPE.NORMAL] = "UIAtlas2_Public_PublicIcon_PublicIcon1_img_pc.png",
            [CLIENT_VERSION_TYPE.WEGAME] = "UIAtlas2_Public_PublicIcon_PublicIcon1_img_pc.png",
            [CLIENT_VERSION_TYPE.STREAMING] = "UIAtlas2_Public_PublicIcon_PublicIcon1_img_cloud.png",
        }
    end

    local player = GetClientPlayer()
    if targetID == nil or (player and targetID ~= player.dwID) then
        local szSiteIconPath = PlayerData.tbSiteIconPath[nClientVersionType]
        if szSiteIconPath then
            UIHelper.SetSpriteFrame(imgLoginSite ,szSiteIconPath)
            bShowSite = true
        end
    end
    UIHelper.SetVisible(imgLoginSite , false)
end

function PlayerData.SetMountKungfuIcon(img, kungfuID, nClientVersionType)
    --if nClientVersionType and not IsMobileClientVersionType(nClientVersionType) and not TabHelper.IsHDKungfuID(kungfuID) then
    --    UIHelper.SetSpriteFrame(img, PlayerKungfuWuImg[kungfuID])
    --else
    --    UIHelper.SetSpriteFrame(img, PlayerKungfuImg[kungfuID])
    --end
    UIHelper.SetSpriteFrame(img, PlayerKungfuImg[kungfuID])
end

function registerEvents()
    Event.Reg(self, "SET_MAIN_PLAYER", function (nPlayerID)
        if nPlayerID == 0 then
            self.tPlayers = {}
            self.nPlayerNum = 0
        end
    end)

    Event.Reg(self, "PLAYER_ENTER_SCENE", function (nPlayerID)
        PlayerData.OnPlayerEnter(nPlayerID)
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function (nPlayerID)
        PlayerData.OnPlayerLeave(nPlayerID)
    end)
end

function PlayerData.GetOutfit(tSet)
    if not tSet.tDataMap then
        local tMap = {}
        for _, tData in ipairs(tSet.tData) do
            tMap[tData.nIndex] = tData
        end
        tSet.tDataMap = tMap
    end

    return tSet.tDataMap
end

function PlayerData.GetChangeExterior(tOutfit, tChangeList)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nCurrentSetID = player.GetCurrentSetID()
    local tExteriorSet = player.GetExteriorSet(nCurrentSetID)

    for i = 1, EXTERIOR_SUB_NUMBER do
        local tData = tOutfit[i]
        local dwExteriorID = 0
        if tData then
            dwExteriorID = tData.dwID
        end
        local nExteriorSub  = Exterior_BoxIndexToExteriorSub(i)
        local dwCurrentExteriorID = tExteriorSet[nExteriorSub]

        if dwExteriorID and dwExteriorID ~= dwCurrentExteriorID then
            local tItem = {}
            tItem.dwGoodsID = dwExteriorID
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR

            local nOwnType = GetCoinShopClient().CheckAlreadyHave(tItem.eGoodsType, tItem.dwGoodsID)
            tItem.bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE

            local nTimeType, nTime = player.GetExteriorTimeLimitInfo(dwExteriorID)
            if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT or
                nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON
            then
                tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.RENEW
                tItem.nRenewTime = nTime
            end

            if dwExteriorID > 0 then
                tItem.tPriceInfo = CoinShop_GetExteriorPriceInfo(dwExteriorID)
                tItem.szTime = CoinShop_GetExteriorTime(dwExteriorID)
                local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
                tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
                tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
            end
            tItem.nSubType = Exterior_BoxIndexToSub(i)
            table.insert(tChangeList, tItem)
        end
    end
end

function PlayerData.GetChangePendant(tOutfit, tChangeList)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
    local dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    local tItemList = {}
    for nPendantPos = 0, PENDENT_SELECTED_POS.TOTAL - 1 do
        local nIndex = CoinShop_PendantTypeToBoxIndex(nPendantPos)
        if nIndex then
            local dwCurrentIndex = player.GetSelectPendent(nPendantPos)
            local tData = tOutfit[nIndex]
            local dwIndex = 0
            local bChange = true
            if tData then
                dwIndex = tData.dwID
                local tRItem = {}
                tRItem.dwIndex = dwIndex
                tRItem.tColorID = tData.tColorID
                bChange = CoinShopPreview.IsPendantChange(tRItem, nPendantPos)
            else
                bChange = dwCurrentIndex ~= 0
            end
            if bChange then
                local tItem = {}
                local dwLogicID = Table_GetRewardsGoodID(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
                tItem.dwGoodsID = dwLogicID or 0
                tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
                tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
                local bHave = true
                if dwLogicID and dwLogicID > 0 then
                    local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
                    bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
                elseif dwIndex > 0 then
                    bHave = player.IsPendentExist(dwIndex)
                end

                tItem.bHave = bHave
                if dwLogicID and dwLogicID > 0 then
                    tItem.tPriceInfo = CoinShop_GetRewardsPriceInfo(dwLogicID)
                    tItem.szTime = CoinShop_GetRewardsTime(dwLogicID)
                    tInfo = hRewardsShop.GetRewardsShopInfo(dwLogicID)
                    tItem.bCanBuyMultiple = tInfo.bCanBuyMultiple
                    tItem.bLimitItem = tInfo.nGlobalCounterID > 0
                    tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
                    tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
                    tItem.bRel = tInfo.bIsReal
                end
                if dwIndex > 0 then
                    tItem.dwTabType = dwTabType
                    tItem.dwTabIndex = dwIndex
                end
                tItem.nSubType = CoinShop_PendantPosToSub(nPendantPos)
                tItem.nSelectedPos = nPendantPos
                table.insert(tChangeList, tItem)
            end
        end
    end
end

function PlayerData.GetChangeWeapon(tOutfit, tChangeList)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nCurrentSetID = player.GetCurrentSetID()
    local tWeaponExterior = player.GetWeaponExteriorSet(nCurrentSetID)
    local tWeaponBox = CoinShop_GetWeaponIndexArray()
    local tWeaponList = {}
    for i, nWeaponSub in pairs(tWeaponBox) do
        local tData = tOutfit[i]
        local dwWeaponID = 0
        if tData then
            dwWeaponID = tData.dwID
        end
        local dwCurrent = tWeaponExterior[nWeaponSub]
        if dwWeaponID and dwWeaponID ~= dwCurrent then
            local tItem = {}
            tItem.dwGoodsID = dwWeaponID
            tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
            tItem.nEquipPos = nWeaponSub
            local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID)
            local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
            tItem.bHave = bHave

            if dwWeaponID > 0 then
                local tInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID)
                tItem.tPriceInfo = CoinShop_GetWeaponPriceInfo(dwWeaponID)
                tItem.szTime = CoinShop_GetWeaponTime(dwWeaponID)
                tItem.bForbiddPeerPay = tInfo.bForbiddPeerPay
                tItem.bForbidDisCoupon = tInfo.bForbidDisCoupon
            end
            table.insert(tChangeList, tItem)
        end
    end
end

function PlayerData.GetChangePendantPet(tOutfit, tChangeList)
    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end
    local dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    local tItemList = {}
    local nIndex = COINSHOP_BOX_INDEX.PENDANT_PET
    local tData = tOutfit[nIndex]
    local dwIndex = 0
    local bChange = true
    if tData then
        dwIndex = tData.dwID
        bChange = dwCurrentIndex ~= dwIndex
    else
        bChange = dwCurrentIndex ~= 0
    end
    if bChange then
        local tItem = {}
        local dwLogicID = Table_GetRewardsGoodID(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
        tItem.dwGoodsID = dwLogicID or 0
        tItem.nState = ACCOUNT_ITEM_STATUS.NORMAL
        tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
        local bHave = true
        if dwLogicID and dwLogicID > 0 then
            local nHaveType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, dwLogicID)
            bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
        elseif dwIndex > 0 then
            bHave = player.IsHavePendentPet(dwIndex)
        end

        tItem.bHave = bHave
        if tData then
            local tPendantPet = player.GetPendentPet(tData.dwID)
            tItem.nPos = tPendantPet.nPos
        end
        tItem.bPendantPet = true
        local tRItem = {}
        tRItem.dwTabType = dwTabType
        tRItem.dwIndex = dwIndex
        tRItem.dwLogicID = dwLogicID
        CoinShop_GetRewardItemInfo(tItem, tRItem)
        tItem.nSubType = Exterior_BoxIndexToSub(nIndex)
        table.insert(tChangeList, tItem)
    end
end

function PlayerData.GetCurrentChange(tOutfit)
    local tChangeList = {}
    self.GetChangeExterior(tOutfit, tChangeList)
    -- GetChangeFaceLift(tOutfit, tChangeList)
    self.GetChangePendant(tOutfit, tChangeList)
    self.GetChangeWeapon(tOutfit, tChangeList)
    self.GetChangePendantPet(tOutfit, tChangeList)
    return tChangeList
end

function PlayerData.GetEquipScoresLevel(nScores)
    local tLevel =
    { --ui\Image\UICommon\CommonPanel7.UITex
        [0]  = {nLow=0, 	nHigh=1000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon01.png"},
        [1]  = {nLow=1000, 	nHigh=2000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon02.png"},
        [2]  = {nLow=2000, 	nHigh=3000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon03.png"},
        [3]  = {nLow=3000, 	nHigh=3500, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon04.png"},
        [4]  = {nLow=3500, 	nHigh=4000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon05.png"},
        [5]  = {nLow=4000, 	nHigh=5000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon06.png"},
        [6]  = {nLow=5000, 	nHigh=6000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon07.png"},
        [7]  = {nLow=6000, 	nHigh=7000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon07.png"},
        [8]  = {nLow=7000, 	nHigh=8000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon07.png"},
        [9]  = {nLow=8000, 	nHigh=9000, 		szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon07.png"},
        [10] = {nLow=9000, 	nHigh=100000000, 	szImageFrame= "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon07.png"},
    }
    local nMax = #tLevel
    for i = 0, nMax, 1 do
        if nScores >= tLevel[i].nLow and  nScores < tLevel[i].nHigh then
            return i, tLevel[i].szImageFrame
        end
    end
    return nMax, "UIAtlas2_Character_EquipScore_ImgEquipScoreIcon07.png"
end

function PlayerData.IsPlayerDeath()
    local bResult = false
    if g_pClientPlayer then
        bResult = g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH
    end
    return bResult
end

function PlayerData.CheckForceOrNoneSchool(dwMKungfuID) -- 当前门派的内功或者流派
    if not g_pClientPlayer then
        return false
    end
	if not dwMKungfuID then
		dwMKungfuID = UI_GetPlayerMountKungfuID()
	end
	local dwForceID = UI_GetPlayerForceID()

	local nSkillLevel = g_pClientPlayer.GetSkillLevel(dwMKungfuID)
	if nSkillLevel <= 0 then
		return false
	end

	return Kungfu_GetType(dwMKungfuID) == dwForceID or IsNoneSchoolKungfu(dwMKungfuID)
end

function PlayerData.GetForceAndNoneKungfuList()
	local player = g_pClientPlayer
	local aSchoolList = player.GetSchoolList()
	local tList = {}
	for _, nSchool in pairs(aSchoolList) do
		local aKungfuList = player.GetKungfuList(nSchool)
		if aKungfuList then
			for dwKungfuID in pairs(aKungfuList) do
				if PlayerData.CheckForceOrNoneSchool(dwKungfuID) then
					table.insert(tList, dwKungfuID)
				end
			end
		end
	end
	return tList
end

function PlayerData.CheckMatchKungfus(tKungfuMap)
     for dwKungfuID,_ in pairs(tKungfuMap) do
        local bMatch = PlayerData.CheckForceOrNoneSchool(dwKungfuID)
        if bMatch then
            return true, dwKungfuID
        end
    end
    return false, 0
end

function PlayerData.MingJiaoDoAction(dwMiniAvatarID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

	if dwMiniAvatarID then
		local bInHat = APIHelper.IsInSecondRepresent()
		if bInHat then
			DoAction(pPlayer.dwID, 11471)
		else
			DoAction(pPlayer.dwID, 11470)
		end
	end
end

function PlayerData.UpdateMJMiniAvatar(dwMiniAvatarID)
	local tLine = Table_GetRoleAvatarInfo(dwMiniAvatarID)

	if tLine.nRelateID > 0 then
		local hPlayer = GetControlPlayer()
		hPlayer.SetMiniAvatar(tLine.nRelateID)
	end
end