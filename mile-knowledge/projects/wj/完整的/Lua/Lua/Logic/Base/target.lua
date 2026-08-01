g_nSearchAlliesIndex = 0
g_nSearchEnemyIndex = 0
g_nLastTabDownFrame = 0
g_nTabPlayerPriority = false
g_nSearchMaxRadius = nil
--RegisterCustomData("g_nTabPlayerPriority")

local SEARCH_MODE = {
    ENMEY = "Enmey",
    ALLY = "Ally",
}
local SearchOption = {
    [SEARCH_MODE.ENMEY] = {
        nVersion = 2,
        bOnlyPlayer = false,
        bPlayerFirst = false,
        bOnlyNearDis = false,
        bWeakness = false,  -- 血量最少
        bMidAxisFirst = false,
        bSureTarget = false,
        nCoolTime = 16, --帧

        bRedFirst = false,
        tArea = {
            [1] = { nRadius = 2560, nAngle = 15, nSelLevel = 3, szArea = "MidAxis" }, --"MidAxis"
            [2] = { nRadius = 512, nAngle = 85, nSelLevel = 2, szArea = "Inner" }, -- "Inner"
            [3] = { nRadius = 1280, nAngle = 114, nSelLevel = 1, szArea = "Outer" }, --"Outer"
        }
    },
    [SEARCH_MODE.ALLY] = {
        nVersion = 2,
        bOnlyPlayer = false,
        bPlayerFirst = false,
        bOnlyNearDis = false,
        bWeakness = false,      -- 血量最少
        bMidAxisFirst = false,
        bSureTarget = false,
        nCoolTime = 16, --帧

        bTeammate = false,
        tArea = {
            [1] = { nRadius = 2560, nAngle = 15, nSelLevel = 3, szArea = "MidAxis" }, --"MidAxis"
            [2] = { nRadius = 512, nAngle = 85, nSelLevel = 2, szArea = "Inner" }, -- "Inner"
            [3] = { nRadius = 1280, nAngle = 114, nSelLevel = 1, szArea = "Outer" }, --"Outer"
        }
    }
}

local SearchCoolTime = {
    [SEARCH_MODE.ENMEY] = {},
    [SEARCH_MODE.ALLY] = {},
}
local SEARCH_RUN_MODE = SEARCH_MODE.ENMEY
local MAX_ANGLE = 256

local function GetFormatData(Data, Default)
    if Data ~= nil then
        return Data
    end
    return Default
end

local function GetSearchOption(szMode)
    return SearchOption[szMode]
end

function CalHorizontalDistance(dwCharacterID)
    local Target = nil
    if IsPlayer(dwCharacterID) then
        Target = GetPlayer(dwCharacterID)
    else
        Target = GetNpc(dwCharacterID)
    end
    if not Target then
        return
    end
    local player = GetControlPlayer()
    local nDis = (player.nX - Target.nX) * (player.nX - Target.nX) + (player.nY - Target.nY) * (player.nY - Target.nY)
    return nDis
end

local function CalcDistance(dwCharacterID)
    local Target = nil
    if IsPlayer(dwCharacterID) then
        Target = GetPlayer(dwCharacterID)
    else
        Target = GetNpc(dwCharacterID)
    end
    local player = GetControlPlayer()
    local nDis = (player.nX - Target.nX) * (player.nX - Target.nX) +
            (player.nY - Target.nY) * (player.nY - Target.nY) +
            (player.nZ - Target.nZ) * (player.nZ - Target.nZ) / 64
    return nDis
end

local function GetMidAxisDis(hTarget)
    local player = GetControlPlayer()
    local nXDis, nYDis = hTarget.nX - player.nX, hTarget.nY - player.nY
    local fDis = nXDis * nXDis + nYDis * nYDis
    local tarDir = math.atan2(nYDis, nXDis)
    if tarDir < 0 then
        tarDir = tarDir + 2 * math.pi
    end
    local playerDir = 2 * math.pi * player.nFaceDirection / 255
    local disDir = math.abs(playerDir - tarDir)

    if disDir > math.pi * 3 / 4 then
        disDir = 2 * math.pi - disDir
    end

    if disDir > math.pi then
        disDir = disDir - math.pi
    end

    if disDir > math.pi / 2 then
        disDir = math.pi - disDir
    end

    fDis = math.sqrt(fDis) * math.sin(disDir)
    return fDis
end

local function CanSelect(dwID, szMode)
    local bPlayer = IsPlayer(dwID)
    local character
    if bPlayer then
        if not CanSelectPlayer(dwID) then
            return false
        end
        character = GetPlayer(dwID)

    else
        if not CanSelectNpc(dwID) then
            return false
        end

        character = GetNpc(dwID)
    end

    if not character then
        return false
    end

    if character.nSelectableType == SELECTABLE_TYPE.SELECTABLE_NONE then
        return false
    end

    if character.nSelectableType == SELECTABLE_TYPE.SELECTABLE_NOT_ENEMY and szMode == SEARCH_MODE.ENMEY then
        return false
    end

    return true
end

function FliterUnSelectableTarget(tData, szMode)
    local tResult = {}
    if not tData then
        return tResult
    end

    for k, dwID in ipairs(tData) do
        if CanSelect(dwID, szMode) then
            table.insert(tResult, dwID)
        end
    end
    return tResult
end

local function SortTargetCmp(a, b)
    local tOption = GetSearchOption(SEARCH_RUN_MODE)
    if tOption.bPlayerFirst then
        if a.bPlayer ~= b.bPlayer then
            if a.bPlayer then
                return true
            else
                return false
            end
        end
    end

    if a.bIsInScreen ~= b.bIsInScreen then
        if a.bIsInScreen then
            return true
        else
            return false
        end
    end

    if g_nTabPlayerPriority and a.bPet ~= b.bPet then
        return not a.bPet
    end

    if tOption.bOnlyNearDis then
        if a.nDis ~= b.nDis then
            return a.nDis < b.nDis
        end
    end

    if tOption.bRedFirst then
        if a.nRed ~= b.nRed then
            return a.nRed > b.nRed
        end
    end

    if tOption.bWeakness then
        if a.nLife ~= b.nLife then
            return a.nLife < b.nLife
        end
    end

    if a.nSelLevel ~= b.nSelLevel then
        return a.nSelLevel > b.nSelLevel
    end

    if tOption.bMidAxisFirst then
        if a.nAxisDis ~= b.nAxisDis then
            return a.nAxisDis < b.nAxisDis
        end
    end

    if a.nCount ~= b.nCount then
        return a.nCount > b.nCount
    end

    return a.nIndex < b.nIndex
end

---cooltime target---
local function IsInCoolTime(dwCharacterID)
    local tCoolTime = SearchCoolTime[SEARCH_RUN_MODE]
    for k, v in pairs(tCoolTime) do
        if v == dwCharacterID then
            return k
        end
    end
    return false
end

local function GetPrevSelectTarget()
    local tCoolTime = SearchCoolTime[SEARCH_RUN_MODE]
    local player = GetClientPlayer()
    local dwTargetType, dwTargetID = player.GetTarget();
    if dwTargetType == TARGET.NO_TARGET then
        return
    end

    local nFind = #tCoolTime
    if nFind > 0 then
        return tCoolTime[nFind]
    end
    return
end

local function AppendSelectTarget(dwID)
    table.insert(SearchCoolTime[SEARCH_RUN_MODE], dwID)
end

local function ClearSelectHistory(dwID)
    if not dwID then
        SearchCoolTime[SEARCH_RUN_MODE] = {}
        return
    end

    local nIndex = IsInCoolTime(dwID)
    if nIndex and nIndex > 0 then
        table.remove(SearchCoolTime[SEARCH_RUN_MODE], nIndex)
    end
end
---cooltime target end---

local function GetTargetID(tData)
    local tOption = GetSearchOption(SEARCH_RUN_MODE)
    local player = GetClientPlayer()
    local dwTargetType, dwTargetID = player.GetTarget();
    if dwTargetType == TARGET.NO_TARGET then
        ClearSelectHistory()
        return tData[1].dwID, nil
    end

    if tOption.bSureTarget then
        local nCurrentMainLoop = GetLogicFrameCount()
        if (nCurrentMainLoop - g_nLastTabDownFrame) > tOption.nCoolTime and
                dwTargetID == tData[1].dwID then
            return dwTargetID
        end
    end

    for k, v in ipairs(tData) do
        if not IsInCoolTime(v.dwID) and dwTargetID ~= v.dwID then
            return v.dwID, dwTargetID
        end
    end

    ClearSelectHistory()

    if tData[1].dwID == dwTargetID and tData[2] then
        return tData[2].dwID
    end
    return tData[1].dwID
end


--如果返回false，接下来会对该目标释放技能，true则不释放技能
function InteractTarget(objType, objId)
    --	Log("InteractTarget("..objtype..", "..objid..")\n")
    if objType == TARGET.PLAYER then
        return InteractPlayer(objId)
    elseif objType == TARGET.NPC then
        return InteractNpc(objId)
    elseif objType == TARGET.DOODAD then
        return InteractDoodad(objId)
    elseif objType == TARGET.FURNITURE then
        return InteractLandObject(objId)
    elseif objType == TARGET.DUMMY then
        return InteractDummyObject(objId)
    end
    return false
end

-- 点选优先级：可捡尸体 > doodad,npc > player
-- esc-战斗相关：可捡尸体 > doodad,npc > player > pet
function GetFitObject(tSelectObject)
    if not tSelectObject then
        return
    end

    for i, object in pairs(tSelectObject) do
        if object["Type"] == TARGET.DOODAD and IsCorpseAndCanLoot(object["ID"]) then
            return object["Type"], object["ID"]
        end
    end

    for i, object in pairs(tSelectObject) do
        if object["Type"] == TARGET.DOODAD then
            return object["Type"], object["ID"]
        elseif object["Type"] == TARGET.NPC then
            local npc = GetNpc(object["ID"])
            if g_nTabPlayerPriority then
                if CanSelectNpc(object["ID"]) and npc.dwEmployer == 0 then
                    return object["Type"], object["ID"]
                end
            elseif CanSelectNpc(object["ID"]) then
                return object["Type"], object["ID"]
            end
        elseif object["Type"] == TARGET.FURNITURE or object["Type"] == TARGET.DUMMY then
            return object["Type"], object["ID"]
        end
    end
    for i, object in pairs(tSelectObject) do
        if object["Type"] == TARGET.PLAYER then
            if CanSelectPlayer(object["ID"]) then
                return object["Type"], object["ID"]
            end
        end
    end

    for i, object in pairs(tSelectObject) do
        if object["Type"] == TARGET.NPC then
            local npc = GetNpc(object["ID"])
            if g_nTabPlayerPriority and CanSelectNpc(object["ID"]) and npc.dwEmployer ~= 0 then
                return object["Type"], object["ID"]
            end
        end
    end
    return TARGET.NO_TARGET, 0
end

function GetTargetName(dwType, dwID)
    local szName = nil
    if dwType == TARGET.NPC then
        local npc = GetNpc(dwID)
        if npc then
            szName = npc.szName
        end
    elseif dwType == TARGET.DOODAD then
        local doodad = GetDoodad(dwID)
        if doodad then
            szName = Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID)
        end
    elseif dwType == TARGET.ITEM then
        local item = GetItem(dwID)
        if item then
            szName = GetItemNameByItem(item)
        end
    elseif dwType == TARGET.PLAYER then
        local player = GetPlayer(dwID)
        if player then
            szName = player.szName
        end
    end
    return szName
end

---------------------------------------------------------------------------------------
function SearchAlliesVer1()
    local nCurrentMainLoop = GetLogicFrameCount()
    local player = GetControlPlayer()
    local dwTargetType;
    local dwTargetID = 0;
    local dwCharacterID = 0;

    local CharacterIDArray1, dwAlliesSize1 = player.SearchForAllies(1920, 42)
    local CharacterIDArray2, dwAlliesSize2 = player.SearchForAllies(640, -42)
    if dwAlliesSize1 + dwAlliesSize2 == 0 then
        return
    end

    if (nCurrentMainLoop - g_nLastTabDownFrame) > 32 then
        g_nSearchAlliesIndex = 0;
    else
        g_nSearchAlliesIndex = g_nSearchAlliesIndex + 1;
    end

    if g_nSearchAlliesIndex >= (dwAlliesSize1 + dwAlliesSize2) then
        g_nSearchAlliesIndex = 0;
    end

    dwTargetType, dwTargetID = GetClientPlayer().GetTarget();
    if dwTargetType == TARGET.NO_TARGET then
        g_nSearchAlliesIndex = 0;
    end

    if g_nSearchAlliesIndex >= dwAlliesSize1 then
        dwCharacterID = CharacterIDArray2[g_nSearchAlliesIndex - dwAlliesSize1 + 1];
    else
        dwCharacterID = CharacterIDArray1[g_nSearchAlliesIndex + 1];
    end

    if dwCharacterID == dwTargetID then
        g_nSearchAlliesIndex = g_nSearchAlliesIndex + 1;
    end

    if g_nSearchAlliesIndex >= (dwAlliesSize1 + dwAlliesSize2) then
        g_nSearchAlliesIndex = 0;
    end

    if g_nSearchAlliesIndex >= dwAlliesSize1 then
        dwCharacterID = CharacterIDArray2[g_nSearchAlliesIndex - dwAlliesSize1 + 1];
    else
        dwCharacterID = CharacterIDArray1[g_nSearchAlliesIndex + 1];
    end

    g_nLastTabDownFrame = GetLogicFrameCount();
    if dwCharacterID ~= 0 then
        if IsPlayer(dwCharacterID) then
            SelectTarget(TARGET.PLAYER, dwCharacterID)
        else
            SelectTarget(TARGET.NPC, dwCharacterID)
        end
    end
end

local function SearchEnemyVer1()
    local nCurrentMainLoop = GetLogicFrameCount()
    local player = GetControlPlayer()
    local dwTargetType;
    local dwTargetID = 0;
    local dwCharacterID = 0;
    local CharacterIDArray1, dwEnemySize1 = player.SearchForEnemy(1920, 42)
    local CharacterIDArray2, dwEnemySize2 = player.SearchForEnemy(640, -42)

    if dwEnemySize1 + dwEnemySize2 == 0 then
        return
    end

    CharacterIDArray1 = FliterUnSelectableTarget(CharacterIDArray1, SEARCH_MODE.ENMEY)
    dwEnemySize1 = #CharacterIDArray1

    CharacterIDArray2 = FliterUnSelectableTarget(CharacterIDArray2, SEARCH_MODE.ENMEY)
    dwEnemySize2 = #CharacterIDArray2

    if (nCurrentMainLoop - g_nLastTabDownFrame) > 32 then
        g_nSearchEnemyIndex = 0;
    else
        g_nSearchEnemyIndex = g_nSearchEnemyIndex + 1;
    end

    if g_nSearchEnemyIndex >= (dwEnemySize1 + dwEnemySize2) then
        g_nSearchEnemyIndex = 0;
    end

    dwTargetType, dwTargetID = GetClientPlayer().GetTarget();
    if dwTargetType == TARGET.NO_TARGET then
        g_nSearchEnemyIndex = 0;
    end

    if g_nSearchEnemyIndex >= dwEnemySize1 then
        dwCharacterID = CharacterIDArray2[g_nSearchEnemyIndex - dwEnemySize1 + 1];
    else
        dwCharacterID = CharacterIDArray1[g_nSearchEnemyIndex + 1];
    end

    --判断是否选择了与原来一样的目标,是就切换到下一个
    if dwCharacterID == dwTargetID then
        g_nSearchEnemyIndex = g_nSearchEnemyIndex + 1;
    end

    if g_nSearchEnemyIndex >= (dwEnemySize1 + dwEnemySize2) then
        g_nSearchEnemyIndex = 0;
    end

    if g_nSearchEnemyIndex >= dwEnemySize1 then
        dwCharacterID = CharacterIDArray2[g_nSearchEnemyIndex - dwEnemySize1 + 1];
    else
        dwCharacterID = CharacterIDArray1[g_nSearchEnemyIndex + 1];
    end

    g_nLastTabDownFrame = GetLogicFrameCount();

    if dwCharacterID ~= 0 then
        if IsPlayer(dwCharacterID) then
            SelectTarget(TARGET.PLAYER, dwCharacterID)
        else
            SelectTarget(TARGET.NPC, dwCharacterID)
        end
    end
end

local function SearchCharacter(tAreaTarget)
    local tOption = GetSearchOption(SEARCH_RUN_MODE)
    local nCurrentMainLoop = GetLogicFrameCount()
    local player = GetClientPlayer()
    local hTeam = GetClientTeam()

    local tTargetInfo = {}
    local tMap = {}
    for k, tArea in pairs(tAreaTarget) do
        local nLevel, tTarget = tArea.nLevel, tArea.tTarget
        for _, dwID in ipairs(tTarget) do
            local bFliter = false
            local bPlayer = IsPlayer(dwID)
            if tOption.bOnlyPlayer and not bPlayer then
                bFliter = true
            end

            if tOption.bTeammate and (not bPlayer or (not hTeam.IsPlayerInTeam(dwID))) then
                bFliter = true
            end

            local nSkillID, nSkillLevel = GetCastingSkill()
            if nSkillID and nSkillLevel then
                local tRecipeKey = player.GetSkillRecipeKey(nSkillID, nSkillLevel)
                local pSkillInfo = GetSkillInfoEx(tRecipeKey, player.dwID)
                if pSkillInfo.MaxRadius * pSkillInfo.MaxRadius <= CalHorizontalDistance(dwID) then
                    bFliter = true
                end
            end

            if not bFliter then
                -- 没有被过滤的
                local hTarget = nil
                local bPet = false
                if bPlayer then
                    hTarget = GetPlayer(dwID)
                else
                    hTarget = GetNpc(dwID)
                    if hTarget.dwEmployer ~= 0 then
                        bPet = true
                    end
                end

                local nIndex = tMap[dwID]
                if not tMap[dwID] then
                    table.insert(
                            tTargetInfo,
                            { dwID = dwID, nIndex = 0, nCount = 0, nSelLevel = 0, bPlayer = bPlayer, bPet = bPet --[[nAxisDis=0, nRed = 0, nDis = 0, nLife=0]]}
                    )
                    nIndex = #tTargetInfo
                    tMap[dwID] = nIndex
                end
                local tInfo = tTargetInfo[nIndex]

                tInfo.nIndex = nIndex
                tInfo.bPlayer = bPlayer
                tInfo.nCount = tInfo.nCount + 1
                if nLevel > tInfo.nSelLevel then
                    tInfo.nSelLevel = nLevel
                    if g_nTabPlayerPriority and tInfo.bPet and tInfo.nSelLevel > 0 then
                        tInfo.nSelLevel = tInfo.nSelLevel - 1
                    end
                end

                if tOption.bMidAxisFirst then
                    tInfo.nAxisDis = GetMidAxisDis(hTarget)
                end

                if tOption.bOnlyNearDis then
                    tInfo.nDis = CalcDistance(dwID)
                end

                if tOption.bWeakness then
                    tInfo.nLife = hTarget.nCurrentLife
                end

                if tOption.bRedFirst then
                    tInfo.nRed = 0
                    if IsEnemy(player.dwID, dwID) then
                        tInfo.nRed = 1
                    end
                end
            end
        end
    end
    if #tTargetInfo == 0 then
        return
    end

    local tPositionList = {}
    for _, tInfo in ipairs(tTargetInfo) do
        local bPlayer, hTarget = IsPlayer(tInfo.dwID)
        if bPlayer then
            hTarget = GetPlayer(tInfo.dwID)
        else
            hTarget = GetNpc(tInfo.dwID)
        end
        table.insert(tPositionList, { hTarget.nX, hTarget.nY, hTarget.nZ })
    end
    local tPositionList = Scene_GameWorldPositionListToScreenPointList(tPositionList, #tPositionList)

    --local nWidth, nHeight = Station.GetClientSize()
    local nWidth = 1600
    local nHeight = 900
    for i, tInfo in ipairs(tTargetInfo) do
        local nScreenX, nScreenY = tPositionList[i * 2 - 1], tPositionList[i * 2]
        tTargetInfo[i].bIsInScreen = false
        if nScreenX and nScreenY and 0 < nScreenX and nScreenX < nWidth and 0 < nScreenY and nScreenY < nHeight then
            tTargetInfo[i].bIsInScreen = true
        end
    end

    table.sort(tTargetInfo, SortTargetCmp)
    if (nCurrentMainLoop - g_nLastTabDownFrame) > tOption.nCoolTime then
        ClearSelectHistory()
    end

    local dwCharacterID, dwTargetID = GetTargetID(tTargetInfo)
    if not tOption.bOnlyNearDis then
        if dwTargetID and dwCharacterID ~= dwTargetID then
            AppendSelectTarget(dwTargetID)
        end
        g_nLastTabDownFrame = GetLogicFrameCount();
    end
    if dwCharacterID ~= 0 then
        if IsPlayer(dwCharacterID) then
            SelectTarget(TARGET.PLAYER, dwCharacterID)
        else
            SelectTarget(TARGET.NPC, dwCharacterID)
        end
    end

    if IsMobileStreamingEnable() then
        FireUIEvent("MOBILE_PLAYER_SUCCESS_SEARCHENEMY")
    end
end

local function GetAreaTarget(szMode, tOption)
    local tResult = {}
    tOption = tOption or GetSearchOption(szMode)
    local player = GetControlPlayer()
    local tTarget, dwSize = nil, nil

    for k, tData in pairs(tOption.tArea) do
        if szMode == SEARCH_MODE.ENMEY then
            tTarget, dwSize = player.SearchForEnemy(g_nSearchMaxRadius or tData.nRadius, MAX_ANGLE)
        elseif szMode == SEARCH_MODE.ALLY then
            tTarget, dwSize = player.SearchForAllies(g_nSearchMaxRadius or tData.nRadius, tData.nAngle)
        end

        tTarget = FliterUnSelectableTarget(tTarget, szMode)
        dwSize = #tTarget
        if dwSize ~= 0 then
            table.insert(tResult, { nLevel = tData.nSelLevel, tTarget = tTarget })
        end
    end
    return tResult
end

function GetAreaTargetNum(nRadius)
    local pPlayer = GetControlPlayer()
    if not pPlayer then
        return 0
    end
    local _, dwSize = pPlayer.SearchForEnemy(nRadius, MAX_ANGLE)
    return dwSize
end

function SearchEnemy()
    if g_tAutoChooseData and g_tAutoChooseData.bChoose then
        return
    end

    local player = GetClientPlayer()
    if player.bSprintFlag then
        player.AimAtSprintDashTarget(1920, 1)
        return
    end

    local tOption = GetSearchOption(SEARCH_MODE.ENMEY)
    if tOption.nVersion == 1 then
        SearchEnemyVer1() -- 旧版本
    elseif tOption.nVersion == 2 then
        SEARCH_RUN_MODE = SEARCH_MODE.ENMEY
        local tAreaTarget = GetAreaTarget(SEARCH_MODE.ENMEY)
        SearchCharacter(tAreaTarget) -- 新版本
    end
end

function SearchEnemyVer2(Option)
    SEARCH_RUN_MODE = SEARCH_MODE.ENMEY
    local tAreaTarget = GetAreaTarget(SEARCH_MODE.ENMEY, Option)
    return SearchCharacter(tAreaTarget)
end

function SearchAllies()
    local tOption = GetSearchOption(SEARCH_MODE.ALLY)
    if tOption.nVersion == 1 then
        SearchAlliesVer1() -- 旧版本
    elseif tOption.nVersion == 2 then
        SEARCH_RUN_MODE = SEARCH_MODE.ALLY
        local tAreaTarget = GetAreaTarget(SEARCH_MODE.ALLY)
        SearchCharacter(tAreaTarget) -- 新版本
    end
    --FireUIEvent("MOBILE_PLAYER_SUCCESS_SEARCHALLIES", tOption.nVersion)
end

function SelectPrevTarget()
    local tOption = GetSearchOption(SEARCH_RUN_MODE)
    if tOption.nVersion == 2 then
        local dwID = GetPrevSelectTarget()

        if dwID and dwID ~= 0 then
            if IsPlayer(dwID) then
                SelectTarget(TARGET.PLAYER, dwID)
            else
                SelectTarget(TARGET.NPC, dwID)
            end
            ClearSelectHistory(dwID)
            g_nLastTabDownFrame = GetLogicFrameCount();
        end
    end
end

function SearchTarget_SetAreaSettting(szType, nRadius, nAngle, nSelLevel, szMode)
    szMode = GetFormatData(szMode, SEARCH_MODE.ENMEY)
    local tOption = GetSearchOption(szMode)
    if not tOption then
        return
    end

    for k, v in pairs(tOption.tArea) do
        if szType == v.szArea then
            tOption.tArea[k].nRadius = GetFormatData(nRadius, tOption.tArea[k].nRadius)
            tOption.tArea[k].nAngle = GetFormatData(nAngle, tOption.tArea[k].nAngle)
            tOption.tArea[k].nSelLevel = GetFormatData(nSelLevel, tOption.tArea[k].nSelLevel)
            break
        end
    end
end

function SearchTarget_SwitchOnlyPlayer()
    if SearchTarget_IsOldVerion() then
        return
    end
    local tOption = GetSearchOption(SEARCH_MODE.ENMEY)
    StorageServer.SetData("UISetting_BoolValues2", "TAB_PLAYER", not tOption.bOnlyPlayer)
    SearchTarget_SetSettings("OnlyPlayer", not tOption.bOnlyPlayer, true)
    FireUIEvent("UI_SearchTarget_SwitchOnlyPlayer", not tOption.bOnlyPlayer)
end

function SearchTarget_SetSettings(k, v, bMsg)
    --只对新版起作用
    if SearchTarget_IsOldVerion() then
        return
    end
    if bMsg then
        if k == "OnlyPlayer" then
            if v then
                OutputMessage("MSG_SYS", g_tStrings.WRENCH_OPEN_TAB_PLAYER)
            else
                OutputMessage("MSG_SYS", g_tStrings.WRENCH_CLOSE_TAB_PLAYER)
            end
        end
    end

    SearchTarget_SetOtherSetting(k, v, "Enmey")
    SearchTarget_SetOtherSetting(k, v, "Ally")
end

function SearchTarget_SetOtherSetting(szType, Data, szMode)
    szMode = GetFormatData(szMode, SEARCH_MODE.ENMEY)
    local tOption = GetSearchOption(szMode)
    if not tOption then
        return
    end

    if szType == "OnlyPlayer" then
        tOption.bOnlyPlayer = GetFormatData(Data, tOption.bOnlyPlayer)

    elseif szType == "PlayerFirst" then
        tOption.bPlayerFirst = GetFormatData(Data, tOption.bPlayerFirst)

    elseif szType == "Weakness" then
        tOption.bWeakness = GetFormatData(Data, tOption.bWeakness)

    elseif szType == "MidAxisFirst" then
        tOption.bMidAxisFirst = GetFormatData(Data, tOption.bMidAxisFirst)

    elseif szType == "OnlyNearDis" then
        tOption.bOnlyNearDis = GetFormatData(Data, tOption.bOnlyNearDis)

    elseif szType == "nVersion" then
        tOption.nVersion = GetFormatData(Data, tOption.nVersion)

    elseif szType == "CoolTime" then
        tOption.nCoolTime = GetFormatData(Data, tOption.nCoolTime)

    elseif szType == "SureTarget" then
        tOption.bSureTarget = GetFormatData(Data, tOption.bSureTarget)

    elseif szMode == SEARCH_MODE.ENMEY and szType == "RedFirst" then
        tOption.bRedFirst = GetFormatData(Data, tOption.bRedFirst)

    elseif szMode == SEARCH_MODE.ALLY and szType == "Teammate" then
        tOption.bTeammate = GetFormatData(Data, tOption.bTeammate)
    end
end

function SearchTarget_IsOldVerion()
    return SearchOption[SEARCH_MODE.ENMEY].nVersion == 1
end

function IsPlayerPriority()
    return g_nTabPlayerPriority
end

function SetPlayerPriority(bCheck)
    g_nTabPlayerPriority = bCheck
end

---comment 获取设置的最大索敌半径
---@return number|nil
function GetSearchMaxRadius()
    return g_nSearchMaxRadius
end

---comment 设置搜多最大半径
---@param nDistance number|nil 距离
function SetSearchMaxRadius(nDistance)
    g_nSearchMaxRadius = nDistance
end

function GetTargetLevelFontColor(nLevelDiff)
    local szFontColor = "yellow2"
    if nLevelDiff > 4 then
        -- 红
        szFontColor = "red2"
    elseif nLevelDiff > 2 then
        -- 桔
        szFontColor = "orange2"
    elseif nLevelDiff > -3 then
        -- 黄
        szFontColor = "yellow2"
    elseif nLevelDiff > -6 then
        -- 绿
        szFontColor = "green2"
    else
        -- 灰
        szFontColor = "gray2"
    end
    return szFontColor
end


