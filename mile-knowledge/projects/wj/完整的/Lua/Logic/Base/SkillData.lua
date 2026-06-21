-- 技能操作接口

SkillData = SkillData or { className = "SkillData" }
--************************************逻辑数据***************************************

SkillData.SkillCacheTime = 0.5 --技能缓存时间
SkillData.DisableCast = false;
SkillData.IsFinishSkillLevelUpTeach = nil
SkillData.bUseSkillDirectionCancel = true
SkillData.tShootPos = { nX = 0, nY = 0, nZ = 0 }
SkillData.DXMaxSlotNum = 33
SkillData.DouqiQixueType = "Douqi"
SkillData.g_tSkillNounsList = {}
SkillData.tTotalNoun = {}

local tKungFuIDOrder = {
    KUNGFU_ID.CHUN_YANG,
    KUNGFU_ID.QI_XIU,
    KUNGFU_ID.WAN_HUA,
    KUNGFU_ID.TIAN_CE,
    KUNGFU_ID.SHAO_LIN,
    KUNGFU_ID.CANG_JIAN,
    KUNGFU_ID.WU_DU,
    KUNGFU_ID.TANG_MEN,
    KUNGFU_ID.MING_JIAO,
    KUNGFU_ID.GAI_BANG,
    KUNGFU_ID.CANG_YUN,
    KUNGFU_ID.CHANG_GE,
    KUNGFU_ID.BA_DAO,
    KUNGFU_ID.PENG_LAI,
    KUNGFU_ID.LING_XUE,
    KUNGFU_ID.YAN_TIAN,
    KUNGFU_ID.YAO_ZONG,
    KUNGFU_ID.DAO_ZONG,
    KUNGFU_ID.WAN_LING,
    KUNGFU_ID.DUAN_SHI,
}

SkillData.tSchoolTypeOrder = {
    SCHOOL_TYPE.CHUN_YANG,
    SCHOOL_TYPE.QI_XIU,
    SCHOOL_TYPE.WAN_HUA,
    SCHOOL_TYPE.TIAN_CE,
    SCHOOL_TYPE.SHAO_LIN,
    SCHOOL_TYPE.CANG_JIAN_SHAN_JU,
    SCHOOL_TYPE.WU_DU,
    SCHOOL_TYPE.TANG_MEN,
    SCHOOL_TYPE.MING_JIAO,
    SCHOOL_TYPE.GAI_BANG,
    SCHOOL_TYPE.CANG_YUN,
    SCHOOL_TYPE.CHANG_GE,
    SCHOOL_TYPE.BA_DAO,
    SCHOOL_TYPE.PENG_LAI,
    SCHOOL_TYPE.LING_XUE,
    SCHOOL_TYPE.YAN_TIAN,
    SCHOOL_TYPE.YAO_ZONG,
    SCHOOL_TYPE.DAO_ZONG,
    SCHOOL_TYPE.WAN_LING,
    SCHOOL_TYPE.DUAN_SHI,
    SCHOOL_TYPE.WU_XIANG,
}

local tbPublicSkills = {
    17, -- 打坐
    34, -- 虹气长空
    35, -- 传功
    81, -- 神行千里
    608, -- 自绝经脉
    100004, -- 扶摇直上·悟
    100005, -- 蹑云逐月·悟
    101937, -- 踏云·悟
    101957, -- 蹑云逐月·悟
}

local tbPublicDxSkills = {
    17, -- 打坐
    34, -- 虹气长空
    35, -- 传功
    81, -- 神行千里
    608, -- 自绝经脉
    605, --骑术
    9003, --蹑云逐月
    9002, --扶摇直上
    9005, --凌霄揽胜
    9006, --瑶台枕鹤
    9004 --迎风回浪
}
local MAX_SET_INDEX = 4
local self = SkillData
local kDirectionCount = GLOBAL.DIRECTION_COUNT
local kMetreLength = GLOBAL.LOGICAL_CELL_CM_LENGTH / GLOBAL.CELL_LENGTH / 100
local kZpointToXy = 8 -- 注意，这个常量没有导出

local WU_XIANG_LOU_SPECIAL_SKIN_SKILL = 41453 -- 无相楼傀儡短期换模技能

---comment 获取逻辑距离
---@param nX number
---@param nY number
---@param nZ number
---@return number distance
local function getDistance(nX, nY, nZ)
    nZ = nZ / kZpointToXy
    local nDis = math.sqrt(nX * nX + nY * nY + nZ * nZ)
    return nDis
end

local JIANG_HU_TYPE = 11
local MountRequestTypeDict = {
    [0] = 1,
    [JIANG_HU_TYPE] = 1
}

local function Kungfu_GetPlayerMountType(player)
    return player and player.dwForceID
end

SkillData.tKungFuIDOrder = tKungFuIDOrder
function SkillData.IsSkillBelongToCurrentKungFu(nSkillID, nSkillLevel, nInputKungFuID)
    local player = g_pClientPlayer
    local tKungfu, nKungFuID
    if nInputKungFuID then
        nKungFuID = nInputKungFuID
        tKungfu = GetSkill(nInputKungFuID, 1)
    else
        tKungfu = player.GetActualKungfuMount()
        if not tKungfu then
            return false -- 大侠号可能没有心法
        end
        nKungFuID = tKungfu.dwSkillID
    end

    local skill = GetSkill(nSkillID, nSkillLevel)
    if skill then
        local bPlatformMatch = skill.nPlatformType == tKungfu.nPlatformType
        if skill.nUIType ~= SkillNUIType.XinFa and bPlatformMatch then
            return skill.dwMountRequestDetail == nKungFuID or (skill.dwMountRequestDetail == 0 and
                    (skill.dwMountRequestType == tKungfu.dwMountType or MountRequestTypeDict[skill.dwMountRequestType] == 1))
        end
    end
end

function SkillData.GetCurrentPlayerSkillList(nKungFuID)
    local player = g_pClientPlayer
    local totalSkills = player.GetAllSkillList()
    local availableSkills = {}
    local tKungfu = player.GetActualKungfuMount()
    if not tKungfu then
        return availableSkills
    end

    nKungFuID = nKungFuID or tKungfu.dwSkillID
    local bIsHD = TabHelper.IsHDKungfuID(nKungFuID)

    for dwID, dwLevel in pairs(totalSkills) do
        local skill = GetSkill(dwID, dwLevel)
        local bIsMobileSkill = skill.nPlatformType == SkillPlatformType.Mobile and
                (skill.dwMountRequestDetail == nKungFuID
                        or (skill.dwMountRequestDetail == 0 and (skill.dwMountRequestType == tKungfu.dwMountType or MountRequestTypeDict[skill.dwMountRequestType] == 1)))
        local bIsHDSkill = skill.nPlatformType ~= SkillPlatformType.Mobile and (skill.dwMountRequestDetail == nKungFuID
                or (skill.dwMountRequestDetail == 0 and (skill.dwMountRequestType == tKungfu.dwMountType)))
        if skill.nUIType ~= SkillNUIType.XinFa then
            if not bIsHD and bIsMobileSkill then
                local skillInfo = TabHelper.GetUISkillMap(dwID)
                if skillInfo then
                    table.insert(availableSkills, { nID = dwID, tInfo = skillInfo })
                end
            elseif bIsHD and bIsHDSkill then
                table.insert(availableSkills, dwID)
            end
        end
    end

    if not bIsHD then
        table.sort(availableSkills, function(a, b)
            ---普通攻击将会在列表的头部
            if a.tInfo.nType == UISkillType.Common and b.tInfo.nType ~= UISkillType.Common then
                return true
            end
            if a.tInfo.nType ~= UISkillType.Common and b.tInfo.nType == UISkillType.Common then
                return false
            end
            local tbOrderA = a.tInfo.tbOrder or { [1] = 99 }
            local tbOrderB = b.tInfo.tbOrder or { [1] = 99 }
            return tbOrderA[1] < tbOrderB[1] --根据技能类型和order进行相应的排序
        end)
    end

    return availableSkills
end

function SkillData.GetAppendSkillDict(nKungFuID, bDisplayOnly, bIgnoreMiji)
    local tKungFuSkill = nKungFuID and IsNumber(nKungFuID) and GetSkill(nKungFuID, 1)
    if not (tKungFuSkill and tKungFuSkill.nPlatformType == SkillPlatformType.Mobile) then
        return {}
    end
    bIgnoreMiji = bIgnoreMiji or false -- 忽略是否需要秘籍激活
    local tLearnedAppendSkillDict = {}
    local nMountType = tKungFuSkill.dwMountType
    local skillInfoList = bDisplayOnly and SkillData.GetSchoolSkillList(MountTypeToSchoolType[nMountType]) or
            SkillData.GetCurrentPlayerSkillList(nKungFuID)
    local dict = {}

    for _, tSkill in ipairs(skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if skillInfo.nType == UISkillType.Append then
            if skillInfo.tbParentSkillID then
                for _, nParentSkillID in ipairs(skillInfo.tbParentSkillID) do
                    -- 查看是否为已激活的追加技
                    local tMijiLearnAppendSkills = tLearnedAppendSkillDict[nParentSkillID]
                    if not tMijiLearnAppendSkills then
                        tMijiLearnAppendSkills = {}
                        local tRecipes = SkillData.GetFinalRecipeList(nParentSkillID)
                        for _, tRecipe in ipairs(tRecipes) do
                            if bIgnoreMiji or tRecipe.active then
                                local tRecipeInfo = Table_GetSkillRecipe(tRecipe.recipe_id)
                                if tRecipeInfo and tRecipeInfo.nShowAppendSkillID then
                                    table.insert(tMijiLearnAppendSkills, tRecipeInfo.nShowAppendSkillID)
                                end
                            end
                        end
                        tLearnedAppendSkillDict[nParentSkillID] = tMijiLearnAppendSkills
                    end

                    -- 如果默认显示或对应秘籍被激活的话则示威合法追加技
                    local tSkillInfo = TabHelper.GetUISkillMap(nSkillID)
                    if tSkillInfo.bIsDefaultShow or table.contain_value(tMijiLearnAppendSkills, nSkillID) then
                        local lst = dict[nParentSkillID]
                        if not lst then
                            dict[nParentSkillID] = {}
                            lst = dict[nParentSkillID]
                        end
                        table.insert(lst, nSkillID)
                    end
                end
            end
        end
    end

    local sortFunc = function(nSkillID1, nSkillID2)
        if TabHelper.GetUISkillMap(nSkillID1) and TabHelper.GetUISkillMap(nSkillID2) then
            local nOrder1 = TabHelper.GetUISkillMap(nSkillID1).nAppendSkillOrder
            local nOrder2 = TabHelper.GetUISkillMap(nSkillID2).nAppendSkillOrder
            return nOrder1 < nOrder2
        end
        return false
    end
    for key, lst in pairs(dict) do
        table.sort(lst, sortFunc)
    end

    return dict
end

function SkillData.ProcessSkillPlaceholder(szDesc, hPlayer)
    hPlayer = hPlayer or g_pClientPlayer
    local bSingleValEmpty = false
    local fnReplace = function(szSub)
        local tList = string.split(szSub, ":")
        local nSkillID = tonumber(tList[1])
        local szField = tList[2]

        local tSkill = SkillData.GetSkill(hPlayer, nSkillID)
        if tSkill then
            local nVal = 9999
            if szField == "nWeaponDamagePercent" then
                nVal = tSkill.nWeaponDamagePercent / 1024
            elseif szField == "nSurplusCoefficient" then
                nVal = tSkill.nSurplusCoefficient / 1024
            elseif szField == "nDotCoefficient" then
                nVal = tSkill.nDotCoefficient / 16 / 10
            elseif szField == "nSkillCoefficient" then
                local nLevel = math.min(120, math.max(100, hPlayer.nLevel))
                local nMultiplier = 0.6 + 0.02 * (nLevel - 100)
                local nModifier = tSkill.nKindType == 1 and 10 or 12
                nVal = (tSkill.nSkillCoefficient * nMultiplier) / nModifier / GLOBAL.GAME_FPS
            end
            local szVal = string.format("%.0f", nVal * 100)

            bSingleValEmpty = bSingleValEmpty or nVal == 0
            return szVal
        end
    end

    local bTotalEmpty = true
    local fnOuter = function(szSub)
        local szProcessed = "return " .. szSub
        local nVal = loadstring(szProcessed)()
        bTotalEmpty = nVal == 0
        return nVal
    end

    local ans = string.gsub(szDesc, "<(%d+:%a+)>", fnReplace)
    ans = string.gsub(ans, "%$(.-)%$", fnOuter)

    --当单个值为空并且没有计算式 或 计算式值为空时 输出为空
    if bSingleValEmpty and bTotalEmpty then
        ans = ""
    end

    return ans
end

--- 根据角色当前的奇穴Set获取对应槽位信息
function SkillData.GetSlotSkillsGroupBySet(nCurrentKungFuID, nSetID)
    local pPlayer = g_pClientPlayer
    local dwForceID = pPlayer and pPlayer.dwForceID
    if not pPlayer then
        return
    end

    if nSetID and IsNumber(nSetID) and nSetID >= 0 and nSetID <= MAX_SET_INDEX then
        return g_pClientPlayer.GetSlotToSkillList(nSetID)
    end

    if nCurrentKungFuID then
        nSetID = pPlayer.GetTalentCurrentSet(dwForceID, nCurrentKungFuID)
        return g_pClientPlayer.GetSlotToSkillList(nSetID)
    end

    LOG.ERROR("SkillData.GetSlotSkillsGroupBySet nCurrentKungFuID invalid")
end

---comment 获取指定心法下槽位绑定的技能ID
---@param nSlotID number 槽位
---@param nKungFuID number 心法
---@return number 技能ID 失败返回nil
function SkillData.GetSlotSkillID(nSlotID, nKungFuID, nSetID)
    if not (nSetID and IsNumber(nSetID) and nSetID >= 0 and nSetID <= MAX_SET_INDEX) then
        LOG.ERROR("SkillData.GetSlotSkillIDInSpecificSet nSetID invalid")
    end

    nKungFuID = nKungFuID or g_pClientPlayer.GetActualKungfuMountID()
    local tKungfu = nKungFuID and nKungFuID > 0 and GetSkill(nKungFuID, 1)
    local nKungfuMountType = tKungfu and tKungfu.dwMountType

    if nSlotID == UI_SKILL_UNIQUE_SLOT_ID then
        return SkillData.GetUniqueSkillID(nKungFuID, nSetID)
    elseif nSlotID == UI_SKILL_DOUQI_SLOT_ID then
        return SkillData.GetDouqiSkillID(nKungFuID, nSetID)
    end

    local tSkills = SkillData.GetSlotSkillTable(nSlotID, nKungFuID, nSetID)
    for _, nID in ipairs(tSkills) do
        if nID <= 0 then
            return nil
        end

        local skill = GetSkill(nID, 1)
        if skill then
            local bMatch1 = skill.dwMountRequestDetail == nKungFuID
            local bMatch2 = skill.dwMountRequestDetail == 0 and
                    (skill.dwMountRequestType == nKungfuMountType or MountRequestTypeDict[skill.dwMountRequestType] == 1)
            if bMatch1 or bMatch2 then
                return nID
            end
        end
    end
    return nil
end

---comment 获取槽位绑定的技能列表
---@param nSlotID number 槽位ID
---@return table 技能ID列表 失败返回nil
function SkillData.GetSlotSkillTable(nSlotID, nCurrentKungFuID, nSetID)
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return {}
    end

    if not (not nSetID or (IsNumber(nSetID) and nSetID >= 0 and nSetID <= MAX_SET_INDEX)) then
        LOG.ERROR("SkillData.GetSlotSkillTableInSpecificSet nSetID invalid")
    end

    nCurrentKungFuID = nCurrentKungFuID or pPlayer.GetActualKungfuMountID()
    if nCurrentKungFuID then
        nSetID = nSetID or pPlayer.GetTalentCurrentSet(pPlayer.dwForceID, nCurrentKungFuID)
    end

    if pPlayer.dwForceID == 0 and not nSetID then
        nSetID = 0 -- 大侠号可能拿不到nSetID，给一个默认值0
    end

    local slotSkills = SkillData.GetSlotSkillsGroupBySet(nCurrentKungFuID, nSetID) or {}
    local tSkills = slotSkills[nSlotID]

    return tSkills
end

--- 获取门派轻功技能ID
function SkillData.GetForceSpecialSprintID(nSchoolID)
    local skillInfoList = SkillData.GetSchoolSkillList(nSchoolID)
    local res = {}
    local nDashID = UI_SKILL_DASH_ID
    local nJumpID = UI_SKILL_JUMP_ID
    local nFuYaoID = UI_SKILL_FUYAO_ID
    for _, tSkill in ipairs(skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if nSkillID ~= nDashID and nSkillID ~= nJumpID and nSkillID ~= nFuYaoID and skillInfo.nType == UISkillType.SecSprint then
            table.insert(res, nSkillID)
        end
    end
    return res
end

function SkillData.GetSkillPanelPrefabID()
    local nPrefabID = PREFAB_ID.WidgetSkillPanel
    if SkillData.IsUsingHDKungFu() then
        nPrefabID = PREFAB_ID.WidgetSkillPanelDX
    end

    return nPrefabID
end

function SkillData.GetFunctionPanelPrefabID()
    local nPrefabID = PREFAB_ID.WidgetRightBottonFunction
    if SkillData.IsUsingHDKungFu() then
        nPrefabID = PREFAB_ID.WidgetRightBottonFunctionDX
    end

    return nPrefabID
end

---- Todo
function SkillData.GetJumpSlot()
    local tbSLot = { 7, 8, 9, 10 }
    for nIndex, nSlot in ipairs(tbSLot) do
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(nSlot)
        if nSkillID == UI_SKILL_JUMP_ID then
            return nSlot
        end
    end
    return nil
end

local kJoyStickCastModes = {
    --SKILL_CAST_MODE.TARGET_AREA,
    SKILL_CAST_MODE.POINT_AREA,
    SKILL_CAST_MODE.POINT_AREA_FIND_FIRST,
}
function SkillData.GetUIDynamicSkillMap(skillID, nSkillLevel)
    local skill = GetSkill(skillID, nSkillLevel)
    local type = Skill_GetOptType(skillID, nSkillLevel, skill)
    local nCastMode = skill.nCastMode
    local bIsChannelSkill = skill.bIsChannelSkill
    local tbDynamicSkillMap = {
        nForceID = g_pClientPlayer.dwForceID,
        szName = "",
        nIconID = TabHelper.GetSkillIconPathByIDAndLevel(skillID, nSkillLevel),
        szDesc = "",
        tbSkillEffectDesc = {},
        tbAttrib = {},
        nType = 1,
        nCastType = UISkillCastType.Normal, -- DX通道技能释放方式与Normal一致 都是按下释放
        bJoystick = table.contain_value(kJoyStickCastModes, nCastMode),
        bCastXYZ = true,
        nPosture = 0,
        bForbidLevelUp = false,
        fPressGuardTime = 0,
        bForbidSelectTarget = false,
        bAllyTarget = false,
        -- nUIRadius = 20,
        bAreaBoxHeightFollow = false,
        bDynamicSkill = true,
        nProgressBarDirection = bIsChannelSkill and 1 or 2,
        nDXCastMode = skill.nCastMode
    }

    if nCastMode == SKILL_CAST_MODE.POINT_AREA and g_pClientPlayer.dwShapeShiftID > 0 then
        tbDynamicSkillMap.bJoystick = false  -- 载具上的选点技能不走遥感选点
    end

    if not bIsChannelSkill and (type == "keydown" or nCastMode == SKILL_CAST_MODE.CASTER_SINGLE or nCastMode == SKILL_CAST_MODE.TARGET_SINGLE) then
        tbDynamicSkillMap.nCastType = UISkillCastType.Down
    end

    return tbDynamicSkillMap
end

function SkillData.GetSkillName(dwSkillID, dwSkillLevel)
    local tSkillTab = TabHelper.GetUISkillMap(dwSkillID)
    local szSkillName = (tSkillTab and tSkillTab.szName) or ""
    local dwSkillLevel = dwSkillLevel or 1

    if szSkillName == "" then
        szSkillName = Table_GetSkillName(dwSkillID, dwSkillLevel)
        szSkillName = szSkillName ~= "" and UIHelper.GBKToUTF8(szSkillName) or ""
    end

    if szSkillName == "" then
        szSkillName = Table_GetBuffName(dwSkillID, dwSkillLevel)
        szSkillName = szSkillName ~= "" and UIHelper.GBKToUTF8(szSkillName) or ""
    end

    return szSkillName
end

function SkillData.SetCastPoint(x, y, z)
    if SkillData.castPoint == nil then
        SkillData.castPoint = cc.vec3(0, 0, 0)
    end
    SkillData.castPoint.x = x
    SkillData.castPoint.y = y
    SkillData.castPoint.z = z
end

--获取表现逻辑修正过的技能释放点
function SkillData.UpdateCastPointFromRL(player, nX, nY)
    local a1, a2, a3, cameraX, cameraZ, cameraY, playerX, playerZ, playerY = Camera_GetRTParams()
    local playerAbsoluteX, playerAbsoluteY, playerAbsoluteZ = player.GetAbsoluteCoordinate()

    local trueX = playerX - cameraX
    local trueY = playerY - cameraY

    local nNormalizeX, nNormalizeY = kmath.normalize2(trueX, trueY)
    local forward = cc.p(nNormalizeX, nNormalizeY)

    local distance = kmath.len2(0, 0, nX, nY)

    local up = cc.p(0, 1)
    local deg_45 = cc.p(nX, nY)
    local radius = cc.pGetAngle(up, deg_45) -- 向量夹角：弧度

    local calculatedVec = cc.pForAngle(radius)
    local finalDirection = cc.pRotate(forward, calculatedVec)
    local nX = finalDirection.x * distance + playerAbsoluteX
    local nY = finalDirection.y * distance + playerAbsoluteY
    local nZ = player.GetScene().GetFloor(nX, nY, playerAbsoluteZ) or playerAbsoluteZ
    SkillData.SetCastPoint(nX, nY, nZ)
end

-- 获取表现逻辑修正过的技能释放点
function SkillData.GetCastPointFromRL(pPlayer, nDirX, nDirY, nDistance, bHeightFollow)
    local a1, a2, a3, cameraX, cameraZ, cameraY, playerX, playerZ, playerY = Camera_GetRTParams()
    local trueX = playerX - cameraX
    local trueY = playerY - cameraY

    local nNormalizeX, nNormalizeY = kmath.normalize2(trueX, trueY)
    local forward = cc.p(nNormalizeX, nNormalizeY)

    local up = cc.p(0, 1)
    local deg_45 = cc.p(nDirX, nDirY)
    local radius = cc.pGetAngle(up, deg_45) -- 向量夹角：弧度

    local calculatedVec = cc.pForAngle(radius)
    local finalDirection = cc.pRotate(forward, calculatedVec)
    local nSrcX, nSrcY, nSrcZ = pPlayer.GetAbsoluteCoordinate()
    local nX = finalDirection.x * nDistance + nSrcX
    local nY = finalDirection.y * nDistance + nSrcY
    local nZ = nSrcZ
    if not bHeightFollow then
        nX, nY, nZ = pPlayer.GetScene().GetAlongFloorPoint(
                nSrcX, nSrcY, nSrcZ,
                nX, nY,
                1.0 / Const.kMetreHeight,
                10.0 / Const.kMetreHeight,
                0.25 / Const.kMetreHeight
        )
        --LOG("queryCastFloor src:{%d, %d, %d} dst:{%d, %d, %d}", nSrcX, nSrcY, nSrcZ, nX, nY, nZ)
        nZ = pPlayer.GetScene().GetFloor(nX, nY, nZ) or nZ
    end
    return nX, nY, nZ
end

function SkillData.GetCastPoint()
    --LOG.ERROR("SkillData.GetCastPoint")
    return SkillData.castPoint --or Lua2CSData.GetCastPoint()

    --return Lua2CSData.GetCastPoint()
end

function SkillData.CastSkill(player, SkillID, targetID, nSkillLevel, skilldirection)
    if MapHelper.IsRemotePvpMap() then
        StopFollow()
    end
    SpecialSettings.ChangeMultiStageSkill(SkillID)
    local mask = (SkillID * (SkillID % 10 + 1))
    local nRes = OnUseSkill(SkillID, mask)
    print("SkillData.CastSkill", SkillID, mask, nRes)
    Event.Dispatch(EventType.OnClientCastSkill, SkillID)
    --local logicDirection = -1
    --local ignoreJoystickHold = false
    --if SkillData.DisableCast or not player or not SkillID then
    --    return
    --end
    --if not nSkillLevel then
    --    nSkillLevel = 0
    --end
    --SkillData.ProcessSelectTarget(SkillID)
    --do
    --    local skillConfig = TabHelper.GetUISkill(SkillID)
    --    if skillConfig and not skillConfig.bJoystick then
    --        local info = SkillData.AutoSelectEnemy(SkillID)
    --        if info then
    --            skilldirection = info.angle
    --            if skilldirection and not info.IsRectExt and info.IsRectType then
    --                ignoreJoystickHold = true
    --            end
    --        end
    --    end
    --end
    --
    --if not skilldirection or skilldirection < -1000 then
    --    local skillConfig = TabHelper.GetUISkill(SkillID)
    --    if skillConfig then
    --        logicDirection = Lua2CSData.GetJoystickDirection(skillConfig.CanCast360)
    --    else
    --        logicDirection = Lua2CSData.GetJoystickDirection(true)
    --    end
    --else
    --    logicDirection = Lua2CSData.ScreenDirectionToLogicDirection(skilldirection)
    --end
    --
    --player.bIgnoreJoystickHold = ignoreJoystickHold
    --
    --if targetID then
    --    targetID = PlayerData.GetMainCtrlPlayerID(targetID) or targetID
    --    player:CastSkillToTargetByGlobalID(SkillID, nSkillLevel, logicDirection, targetID)
    --else
    --    player:CastSkillToTargetByGlobalID(SkillID, nSkillLevel, logicDirection)
    --end
end

---comment 对点释放技能
---@param player KPlayer
---@param nSkillID integer
---@param nSkillLevel integer
---@param nX integer
---@param nY integer
---@param nZ integer
function SkillData.CastSkillXYZ(player, nSkillID, nSkillLevel, nX, nY, nZ)
    if SkillData.DisableCast or not player or not nSkillID then
        return
    end
    if MapHelper.IsRemotePvpMap() then
        StopFollow()
    end

    local skillConfig = TabHelper.GetUISkill(nSkillID)
    --TODO: bCastSkillByUseItem字段已经被废弃
    if skillConfig and skillConfig.bCastSkillByUseItem then
        -- if SkillData.CanCastSkill(player, nSkillID) then
        --     local itemCount = ItemData.GetCountByTabID(skillConfig.nCastSkillByUseItem_ItemID)
        --     if itemCount > 0 then
        --         local item = ItemData.GetItemByTabID(skillConfig.nCastSkillByUseItem_ItemID)

        --         ItemData.ReqUseItemToCoordinate(item, 1, pos.x, pos.y, pos.z)
        --         CastSkillXYZ(SkillID, nSkillLevel, pos.x, pos.y, pos.z)

        --     end
        -- end
        assert(false)
    else
        Event.Dispatch(EventType.OnClientCastSkill, nSkillID)
        CastSkillXYZ(nSkillID, nSkillLevel, nX, nY, nZ)
    end
end

function SkillData.GetSkill(player, SkillID)
    local nSkillLevel = player.GetSkillLevel(SkillID)
    if not nSkillLevel or nSkillLevel == 0 then
        return GetSkill(SkillID, 1)
    end

    return GetPlayerSkill(SkillID, nSkillLevel, player.dwID)
end

---获取当前角色的大招技能
function SkillData.GetUniqueSkillID(nCurrentKungFuID, nCurrentSetID)
    local player = g_pClientPlayer
    if not player then
        return
    end

    nCurrentKungFuID = nCurrentKungFuID or player.GetActualKungfuMountID()
    nCurrentSetID = nCurrentSetID or player.GetTalentCurrentSet(player.dwForceID, nCurrentKungFuID)

    if nCurrentKungFuID and nCurrentSetID then
        local tList = SkillData.GetQixueList(true, nCurrentKungFuID, nCurrentSetID)

        local tQixue = tList[4] --从奇穴列表中获取第四重奇穴主动技能信息
        if tQixue then
            local nSelectIndex = tQixue.nSelectIndex
            local tSkillArray = tQixue.SkillArray

            if nSelectIndex > 0 then
                local tSkill = tSkillArray[nSelectIndex]
                return tSkill.dwSkillID
            end
        end
    end
    return nil
end

---获取当前角色的斗气奇穴技能
function SkillData.GetDouqiSkillID(nCurrentKungFuID, nCurrentSetID)
    if nCurrentKungFuID and nCurrentSetID then
        local tList = SkillData.GetQixueList(true, nCurrentKungFuID, nCurrentSetID)

        local tQixue = tList[5] --从奇穴列表中获取第四重奇穴主动技能信息
        if tQixue then
            local nSelectIndex = tQixue.nSelectIndex
            local tSkillArray = tQixue.SkillArray

            if nSelectIndex > 0 then
                local tSkill = tSkillArray[nSelectIndex]
                return tSkill.dwSkillID
            end
        end
    end
end

function SkillData.GetCastSkillResult(player, nSkillID, nTargetID)
    local pSkill = SkillData.GetSkill(player, nSkillID)
    if not pSkill then
        return
    end

    if nTargetID then
        return pSkill.UITestCast(player.dwID, false, nTargetID)
    end

    return pSkill.UITestCast(player.dwID, IsSkillCastMyself(pSkill))
end

---comment 检测角色是否能够释放技能
---@param player PlayType 释放角色
---@param nSkillID number 技能ID
---@param nTargetID any 目标ID(nil)
---@return boolean
function SkillData.CanCastSkill(player, nSkillID, nTargetID)
    local pSkill = SkillData.GetSkill(player, nSkillID)
    if not pSkill then
        return
    end

    if nSkillID == UI_SKILL_JUMP_ID then
        if QTEMgr.IsInDynamicSkillState() and QTEMgr.CanJump() then
            return player.nMaxJumpCount > 0
        end
        return player.nJumpCount < player.nMaxJumpCount or player.nFlyFlag == 1 -- 判断是否可跳跃
    end

    local bPlayerState = pSkill.CheckCasterState(player.dwID) == SKILL_RESULT_CODE.SUCCESS

    bPlayerState = bPlayerState and pSkill.CheckSilence(player.dwID) == SKILL_RESULT_CODE.SUCCESS

    if nTargetID and pSkill.nPlatformType == SkillPlatformType.Mobile then
        return bPlayerState and pSkill.UITestCast(player.dwID, false, nTargetID) == SKILL_RESULT_CODE.SUCCESS
    end

    return bPlayerState and pSkill.UITestCast(player.dwID, IsSkillCastMyself(pSkill)) == SKILL_RESULT_CODE.SUCCESS
end

---comment 检测能否对点释放技能
---@param pPlayer KPlayer
---@param nSkillID integer
---@param nSkillLevel integer
---@param nX integer
---@param nY integer
---@param nZ integer
---@return boolean
function SkillData.CanCastSkillXYZ(pPlayer, nSkillID, nSkillLevel, nX, nY, nZ, bItem)
    local pSkill = SkillData.GetSkill(pPlayer, nSkillID, nSkillLevel)

    if not pSkill then
        return false
    end

    if bItem == nil then
        bItem = false
    end

    local bPlayerState = pSkill.CheckCasterState(pPlayer.dwID) == SKILL_RESULT_CODE.SUCCESS
    bPlayerState = bPlayerState and pSkill.CheckSilence(pPlayer.dwID) == SKILL_RESULT_CODE.SUCCESS
    bPlayerState = bPlayerState and pSkill.CheckDistance(pPlayer.dwID, nX, nY, nZ) == SKILL_RESULT_CODE.SUCCESS
    if not bItem then
        bPlayerState = bPlayerState and pSkill.UITestCast(pPlayer.dwID, nX, nY, nZ) == SKILL_RESULT_CODE.SUCCESS -- 物品技能不走UITestCast
    end

    return bPlayerState
end

-- TODO： 为移动端设计的全新的展示逻辑
---@note 技能是否能显示
function SkillData.CanUIShow(pPlayer, nSkillID)
    if not pPlayer then
        return false
    end

    if pPlayer.dwForceID == FORCE_TYPE.JIANG_HU and nSkillID == UI_SKILL_JUMP_ID then
        return true --特殊处理大侠号跳跃
    end

    -- 判断技能与关联心法是否匹配
    local nKungFuID = pPlayer.GetActualKungfuMountID()
    local nLevel = pPlayer.GetSkillLevel(nSkillID)
    if nLevel > 0 then
        local pSkill = GetSkill(nSkillID, pPlayer.GetSkillLevel(nSkillID))
        return pSkill and (pSkill.dwMountRequestDetail == 0 or pSkill.dwMountRequestDetail == nKungFuID)
    end

    return false
end

function SkillData.SetCastPointToTargetPos()
    local dwTargetType, dwTargetID = g_pClientPlayer.GetTarget()
    local pTarget = (dwTargetType == TARGET.NPC or dwTargetType == TARGET.PLAYER) and Global.GetCharacter(dwTargetID)
    if not pTarget then
        pTarget = g_pClientPlayer
    end
    if pTarget then
        local nTarX, nTarY, nTarZ = pTarget.GetAbsoluteCoordinate()
        SkillData.SetCastPoint(nTarX, nTarY, nTarZ)
    end
end

function SkillData.GetKungFuList(bGetHD)
    local fnIsHDKungfu = function(tSkill, player)
        if not tSkill or not (tSkill.nUIType == SkillNUIType.XinFa and tSkill.nPlatformType ~= SkillPlatformType.Mobile) then
            return false
        end
        return tSkill.dwMountType == ForceIDToMountType[player.dwForceID]
                or IsNoneSchoolKungfu(tSkill.dwSkillID) or player.dwForceID == 0 -- 显示当前门派的心法或者新流派
    end

    local fnCheckFunc = SkillData.IsMobileKungFu
    if bGetHD == true then
        fnCheckFunc = fnIsHDKungfu
    end

    local aKf = {}
    local player = g_pClientPlayer
    if not player then
        return
    end
    local aSchool = player.GetSchoolList()
    for k, v in pairs(aSchool) do
        local aKungfu = player.GetKungfuList(v)
        for dwID, dwLevel in pairs(aKungfu) do
            local skill = GetSkill(dwID, dwLevel)
            if fnCheckFunc(skill, player) then
                table.insert(aKf, { dwID, dwLevel })
            end
        end
    end
    return aKf
end

function SkillData.GetKungFuList_Sorted(bGetHD)
    local list = SkillData.GetKungFuList(bGetHD)
    table.sort(list, function(a, b)
        local nSkillIDA = a[1]
        local nSkillIDB = b[1]
        if bGetHD then
            return nSkillIDA < nSkillIDB -- 仅根据ID排序
        else
            local tbOrderA = TabHelper.GetUISkill(nSkillIDA).tbOrder or { [1] = 99 }
            local tbOrderB = TabHelper.GetUISkill(nSkillIDB).tbOrder or { [1] = 99 }
            return tbOrderA[1] < tbOrderB[1] --根据order进行相应的排序
        end
    end)
    return list
end

--获取技能CD
function SkillData.GetSkillCDProcess(player, SkillID)
    if player then
        local bCool, nLeft, nTotal, _, bPublicCD = player.GetSkillCDProgress(SkillID, 1)
        local bIsRecharge = true
        local nMaxCount, dwCDID = player.GetCDMaxCount(SkillID)
        local nLeftCooldown, nCDCount
        if nMaxCount > 1 then
            nLeftCooldown, nCDCount = player.GetCDLeft(dwCDID)
        else
            nMaxCount, dwCDID = player.GetCDMaxOverDraftCount(SkillID)
            if nMaxCount > 1 then
                bIsRecharge = false
                nLeftCooldown, nCDCount = player.GetOverDraftCoolDown(dwCDID)
                nCDCount = nMaxCount - nCDCount -- 透支技能和充能的nCDCount逻辑统一
            end
        end

        -- 处理透支或者充能技能的公共CD情况
        if nMaxCount > 1 then
            local pSkill = SkillData.GetSkill(player, SkillID)
            local dwPublicCDID = pSkill and pSkill.GetPublicCoolDown()
            if dwPublicCDID > 0 then
                local nLeftPublicCooldown, nCDCount = player.GetCDLeft(dwPublicCDID)
                bPublicCD = nLeftPublicCooldown > 0
            end
        end

        return bCool, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD
    end
end

function SkillData.GetSkillCDDesc(nSkillID, nSkillLevel, player)
    player = player or g_pClientPlayer
    if player then
        local tRecipeKey = player.GetSkillRecipeKey(nSkillID, nSkillLevel)
        if tRecipeKey then
            local hSkillInfo = GetSkillInfoEx(tRecipeKey, player.dwID)
            local tOriRecipeKey = clone(tRecipeKey)
            for nIndex = 1, 12, 1 do
                tOriRecipeKey["recipe" .. nIndex] = 0
            end
            local hOriSkillInfo = GetSkillInfoEx(tOriRecipeKey, player.dwID)
            local szCoolDown = FormatCooldown(nSkillID, nSkillLevel, hSkillInfo, hOriSkillInfo, true, player)
            return szCoolDown
        else
            return g_tStrings.STR_SKILL_NOT_SUITABLE_KUNGFU
        end
    end
end

function SkillData.GetSelfToTargetObstaclePoint(player, x, y, z)
    if not x then
        local vec3 = SkillData.GetCastPoint()
        x = vec3.x
        y = vec3.y
        z = vec3.z
    end

    if player then
        return player:GetSelfToTargetObstaclePoint(x, y, z)
    end
end

--技能缓存相关
function SkillData.AddSkillCache(nSlotID, CastType, StartTime, nSkillID)
    if SkillData.LastCastInfo then
        if SkillData.LastCastInfo.nSlotID == nSlotID then
            if SkillData.LastCastInfo.LastCastTime + SkillData.SkillCacheTime >= StartTime then
                return
            end
        end
    end

    local bUseCache = GameSettingData.GetNewValue(UISettingKey.SkillQueueing)
    if bUseCache == true then
        SkillData.CacheSlotInfo = {}
        SkillData.CacheSlotInfo.nSlotID = nSlotID
        SkillData.CacheSlotInfo.CastType = CastType
        SkillData.CacheSlotInfo.StartTime = StartTime
        SkillData.CacheSlotInfo.nSkillID = nSkillID
    end
end

function SkillData.AddLastCast(nSlotID, castTime)
    if not SkillData.LastCastInfo then
        SkillData.LastCastInfo = {}
    end

    SkillData.LastCastInfo.nSlotID = nSlotID
    SkillData.LastCastInfo.LastCastTime = castTime
end

function SkillData.ClearSkillCache()
    SkillData.CacheSlotInfo = {}
end

function SkillData.GetCacheSlotID()
    if SkillData.CacheSlotInfo and SkillData.CacheSlotInfo.nSlotID then
        return SkillData.CacheSlotInfo.nSlotID
    end
end

--技能圆盘取消技能释放
function SkillData.IsUseSkillDirectionCancel()
    return SkillData.bUseSkillDirectionCancel
end

function SkillData.IsMobileKungFu(tSkill, player)
    return tSkill and tSkill.nUIType == SkillNUIType.XinFa and tSkill.nPlatformType == SkillPlatformType.Mobile
            and (tSkill.dwMountType == ForceIDToMountType[player.dwForceID]
            or IsNoneSchoolKungfu(tSkill.dwSkillID) or player.dwForceID == 0) -- 显示当前门派的心法或者新流派)
end

function SkillData.IsUsingHDKungFu(dwKungFuID)
    if not g_pClientPlayer then
        return false
    end
    if BattleFieldData.IsInXunBaoBattleFieldMap() then
        return false
    end
    dwKungFuID = dwKungFuID or g_pClientPlayer.GetActualKungfuMountID()
    return TabHelper.IsHDKungfuID(dwKungFuID)
end

---comment 搜索技能目标
---@param pPlayer KPlayer 释放角色
---@param nSkillID integer 技能ID
---@param nSkillLevel integer 技能等级
function SkillData.SelectSkillTarget(pPlayer, nSkillID, nSkillLevel, tSkillConfig)
    local pSkill = GetSkill(nSkillID, nSkillLevel)
    if not pSkill then
        return
    end

    -- 根据半径搜索目标
    local nRadius = pPlayer.GetSkillMaxRadius(nSkillID, nSkillLevel)
    local nHeight = pSkill.nCastHeight > 0 and pSkill.nCastHeight or pSkill.nHeight
    if nHeight == 0 then
        nHeight = nRadius -- 如果没有配置高度则用半径
    end

    local nSearchRadius
    -- 搜索半径，选取技能半径、视野半径的最大值
    if tSkillConfig.bJoystick and TargetMgr.IsEnableSearch() then
        nSearchRadius = math.max(TargetMgr.GetSearchRadius() / kMetreLength, nRadius)
    else
        nSearchRadius = nRadius
    end

    --TODO: 如果是选头像，这里要根据一些参数得到哪些人的头像
    local tTargetIDs
    -- SearchForCharacter 会将搜索到的目标列表按照距离排序
    if tSkillConfig.bAllyTarget then
        local tSearch = pPlayer.SearchForCharacter(nSearchRadius, kDirectionCount,
                RELATION_TYPE.ALLY + RELATION_TYPE.PARTY,
                {
                    bAdjustByVisible = pSkill.bUse3DObstacle, -- 忽略障碍
                }
        )
        tTargetIDs = FliterUnSelectableTarget(tSearch, "Ally")
    else
        local tSearch = pPlayer.SearchForCharacter(nSearchRadius, kDirectionCount, RELATION_TYPE.ENEMY,
                {
                    bAdjustByVisible = pSkill.bUse3DObstacle, -- 忽略障碍
                }
        )
        tTargetIDs = FliterUnSelectableTarget(tSearch, "Enmey") or {}
    end

    -- 过滤高度不匹配的目标
    local tTargets = {}
    local nMyX, nMyY, nMyZ = pPlayer.GetAbsoluteCoordinate()
    for _, nID in ipairs(tTargetIDs) do
        local pObj = Global.GetCharacter(nID)
        if pObj and math.abs(pObj.nZ - nMyZ) / kZpointToXy <= nHeight then
            table.insert(tTargets, { nID = nID, nX = pObj.nX, nY = pObj.nY, nZ = pObj.nZ })
        end
    end

    local tTarget
    for _, t in ipairs(tTargets) do
        if self.CanCastSkill(pPlayer, nSkillID, t.nID) then
            tTarget = t
            break
        end
    end

    if not tTarget then
        -- no valid target, try self as target
        if not self.CanCastSkill(pPlayer, nSkillID, pPlayer.dwID) then
            return
        end

        tTarget = { dwID = pPlayer.dwID, nX = pPlayer.nX, nY = pPlayer.nY, nZ = pPlayer.nZ }
    end

    if tSkillConfig.bJoystick then
        -- 修正坐标
        local nDis = getDistance(tTarget.nX - nMyX, tTarget.nY - nMyY, 0)
        -- 记录减少0.1米，避免浮点计算误差
        if nDis > nRadius - 0.1 * kMetreLength then
            local nPer = nRadius / nDis
            tTarget.nX = nMyX + (tTarget.nX - nMyX) * nPer
            tTarget.nY = nMyY + (tTarget.nY - nMyY) * nPer
        end

        if not tSkillConfig.bCastXYZ and nDis < 0.1 * kMetreLength then
            -- 方向技
            --TIDO: 使用角色面向1米处坐标
        end
    end
    return tTarget
end

function SkillData.GetQixueList(bSortbyLevel, dwMKungfuID, nSetID, player)
    local hPlayer = player or GetClientPlayer()
    if not hPlayer then
        return {}
    end

    local dwForceID = hPlayer.dwForceID
    if not dwMKungfuID then
        local tKungfu = hPlayer.GetActualKungfuMount()
        if not tKungfu then
            return {}
        end
        dwMKungfuID = tKungfu.dwSkillID
    end

    if not nSetID then
        nSetID = hPlayer.GetTalentCurrentSet(dwForceID, dwMKungfuID)
    end

    if nSetID == -1 then
        return {}
    end

    local tList = hPlayer.GetTalentInfo(dwForceID, dwMKungfuID, nSetID)
    if not tList or #tList <= 0 then
        return {}
    end

    local tDouqi = Table_GetSkillQixueDouqiInfo(dwMKungfuID)
    if tDouqi then
        for _, tQixue in ipairs(tList) do
            if tQixue.nType == TALENT_SELECTION_TYPE.NONE and tQixue.dwPointID == tDouqi.dwPointID then
                tQixue.nType = SkillData.DouqiQixueType
                tQixue.nSpecialIndex = tDouqi.nSPIndex
            end
        end
    end


    if bSortbyLevel then
        local fnSortByLevel = function(tLeft, tRight)
            if tLeft.nRequireLevel == tRight.nRequireLevel then
                return tLeft.dwPointID < tRight.dwPointID
            end
            return tLeft.nRequireLevel < tRight.nRequireLevel
        end

        table.sort(tList, fnSortByLevel)
    end
    return tList
end

function SkillData.GetQiXueModifiedSkillIDList(dwKungfuID, nSetID, player)
    local tResult = {}
    local tList = SkillData.GetQixueList(true, dwKungfuID, nSetID, player)
    for index = 1, 4 do
        local tQixue = tList[index]
        if tQixue then
            local nSelectIndex = tQixue.nSelectIndex
            local tSkillArray = tQixue.SkillArray

            if nSelectIndex > 0 then
                local tSkill = tSkillArray[nSelectIndex]
                local nQiXueSkillID = tSkill.dwSkillID
                local tQiXueSkillInfo = TabHelper.GetUISkillMap(nQiXueSkillID)
                if tQiXueSkillInfo then
                    for _, szString in ipairs(tQiXueSkillInfo.tbSkillEffectDescTalent) do
                        local splited = string.split(szString, ":")
                        local nSkillID = tonumber(splited[1])
                        local nMijiID = #splited > 1 and tonumber(splited[2]) or nil
                        if not tResult[nSkillID] then
                            tResult[nSkillID] = {}
                        end
                        table.insert(tResult[nSkillID], { nQiXueID = nQiXueSkillID, nMijiID = nMijiID })
                    end
                end
            end
        end
    end
    return tResult
end

function SkillData.ChangeMirrorSkillRecipeList(dwSkillID, dwLevel)
    local dwMirrorSkillID = GetSkillRecipeMirror(dwSkillID)
    if dwSkillID and dwMirrorSkillID and dwMirrorSkillID ~= 0 then
        local dwMirrorSkillLevel = nil
        local hPlayer = g_pClientPlayer
        if hPlayer then
            dwMirrorSkillLevel = hPlayer.GetSkillLevel(dwSkillID)
        end
        if dwMirrorSkillLevel and dwMirrorSkillLevel > 0 then
            dwSkillID = dwMirrorSkillID
            dwLevel = dwMirrorSkillLevel
        end
    end
    return dwSkillID, dwLevel
end

function SkillData.GetRecipeList(dwSkillID, dwLevel, targetPlayer)
    local tRecipeList = Table_GetRecipeList(dwSkillID)
    if not tRecipeList then
        return {}
    end

    local hPlayer = targetPlayer or GetClientPlayer()
    if not hPlayer then
        return {}
    end
    local tMyRecipeList = hPlayer.GetSkillRecipeList(dwSkillID, dwLevel)
    if not tMyRecipeList then
        tMyRecipeList = {}
    end
    local tMyRecipeMap = {}
    for _, tRecipe in ipairs(tMyRecipeList) do
        tMyRecipeMap[tRecipe.recipe_id] = tRecipe
    end

    local tRecipeGroupList = {}
    for nIndex, tRecipe in ipairs(tRecipeList) do
        local tRecipeInfo = {}
        local tSkillRecipe = Table_GetSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
        local dwID = 0
        if tSkillRecipe then
            dwID = tSkillRecipe.dwTypeID
        end
        if not tRecipeGroupList[dwID] then
            tRecipeGroupList[dwID] = {}
        end

        if tMyRecipeMap[tRecipe.recipe_id] then
            tRecipeInfo = tMyRecipeMap[tRecipe.recipe_id]
            tRecipeInfo.bHave = true
        else
            tRecipeInfo = tRecipe
            tRecipeInfo.bHave = true
            if tSkillRecipe.nTrainCost >= 0 then
                tRecipeInfo.bCanOpen = true
            end
        end
        tRecipeInfo.nPriority = tSkillRecipe.nPriority
        tRecipeInfo.nTeachPriority = tSkillRecipe.nTeachPriority
        table.insert(tRecipeGroupList[dwID], tRecipeInfo)
    end

    return tRecipeGroupList
end

function SkillData.GetFinalRecipeList(nSkillID, targetPlayer)
    if not nSkillID then
        return {}, false
    end
    local hPlayer = targetPlayer or g_pClientPlayer
    local bActivated = false
    local nActivatedMijiID
    local dwLevel = hPlayer.GetSkillLevel(nSkillID)

    local nOriginalSkill = GetSkillRecipeMirror(nSkillID)
    if nOriginalSkill == 0 then
        nOriginalSkill = Table_GetSkillRecipeMirror(nSkillID) or nOriginalSkill -- 兼容dx替换逻辑
    end

    if nOriginalSkill > 0 then
        nSkillID = nOriginalSkill
        dwLevel = 1
    end

    if dwLevel <= 0 then
        dwLevel = 1
    end

    local tList = SkillData.GetRecipeList(nSkillID, dwLevel, hPlayer)
    local tRecipes = {}
    for dwTypeID, tRecipeGroup in pairs(tList) do
        if tRecipeGroup and #tRecipeGroup >= 1 then
            for _, tRecipe in ipairs(tRecipeGroup) do
                table.insert(tRecipes, tRecipe)
                if tRecipe.active then
                    bActivated = tRecipe.active
                    nActivatedMijiID = tRecipe.recipe_id
                end
            end
        end
    end

    return tRecipes, bActivated, nActivatedMijiID
end

function SkillData.ClearSpecialNoun()
    SkillData.tTotalNoun = {}
end

function SkillData.GetNounDesc(tNounInfo)
    if tNounInfo then
        local dwID = tNounInfo.dwSkillID
        local dwLevel = tNounInfo.dwSkillLevel
        if tNounInfo.szSource == DESC_CONTEXT_SOURCE.BUFF then
            return GetBuffDesc(dwID, dwLevel, "desc", tBuffCtx) or ""
        elseif tNounInfo.szSource == DESC_CONTEXT_SOURCE.SKILL then
            local szDesc, szDesc1 = GetSkillDesc(dwID, dwLevel, tNounInfo.skillkey, tNounInfo.skillInfo, tNounInfo.bShort, tNounInfo.hPlayer, tSkillCtx)
            return szDesc
        elseif tNounInfo.szSource == DESC_CONTEXT_SOURCE.NOUN then
            return tNounInfo.szDesc
        end
    end
end

function SkillData.AddToNounTable(szNoun, dwSkillID, dwSkillLevel, skillkey, skillInfo, bShort, hPlayer)
    if szNoun and not table.contain_value(SkillData.tTotalNoun, szNoun) then
        table.insert(SkillData.tTotalNoun, szNoun)

        local nNounID = tonumber(szNoun)
        local tSkillNounInfo = nNounID and Table_GetSkillNouns(nNounID) or {}
        local t = {
            dwSkillID = dwSkillID,
            dwSkillLevel = dwSkillLevel,
            skillkey = skillkey,
            skillInfo = skillInfo,
            bShort = bShort,
            hPlayer = hPlayer,
            szName = tSkillNounInfo.szName or "",
            szDesc = tSkillNounInfo.szDesc or "",
            szRGB = tSkillNounInfo.szRGB or "",
            szSource = DESC_CONTEXT_SOURCE.NOUN,
        }
        SkillData.g_tSkillNounsList[szNoun] = t
    end
end

function SkillData.AddBuffToNounTable(szBuff, dwID, dwLevel, skillkey, skillInfo, bShort, hPlayer, tBuffCtx)
    if szBuff and not table.contain_value(SkillData.tTotalNoun, szBuff) then
        table.insert(SkillData.tTotalNoun, szBuff)
        
        local t = {
            dwSkillID = dwID,
            dwSkillLevel = dwLevel,
            skillkey = skillkey,
            skillInfo = skillInfo,
            bShort = bShort,
            hPlayer = hPlayer,
            szName = szBuff or "",
            --szDesc = szDesc,
            szRGB = "",
            szSource = DESC_CONTEXT_SOURCE.BUFF,
        }
        SkillData.g_tSkillNounsList[szBuff] = t
    end
end

function SkillData.AddSkillToNounTable(szSkill, dwID, dwLevel, skillkey, skillInfo, bShort, hPlayer, tSkillCtx)
    if szSkill and not table.contain_value(SkillData.tTotalNoun, szSkill) then
        table.insert(SkillData.tTotalNoun, szSkill)

      
        local t = {
            dwSkillID = dwID,
            dwSkillLevel = dwLevel,
            skillkey = skillkey,
            skillInfo = skillInfo,
            bShort = bShort,
            hPlayer = hPlayer,
            szName = szSkill or "",
            --szDesc = szDesc,
            szRGB = "",
            szSource = DESC_CONTEXT_SOURCE.SKILL,
        }
        SkillData.g_tSkillNounsList[szSkill] = t
    end
end

function SkillData.FormSpecialNoun(szDesc1, dwSkillID)
    local fnAddToNounTable = SkillData.AddToNounTable

    local fnReplace = function(szSub)
        fnAddToNounTable(szSub)
        local tbLinkData = { type = "ShowNounInfo", szNoun = szSub, dwSkillID = dwSkillID}
        local szLink = JsonEncode(tbLinkData)
        szLink = UrlEncode(szLink)
        return string.format("<href=%s><color=#ffe26e>[%s]</color></href>", szLink, szSub)
    end

    if not szDesc1 then
        return ""
    end

    local szResult = string.gsub(szDesc1, "{(.-)}", fnReplace)
    szResult = string.gsub(szResult, "<SUB (%d+) (%d+)>", function(dwID, dwLevel)
        dwLevel = dwLevel == "0" and 1 or dwLevel
        local szDesc = GetSubSkillDesc(dwID, dwLevel, false)
        return UIHelper.GBKToUTF8(szDesc)
    end)

    return szResult
end

---@param tSlotToNewSkillID table 槽位上对应的新技能ID
function SkillData.ChangeSkill(tSlotToNewSkillID, nCurrentKungFuID, nCurrentSetID)
    g_pClientPlayer.SetSlotToSkill(nCurrentKungFuID, nCurrentSetID, tSlotToNewSkillID)
end

function SkillData.ChangeQiXue(dwPointID, nIndex, nCurrentKungFuID, nCurrentSetID)
    local hPlayer = g_pClientPlayer
    if hPlayer and hPlayer.nLevel < SKILL_RESTRICTION_LEVEL then
        TipsHelper.ShowNormalTip("侠士达到106级后方可切换奇穴")
        return false
    end

    local nKungFuID = nCurrentKungFuID or hPlayer.GetActualKungfuMount().dwSkillID
    local nSetID = nCurrentSetID or hPlayer.GetTalentCurrentSet(hPlayer.dwForceID, nKungFuID)

    if hPlayer.bOnHorse then
        TipsHelper.ShowImportantRedTip(g_tStrings.SELECT_TALENT_ERROR_ONHORSE, 3)
        return false
    else
        local nowKungFu = g_pClientPlayer.GetActualKungfuMountID()
        local nowSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nowKungFu)
        local bPreset = not (nKungFuID == nowKungFu and nSetID == nowSetID) -- 如果有分页， 要判断是不是当前选中分页
        local nRetCode

        if bPreset then
            nRetCode = hPlayer.CanPresetNewTalentPoint(dwPointID, nIndex, nKungFuID, nSetID)
        else
            nRetCode = hPlayer.CanSelectNewTalentPoint(dwPointID, nIndex)
        end
        --LOG.ERROR("%s %s", dwPointID, nIndex)
        if nRetCode == SELECT_TALENT_RESULT.SUCCESS then
            if bPreset then
                hPlayer.PresetNewTalentPoint(dwPointID, nIndex, nKungFuID, nSetID)
            else
                hPlayer.SelectNewTalentPoint(dwPointID, nIndex)
            end
        else
            TipsHelper.ShowImportantRedTip(g_tStrings.tSelectTalentResult[nRetCode], 3)
            return false
        end
    end
    return true
end

function SkillData.GetSpecialTag(nSkillID, nCurrentKungFuID, nCurrentSetID)
    local tSkillInfo = TabHelper.GetUISkill(nSkillID)
    local szTag = tSkillInfo and tSkillInfo.szSpecialTag
    if szTag and szTag ~= "" then
        local tSplit = string.split(szTag, ':')
        local nType = tSplit[1] and tonumber(tSplit[1])
        local nMijiID, nQiXueID
        if tSplit[2] then
            local tIDs = string.split(tSplit[2], ',')
            for _, szID in ipairs(tIDs) do
                local number = tonumber(szID)
                if number > 100000 then
                    nQiXueID = number
                else
                    nMijiID = number
                end
            end
        end

        if not nMijiID and not nQiXueID then
            return nType, true
        end

        if nMijiID then
            local dwLevel = g_pClientPlayer.GetSkillLevel(nSkillID)
            local tList = SkillData.GetFinalRecipeList(nSkillID)

            for nIndex, tRecipe in ipairs(tList) do
                local bShow = tRecipe.active
                if bShow and tRecipe.recipe_id == nMijiID then
                    return nType, true
                end
            end
        end

        if nQiXueID then
            local tList = SkillData.GetQixueList(true, nCurrentKungFuID, nCurrentSetID)
            for _, tQiXueInfo in ipairs(tList) do
                local nSelectIndex = tQiXueInfo.nSelectIndex
                local tSkillArray = tQiXueInfo.SkillArray

                if nSelectIndex > 0 then
                    local tSkill = tSkillArray[nSelectIndex]
                    if tSkill.dwSkillID == nQiXueID then
                        return nType, true
                    end
                end
            end
        end

        return nType, false
    end
end

function SkillData.OnReload()

end

local function onShootPoint(x, y, z)
    SkillData.tShootPos.nX, SkillData.tShootPos.nY, SkillData.tShootPos.nZ = x, y, z
end

---comment 获取载具上当前瞄准的目标坐标
---@return integer
---@return integer
---@return integer
function SkillData.GetShootPoint()
    return SkillData.tShootPos.nX, SkillData.tShootPos.nY, SkillData.tShootPos.nZ
end

function SkillData.TryOpenPanelSkillNew()
    --if g_pClientPlayer and g_pClientPlayer.dwForceID == 0 then
    --    return
    --end

    if UIMgr.GetView(VIEW_ID.PanelSystemPrograssBar) then
        return
    end

    UIMgr.Open(VIEW_ID.PanelSkillNew)
end

function SkillData.IsPassiveSkill(dwSkillID, dwSKillLevel)
    local hSkill = GetSkill(dwSkillID, dwSKillLevel)
    return hSkill and hSkill.bIsPassiveSkill
end

local tForceIDToSkillAutoLearningTab = {}
local tForceIDToSkillAutoLearningTab_Dx = {}
local tSchoolIDToTableID = {
    [SCHOOL_TYPE.SHAO_LIN] = 12,
    [SCHOOL_TYPE.WAN_HUA] = 13,
    [SCHOOL_TYPE.TIAN_CE] = 14,
    [SCHOOL_TYPE.CHUN_YANG] = 15,
    [SCHOOL_TYPE.QI_XIU] = 16,
    [SCHOOL_TYPE.WU_DU] = 17,
    [SCHOOL_TYPE.TANG_MEN] = 18,
    [SCHOOL_TYPE.CANG_JIAN_WEN_SHUI] = 19,
    [SCHOOL_TYPE.CANG_JIAN_SHAN_JU] = 19,
    [SCHOOL_TYPE.GAI_BANG] = 20,
    [SCHOOL_TYPE.MING_JIAO] = 21,
    [SCHOOL_TYPE.CANG_YUN] = 22,
    [SCHOOL_TYPE.CHANG_GE] = 23,
    [SCHOOL_TYPE.BA_DAO] = 24,
    [SCHOOL_TYPE.PENG_LAI] = 25,
    [SCHOOL_TYPE.LING_XUE] = 26,
    [SCHOOL_TYPE.YAN_TIAN] = 27,
    [SCHOOL_TYPE.YAO_ZONG] = 28,
    [SCHOOL_TYPE.DAO_ZONG] = 29,
    [SCHOOL_TYPE.WAN_LING] = 30,
    [SCHOOL_TYPE.DUAN_SHI] = 31,
    [SCHOOL_TYPE.WU_XIANG] = 32,
}

function SkillData.GetSchoolSkillList(nSchoolID)
    local tAllSkills = tForceIDToSkillAutoLearningTab[nSchoolID] or {}
    if #tAllSkills > 0 then
        return tAllSkills
    end

    local tSetSkills = {}

    for i, tRow in pairs(GetSkillAutoLearnTable(tSchoolIDToTableID[nSchoolID]).SkillArray) do
        local nSkillID = tRow.dwSkillID
        local tSkill = GetSkill(nSkillID, 1)
        local skillInfo = not tSetSkills[nSkillID] and tSkill.nUIType ~= SkillNUIType.XinFa and TabHelper.GetUISkill(nSkillID)
        if skillInfo then
            table.insert(tAllSkills, { nID = nSkillID, tInfo = skillInfo })
            tSetSkills[nSkillID] = true
        end
    end

    tForceIDToSkillAutoLearningTab[nSchoolID] = tAllSkills
    return tAllSkills
end

function SkillData.GetSchoolDxSkillList(nSchoolID, nKongFuID)
    local tAllSkills = tForceIDToSkillAutoLearningTab_Dx[nSchoolID] or {}
    if #tAllSkills > 0 then
        return tAllSkills
    end

    local tSetSkills = {}

    local tKungfu = Table_GetMKungfuList(nKongFuID)
    for i, tRow in pairs(GetSkillAutoLearnTable(tSchoolIDToTableID[nSchoolID]).SkillArray) do
        local nSkillID = tRow.dwSkillID
        local nLevel = tRow.dwSkillLevel
        local tSkill = GetSkill(nSkillID, 1)
        local skillInfo = not tSetSkills[nSkillID] and tSkill.nUIType ~= SkillNUIType.XinFa and not TabHelper.GetUISkill(nSkillID) and Table_GetSkill(nSkillID, nLevel)
        if skillInfo and not table.contain_value(tKungfu, nSkillID) then
            table.insert(tAllSkills, { nID = nSkillID, tInfo = skillInfo })
            tSetSkills[nSkillID] = true
        end
    end

    tForceIDToSkillAutoLearningTab_Dx[nSchoolID] = tAllSkills
    return tAllSkills
end

function SkillData.GetQiXueByTalentGroup(nTalentGroup, bDxSkill)
    local tTabTitle = {
        { f = "i", t = "ForceID" },
        { f = "i", t = "KungFuID" },
        { f = "i", t = "PointID" },
        { f = "i", t = "CostTrain" },
        { f = "i", t = "CostNothing" },
        { f = "i", t = "PointRequireLevel" },
        { f = "i", t = "SkillID1" },
        { f = "i", t = "SkillLevel1" },
        { f = "i", t = "RequireLevel1" },
        { f = "i", t = "RequireQuestID1" },
        { f = "i", t = "SkillID2" },
        { f = "i", t = "SkillLevel2" },
        { f = "i", t = "RequireLevel2" },
        { f = "i", t = "RequireQuestID2" },

        { f = "i", t = "SkillID21" },
        { f = "i", t = "SkillLevel21" },
        { f = "i", t = "RequireLevel21" },
        { f = "i", t = "RequireQuestID21" },
        { f = "i", t = "SkillID22" },
        { f = "i", t = "SkillLevel22" },
        { f = "i", t = "RequireLevel22" },
        { f = "i", t = "RequireQuestID22" },
        { f = "i", t = "SkillID23" },
        { f = "i", t = "SkillLevel23" },
        { f = "i", t = "RequireLevel23" },
        { f = "i", t = "RequireQuestID23" },
    }

    local tDxTabTitle = {
        { f = "i", t = "ForceID" },
        { f = "i", t = "KungFuID" },
        { f = "i", t = "PointID" },
        { f = "i", t = "Type" },
        { f = "i", t = "CostTrain" },
        { f = "i", t = "PointRequireLevel" },
        { f = "i", t = "SkillID1" },
        { f = "i", t = "SkillLevel1" },
        { f = "i", t = "RequireLevel1" },
        { f = "i", t = "RequireQuestID1" },
        { f = "i", t = "SkillColor1" },
        { f = "i", t = "SkillID2" },
        { f = "i", t = "SkillLevel2" },
        { f = "i", t = "RequireLevel2" },
        { f = "i", t = "RequireQuestID2" },
        { f = "i", t = "SkillColor2" },
        { f = "i", t = "SkillID3" },
        { f = "i", t = "SkillLevel3" },
        { f = "i", t = "RequireLevel3" },
        { f = "i", t = "RequireQuestID3" },
        { f = "i", t = "SkillColor3" },
        { f = "i", t = "SkillID4" },
        { f = "i", t = "SkillLevel4" },
        { f = "i", t = "RequireLevel4" },
        { f = "i", t = "RequireQuestID4" },
        { f = "i", t = "SkillColor4" },
        { f = "i", t = "SkillID5" },
        { f = "i", t = "SkillLevel5" },
        { f = "i", t = "RequireLevel5" },
        { f = "i", t = "RequireQuestID5" },
        { f = "i", t = "SkillColor5" },
        { f = "i", t = "SkillID6" },
        { f = "i", t = "SkillLevel6" },
        { f = "i", t = "RequireLevel6" },
        { f = "i", t = "RequireQuestID6" },
        { f = "i", t = "SkillColor6" },
        { f = "i", t = "SkillID7" },
        { f = "i", t = "SkillLevel7" },
        { f = "i", t = "RequireLevel7" },
        { f = "i", t = "RequireQuestID7" },
        { f = "i", t = "SkillColor7" },
        { f = "i", t = "SkillID8" },
        { f = "i", t = "SkillLevel8" },
        { f = "i", t = "RequireLevel8" },
        { f = "i", t = "RequireQuestID8" },
        { f = "i", t = "SkillColor8" },
        { f = "i", t = "SkillID9" },
        { f = "i", t = "SkillLevel9" },
        { f = "i", t = "RequireLevel9" },
        { f = "i", t = "RequireQuestID9" },
        { f = "i", t = "SkillColor9" },
        { f = "i", t = "SkillID10" },
        { f = "i", t = "SkillLevel10" },
        { f = "i", t = "RequireLevel10" },
        { f = "i", t = "RequireQuestID10" },
        { f = "i", t = "SkillColor10" },
        { f = "i", t = "SkillID11" },
        { f = "i", t = "SkillLevel11" },
        { f = "i", t = "RequireLevel11" },
        { f = "i", t = "RequireQuestID11" },
        { f = "i", t = "SkillColor11" },
        { f = "i", t = "SkillID12" },
        { f = "i", t = "SkillLevel12" },
        { f = "i", t = "RequireLevel12" },
        { f = "i", t = "RequireQuestID12" },
        { f = "i", t = "SkillColor12" },
    }

    local tResult = {}
    local szPath = bDxSkill and "settings\\skill\\TenExtraPoint.tab" or "settings\\skill_mobile\\TenExtraPoint.tab"
    local tTitle = bDxSkill and tDxTabTitle or tTabTitle
    local tIndexTab = KG_Table.Load(szPath, tTitle, 0)
    if tIndexTab then
        local nCount = tIndexTab:GetRowCount()
        for i = 1, nCount do
            local tRow = tIndexTab:GetRow(i)
            if tRow.KungFuID == nTalentGroup then
                if bDxSkill then
                    local skillArray = {}
                    for i = 1, 12 do
                        local skillID = tRow["SkillID" .. i]
                        if skillID == 0 then
                            break
                        else
                            table.insert(skillArray, { dwSkillID = skillID, dwSkillLevel = 1 })
                        end
                    end
                    if skillArray then
                        table.insert(tResult, {
                            nSelectIndex = 0,
                            SkillArray = skillArray
                        })
                    end
                else
                    table.insert(tResult, {
                        nSelectIndex = 0,
                        SkillArray = {
                            { dwSkillID = tRow.SkillID1, dwSkillLevel = 1 },
                            { dwSkillID = tRow.SkillID2, dwSkillLevel = 1 } }
                    })
                end

            end
        end
        tIndexTab = nil
    end
    return tResult
end

function SkillData.GetTargetMijiInfo(nSkillID, tTargetMijiIDList)
    local tList = SkillData.GetFinalRecipeList(nSkillID)
    for _, tRecipe in ipairs(tList) do
        if table.contain_value(tTargetMijiIDList, tRecipe.recipe_id) then
            return tRecipe
        end
    end
end

function SkillData.IsRecommendActivated(nKungfuID, nSetID, tSpecificData)
    if not UISkillRecommendTab[nKungfuID] then
        return false
    end

    local tData = tSpecificData or UISkillRecommendTab[nKungfuID].PVE
    local tQiXueList = SkillData.GetQixueList(true, nKungfuID, nSetID)

    -- 检查奇穴
    for nIndex = 1, 4 do
        local nSelectIndex = tQiXueList[nIndex].nSelectIndex
        local SkillArray = tQiXueList[nIndex].SkillArray
        for nSubIndex = 1, 2 do
            if table.contain_value(tData.QiXue, SkillArray[nSubIndex].dwSkillID) and nSelectIndex ~= nSubIndex then
                return false
            end
        end
    end

    -- 检查技能装配
    local tSkillIDSet = {}
    for _, nSkillID in ipairs(tData.Skill) do
        table.insert(tSkillIDSet, nSkillID)
    end

    for i = 1, 5 do
        local nSkillID = SkillData.GetSlotSkillID(i, nKungfuID, nSetID)
        table.remove_value(tSkillIDSet, nSkillID)
    end

    if not IsTableEmpty(tSkillIDSet) then
        return false
    end

    -- 检查秘籍装配
    for i = 1, 5 do
        local nSkillID = tData.Skill[i]
        local tRecipe = SkillData.GetTargetMijiInfo(nSkillID, tData.Miji)
        if tRecipe and not tRecipe.active then
            return false
        end
    end

    -- 检查武学助手队列
    local tAutoSkillList = tData.AutoSkills
    if tAutoSkillList then
        local bHasSkill = false

        local lst = AutoBattle.GetCustomizeSkillList(nKungfuID, nSetID)
        for i = 1, AutoBattle.nMaxCustomizeNum do
            local nSkillID = tAutoSkillList[i]
            if nSkillID then
                bHasSkill = true
            end
            if nSkillID ~= lst[i] then
                return false
            end
        end

        if AutoBattle.IsCustomized(nKungfuID) ~= bHasSkill then
            return false
        end
    end

    return true
end

------------------武学分页绑定设置--------------------------

local tDefaultSkillSetNames = {
    [1] = "配置一",
    [2] = "配置二",
    [3] = "配置三",
    [4] = "配置四",
    [5] = "配置五",
}
local nSetMaxNum = 5
local NO_EQUIP_BINDING_INDEX = 128
local EQUIP_BIND_SERVER_KEY_LIST = { "SkillEquipBinding_1", "SkillEquipBinding_2", "SkillEquipBinding_3" }
local EQUIP_BIND_SERVER_KEY = "SkillEquipBinding_"

local function GetKungFuOrder(nKungFuID, bHD)
    local playerKungFuList = SkillData.GetKungFuList_Sorted(bHD)
    local nIndex = 1
    if playerKungFuList then
        for i = 1, #playerKungFuList do
            if playerKungFuList[i][1] == nKungFuID then
                nIndex = i -- 按照心法顺序确定服务器存储位置
            end
        end
    end
    return nIndex
end

function SkillData.GetSkillSetName(nCurrentKungFuID, nCurrentSetID)
    local nLuaSetID = nCurrentSetID + 1
    local szSetName = Storage.SkillSetNames[nCurrentKungFuID] and
            Storage.SkillSetNames[nCurrentKungFuID][nLuaSetID]
    szSetName = szSetName or tDefaultSkillSetNames[nLuaSetID] -- 没有配置时显示默认名字
    return szSetName
end

function SkillData.SetSkillSetName(nCurrentKungFuID, nCurrentSetID, szSetName)
    assert(szSetName)
    local nLuaSetID = nCurrentSetID + 1
    Storage.SkillSetNames[nCurrentKungFuID] = Storage.SkillSetNames[nCurrentKungFuID] or {}
    Storage.SkillSetNames[nCurrentKungFuID][nLuaSetID] = szSetName
    Storage.SkillSetNames.Dirty()
end

function SkillData.HasStorageOnServer_SkillEquipBinding()
    local tbEquipSetBinding = Storage.PanelSkill.tbEquipSetBinding
    local playerKungFuList = SkillData.GetKungFuList_Sorted()
    if not playerKungFuList then
        return
    end

    local bHasStorage = false
    for i = 1, #playerKungFuList do
        local szKey = EQUIP_BIND_SERVER_KEY_LIST[i]
        local nKungFuID = playerKungFuList[i][1]
        tbEquipSetBinding[nKungFuID] = tbEquipSetBinding[nKungFuID] or {}
        for nIndex = 1, nSetMaxNum do
            local nEquipIndex = Storage_Server.GetData(szKey, nIndex)
            if nEquipIndex ~= 0 then
                bHasStorage = true -- 0 是默认值 以下用NO_EQUIP_BINDING_INDEX表示未配置方案方案
            end
        end
    end
    return bHasStorage
end

function SkillData.SyncSkillEquipBinding()
    local tbEquipSetBinding = Storage.PanelSkill.tbEquipSetBinding
    local bOpen = GameSettingData.GetNewValue(UISettingKey.SyncSkillEquipBinding)
    if bOpen then
        local playerKungFuList = SkillData.GetKungFuList_Sorted()
        if not playerKungFuList then
            return
        end

        local bHasStorage = SkillData.HasStorageOnServer_SkillEquipBinding()
        for i = 1, #playerKungFuList do
            local nKungFuID = playerKungFuList[i][1]
            do
                ------------同步武学分页绑定------------
                local szKey = EQUIP_BIND_SERVER_KEY_LIST[i]
                local tBindList = tbEquipSetBinding[nKungFuID]
                for nIndex = 1, nSetMaxNum do
                    if not bHasStorage then
                        local nBind = tBindList[nIndex] or NO_EQUIP_BINDING_INDEX
                        Storage_Server.SetData(szKey, nIndex, nBind)        -- 服务器没有已存储内容时存储当前绑定设置到服务器
                    else
                        local nBind = Storage_Server.GetData(szKey, nIndex) -- 用服务器内容内容覆盖本地
                        tBindList[nIndex] = nBind ~= NO_EQUIP_BINDING_INDEX and nBind or nil
                    end
                end
            end
        end
    end
    Storage.PanelSkill.Flush()
    Storage.SkillSetNames.Flush()
end

function SkillData.SetSkillEquipBinding(nKungFuID, nSetID, nVal)
    if not nKungFuID or not nSetID or nSetID < 1 or nSetID > nSetMaxNum then
        return
    end

    local tbEquipSetBinding = Storage.PanelSkill.tbEquipSetBinding
    tbEquipSetBinding[nKungFuID] = tbEquipSetBinding[nKungFuID] or {}
    tbEquipSetBinding[nKungFuID][nSetID] = nVal

    local bOpen = GameSettingData.GetNewValue(UISettingKey.SyncSkillEquipBinding)
    if bOpen then
        local szServerKey = EQUIP_BIND_SERVER_KEY .. GetKungFuOrder(nKungFuID)
        if not szServerKey then
            LOG.ERROR("未查询到合适的szServerKey %d %d", nKungFuID, nSetID)
            return
        end
        if nVal then
            Storage_Server.SetData(szServerKey, nSetID, nVal)
        else
            Storage_Server.SetData(szServerKey, nSetID, NO_EQUIP_BINDING_INDEX) -- 清除绑定
        end
    end
end

function SkillData.GetSkillEquipBinding(nKungFuID, nSetID)
    local tbEquipSetBinding = Storage.PanelSkill.tbEquipSetBinding
    return tbEquipSetBinding[nKungFuID] and tbEquipSetBinding[nKungFuID][nSetID]
end

local DX_EQUIP_BIND_SERVER_KEY_LIST = { "SkillEquipBindingDX_1", "SkillEquipBindingDX_2", "SkillEquipBindingDX_3", "SkillEquipBindingDX_4" }
local nDXSetMaxNum = 5

function SkillData.GetSkillEquipBindingDX(nKungFuID, nSetID)
    if not nKungFuID or not nSetID or nSetID < 1 or nSetID > nDXSetMaxNum then
        return
    end

    local nKungFuOrder = GetKungFuOrder(nKungFuID, true)
    local szServerKey = DX_EQUIP_BIND_SERVER_KEY_LIST[nKungFuOrder]
    if not szServerKey then
        LOG.ERROR("未查询到合适的szServerKey %d %d", nKungFuID, nSetID)
        return
    end

    local nResult = Storage_Server.GetData(szServerKey, nSetID)
    if nResult and (nResult < 1 or nResult > nDXSetMaxNum) then
        nResult = nil
    end
    return nResult
end

function SkillData.SetSkillEquipBindingDX(nKungFuID, nSetID, nVal)
    if not nKungFuID or not nSetID or nSetID < 1 or nSetID > nDXSetMaxNum then
        return
    end

    local nKungFuOrder = GetKungFuOrder(nKungFuID, true)
    local szServerKey = DX_EQUIP_BIND_SERVER_KEY_LIST[nKungFuOrder]
    if not szServerKey then
        LOG.ERROR("未查询到合适的szServerKey %d %d", nKungFuID, nSetID)
        return
    end

    if nVal then
        Storage_Server.SetData(szServerKey, nSetID, nVal)
    else
        Storage_Server.SetData(szServerKey, nSetID, NO_EQUIP_BINDING_INDEX) -- 清除绑定
    end
end

------------------------------------------------------------

function SkillData.GetPublicSkillList(bDxSkill)
    return bDxSkill and tbPublicDxSkills or tbPublicSkills
end

function SkillData.OnReload()

end

function SkillData.UsePCSkillReleaseMode()
    return (KeyBoard.MobileHasKeyboard() or Platform.IsMac() or Platform.IsWindows())
end

-- 槽位对应 SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Fight]的index
SkillData.tSlotId2FightIndex = {
    [1] = 11,
    [2] = 12,
    [3] = 13,
    [4] = 14,
    [5] = 15,
    [6] = 16,
    [11] = 25,
    [12] = 23,
}

SkillData.tDXSkillID2FightIndex = {
    [UI_SKILL_JUMP_ID] = 76,
    [UI_DXSKILL_FUYAO_ID] = 77,
    [UI_DXSKILL_HOUCHE_ID] = 75,
    [UI_DXSKILL_DASH_ID] = 78,

    [UI_DXSKILL_LINGXIAO_ID] = 79,
    [UI_DXSKILL_YAOTAI_ID] = 80,
    [UI_DXSKILL_YINGFENG_ID] = 81
}

SkillData.tDXSprintSlots = {
    26, 27, 28, 29
}

SkillData.tDXSlotID2FightIndex = {
    [1] = 50,
    [2] = 51,
    [3] = 52,
    [4] = 53,
    [5] = 54,
    [6] = 55,
    [7] = 56,
    [8] = 57,
    [9] = 58,
    [10] = 59,
    [11] = 60,
    [12] = 61,
    [13] = 62,
    [14] = 63,
    [15] = 64,
    [16] = 65,
    [17] = 66,
    [18] = 67,
    [19] = 68,
    [20] = 69,
    [21] = 70,
    [22] = 71,
    [23] = 72,
    [24] = 73,
    [25] = 74,
    --[26] = 75,
    --[27] = 76,
    --[28] = 77,
    --[29] = 78,
}


------------------DX槽位相关--------------------------

function SkillData.GetDXSkillList(dwMKungfuID, dwKungfuID)
    local hPlayer = GetClientPlayer()
    local bSection = Table_MKungfuIsSection(dwMKungfuID)
    local tSkillList = Table_GetKungfuSkillListEx(dwKungfuID, dwMKungfuID, bSection)
    local tList = {}
    local tExistingIDSet = {}
    for nIndex, tSkill in ipairs(tSkillList) do
        tList[nIndex] = {}
        for _, dwID in ipairs(tSkill) do
            local dwFinalID = SkillData.CheckDXSkillReplace(dwID)
            local dwLevel = hPlayer.GetSkillLevel(dwFinalID) or 0
            local nOpenLevel = Table_OpenSkillLevel(dwFinalID, 1)
            nOpenLevel = nOpenLevel or 0
            if not tExistingIDSet[dwFinalID] then
                tExistingIDSet[dwFinalID] = true
                table.insert(tList[nIndex], { dwFinalID, dwLevel, nOpenLevel })
            end
        end
    end

    if #tList < 2 then
        table.insert(tList, {}) --兼容4100;403;415;480|这种情况
    end
    return tList
end

function SkillData.IsCommonDXSkill(dwID)
    if not IsCommonSkill(dwID) then
        return false, false, false
    end
    local hPlayer = GetClientPlayer()
    if dwID == hPlayer.GetCommonSkill(true) then
        return true, true, true
    end
    return true, false, false
end

local tReplaceSkill = {}
local tSkillIDToShowNum = {}

function SkillData.GetDxSlotData(nSlotID, nActionBarIndex)
    local t = {}
    if Storage_Server.IsReady() and nSlotID and nSlotID >= 1 and nSlotID <= 33 then
        if nActionBarIndex == nil then
            nActionBarIndex = SkillData.GetCurrentDxSkillBarIndex()
        end
        local szDXStorageKey = STORAGE_DXACTIONBAR_ENUM_LIST[nActionBarIndex]
        assert(szDXStorageKey)
        local nType, data1, data2, data3 = Storage_Server.GetData(szDXStorageKey, nSlotID)
        if nType then
            t = {
                nType = nType,
                data1 = data1,
                data2 = data2,
                data3 = data3
            }
        end

        if nType == DX_ACTIONBAR_TYPE.SKILL then
            t.data1 = SkillData.CheckDXSkillReplace(data1) -- 处理二段替换
        end
    end
    return t
end

---@param tSlotData DXSlotData
function SkillData.SaveDXSlotData(tSlotData, nSlotIndex, nActionBarIndex)
    assert(nSlotIndex)
    if nActionBarIndex == nil then
        nActionBarIndex = 1
        if g_pClientPlayer and g_pClientPlayer.dwForceID == FORCE_TYPE.BA_DAO then
            nActionBarIndex = g_pClientPlayer.nPoseState
        end
    end
    local szDXStorageKey = STORAGE_DXACTIONBAR_ENUM_LIST[nActionBarIndex]
    if tSlotData and szDXStorageKey then
        if tSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
            assert(tSlotData.data1)
            Storage_Server.SetData(szDXStorageKey, nSlotIndex, DX_ACTIONBAR_TYPE.SKILL, tSlotData.data1)
        elseif tSlotData.nType == DX_ACTIONBAR_TYPE.EQUIP then
            assert(tSlotData.data1)
            assert(tSlotData.data2)
            Storage_Server.SetData(szDXStorageKey, nSlotIndex,
                    DX_ACTIONBAR_TYPE.EQUIP, tSlotData.data1, tSlotData.data2, tSlotData.data3)
        elseif tSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
            assert(tSlotData.data1)
            assert(tSlotData.data2)
            Storage_Server.SetData(szDXStorageKey, nSlotIndex,
                    DX_ACTIONBAR_TYPE.ITEM_INFO, tSlotData.data1, tSlotData.data2, tSlotData.data3)
        elseif tSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
            assert(tSlotData.data1)
            Storage_Server.SetData(szDXStorageKey, nSlotIndex, DX_ACTIONBAR_TYPE.MACRO, tSlotData.data1)
        end
    end

    Event.Dispatch(EventType.OnDXSkillSlotChanged, nSlotIndex) -- 发送槽位变更事件
end

function SkillData.ClearDXSlotData(nSlotIndex, nActionBarIndex)
    assert(nSlotIndex)
    assert(nActionBarIndex)

    local szDXStorageKey = STORAGE_DXACTIONBAR_ENUM_LIST[nActionBarIndex]
    Storage_Server.SetData(szDXStorageKey, nSlotIndex, nil)

    Event.Dispatch(EventType.OnDXSkillSlotChanged, nSlotIndex) -- 发送槽位变更事件
end

---@param tSlotData DXSlotData
function SkillData.GetDXSlotEquip(tSlotData)
    if tSlotData.nType == DX_ACTIONBAR_TYPE.EQUIP then
        local nBox = tSlotData.data1
        local nIndex = tSlotData.data2
        local nSuitIndex = tSlotData.data3 or 0
        local player = GetClientPlayer()
        local item
        --local item = ItemData.GetPlayerItem(player, nBox, nIndex)
        local nEquipIndex = 0
        if nBox == INVENTORY_INDEX.EQUIP then
            nEquipIndex = GetLogicEquipPos(nSuitIndex)
            item = ItemData.GetPlayerItem(player, nEquipIndex, nIndex)
        end
        return item
    end
end

---@param tSlotData DXSlotData
function SkillData.ShowDxSlotTips(tSlotData, node, fnExit, nDirection)
    if not tSlotData then
        return
    end
    nDirection = nDirection or TipsLayoutDir.LEFT_CENTER

    local tips, tipsScriptView
    if tSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
        tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, node, nDirection, tSlotData.data1)

    elseif tSlotData.nType == DX_ACTIONBAR_TYPE.EQUIP then
        local item = SkillData.GetDXSlotEquip(tSlotData)
        if item then
            tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, node, TipsLayoutDir.LEFT_CENTER)
            tipsScriptView:SetFunctionButtons({})
            tipsScriptView:OnInit(item.nBox, item.nIndex)
        end
    elseif tSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
        tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, node, TipsLayoutDir.LEFT_CENTER)
        tipsScriptView:SetFunctionButtons({})
        tipsScriptView:OnInitWithTabID(tSlotData.data1, tSlotData.data2)
    elseif tSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
        local dwMacro = tSlotData.data1
        local szTips = GetMacroName(dwMacro) .. "\n宏\n" .. GetMacroDesc(dwMacro)
        tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, node, TipsLayoutDir.LEFT_CENTER, szTips)
    end
    if tipsScriptView and tipsScriptView.BindExitFunc then
        tipsScriptView:BindExitFunc(fnExit)
    end
    return tips, tipsScriptView
end

function SkillData.IsDXSlotEmpty(tSlotData)
    if tSlotData == nil or IsTableEmpty(tSlotData) then
        return true
    end

    if tSlotData.data1 == nil then
        return true
    end

    if tSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
        return IsMacroRemoved(tSlotData.data1)
    end

    return false
end

function SkillData.OnDXSkillReplace(dwOldSkillID, dwNewSkillID, dwNewSkillLevel, dwOrgSkill)
    dwOrgSkill = dwOrgSkill or dwOldSkillID
    if tReplaceSkill[dwNewSkillID] then
        tReplaceSkill[dwNewSkillID] = nil
    end
    tReplaceSkill[dwOrgSkill] = { dwNewSkillID, dwNewSkillLevel }

    CorrectSkillName(dwNewSkillID)
    LOG.WARN("ON_SKILL_REPLACE_DX %d %d", dwOldSkillID, dwNewSkillID)
    Event.Dispatch("ON_SKILL_REPLACE_DX", dwOldSkillID, dwNewSkillID)

    SkillData.ReplaceSavedSkill(dwOldSkillID, dwNewSkillID)
end

---@param ShowPetSkillTips
function SkillData.ShowPetSkillTips(node, nSkillID, nSkillLevel)
    if not node then
        return
    end

    local tSkillInfo = Table_GetSkill(nSkillID, nSkillLevel)
    if tSkillInfo then
        local szText = UIHelper.GBKToUTF8(tSkillInfo.szName).."\n"..UIHelper.GBKToUTF8(tSkillInfo.szDesc)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, node, TipsLayoutDir.LEFT_CENTER, szText)
    end
end

function SkillData.ReplaceSavedSkill(dwOldSkillID, dwNewSkillID)
    local fnAction = function(key, index, type, data1)
        if type == DX_ACTIONBAR_TYPE.SKILL then
            if data1 == dwOldSkillID then
                Storage_Server.SetData(key, index, DX_ACTIONBAR_TYPE.SKILL, dwNewSkillID) --skill
            end
        end
    end
    Storage_Server.ActionBarTask(fnAction)
end

function SkillData.CheckDXSkillReplace(dwSkillID, dwStartSkillID)
    if dwSkillID == dwStartSkillID then
        return dwSkillID -- 防止死循环
    end
    if dwSkillID and tReplaceSkill[dwSkillID] and dwSkillID ~= tReplaceSkill[dwSkillID][1] then
        return SkillData.CheckDXSkillReplace(tReplaceSkill[dwSkillID][1], dwStartSkillID or dwSkillID)
    end
    return dwSkillID
end

local tAutoDownMapWhiteList = {
    [6] = true,
    [8] = true,
    [15] = true,
    [74] = true,
    [108] = true,
    [172] = true,
    [194] = true,
    [332] = true,
}

function SkillData.IsAutoCastEnable(player)
    if not player then
        player = GetClientPlayer()
    end

    if not player then
        return false
    end

    local scene = player.GetScene()
    if tAutoDownMapWhiteList[scene.dwMapID] or scene.nType == MAP_TYPE.DUNGEON or scene.nType == MAP_TYPE.HOMELAND then
        return true
    else
        return false
    end
end

function SkillData.IsEnergyShow()
    return SkillData.IsUsingHDKungFu()
end

function SkillData.GetSurfaceNum(nSkillID)
    return tSkillIDToShowNum[nSkillID]
end

local tbDXSpecialSkillBuffList = {
    10021, 10585, 10627, 10225, 10224, 10015
}
function SkillData.IsDXSpecialSkillBuffShow()
    if not g_pClientPlayer then
        return false
    end
    local dwKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local bShowSpecialBuff = table.contain_value(tbDXSpecialSkillBuffList, dwKungFuID)
    return bShowSpecialBuff
end

------------------DX按照当前状态切换分页--------------------------

local tSpecialKungFuOffset = {
    [FORCE_TYPE.PENG_LAI] = 1,
    [FORCE_TYPE.DAO_ZONG] = 1,
    [FORCE_TYPE.BA_DAO] = 2,
    [FORCE_TYPE.CANG_YUN] = 2,
    [FORCE_TYPE.TIAN_CE] = 2,
}

local nDXSkillBarIndex = 1

local function SelectByHorse(tSkill)
    local player = GetClientPlayer()
    local nForceType = Kungfu_GetPlayerMountType(player)
    local tSkill = tSkill or player.GetActualKungfuMount()
    if nForceType == FORCE_TYPE.TIAN_CE and (tSkill and tSkill.dwMountType == ForceIDToMountType[nForceType]) then
        local bOnHorse = player.bOnHorse and (not player.bHoldHorse)
        if tSkill.dwSkillID == 10026 then
            return bOnHorse and 2 or 1
        else
            return bOnHorse and 4 or 3
        end
    end
end

local function SelectByPoseState(tSkill)
    local player = GetClientPlayer()
    --if player.nPoseState <= 0 then
    --    return false
    --end

    local nForceType = Kungfu_GetPlayerMountType(player)
    if nForceType ~= FORCE_TYPE.BA_DAO and nForceType ~= FORCE_TYPE.CANG_YUN and nForceType ~= FORCE_TYPE.DAO_ZONG then
        return
    end

    tSkill = tSkill or player.GetActualKungfuMount()
    if not tSkill or tSkill.dwMountType ~= ForceIDToMountType[nForceType] then
        return
    end

    local page = 0
    if nForceType == FORCE_TYPE.DAO_ZONG then
        if player.nPoseState == 1 or player.nPoseState == 3 then
            page = 1
        elseif player.nPoseState == 2 or player.nPoseState == 4 then
            page = 2
        end
    elseif nForceType == FORCE_TYPE.CANG_YUN then
        if tSkill.dwSkillID == 10389 then
            page = player.nPoseState == 2 and 2 or 1
        else
            page = player.nPoseState == 2 and 4 or 3
        end
    else
        page = player.nPoseState
    end

    page = math.max(1, page)
    return page
end

local function SelectByParachute(tSkill)
    local player = GetClientPlayer()
    local nForceType = Kungfu_GetPlayerMountType(player)
    tSkill = tSkill or player.GetActualKungfuMount()
    if nForceType == FORCE_TYPE.PENG_LAI and (tSkill and tSkill.dwMountType == ForceIDToMountType[nForceType]) then
        local nPage = player.bOnParachuteFlag and 2 or 1
        return nPage
    end
end

local function SelectByKungFu(tSkill)
    local player = GetClientPlayer()
    local nForceType = Kungfu_GetPlayerMountType(player)

    local tDXKungfuList = SkillData.GetKungFuList_Sorted(true)
    local nKungFuID = tSkill and tSkill.dwSkillID or player.GetActualKungfuMountID()
    local nTargetPage = 1
    local bFound = false
    for i = 1, #tDXKungfuList do
        if tDXKungfuList[i][1] == nKungFuID then
            nTargetPage = i
            bFound = true
            break
        end
    end

    if not bFound then
        nTargetPage = #tDXKungfuList + 1
    end

    if tSpecialKungFuOffset[nForceType] then
        nTargetPage = nTargetPage + tSpecialKungFuOffset[nForceType] -- 非职业流派 遇到特殊有职业时需跳过已占用技能栏
    end

    return nTargetPage
end

function SelectDXActionBarIndex()
    if not SkillData.IsUsingHDKungFu() then
        return
    end

    local nFinalPage = nil
    local nNewPage = SelectByHorse()
    if nNewPage then
        nFinalPage = nNewPage
    end

    nNewPage = SelectByPoseState()
    if nNewPage then
        nFinalPage = nNewPage
    end

    nNewPage = SelectByParachute()
    if nNewPage then
        nFinalPage = nNewPage
    end

    if not nFinalPage then
        nFinalPage = SelectByKungFu()
    end

    nDXSkillBarIndex = nFinalPage
    Event.Dispatch(EventType.OnDxSkillBarIndexChange)
    print("SelectDXActionBarIndex", nDXSkillBarIndex)
end

function SkillData.GetPreviewSkillBarIndex(tSkill)
    local player = GetClientPlayer()
    local nForceType = Kungfu_GetPlayerMountType(player)
    if not tSkill then
        return
    end

    local nFinalIndex = 1
    if tSpecialKungFuOffset[nForceType] and tSkill and tSkill.dwMountType == ForceIDToMountType[nForceType] then

        local nNewPage = SelectByHorse(tSkill)
        if nNewPage then
            nFinalIndex = nNewPage
        end

        nNewPage = SelectByPoseState(tSkill)
        if nNewPage then
            nFinalIndex = nNewPage
        end

        nNewPage = SelectByParachute(tSkill)
        if nNewPage then
            nFinalIndex = nNewPage
        end
    else
        nFinalIndex = SelectByKungFu(tSkill)
    end
    return nFinalIndex
end

function SkillData.GetCurrentDxSkillBarIndex()
    return nDXSkillBarIndex
end

------------------凌雪特殊特效--------------------------

local bFightCircleSettingShow = true

local function CanCastSelfSkill(pPlayer)
    local dwGroup = pPlayer.GetDynamicSkillGroup()
    if dwGroup <= 0 then
        return true
    end
    local tSkills = GetDynamicSkillGroupSkills(dwGroup)
    return tSkills.CanCastSkill
end

local function ShowLXGFightCircle()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local bInFight = pPlayer.bFightState
    local nSkillLevel = pPlayer.GetSkillLevel(22327) --判断是否学会寂洪荒

    local dwKungfuID = pPlayer.GetActualKungfuMountID()
    if dwKungfuID and dwKungfuID == 10585 and bFightCircleSettingShow and bInFight and nSkillLevel > 0 and CanCastSelfSkill(pPlayer) then
        rlcmd("npc special 1 69759")
    else
        rlcmd("npc special 0")
    end
end

-- 凌雪阁显示辅助圈
function SkillData.ShowLXGFightCircleBySetting(bShow)
    bFightCircleSettingShow = bShow
    ShowLXGFightCircle()
end

Event.Reg(SkillData, "FIGHT_HINT", ShowLXGFightCircle)

Event.Reg(SkillData, "CHANGE_DYNAMIC_SKILL_GROUP", ShowLXGFightCircle)

--------------------流派相关-------------------------------

local function ParseStringList(szList)
    local dwPreQuestID, szQuestID = string.match(szList, "(%d+)|(.+)")
    dwPreQuestID = dwPreQuestID and tonumber(dwPreQuestID)
    if not szQuestID then
        szQuestID = szList
    end

    local tRes = {}
    local t = string.split(szQuestID, ";")
    for _, v in pairs(t) do
        local value = tonumber(v)
        if value then
            table.insert(tRes, value)
        end
    end
    return tRes, dwPreQuestID
end

function GetLastTrackID(szQuestList)
    local tQuestList, dwPreQuestID = ParseStringList(szQuestList)
    local nLen = #tQuestList
    local dwLastTrackID = tQuestList[nLen]
    return dwLastTrackID
end

--当前任务指引
function GetQuestTrackID(szQuestList)
    local bResult = true
    local dwQuestID = nil
    local tQuestList, dwPreQuestID = ParseStringList(szQuestList)

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if dwPreQuestID then
        if hPlayer.GetQuestState(dwPreQuestID) ~= QUEST_STATE.FINISHED then
            return dwPreQuestID, true
        end
    end

    --判最后一个任务
    local nLen = #tQuestList
    local dwID = tQuestList[nLen]
    if hPlayer.GetQuestState(dwID) ~= QUEST_STATE.FINISHED then
        bResult = false
    end

    --没完成再判任务线
    if not bResult then
        for _, v in pairs(tQuestList) do
            if hPlayer.GetQuestState(v) ~= QUEST_STATE.FINISHED then
                dwQuestID = v
                break
            end
        end
    end

    return dwQuestID
end

function SkillData.GetWXLSkinSkillLearn()
    local player = GetClientPlayer()
    if not player then
        return false
    end

    local nSkillID = WU_XIANG_LOU_SPECIAL_SKIN_SKILL
    local nSkillLevel = player.GetSkillLevel(nSkillID)
    if nSkillLevel <= 0 then
        return false
    end

    return SkillData.CanUIShow(player, nSkillID)
end

--------------------DX武学推荐相关-------------------------------

function GetTeachList()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return {}
    end
    local tKungfu = hPlayer.GetKungfuMount()
    if not tKungfu then
        return {}
    end
    local tTeachList = Table_GetSkillTeach(hPlayer.dwForceID, tKungfu.dwSkillID, hPlayer.nLevel)
    return tTeachList
end

function GetSkillTeachRecipe(dwSkillID, dwLevel, bOptimal)
    local tGroupList = SkillData.GetRecipeList(dwSkillID, dwLevel)

    local tRecipeList = {}
    for dwTypeID, tRecipeGroup in pairs(tGroupList) do
        for _, tRecipe in ipairs(tRecipeGroup) do
            table.insert(tRecipeList, tRecipe)
        end
    end

    local fnSort = function(tLeft, tRight)
        return tLeft.nTeachPriority > tRight.nTeachPriority
    end
    table.sort(tRecipeList, fnSort)

    if bOptimal then
        --前四本秘籍最优
        local tOptimal = {}
        for i = 1, 4 do
            if tRecipeList[i] then
                table.insert(tOptimal, tRecipeList[i])
            end
        end
        tRecipeList = tOptimal
    end
    return tRecipeList
end

local nLastCheckTime = 0
local CHECK_TIME_LIMIT = 300
function CheckQixueAndRecipe()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local nTime = GetCurrentTime()
    if nTime - nLastCheckTime < CHECK_TIME_LIMIT then
        return
    end
    nLastCheckTime = nTime

    local tTeachList = GetTeachList()
    local tTeach = tTeachList[1]
    if not tTeach then
        return
    end

    local bCheck = false
    --检测奇穴
    if not bCheck then
        local tQixueList = tTeach.tQixueList or {}
        for i, tQixue in ipairs(tQixueList) do
            local dwPointID = tQixue[1]
            local nIndex = tQixue[2]
            local tInfo = player.GetTalentInfoByPointID(dwPointID)
            if not tInfo.SkillGroup[nIndex].bSelected then
                bCheck = true
                break
            end
        end
    end

    --检测秘籍
    if not bCheck then
        local tRecipeSkillList = tTeach.tRecipeSkillList or {}
        for _, dwSkillID in ipairs(tRecipeSkillList) do
            local dwLevel = player.GetSkillLevel(dwSkillID)
            if dwSkillID == 0 then
                dwSkillID = 1
            end

            local tRecipeList = GetSkillTeachRecipe(dwSkillID, dwLevel, true)
            for _, tTeach in ipairs(tRecipeList) do
                if not tTeach.active then
                    bCheck = true
                    break
                end
            end
        end
    end

    if bCheck then
        OutputMessage("MSG_SYS", g_tStrings.SKILL_RECIPE_TEACH_CHECK)
        TipsHelper.ShowImportantYellowTip(g_tStrings.SKILL_RECIPE_TEACH_CHECK)
    end
end

--------------------------------------------------------------------------
SkillData.bIsCurrentDXKungFu = false
local bDebug = Debug.IsDevEnv()

Event.Reg(SkillData, "DO_SKILL_CAST", function(arg0, arg1)
    if arg0 == UI_GetClientPlayerID() then
        SpecialSettings.AutoMJSkillCast(arg1)
    end
end)

Event.Reg(SkillData, "SKILL_MOUNT_KUNG_FU", function()
    SkillData.bIsCurrentDXKungFu = SkillData.IsUsingHDKungFu()
    SelectDXActionBarIndex()
end)

Event.Reg(SkillData, "PLAYER_MOUNT_HORSE", function(dwPlayerID, bMount, dwParam, bHoldHorse)
    if dwPlayerID == UI_GetClientPlayerID() then
        local nNewPage = SelectByHorse()
        if nNewPage then
            nDXSkillBarIndex = nNewPage
            Event.Dispatch(EventType.OnDxSkillBarIndexChange)
        end
    end
end)

Event.Reg(SkillData, "ON_CHARACTER_POSE_STATE_UPDATE", function()
    local nNewPage = SelectByPoseState()
    if nNewPage then
        nDXSkillBarIndex = nNewPage
        Event.Dispatch(EventType.OnDxSkillBarIndexChange)
    end
end)

Event.Reg(SkillData, "PLAYER_CHANGE_PARACHUTE_STATE", function(bOpen)
    local nNewPage = SelectByParachute()
    if nNewPage then
        nDXSkillBarIndex = nNewPage
        Event.Dispatch(EventType.OnDxSkillBarIndexChange)
    end
end)

Event.Reg(SkillData, EventType.OnClientPlayerLeave, function()
    tReplaceSkill = {}
    tSkillIDToShowNum = {}
    SkillData.g_tSkillNounsList = {}
end)

Event.Reg(SkillData, EventType.OnClientPlayerEnter, function()
    SkillData.bIsCurrentDXKungFu = SkillData.IsUsingHDKungFu()
    SelectDXActionBarIndex()
    Timer.DelAllTimer(SkillData)
    if g_pClientPlayer and g_pClientPlayer.dwForceID == FORCE_TYPE.MING_JIAO then
        Timer.AddCycle(SkillData, 1 / 16, SpecialSettings.AutoMJSKillDelayCast)
    end

    Timer.Add(SkillData, 0.8, function()
        tReplaceSkill = {} -- 玩家刚登录时服务器会发送一堆二段替换事件来确保技能正确性 我们不希望记录这些数据 因为会导致长歌替换显示不正确
    end)
end)

Event.Reg(SkillData, "CHANGE_SKILL_SURFACE_NUM", function(arg0, arg1)
    tSkillIDToShowNum[arg0] = arg1
end)

Event.Reg(SkillData, "ON_SKILL_REPLACE", function(dwOldSkillID, dwNewSkillID, dwNewSkillLevel, dwOrgSkill)
    if bDebug then
        print("ActionBar_ReplaceServerSkillGroup", dwOldSkillID, dwNewSkillID)
    end

    SkillData.OnDXSkillReplace(dwOldSkillID, dwNewSkillID, dwNewSkillLevel, dwOrgSkill)
end)

Event.Reg(SkillData, "CHANGE_SKILL_ICON", function(dwOldSkillID, dwNewSkillID)
    if bDebug then
        print("ActionBar_ReplaceServerSkillGroup", dwOldSkillID, dwNewSkillID)
    end

    local tSpecialDXSkill = {
        [32143] = 1,
        [32601] = 1,
        [16601] = 1,
        [17078] = 1,
        [17079] = 1,
    }
    if tSpecialDXSkill[dwOldSkillID] then
        SkillData.OnDXSkillReplace(dwOldSkillID, dwNewSkillID) -- 特殊处理刀宗沧浪三叠、霸刀项王
    else
        SkillData.ReplaceSavedSkill(dwOldSkillID, dwNewSkillID)
    end
end)

Event.Reg(SkillData, "ON_ACTIONBAR_SKILL_REPLACE", function(dwOldSkillID, dwNewSkillID)
    if bDebug then
        print("ActionBar_ReplaceServerSkillGroup", dwOldSkillID, dwNewSkillID)
    end

    local tSpecialDXSkill = {
        [8490] = 1,
        [5638] = 1,
    }
    if tSpecialDXSkill[dwOldSkillID] then
        SkillData.OnDXSkillReplace(dwOldSkillID, dwNewSkillID) -- 特殊丐帮第一充奇穴驯致
    else
        SkillData.ReplaceSavedSkill(dwOldSkillID, dwNewSkillID)
    end
end)

Event.Reg(SkillData, "UPDATE_MANNEDSPACE_FRONTSIGHT", onShootPoint)

Event.Reg(SkillData, "SYNC_USER_PREFERENCES_END", SkillData.SyncSkillEquipBinding)

local tIgnoreTipViewIDs = {
    VIEW_ID.PanelYangDaoOverview,
    VIEW_ID.PanelBlessChoose,
    VIEW_ID.PanelBlessConfirm,
    VIEW_ID.PanelYangDaoBlessShop,
    VIEW_ID.PanelYangDaoBlessUpgrade,
    VIEW_ID.PanelYangDaoMainCityCardShow,
}
Event.Reg(SkillData, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end
        
        local decodedString = UrlDecode(szUrl)
        if decodedString ~= "" then
            local tbLinkData = JsonDecode(decodedString)
            if not tbLinkData then
                return
            end

            local szType = tbLinkData.type or ""
            if szType == "ShowNounInfo" then
                local bIsVK = tbLinkData.szOriginalDesc == nil
                if not bIsVK then
                    SkillData.ClearSpecialNoun() -- VK不清除名词列表
                end
                local szDesc = ParseSkillDesc(tbLinkData.szOriginalDesc, tbLinkData.dwSkillID, tbLinkData.dwSkillLevel) -- 只显示上一级描述中涉及的名词
                local script = UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelSkillGlossary,
                        tbLinkData.szNoun, SkillData.tTotalNoun, tbLinkData.szSourceName, szDesc)
                local bIgnoreTip = false
                for _, nViewID in ipairs(tIgnoreTipViewIDs) do
                    if UIMgr.IsViewOpened(nViewID) then
                        bIgnoreTip = true
                        break
                    end
                end
                if not bIgnoreTip then
                    script:ShowSkillTip(tbLinkData.dwSkillID)
                end
            end
        end
end)
