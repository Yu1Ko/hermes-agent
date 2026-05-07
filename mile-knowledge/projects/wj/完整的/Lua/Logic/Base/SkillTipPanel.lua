SkillTipPanel = {
    nItemCount = 0,
    tActionBarInUse = {},
    tTipFlash = {},
    tRefreshCD = {},
    tTipDatas = {}, -- 大图标对应的技能解释
    tSFXData = {},
    tTip2SFX = {},
    tWorkingTipID = {},
    nBoxStarAlpha = 15,
    bIsMobileKungFu = false
}
local self = SkillTipPanel

local m_buff = {}
local function CheckBuff(hTarget, szBuffID, szLevel, szStackNum, szSource, dwSkillID)
    local bEnable = false
    if not hTarget then
        return bEnable
    end

    local nBuffCount = hTarget.GetBuffCount()
    if nBuffCount == 0 then
        return bEnable
    end

    local dwClientPlayerID = UI_GetClientPlayerID()
    local dwBuffID = tonumber(szBuffID)
    local dwLevel = tonumber(szLevel)
    local dwStackNum = tonumber(szStackNum) or 0
    for k = 1, nBuffCount, 1 do
        Buffer_Get(hTarget, k - 1, m_buff)
        if szSource ~= "MYSELF" or m_buff.dwSkillSrcID == dwClientPlayerID then
            if m_buff.dwID == dwBuffID and m_buff.nLevel >= dwLevel and m_buff.nStackNum >= dwStackNum then
                if SkillTipPanel.tTipFlash[dwSkillID] then
                    if dwBuffID == SkillTipPanel.tTipFlash[dwSkillID].nBuffID then
                        SkillTipPanel.tTipFlash[dwSkillID].nEndFrame = m_buff.nEndFrame
                        SkillTipPanel.tTipFlash[dwSkillID].nLeftFrame = m_buff.nLeftFrame
                    else
                        if SkillTipPanel.tTipFlash[dwSkillID].nEndFrame > m_buff.nEndFrame then
                            SkillTipPanel.tTipFlash[dwSkillID].nEndFrame = m_buff.nEndFrame
                            SkillTipPanel.tTipFlash[dwSkillID].nLeftFrame = m_buff.nLeftFrame
                            SkillTipPanel.tTipFlash[dwSkillID].nBuffID = dwBuffID
                        end
                    end
                else
                    SkillTipPanel.tTipFlash[dwSkillID] = {}
                    SkillTipPanel.tTipFlash[dwSkillID].nEndFrame = m_buff.nEndFrame
                    SkillTipPanel.tTipFlash[dwSkillID].nLeftFrame = m_buff.nLeftFrame
                    SkillTipPanel.tTipFlash[dwSkillID].nBuffID = dwBuffID
                end

                bEnable = true
                break
            end
        end
    end

    return bEnable
end

local function CheckEnergy(szEnergy)
    local nEnergy = tonumber(szEnergy)
    local player = GetClientPlayer()
    if player.nCurrentEnergy >= nEnergy then
        return true
    end
    return false;
end

local function CheckRage(szRage)
    local nRage = tonumber(szRage)
    local player = GetClientPlayer()
    if player.nCurrentRage >= nRage then
        return true
    end
    return false;
end

local function CheckLife(hTarget, szCondition, szPercent)
    local bEnable = false

    if not hTarget then
        return bEnable
    end

    if hTarget.nMoveState == MOVE_STATE.ON_DEATH then
        return bEnable
    end

    local dwPlayerLifePercent = hTarget.fCurrentLife64 / hTarget.fMaxLife64
    local dwPercent = szPercent / 100

    if szCondition == "+" then
        if dwPercent < dwPlayerLifePercent then
            bEnable = true;
        end
    elseif szCondition == "-" then
        if dwPercent > dwPlayerLifePercent then
            bEnable = true;
        end
    end

    return bEnable
end

local function CheckMana(hTarget, szCondition, szPercent)
    local bEnable = false

    if not hTarget then
        return bEnable
    end

    if hTarget.nMoveState == MOVE_STATE.ON_DEATH then
        return bEnable
    end

    local dwPlayerManaPercent = hTarget.nCurrentMana / hTarget.nMaxMana
    local dwPercent = szPercent / 100

    if szCondition == "+" then
        if dwPercent < dwPlayerManaPercent then
            bEnable = true;
        end
    elseif szCondition == "-" then
        if dwPercent > dwPlayerManaPercent then
            bEnable = true;
        end
    end

    return bEnable
end

local function CheckAccumulate(szAccumulateValue)
    local nAccumulateValue = tonumber(szAccumulateValue)
    local player = GetClientPlayer()
    if player.nAccumulateValue >= nAccumulateValue then
        return true
    end
    return false;
end

local function CheckSunAccumulate(szAccumulateValue)
    local nAccumulateValue = tonumber(szAccumulateValue)
    local player = GetClientPlayer()
    if player.nSunPowerValue >= nAccumulateValue then
        return true
    end
    return false;
end

local function CheckMoonAccumulate(szAccumulateValue)
    local nAccumulateValue = tonumber(szAccumulateValue)
    local player = GetClientPlayer()
    if player.nMoonPowerValue >= nAccumulateValue then
        return true
    end
    return false;
end

local function CheckDoSkill(szSkillID, szLevel)
    local dwSkillID = tonumber(szSkillID)
    local dwLevel = tonumber(szLevel)

    if SkillTipPanel.nLastDoSkillID and SkillTipPanel.nLastDoSkillID == dwSkillID and SkillTipPanel.nLastDoSkillLevel and SkillTipPanel.nLastDoSkillLevel >= dwLevel then
        return true
    end
    return false
end

local function IsCD(dwSkillID, dwSkillLevel)
    local player = GetClientPlayer()
    local bCool, nLeft, nTotal = Skill_GetCDProgress(dwSkillID, dwSkillLevel, Skill_GetCongNengCDID(dwSkillID, player), player)
    if bCool and nTotal > 24 then
        return true
    end
    return false
end

local function CanDoSkill(dwSkillID, dwSkillLevel)
    local skill = GetSkill(dwSkillID, dwSkillLevel)
    if skill and skill.UITestCast(UI_GetClientPlayerID(), IsSkillCastMyself(skill)) == SKILL_RESULT_CODE.SUCCESS then
        return true
    end
    return false
end

local function CheckSkillWithoutCD(dwSkillID, nLevel)
    if dwSkillID == 0 then
        return false
    end

    local player = GetClientPlayer()
    local nSkillLevel = player.GetSkillLevel(dwSkillID)
    if nSkillLevel < nLevel then
        return false
    end

    if not CanDoSkill(dwSkillID, nSkillLevel) then
        return false
    end

    return true
end

local function CheckSkill(dwSkillID, nLevel)
    if dwSkillID == 0 then
        return false
    end

    local player = GetClientPlayer()
    local nSkillLevel = player.GetSkillLevel(dwSkillID)
    if nSkillLevel < nLevel then
        return false
    end

    if IsCD(dwSkillID, nSkillLevel) or not CanDoSkill(dwSkillID, nSkillLevel) then
        return false
    end

    return true
end

local function IsInParty(dwID)
    local player = GetClientPlayer()
    if player then
        return player.IsPlayerInMyParty(dwID)
    end
end

local function CheckSkillTip(hFrame)
    if hFrame.bUpdate then
        --SkillTipPanel.UpdateTipBox(hFrame)
        if hFrame.tSkillTipData then
            SkillTipPanel.UpdateSkillTip(hFrame, hFrame.tSkillTipData)
            hFrame.tSkillTipData = nil
        end
        SkillTipPanel.UpdateWorkingTip(hFrame)
        hFrame.bUpdate = nil
    end
end

function SkillTipPanel.OnFrameBreathe()
    CheckSkillTip(self)
end

function SkillTipPanel.OnEvent(event)
    SkillTipPanel.nLastDoSkillID = nil
    SkillTipPanel.nLastDoSkillLevel = nil

    if event == "PLAYER_ENTER_SCENE" then
        SkillTipPanel.tWorkingTipID = {}
    elseif event == "FIGHT_HINT" then
        if not arg0 then
            SkillTipPanel.ClearUseActionBar()
            SkillTipPanel.tWorkingTipID = {}
        end
    end

    if not g_pClientPlayer or not g_pClientPlayer.bFightState then
        return
    end

    if SkillTipPanel.bIsMobileKungFu then
        return
    end

    local tSkillTipData
    if event == "BUFF_UPDATE" then
        if arg0 == Target_GetTargetID() and Target_IsEnemy() then
            tSkillTipData = SkillTipPanel.GetSkillTipData({ "szTargetBuff" })            -- 目标BUFF
        elseif arg0 == UI_GetClientPlayerID() then
            tSkillTipData = SkillTipPanel.GetSkillTipData({ "szPlayerBuff" })            -- 自身BUFF
        end
    elseif event == "PLAYER_STATE_UPDATE" then
        if arg0 == UI_GetClientPlayerID() then
            -- 自身血量内力能量
            tSkillTipData = SkillTipPanel.GetSkillTipData({ "szPlayerLife", "szPlayerMana", "szPlayerEnergy" })
            if Kungfu_GetPlayerMountType() == FORCE_TYPE.TIAN_CE then
                tSkillTipData = SkillTipPanel.GetSkillTipData({ "szPlayerRage" })
            end
        elseif arg0 == Target_GetTargetID() then
            if Target_IsEnemy() then
                -- 敌人是玩家血量内力
                tSkillTipData = SkillTipPanel.GetSkillTipData({ "szTargetLife", "szTargetMana" })
            elseif IsInParty(arg0) then
                -- 队友血量内力
                tSkillTipData = SkillTipPanel.GetSkillTipData({ "szTeammateLife" })
            end
        end
    elseif event == "NPC_STATE_UPDATE" then
        if arg0 == Target_GetTargetID() and Target_IsEnemy() then
            -- 敌人是NPC血量内力
            tSkillTipData = SkillTipPanel.GetSkillTipData({ "szTargetLife", "szTargetMana" })
        end
    elseif event == "UI_UPDATE_ACCUMULATE" then
        -- 自身豆数
        tSkillTipData = SkillTipPanel.GetSkillTipData({ "szPlayerAccumulate" })
    elseif event == "UI_UPDATE_SUN_MOON_POWER_VALUE" then
        --  明教日月豆
        tSkillTipData = SkillTipPanel.GetSkillTipData({ "szPlayerSunAccumulate", "szPlayerMoonAccumulate" })
    elseif event == "DO_SKILL_CAST" then
        if arg0 == UI_GetClientPlayerID() then
            SkillTipPanel.UnUseActionBar(arg1)
            SkillTipPanel.tTipFlash[arg1] = nil

            SkillTipPanel.nLastDoSkillID = arg1
            SkillTipPanel.nLastDoSkillLevel = arg2
            tSkillTipData = SkillTipPanel.GetSkillTipData({ "szDoSkill" })
        end
    elseif event == "TARGET_LOST" then

    elseif event == "TARGET_CHANGE" then
        return
    end

    if tSkillTipData then
        self.bUpdate = true
        self.tSkillTipData = tSkillTipData
        CheckSkillTip(self)
    end
end

function SkillTipPanel.UpdateSkillTip(frame, tSkillTipData)
    local tParam, bShowTip, dwTargetID
    for _, szTipID in pairs(tSkillTipData) do
        local dwTipID = tonumber(szTipID)

        tParam, bShowTip, dwTargetID = SkillTipPanel.CheckEvent(dwTipID)

        if tParam then
            local szShowType = tParam["szShowType"]
            local szShowData = tParam["szShowData"]
            local fScale = tParam["fScale"]

            if bShowTip and not SkillTipPanel.tWorkingTipID[dwTipID] then
                SkillTipPanel.InUseActionBar(tParam.dwSkillID, dwTargetID, tParam.dwMaxTime)
                SkillTipPanel.tWorkingTipID[dwTipID] = true
            end
        end
    end
end

function SkillTipPanel.UpdateWorkingTip()
    local tParam, bShowTip, dwTargetID
    for dwTipID, _ in pairs(SkillTipPanel.tWorkingTipID) do
        tParam, bShowTip, dwTargetID = SkillTipPanel.CheckEvent(dwTipID)
        if tParam and not bShowTip then
            if not SkillTipPanel.tRefreshCD[dwTipID] then
                SkillTipPanel.UnUseActionBar(tParam.dwSkillID)
            end
            SkillTipPanel.tWorkingTipID[dwTipID] = nil
        end
    end
end

function SkillTipPanel.GetSkillTipData(tKey)
    local tResult = {}
    local tTipInfo = SkillTipPanel.GetTipInfo()
    if tTipInfo then
        local tSkillTipID
        for _, v in pairs(tKey) do
            local szInfo = tTipInfo[v] or ""
            tSkillTipID = SplitString(szInfo, ";")
            for _, v in pairs(tSkillTipID) do
                table.insert(tResult, v)
            end
        end
    end
    return tResult
end

local function IsTargetRelation(szType)
    if szType == "TARGET_BUFF" or szType == "TARGET_MANA" or
            szType == "TARGET_LIFE" or szType == "TEAMMATE_LIFE" then
        return true
    end
end

function SkillTipPanel.CheckEvent(dwSkillTipID)
    local tSkillEvent = g_tTable.SkillTip_Event:Search(dwSkillTipID)
    if not tSkillEvent then
        return
    end

    local dwTargetID
    local bShowTip = true
    local szCondition = tSkillEvent["szCondition"] or ""
    local tConditions = SplitString(szCondition, ";")
    for _, dwCondictionID in pairs(tConditions) do
        local tCondition = g_tTable.SkillTip_Condition:Search(dwCondictionID)
        if not tCondition or not SkillTipPanel.CheckConditions(tCondition, tSkillEvent) then
            bShowTip = false
            break
        end

        if not dwTargetID and IsTargetRelation(tCondition.szType) then
            dwTargetID = Target_GetTargetID()
        end
    end

    return tSkillEvent, bShowTip, dwTargetID
end

local function GetTarget()
    local dwType, dwID = Target_GetTargetData()
    local hTarget
    if dwType == TARGET.NPC then
        hTarget = GetNpc(dwID)
    elseif dwType == TARGET.PLAYER then
        hTarget = GetPlayer(dwID)
    end
    return hTarget
end

local tConditionParams = {
    ["TARGET_BUFF"] = { fnJudge = CheckBuff, fnGetTarget = GetTarget },
    ["CLIENT_BUFF"] = { fnJudge = CheckBuff, fnGetTarget = GetClientPlayer },
    ["TARGET_LIFE"] = { fnJudge = CheckLife, fnGetTarget = GetTarget },
    ["CLIENT_LIFE"] = { fnJudge = CheckLife, fnGetTarget = GetClientPlayer },
    ["TARGET_MANA"] = { fnJudge = CheckMana, fnGetTarget = GetTarget },
    ["CLIENT_MANA"] = { fnJudge = CheckMana, fnGetTarget = GetClientPlayer },
    ["REFRESH_CD"] = { fnJudge = CheckDoSkill },
    ["CLIENT_ACCUMULATE"] = { fnJudge = CheckAccumulate },
    ["CLIENT_SUN_ACCUMULATE"] = { fnJudge = CheckSunAccumulate },
    ["CLIENT_MOON_ACCUMULATE"] = { fnJudge = CheckMoonAccumulate },
    ["TEAMMATE_LIFE"] = { fnJudge = CheckLife, fnGetTarget = GetTarget },
    ["CLIENT_RAGE"] = { fnJudge = CheckRage },
    ["CLIENT_ENERGY"] = { fnJudge = CheckEnergy },
}

function SkillTipPanel.CheckConditions(tCondition, tSkillDes)
    local bEnable = false
    local szConditionType = tCondition.szType
    local szAgr1 = tCondition.szArg1
    local szAgr2 = tCondition.szArg2
    local szAgr3 = tCondition.szArg3
    local szAgr4 = tCondition.szArg4

    local dwSkillTipID = tSkillDes["dwID"]
    local dwSkillID = tSkillDes["dwSkillID"]
    local dwSkillLevel = tSkillDes["dwSkillLevel"]

    if szConditionType == "CAN_DO_SKILL" then
        bEnable = CheckSkill(dwSkillID, dwSkillLevel)
        return bEnable
    end

    local fnJudge = tConditionParams[szConditionType].fnJudge
    local fnGetTarget = tConditionParams[szConditionType].fnGetTarget

    if fnGetTarget then
        bEnable = fnJudge(fnGetTarget(), szAgr1, szAgr2, szAgr3, szAgr4, dwSkillID)
    else
        bEnable = fnJudge(szAgr1, szAgr2, szAgr3, szAgr4)
    end

    if szConditionType == "REFRESH_CD" then
        if not SkillTipPanel.tRefreshCD[dwSkillTipID] then
            SkillTipPanel.tRefreshCD[dwSkillTipID] = true
        end
    end

    return bEnable
end

function SkillTipPanel.InUseActionBar(dwSkillID, dwTargetID, dwMaxTime)
    if SkillTipPanel.tActionBarInUse[dwSkillID] then
        return
    end

    SkillTipPanel.tActionBarInUse[dwSkillID] = true
    print("SkillTipPanel.InUseActionBar(dwSkillID", dwSkillID)
end

function SkillTipPanel.UnUseActionBar(dwSkillID)
    if not SkillTipPanel.tActionBarInUse[dwSkillID] then
        return
    end
    SkillTipPanel.tActionBarInUse[dwSkillID] = nil
    print("UnUseActionBar UnUseActionBar", dwSkillID)
end

function SkillTipPanel.ClearUseActionBar()
    for k, _ in pairs(SkillTipPanel.tActionBarInUse) do
        SkillTipPanel.tActionBarInUse[k] = nil
    end
end

function SkillTipPanel.GetTipInfo()
    if SkillTipPanel.tSkillTipInfo then
        return SkillTipPanel.tSkillTipInfo
    end

    local dwKungfuID = UI_GetPlayerMountKungfuID()
    SkillTipPanel.tSkillTipInfo = g_tTable.SkillTip_Kungfu:Search(dwKungfuID)
    return SkillTipPanel.tSkillTipInfo
end

Event.Reg(SkillTipPanel, EventType.OnClientPlayerEnter, function()
    SkillTipPanel.tSkillTipInfo = nil
    SkillTipPanel.bIsMobileKungFu = not SkillData.IsUsingHDKungFu()
end)

Event.Reg(SkillTipPanel, "SKILL_MOUNT_KUNG_FU", function(dwID)
    SkillTipPanel.tSkillTipInfo = nil
    SkillTipPanel.bIsMobileKungFu = not TabHelper.IsHDKungfuID(dwID)
end)

local eventList = { "BUFF_UPDATE", "PLAYER_STATE_UPDATE", "NPC_STATE_UPDATE", "DO_SKILL_CAST",
                    "UI_UPDATE_ACCUMULATE", "UI_UPDATE_SUN_MOON_POWER_VALUE", "FIGHT_HINT", "TARGET_LOST", "TARGET_CHANGE" }
for _, szEvent in ipairs(eventList) do
    Event.Reg(SkillTipPanel, szEvent, function()
        SkillTipPanel.OnEvent(szEvent)
    end)
end
