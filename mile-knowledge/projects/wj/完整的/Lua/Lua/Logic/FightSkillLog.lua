FightSkillLog = FightSkillLog or { className = "FightSkillLog" }

FightSkillLog.StatBoss = true
FightSkillLog.StatNpc = true
FightSkillLog.bCombineIdenticalNameNpc = true

local MAX_INTEGER = 2e63 - 1
---@class BasicDamage
local tBasicTemplate = {
    tTargetsData = {},
    nTotalDamage = 0,
    nSmallestDamage = MAX_INTEGER,
    nBiggestDamage = 0,
    nHit = 0, ---命中次数
    nCritical = 0, ---会心次数
    nDoge = 0, ---偏离
    dwSkillID = 0,
    dwSkillLevel = 1,
    nEffectType = SKILL_EFFECT_TYPE.SKILL
}

---@class DamageTargetData
local tTargetDataTemplate = {
    tDamages = {},
    nTotalDamage = 0,
    nSmallestDamage = MAX_INTEGER,
    nBiggestDamage = 0,
    nHit = 0,
    nCritical = 0,
    nDoge = 0,
    dwTargetID = 0
}

---@class BeDamageSkillData
local tBeDamageSkillTemplate = {
    nTotalDamage = 0,
    nBiggestDamage = 0,
    nSmallestDamage = MAX_INTEGER,
    nHit = 0, ---命中次数
    nCritical = 0, ---会心次数
    nDoge = 0, ---偏离
    dwSkillID = 0,
    dwSkillLevel = 1,
    nEffectType = SKILL_EFFECT_TYPE.SKILL
}

---@class BeDamageTargetData
local tBeDamageTargetDataTemplate = {
    tSkills = {},
    nTotalDamage = 0,
    nBiggestDamage = 0,
    nSmallestDamage = MAX_INTEGER,
    nHit = 0,
    nCritical = 0,
    nDoge = 0,
    dwTargetID = 0,
}

---@class CasterTemplate
local tCasterTemplate = {
    tList = {},
    bIsEnemy = false,
}

local nFightStartTick = 0
local nFightEndTick = 0

local LogInterval = 4 * 1000
local m_historyId = 0
local HISTORY_MAX_COUNT = 10

local tHistoryTable = {}
local m_tCharacterInfo = {}

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
        return true
    elseif IsEnemy(player.dwID, dwCharacter) then
        return true
    end
    return false
end

local function GetParentNpcID(dwID, bNoNameOnly)
    if bNoNameOnly == nil then
        bNoNameOnly = false
    end

    if not IsPlayer(dwID) then
        local bIsEmployee = false
        local KNpc
        local tableToCheck = bNoNameOnly and FightSkillLog.tEmployeeNoNameTable or FightSkillLog.tEmployeeTable -- 召唤物数据合并至召唤者
        if not tableToCheck[dwID] then
            KNpc = GetNpc(dwID)
            local dwEmployer = KNpc and KNpc.dwEmployer
            bIsEmployee = dwEmployer and dwEmployer ~= 0
            if KNpc and bIsEmployee then
                if not bNoNameOnly or KNpc.szName == "" then
                    tableToCheck[dwID] = KNpc.dwEmployer
                    return KNpc.dwEmployer -- bNoNameOnly为true则只有NPC没有设置名称时才合并数据
                end
            end
        else
            return tableToCheck[dwID]
        end

        -- 非召唤物，同名合并
        if FightSkillLog.bCombineIdenticalNameNpc and KNpc and not bIsEmployee then
            local table = FightSkillLog.tNpcIdenticalNameTable
            if not table[KNpc.szName] then
                table[KNpc.szName] = dwID
            end
            return table[KNpc.szName]
        end
    end

    return dwID
end

function FightSkillLog.Start()
    LOG.INFO("FightSkillLog.Start")
    FightSkillLog.Clear()

    Event.UnRegAll(FightSkillLog)
    Event.Reg(FightSkillLog, "SYS_MSG", function(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        if arg0 == "UI_OME_SKILL_EFFECT_LOG" then
            FightSkillLog.LogSkill(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
            --elseif arg0 == "UI_OME_SKILL_HIT_LOG" then
            --    print("UI_OME_SKILL_HIT_LOG", arg1, arg2, arg3, arg4, arg5)
            --elseif arg0 == "UI_OME_SKILL_DODGE_LOG" or arg0 == "UI_OME_SKILL_MISS_LOG" or arg0 == "UI_OME_SKILL_SHIELD_LOG" then
            ---技能偏离
            --print("技能偏离", arg1, arg2, arg3, arg4, arg5)
        end
    end)

    Event.Reg(FightSkillLog, "STAT_SINGLE_BEGIN", function()
        FightSkillLog.Clear()
        FightSkillLog.bIsInFight = true
        nFightStartTick = GetTickCount()
    end)

    Event.Reg(FightSkillLog, "STAT_SINGLE_END", function()
        if not nFightStartTick then
            return
        end
        FightSkillLog.bIsInFight = false
        nFightEndTick = GetTickCount()
        local dwFightTime = nFightEndTick - nFightStartTick
        if dwFightTime >= LogInterval then
            m_historyId = m_historyId + 1
            FightSkillLog.UpdateHistory()
        end
    end)

    Event.Reg(FightSkillLog, EventType.OnAccountLogout, function()
        tHistoryTable = {}
        m_historyId = 0
    end)

    ActivePlayerStatData(true)
end

function FightSkillLog.Clear()
    FightSkillLog.bIsInFight = false

    FightSkillLog.tDamageData = {}
    FightSkillLog.tTherapyData = {}
    FightSkillLog.tBeDamageData = {}
    FightSkillLog.tBeTherapyData = {}

    FightSkillLog.tEmployeeTable = {}
    FightSkillLog.tEmployeeNoNameTable = {}
    FightSkillLog.tNpcIdenticalNameTable = {}

    m_tCharacterInfo = {}
end

function FightSkillLog.Stop()
    Event.UnRegAll(FightSkillLog)
    ActivePlayerStatData(false)
end

local function IsShowParnterData(dwID)
	local npc = GetNpc(dwID)
	if not npc or npc.dwEmployer == 0 then
		return false
	end

	if Storage.HurtStatisticSettings.ShowParnterType == PARTNER_FIGHT_LOG_TYPE.ALL then
		return true
	end

	local bSelf = npc.dwEmployer == UI_GetClientPlayerID()
	if bSelf and Storage.HurtStatisticSettings.ShowParnterType == PARTNER_FIGHT_LOG_TYPE.SELF then
		return true
	end

	return false
end

function FightSkillLog._GetInternalData(nStatType, dwCaster, dwTarget, dwID, nLevel)
    if nStatType == STAT_TYPE.DAMAGE or nStatType == STAT_TYPE.THERAPY then
        local tMain = nStatType == STAT_TYPE.DAMAGE and FightSkillLog.tDamageData or FightSkillLog.tTherapyData

        local bShowPartner = Storage.HurtStatisticSettings.IsSeparatePartnerData
        if not bShowPartner then
            dwCaster = GetParentNpcID(dwCaster)  ---召唤物数据合并至召唤主体，侠客数据分离
        elseif not PartnerData.IsPartnerNpc(dwCaster) then
            dwCaster = GetParentNpcID(dwCaster)  ---召唤物数据合并至召唤主体，侠客数据分离
        end

        local casterData = tMain[dwCaster] ---@type CasterTemplate
        if casterData == nil then
            tMain[dwCaster] = clone(tCasterTemplate)
            casterData = tMain[dwCaster]
            casterData.bIsEnemy = IsEnemyData(dwCaster)
        end

        local tSkill = casterData.tList[dwID] ---@type BasicDamage
        if tSkill == nil then
            casterData.tList[dwID] = clone(tBasicTemplate)
            tSkill = casterData.tList[dwID]
            tSkill.dwSkillID = dwID
            tSkill.dwSkillLevel = nLevel
        end

        local tTargetData = tSkill.tTargetsData[dwTarget] ---@type DamageTargetData
        if tTargetData == nil then
            tSkill.tTargetsData[dwTarget] = clone(tTargetDataTemplate)
            tTargetData = tSkill.tTargetsData[dwTarget]
            tTargetData.dwTargetID = dwTarget
        end

        return tSkill, tTargetData

    elseif nStatType == STAT_TYPE.BE_DAMAGE or nStatType == STAT_TYPE.BE_THERAPY then
        local tMain = nStatType == STAT_TYPE.BE_DAMAGE and FightSkillLog.tBeDamageData or FightSkillLog.tBeTherapyData

        local bShowPartner = Storage.HurtStatisticSettings.IsSeparatePartnerData
        if not bShowPartner then
            dwCaster = GetParentNpcID(dwCaster)  ---召唤物数据合并至召唤主体，侠客数据分离
        elseif not PartnerData.IsPartnerNpc(dwCaster) then
            dwCaster = GetParentNpcID(dwCaster)  ---召唤物数据合并至召唤主体，侠客数据分离
        end

        local casterData = tMain[dwTarget] ---@type CasterTemplate
        if casterData == nil then
            tMain[dwTarget] = clone(tCasterTemplate)
            casterData = tMain[dwTarget]
            casterData.bIsEnemy = IsEnemyData(dwTarget)
        end

        local tTarget = casterData.tList[dwCaster] ---@type BeDamageTargetData
        if tTarget == nil then
            casterData.tList[dwCaster] = clone(tBeDamageTargetDataTemplate)
            tTarget = casterData.tList[dwCaster]
            tTarget.dwTargetID = dwCaster
        end

        local tSkill = tTarget.tSkills[dwID] ---@type BeDamageSkillData
        if tSkill == nil then
            tTarget.tSkills[dwID] = clone(tBeDamageSkillTemplate)
            tSkill = tTarget.tSkills[dwID]
            tSkill.dwSkillID = dwID
            tSkill.dwSkillLevel = nLevel
        end
        return tSkill, tTarget
    end
end

function FightSkillLog.LogSkill(dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, nCount, tResult)
    if nCount <= 2 then
        return
    end

    if not Storage.HurtStatisticSettings.IsSeparatePartnerData and PartnerData.IsPartnerNpc(dwCaster) then
        -- 未显示侠客且施法者为侠客时直接过滤
        return
    end

    ------将技能信息合并至nDamageLogParentID声明的ID Merge Skill-------
    local tSkillInfo = TabHelper.GetUISkill(dwID)
    if tSkillInfo and tSkillInfo.nDamageParentID and IsNumber(tSkillInfo.nDamageParentID) then
        dwID = tSkillInfo.nDamageParentID
    end

    for _, eValueType in ipairs({
        SKILL_RESULT_TYPE.PHYSICS_DAMAGE, SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE,
        SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE, SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE,
        SKILL_RESULT_TYPE.POISON_DAMAGE
    }) do
        if tResult[eValueType] and tResult[eValueType] > 0 then
            FightSkillLog.GetCharacterInfo(dwCaster)
            FightSkillLog.GetCharacterInfo(dwTarget)

            FightSkillLog._LogDamage(dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, tResult)
            FightSkillLog._LogBeDamage(dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, tResult)
            break
        end
    end

    local nValue = tResult[SKILL_RESULT_TYPE.THERAPY]
    if nValue and nValue > 0 then
        FightSkillLog.GetCharacterInfo(dwCaster)
        FightSkillLog.GetCharacterInfo(dwTarget)

        FightSkillLog._LogTherapy(dwCaster, dwTarget, nEffectType, dwID, dwLevel, bCriticalStrike, tResult)
        FightSkillLog._LogBeTherapy(dwCaster, dwTarget, nEffectType, dwID, dwLevel, bCriticalStrike, tResult)
    end

    --nValue = tResult[SKILL_RESULT_TYPE.ABSORB_DAMAGE]
    --if nValue and nValue > 0 then
    --    FightLog.OnSkillDamageAbsorbLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
    --end
    --
    --nValue = tResult[SKILL_RESULT_TYPE.SHIELD_DAMAGE]
    --if nValue and nValue > 0 then
    --    FightLog.OnSkillDamageShieldLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
    --end
    --
    --nValue = tResult[SKILL_RESULT_TYPE.ABSORB_THERAPY]
    --if nValue and nValue > 0 then
    --    FightLog.OnSkillDamageAbsorbTherapy(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nValue)
    --end
end

function FightSkillLog._LogDamage(dwCaster, dwTarget, bReact, nEffectType, dwID, nLevel, bCriticalStrike, tResult)
    local tSkill, tTargetData = FightSkillLog._GetInternalData(STAT_TYPE.DAMAGE, dwCaster, dwTarget, dwID, nLevel)

    if bCriticalStrike then
        tTargetData.nCritical = tTargetData.nCritical + 1
        tSkill.nCritical = tSkill.nCritical + 1
    else
        tTargetData.nHit = tTargetData.nHit + 1
        tSkill.nHit = tSkill.nHit + 1
    end

    local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0

    tSkill.nTotalDamage = tSkill.nTotalDamage + nEffectDamage
    tTargetData.nTotalDamage = tTargetData.nTotalDamage + nEffectDamage

    tTargetData.nBiggestDamage = math.max(tTargetData.nBiggestDamage, nEffectDamage)
    tTargetData.nSmallestDamage = math.min(tTargetData.nSmallestDamage, nEffectDamage)

    tSkill.nBiggestDamage = math.max(tSkill.nBiggestDamage, nEffectDamage)
    tSkill.nSmallestDamage = math.min(tSkill.nSmallestDamage, nEffectDamage)

    tSkill.nEffectType = nEffectType
end

function FightSkillLog._LogBeDamage(dwCaster, dwTarget, bReact, nEffectType, dwID, nLevel, bCriticalStrike, tResult)
    local tSkill, tTargetData = FightSkillLog._GetInternalData(STAT_TYPE.BE_DAMAGE, dwCaster, dwTarget, dwID, nLevel)

    if bCriticalStrike then
        tTargetData.nCritical = tTargetData.nCritical + 1
        tSkill.nCritical = tSkill.nCritical + 1
    else
        tTargetData.nHit = tTargetData.nHit + 1
        tSkill.nHit = tSkill.nHit + 1
    end

    local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0

    tSkill.nTotalDamage = tSkill.nTotalDamage + nEffectDamage
    tTargetData.nTotalDamage = tTargetData.nTotalDamage + nEffectDamage

    tTargetData.nBiggestDamage = math.max(tTargetData.nBiggestDamage, nEffectDamage)
    tTargetData.nSmallestDamage = math.min(tTargetData.nSmallestDamage, nEffectDamage)

    tSkill.nBiggestDamage = math.max(tSkill.nBiggestDamage, nEffectDamage)
    tSkill.nSmallestDamage = math.min(tSkill.nSmallestDamage, nEffectDamage)

    tSkill.nEffectType = nEffectType
end

function FightSkillLog._LogTherapy(dwCaster, dwTarget, nEffectType, dwID, nLevel, bCriticalStrike, tResult)
    local tSkill, tTargetData = FightSkillLog._GetInternalData(STAT_TYPE.THERAPY, dwCaster, dwTarget, dwID, nLevel)

    if bCriticalStrike then
        tTargetData.nCritical = tTargetData.nCritical + 1
        tSkill.nCritical = tSkill.nCritical + 1
    else
        tTargetData.nHit = tTargetData.nHit + 1
        tSkill.nHit = tSkill.nHit + 1
    end

    local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] or 0

    tSkill.nTotalDamage = tSkill.nTotalDamage + nEffectDamage
    tTargetData.nTotalDamage = tTargetData.nTotalDamage + nEffectDamage

    tTargetData.nBiggestDamage = math.max(tTargetData.nBiggestDamage, nEffectDamage)
    tTargetData.nSmallestDamage = math.min(tTargetData.nSmallestDamage, nEffectDamage)

    tSkill.nBiggestDamage = math.max(tSkill.nBiggestDamage, nEffectDamage)
    tSkill.nSmallestDamage = math.min(tSkill.nSmallestDamage, nEffectDamage)

    tSkill.nEffectType = nEffectType
end

function FightSkillLog._LogBeTherapy(dwCaster, dwTarget, nEffectType, dwID, nLevel, bCriticalStrike, tResult)
    local tSkill, tTargetData = FightSkillLog._GetInternalData(STAT_TYPE.BE_THERAPY, dwCaster, dwTarget, dwID, nLevel)

    if bCriticalStrike then
        tTargetData.nCritical = tTargetData.nCritical + 1
        tSkill.nCritical = tSkill.nCritical + 1
    else
        tTargetData.nHit = tTargetData.nHit + 1
        tSkill.nHit = tSkill.nHit + 1
    end

    local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] or 0

    tSkill.nTotalDamage = tSkill.nTotalDamage + nEffectDamage
    tTargetData.nTotalDamage = tTargetData.nTotalDamage + nEffectDamage

    tTargetData.nBiggestDamage = math.max(tTargetData.nBiggestDamage, nEffectDamage)
    tTargetData.nSmallestDamage = math.min(tTargetData.nSmallestDamage, nEffectDamage)

    tSkill.nBiggestDamage = math.max(tSkill.nBiggestDamage, nEffectDamage)
    tSkill.nSmallestDamage = math.min(tSkill.nSmallestDamage, nEffectDamage)

    tSkill.nEffectType = nEffectType
end

function FightSkillLog.OnSkillDogeLog(dwCaster, dwTarget, nEffectType, dwID, dwLevel)
    local tBasic, tTargetData = FightSkillLog._GetInternalData(STAT_TYPE.DAMAGE, dwCaster, dwTarget, dwID)
    tTargetData.nDoge = tTargetData.nDoge + 1
    tBasic.nDoge = tBasic.nDoge + 1

    local tBasic_BE, tTargetData_BE = FightSkillLog._GetInternalData(STAT_TYPE.BE_DAMAGE, dwCaster, dwTarget, dwID)
    tBasic_BE.nDoge = tBasic_BE.nDoge + 1
    tTargetData_BE.nDoge = tTargetData_BE.nDoge + 1
end

function FightSkillLog.GetStatData(nStatType, eDataType)
    local nStatTypeID = STAT_TYPE2ID[nStatType]
    local eDataType = eDataType or DATA_TYPE.ONCE
    local nIntensity = 0
    local open_npc = false
    if nStatTypeID == STAT_TYPE2ID[STAT_TYPE.DAMAGE] then
        nIntensity = 2
        open_npc = FightSkillLog.StatBoss
    else
        open_npc = (FightSkillLog.StatNpc or FightSkillLog.StatBoss)
    end

    local bShowPartner = Storage.HurtStatisticSettings.IsSeparatePartnerData
    local tResult = QueryPlayerStatData(0, eDataType, nStatTypeID, 0) -- player

    if bShowPartner then
        local tPartnerRes = QueryPlayerStatData(1, eDataType, nStatTypeID, nIntensity, true) -- 侠客
        for k, v in pairs(tPartnerRes) do
            if IsShowParnterData(v.dwID) then
                v.bPartner = true
                table.insert(tResult, v)
            end
        end
    end

    if open_npc then
        local tNpcRes = QueryPlayerStatData(1, eDataType, nStatTypeID, nIntensity) -- npc
        for k, v in pairs(tNpcRes) do
            if v.nValue > 0 and (nIntensity == 0 or (v.nIntensity == 2 or v.nIntensity == 6)) then
                table.insert(tResult, v)
            end
        end
    end
    return tResult
end

function FightSkillLog.GetTotalFightingDataByType(nType)
	local tResult = FightSkillLog.GetStatData(nType, DATA_TYPE.TOTAL)
	tResult = tResult or {}

	return tResult	
end

function FightSkillLog.SaveHistory(nStatType)
    local tResult = FightSkillLog.GetStatData(nStatType)
    tResult = tResult or {}

    local tData = {}
    tData.tSummary = tResult
    tData.tDetail = FightSkillLog.GetTotalDataByStatType(nStatType)

    return tData
end

function FightSkillLog.UpdateHistory()
    local fTimeSecond = FightSkillLog.GetLastFightTimeInSeconds()
    local szCost = UIHelper.GetTimeTextWithDayNoFill(fTimeSecond)
    local nLen = #tHistoryTable
    if nLen == HISTORY_MAX_COUNT + 1 then
        table.remove(tHistoryTable, HISTORY_MAX_COUNT)
    end

    local tTotalData = {}
    tTotalData[STAT_TYPE.DAMAGE] = FightSkillLog.SaveHistory(STAT_TYPE.DAMAGE)
    tTotalData[STAT_TYPE.BE_DAMAGE] = FightSkillLog.SaveHistory(STAT_TYPE.BE_DAMAGE)
    tTotalData[STAT_TYPE.THERAPY] = FightSkillLog.SaveHistory(STAT_TYPE.THERAPY)
    tTotalData[STAT_TYPE.BE_THERAPY] = FightSkillLog.SaveHistory(STAT_TYPE.BE_THERAPY)

    local tBeDamageList = tTotalData[STAT_TYPE.BE_DAMAGE].tSummary
    table.sort(tBeDamageList, function(a, b)
        return a.nValuePer > b.nValuePer
    end)
    local szEnemyName = "战斗"
    for _, tInfo in ipairs(tBeDamageList) do
        local tCharacterInfo = FightSkillLog.GetCharacterInfo(tInfo.dwID)
        if tCharacterInfo and not tCharacterInfo.bIsPlayer and tCharacterInfo.szName ~= "" then
            szEnemyName = UIHelper.LimitUtf8Len(tCharacterInfo.szName, 10)
        end
    end

    local nTimeSecond = math.floor(fTimeSecond)
    local szTime = string.format("%d %s(%s)", m_historyId, szEnemyName, szCost)
    LOG.INFO("UpdateHistory %s", szTime)

    table.insert(tHistoryTable, 1, {
        szTime = szTime,
        tData = tTotalData,
        nTimeSecond = nTimeSecond,
        tCharacterInfo = m_tCharacterInfo -- 存储本次战斗的玩家数据
    })
    Event.Dispatch(EventType.OnFightHistoryUpdate)
end

function FightSkillLog.GetTotalDataByStatType(nStatType)
    if nStatType == STAT_TYPE.DAMAGE then
        return FightSkillLog.tDamageData
    elseif nStatType == STAT_TYPE.BE_DAMAGE then
        return FightSkillLog.tBeDamageData
    elseif nStatType == STAT_TYPE.THERAPY then
        return FightSkillLog.tTherapyData
    elseif nStatType == STAT_TYPE.BE_THERAPY then
        return FightSkillLog.tBeTherapyData
    end
end

---@return CasterTemplate
function FightSkillLog.GetDataByDwIDFromHistory(tHistoryData, dwCaster, nStatType)
    if tHistoryData and tHistoryData.tData and tHistoryData.tData[nStatType] and tHistoryData.tData[nStatType].tDetail then
        return tHistoryData.tData[nStatType].tDetail[dwCaster]
    end
end

function FightSkillLog.GetDetailFromHistory(tHistoryData, nStatType)
    if tHistoryData and tHistoryData.tData and tHistoryData.tData[nStatType] and tHistoryData.tData[nStatType].tDetail then
        return tHistoryData.tData[nStatType].tDetail
    end
end

function FightSkillLog.GetSummaryFromHistory(tHistoryData, nStatType)
    if tHistoryData and tHistoryData.tData and tHistoryData.tData[nStatType] and tHistoryData.tData[nStatType].tDetail then
        return tHistoryData.tData[nStatType].tSummary
    end
end

function FightSkillLog.GetAllCharacterSimpleInfo(tHistoryData)
    local tInfoList = {}
    local dwIDSet = {}
    local nStat = { STAT_TYPE.DAMAGE, STAT_TYPE.BE_DAMAGE, STAT_TYPE.THERAPY, STAT_TYPE.BE_THERAPY }
    for _, nType in ipairs(nStat) do
        local lst = tHistoryData.tData[nType].tDetail
        for dwID, data in pairs(lst) do
            if not table.contain_value(dwIDSet, dwID) then
                table.insert(tInfoList, { dwID = dwID, bIsEnemy = data.bIsEnemy })
                table.insert(dwIDSet, dwID)
            end
        end
    end
    return tInfoList
end

function FightSkillLog.GetHistoryByIndex(nHistoryIndex)
    if nHistoryIndex < 0 or nHistoryIndex > #tHistoryTable then
        LOG.ERROR("FightSkillLog.GetHistory nHistoryIndex error")
        return
    end

    return clone(tHistoryTable[nHistoryIndex])
end

function FightSkillLog.GetHistoryNameList()
    local lst = {}
    for _, data in ipairs(tHistoryTable) do
        table.insert(lst, data.szTime)

    end
    return lst
end

function FightSkillLog.GetCharacterInfo(dwID, hTeam, szName)
    if m_tCharacterInfo[dwID] and m_tCharacterInfo[dwID].szName ~= "" then
        return m_tCharacterInfo[dwID]
    end

    if not IsPlayer(dwID) then
        if not szName then
            local KNpc = GetNpc(dwID)
            if KNpc then
                szName = UIHelper.GBKToUTF8(KNpc.szName)
                if KNpc.dwEmployer and KNpc.dwEmployer ~= 0 then
                    local tInfo = FightSkillLog.GetCharacterInfo(KNpc.dwEmployer)
                    local szEmployer = tInfo and tInfo.szName or g_tStrings.STR_SOME_BODY

                    if szName ~= "" then
                        szName = szName .. "·" .. szEmployer
                    else
                        szName = szEmployer
                    end
                end
            end
        end

        m_tCharacterInfo[dwID] = {
            szName = szName or "",
            dwForceID = 0,
            nLevel = 0,
            bIsPlayer = false,
            dwHDMKungfuID = 0,
        }
        return m_tCharacterInfo[dwID]
    end

    if not hTeam then
        local player = g_pClientPlayer
        if player and player.IsInParty() then
            hTeam = GetClientTeam()
        end
    end

    if hTeam then
        local tMemberInfo = hTeam.GetMemberInfo(dwID)
        if tMemberInfo then
            m_tCharacterInfo[dwID] = {
                szName = UIHelper.GBKToUTF8(tMemberInfo.szName),
                dwForceID = tMemberInfo.dwForceID,
                dwMountKungfuID = tMemberInfo.dwMountKungfuID,
                dwHDMKungfuID = GetHDKungfuID(tMemberInfo.dwMountKungfuID),
                nLevel = tMemberInfo.nLevel,
                bClientPlayer = (dwID == UI_GetClientPlayerID()),
                bIsPlayer = true
            }
            return m_tCharacterInfo[dwID]
        end
    end

    local player = GetClientPlayer()
    if player and dwID == player.dwID then
        m_tCharacterInfo[dwID] = {
            szName = UIHelper.GBKToUTF8(player.szName),
            dwForceID = player.dwForceID,
            dwMountKungfuID = player.GetActualKungfuMountID(),
            dwHDMKungfuID = GetHDKungfuID(player.GetActualKungfuMountID()),
            nLevel = player.nLevel,
            bClientPlayer = true,
            bIsPlayer = true
        }
    else
        --敌方数据
        local playerData = Global.GetCharacter(dwID)
        if playerData then
            local szName = playerData.szName or "未知角色"
            local dwForceID = playerData.dwForceID or 0
            local nLevel = playerData.nLevel or 0
            local tKungFu = playerData.GetActualKungfuMount()
            local dwMKungfuID = player.GetKungfuMountID() or 0
            m_tCharacterInfo[dwID] = {
                szName = UIHelper.GBKToUTF8(szName),
                dwForceID = dwForceID,
                nLevel = nLevel,
                bClientPlayer = false,
                bIsPlayer = true,
                dwHDMKungfuID = 0,
            }
            if tKungFu then
                m_tCharacterInfo[dwID].dwMountKungfuID = tKungFu.dwSkillID
                m_tCharacterInfo[dwID].dwHDMKungfuID = GetHDKungfuID(tKungFu.dwSkillID)
                
            end
        end
    end

    if OBDungeonData.IsPlayerInOBDungeon() then
        local tPlayerInfo = OBDungeonData.GetCompetitor(dwID)
        local TargetPlayer = GetPlayer(dwID)
        if tPlayerInfo and tPlayerInfo[1] and TargetPlayer then
            m_tCharacterInfo[dwID] =
            {
                szName = UIHelper.GBKToUTF8(tPlayerInfo[2]),
                dwForceID = TargetPlayer.dwForceID,
                nLevel = TargetPlayer.nLevel,
                bClientPlayer = (dwID == UI_GetClientPlayerID()),
                dwHDMKungfuID = tPlayerInfo[6] and GetHDKungfuID(tPlayerInfo[6]) or 0,
            }
        end
    end

    return m_tCharacterInfo[dwID]
end

function FightSkillLog.GetCharacterInfoFromHistory(tHistoryData, dwID)
    return tHistoryData.tCharacterInfo[dwID]
end

function FightSkillLog.IsFighting()
    --local me = GetClientPlayer()
    --if not me then
    --    return
    --end
    --local bFightState = me.bFightState
    --if not bFightState and ArenaData.IsInArena() and not ArenaData.IsFinish() then
    --    bFightState = true
    --elseif not bFightState and DungeonData.IsInDungeon() then
    --    local bPlayerFighting, bNpcFighting
    --    for _, p in ipairs(X.GetNearPlayer()) do
    --        if me.IsPlayerInMyParty(p.dwID) and p.bFightState then
    --            bPlayerFighting = true -- 在秘境且附近队友进战且附近敌对NPC进战则判断处于战斗状态
    --            break
    --        end
    --    end
    --    if bPlayerFighting then
    --        for _, p in ipairs(X.GetNearNpc()) do
    --            if IsEnemy(p.dwID, me.dwID) and p.bFightState then
    --                bNpcFighting = true
    --                break
    --            end
    --        end
    --    end
    --    bFightState = bPlayerFighting and bNpcFighting
    --end
    return FightSkillLog.bIsInFight
end

function FightSkillLog.GetLastFightTimeInSeconds()
    if nFightStartTick then
        local nTick
        if FightSkillLog.IsFighting() then
            nTick = GetTickCount() - nFightStartTick -- 战斗状态
        else
            nTick = nFightEndTick - nFightStartTick -- 脱战状态
        end

        return math.floor(nTick / 1000)
    end
    return 1
end