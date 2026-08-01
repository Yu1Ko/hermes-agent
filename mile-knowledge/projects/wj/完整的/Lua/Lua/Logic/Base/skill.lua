local l_tSkillCastToMe = {}
local l_tQiChangSkill = {}
local l_tAddonArenaCastMode = {}
local l_bAutoJianWu = false
local l_bSelfCastSkill = true
local l_nPointAreaCastMode = 2 -- 0 表示传统模式；1表示简化模式，点击技能后立即在鼠标当前位置释放；2表示默认模式，在目标处释放，如果不符合条件就按默认模式释放
local l_bShowGCDBar = true
local l_nAutoCastPengLaiSkillDelay = 0
local _SaveSkillChangeList = {}

local FONT_SKILL_NAME = 31
local FONT_SKILL_LEVEL = 61
local FONT_SKILL_SEP_DESC = 101
local FONT_SKILL_DESC = 100
local FONT_SKILL_DESC1 = 47
local m_nLastAltDownTime = 0

local SurplusParam = 7.421
local POINT_AREA_CAST_MODE =
{
    TRADITION = 0,
    MOUSE = 1,
    TARGET = 2,
}

local Cursor = {}
function Cursor.GetPos()
    local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
    local tCursor = Platform.IsWindows() and GetViewCursorPoint() or GetCursorPoint()
    local tPos = cc.Director:getInstance():convertToGL({ x = tCursor.x, y = tCursor.y })
    return tPos.x * nScaleX, tPos.y * nScaleY
end

ALT_KEY_VALID_INTERVAL = 1000

g_bMoreSkillInfo = false

SKILL_SELECT_POINT_UNNORMAL = --像纯阳六合独尊这类的技能，当超出范围时，显示这空技能所绑的特效
{
nSkillID = 1919,
nLevel = 1,
}

for _, info in pairs(g_tUIConfig.SkillQiChang) do
	if type(info.ids) == "table" then
		for _, id in ipairs(info.ids) do
			l_tQiChangSkill[id] = true
		end
	else
		l_tQiChangSkill[info.ids] = true
	end
end

local tinsert = table.insert
local tconcat = table.concat
local function FormatHandle(szItem, nHandleType, nWidth, nHeight)
    return szItem
end

-- 判断一个技能是不是气场技能
function IsQiChangSkill(nSkillID)
    return l_tQiChangSkill[nSkillID]
end

function SetGasFieldRepresentVisible(dwType, skillInfo, bNotVisible)
    local nVisible = 1
    if bNotVisible then
        nVisible = 0
    end
    if skillInfo.tRepresentID then
        for i, dwRepresentID in ipairs(skillInfo.tRepresentID) do
            rlcmd("set gas field " .. dwType .. " " .. dwRepresentID .. " " .. nVisible)
        end
    end
    if not skillInfo.tSFXID then
        return
    end
    for i, dwSFXID in ipairs(skillInfo.tSFXID) do
        rlcmd("set gas field " .. dwType .. " " .. dwSFXID .. " " .. nVisible)
    end
end

-- 技能只对自己插
function SetSkillCastToMe(skill_id, enable)
    if type(skill_id) == "table" then
        for _, id in pairs(skill_id) do
            l_tSkillCastToMe[id] = enable
        end
    else
        l_tSkillCastToMe[skill_id] = enable
    end
end

function IsSkillCastToMe(skill_id)
    if l_tAddonArenaCastMode[skill_id] then
        -- 插件里配置了自定义释放方式就覆盖官方的对自己释放功能
        return false
    end
    return l_tSkillCastToMe[skill_id]
end

-- 技能没有目标的时候对自己插
function IsSelfCastSkill()
    return l_bSelfCastSkill
end

function SetSelfCastSkill(bSelf)
    l_bSelfCastSkill = bSelf
end

-- 目标点范围模式
function GetPointAreaCastSetting()
    return l_nPointAreaCastMode
end

function SetPointAreaCastSetting(nMode)
    l_nPointAreaCastMode = nMode
end

function IsShowGCDBar()
    return l_bShowGCDBar
end

function SetShowGCDBar(bShow)
    l_bShowGCDBar = bShow
end

function IsMobileKungfu()
    local hPlayer = GetClientPlayer()
    if hPlayer then
        return hPlayer.nSkillPlatformType == SKILL_PLATFORM_TYPE.MOBILE
    end
end

local m_OrgTargetType, m_OrgTargetID
local function RestoreTarget()
    if m_OrgTargetType then
        SetTarget(m_OrgTargetType, m_OrgTargetID)
    end
    m_OrgTargetType, m_OrgTargetID = nil, nil
end

function Skill_GetCongNengCDID(dwSkillID, player, bRetCount)
    player = player or GetClientPlayer()
    local nCount, dwCDID = player.GetCDMaxCount(dwSkillID)
    if nCount == 1 then
        dwCDID = nil
    end
    return dwCDID
end

local m_CDData
local m_bStopCDProgress
local function GetCDKey(dwSkillID, dwLevel, dwCDID)
    dwLevel = dwLevel or 1
    if dwCDID then
        return dwSkillID .. "_" .. dwLevel .. "_" .. dwCDID
    else
        return dwSkillID .. "_" .. dwLevel
    end
end

function Skill_StopCDProgress()
    m_CDData = {}
    local player = GetClientPlayer()
    local aSkill = player.GetAllSkillList() or {}
    local player = GetClientPlayer()

    local dwCDID
    local bCool, nLeft, nTotal
    for dwID, dwLevel in pairs(aSkill) do
        dwCDID = Skill_GetCongNengCDID(dwID, player)
        bCool, nLeft, nTotal = Skill_GetCDProgress(dwID, dwLevel, dwCDID, player)
        m_CDData[GetCDKey(dwID, dwLevel, dwCDID)] = { bCool, nLeft, nTotal }
    end
    m_bStopCDProgress = true
end

function Skill_RestoreCDProgress()
    m_CDData = nil
    m_bStopCDProgress = nil
end

function Skill_GetCDProgress(dwSkillID, dwLevel, dwCDID, player)
    if m_bStopCDProgress then
        local t = m_CDData[GetCDKey(dwSkillID, dwLevel, dwCDID)]
        if t then
            return unpack(t)
        end
        return
    end

    player = player or GetClientPlayer()
    if dwCDID then
        return player.GetSkillCDProgress(dwSkillID, dwLevel, dwCDID)
    else
        return player.GetSkillCDProgress(dwSkillID, dwLevel)
    end
end

function Skill_NotInCountDown(nSkillID, nSkillLevel, pPlayer)
    pPlayer = pPlayer or GetClientPlayer()
    if not pPlayer then
        return
    end

    nSkillLevel = nSkillLevel or pPlayer.GetSkillLevel(nSkillID)
    local bCool, nLeft, nTotal, nCDCount, bPublicCD
    local cd_count, cd_id = pPlayer.GetCDMaxCount(nSkillID)
    local od_count, od_id = pPlayer.GetCDMaxOverDraftCount(nSkillID)
    if cd_count > 1 then
        -- 充能技能CD
        bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(nSkillID, nSkillLevel, cd_id, pPlayer)
        local cd_time, cd_left = pPlayer.GetCDLeft(cd_id)
        if cd_left == 0 then
            return false
        end
    elseif od_count > 1 then
        -- 透支技能CD
        bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(nSkillID, nSkillLevel, od_id, pPlayer)
        local od_count, od_left = pPlayer.GetOverDraftCoolDown(od_id)
        if od_left == od_count then
            -- 透支技能用完了
            bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(nSkillID, nSkillLevel, nil, pPlayer)
        end
    else
        -- 普通技能CD
        bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(nSkillID, nSkillLevel, nil, pPlayer)
    end

    if not bCool or nLeft == 0 and nTotal == 0 then
        return true
    end
    return false
end

function GetSkillInfoEx(tRecipeKey, dwPlayerID)
    if dwPlayerID == GetControlPlayerID() then
        return GetSkillInfoByProxy(tRecipeKey)
    else
        return GetSkillInfo(tRecipeKey)
    end
end

--Check Skill BlackList
function CheckBlackListAddOnUseSkill(dwSkillID, dwSkillLevel, bNoLimit, castmode)
    if Table_IsBlackListSkill(dwSkillID, dwSkillLevel) then
        return
    end
    return OnAddOnUseSkill(dwSkillID, dwSkillLevel, bNoLimit, castmode)
end

local _box = { _vir = true }
function OnAddOnUseSkill(nSkillID, nSkillLevel, bNoLimit, castmode)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local dwTargetType, dwTargetID = hPlayer.GetTarget()
    if not dwTargetType or not dwTargetID then
        dwTargetType, dwTargetID = TARGET.NO_TARGET, 0
    end

    if not bNoLimit and dwTargetType == 4 and (hPlayer.dwID ~= dwTargetID) then
        return
    end

    if SkillData.IsUsingHDKungFu() then
        _box.nSkillLevel = nSkillLevel
        local szType = Skill_GetOptType(nSkillID, nSkillLevel)
        if castmode then
            if castmode == "self" then
                return OnUseSkill(nSkillID, (nSkillID * (nSkillID % 10 + 1)), _box, szType == "hoard", nil, nil, true)
            elseif castmode == "target" then
                return OnUseSkill(nSkillID, (nSkillID * (nSkillID % 10 + 1)), _box, szType == "hoard", nil, true)
            end
        else
            return OnUseSkill(nSkillID, (nSkillID * (nSkillID % 10 + 1)), _box, szType == "hoard")
        end
    else
        for nSlotIndex = 1, 10 do
            local nID = UIBattleSkillSlot.GetShowUI_Ver2(nSlotIndex)
            if nSkillID == nID and AutoBattle.TryCastSkill(hPlayer, nID, nSlotIndex) then
                return SKILL_RESULT_CODE.SUCCESS
            end
        end
    end
end

function IsSkillCastMyself(skill)
    local bTargetSelf = false
    if skill and IsSelfCastSkill() then
        if (skill.nCastMode == SKILL_CAST_MODE.TARGET_SINGLE or
                skill.nCastMode == SKILL_CAST_MODE.CASTER_SINGLE or
                skill.nCastMode == SKILL_CAST_MODE.TARGET_CHAIN or
                skill.nCastMode == SKILL_CAST_MODE.TARGET_TEAM_AREA) and
                (skill.nEffectType == SKILL_CAST_EFFECT_TYPE.BENEFICIAL) then
            local dwTargetType, dwTargetID = Target_GetTargetData()
            local dwPlayerID = GetControlPlayerID()
            if dwTargetType == TARGET.NPC or dwTargetType == TARGET.PLAYER then
                if IsEnemy(dwPlayerID, dwTargetID) then
                    bTargetSelf = true
                end
            else
                bTargetSelf = true
            end
        end
    end
    return bTargetSelf
end

local aTriggerFun = {}
function RegisterCastSkillFun(fnAction)
    table.insert(aTriggerFun, fnAction)
end

function UnRegisterCastSkillFun(fnAction)
    for k, v in ipairs(aTriggerFun) do
        if v == fnAction then
            table.remove(aTriggerFun, k)
            return
        end
    end
end

local m_last_cast_skill

function Skill_GetLastCast()
    return m_last_cast_skill
end

local _skillObj

function Skill_GetOptType(dwID, dwLevel, _skillObj)
    _skillObj = _skillObj or GetSkill(dwID, dwLevel)
    if _skillObj.bHoardSkill then
        return "hoard"
    elseif _skillObj.bKeyDownSkill then
        return "keydown"
    elseif _skillObj.bKeyUpSkill then
        return "keyup"
    elseif _skillObj.bKeyDownAndUpSkill then
        return "onlykeyup"
    end
end

function IsMobileSkill(dwID, dwLevel)
    if dwID == 0 then
        return false
    end
    dwLevel = dwLevel or 1
    local skill = GetSkill(dwID, dwLevel)
    if skill and skill.nPlatformType == SKILL_PLATFORM_TYPE.MOBILE then
        return true
    end
end

local nCastingSkillID, nCastingSkillLevel
function GetCastingSkill()
    return nCastingSkillID, nCastingSkillLevel
end

local function Skill_IsNeedChangeTargetInJoystick(player, nTargetID, skill)
    if nTargetID == 0 then
        return true
    end

    if IsEnemy(player.dwID, nTargetID) then
        return false
    end

    return (skill.nCastMode == SKILL_CAST_MODE.TARGET_SINGLE or
            skill.nCastMode == SKILL_CAST_MODE.TARGET_CHAIN or
            skill.nCastMode == SKILL_CAST_MODE.TARGET_AREA) and
            skill.nEffectType == SKILL_CAST_EFFECT_TYPE.HARMFUL
end

function Skill_AutoSearchEnemyInJoystick(player, nTargetID, skill, nSkillID, nSkillLevel)
    --if GetOperationMode() ~= JOYSTICK_MODE then
    --    return
    --end
    local tUISkill = Table_GetSkill(nSkillID, nSkillLevel)
    if not tUISkill or not tUISkill.bAutoSelectTarget then --策划填写了自动索敌的技能才需要处理
        return
    end

    if Skill_IsNeedChangeTargetInJoystick(player, nTargetID, skill) then
        nCastingSkillID, nCastingSkillLevel = nSkillID, nSkillLevel
        SearchEnemy()
        nCastingSkillID, nCastingSkillLevel = nil, nil
    end
end

local function Skill_AutoSearchEnemyInBirdMove(player, nTargetID, skill)
    if nTargetID ~= 0 then
        return
    end
    if  player.bBirdMove and
            player.nFlyFlag > 0 and
            (skill.nCastMode == SKILL_CAST_MODE.TARGET_SINGLE or
                    skill.nCastMode == SKILL_CAST_MODE.TARGET_CHAIN or
                    skill.nCastMode == SKILL_CAST_MODE.TARGET_AREA) and
            skill.nEffectType ~= SKILL_CAST_EFFECT_TYPE.BENEFICIAL and
            skill.IsRelationEnemy()
    then
        SearchEnemy()
    end
end

local function Skill_AutoSearchEnemy(player, skill, nSkillID, nSkillLevel)
    local _, nTargetID = player.GetTarget()

    Skill_AutoSearchEnemyInBirdMove(player, nTargetID, skill)

    Skill_AutoSearchEnemyInJoystick(player, nTargetID, skill, nSkillID, nSkillLevel)
end

local function Skill_GetPointAreaCastMode(nSkillID, skill, bPointAreaCast, bAutoPointCast)
    local nPointAreaCast = l_nPointAreaCastMode
    if bAutoPointCast then
        nPointAreaCast = POINT_AREA_CAST_MODE.TARGET
    end

    if nPointAreaCast == POINT_AREA_CAST_MODE.MOUSE and bPointAreaCast then
        nPointAreaCast = POINT_AREA_CAST_MODE.TRADITION
    end

    local bRangePutOpti = skill.bRangePutOpti
    if l_tAddonArenaCastMode[nSkillID] then -- 读取插件内对该技能单独设置的释放模式
        if l_tAddonArenaCastMode[nSkillID] == 102 then
            bRangePutOpti = true
            nPointAreaCast = POINT_AREA_CAST_MODE.MOUSE
        else
            bRangePutOpti = false
            nPointAreaCast = l_tAddonArenaCastMode[nSkillID]
        end
    end

    return nPointAreaCast, bRangePutOpti
end

local function Skill_GetTargetData(bAutoPointCast)
    local dwType, dwID = Target_GetTargetData()
    if bAutoPointCast and (not dwType or not dwID) then
        dwType = TARGET.PLAYER
        dwID = GetClientPlayer().dwID
    end
    return dwType, dwID
end

local function GetSkill_OnChekDis(nSkillID, nSkillLevel)
    local skill = GetPlayerSkill(nSkillID, nSkillLevel, GetClientPlayer().dwID)
    if not skill then
        skill = GetSkill(nSkillID, nSkillLevel)
    end

    return skill
end

local function Skill_IsReady(player, nSkillID, nSkillLevel)
    local dwCDID = Skill_GetCongNengCDID(nSkillID, player)
    local bCool, nLeft, nTotal, _, bPublicCD = Skill_GetCDProgress(nSkillID, nSkillLevel, dwCDID, player)
    if not bCool or nLeft == 0 and (bPublicCD or nTotal == 0) then
        return true
    end
end

local function Selection_ShowSFX(nSkillID, nSkillLevel)

end

local function Skill_Selection_ShowSFX(nSkillID, nSkillLevel)
    --if IsMobileSkill(nSkillID, nSkillLevel) then
    --    Selection_ShowSFX(100019, 1) --vk心法要统一提示圈，后续表现增加接口根据技能缩放
    --else
    --    Selection_ShowSFX(nSkillID, nSkillLevel)
    --end
end


local function Skill_CastPointAreaMode(nSkillID, nSkillLevel, nMask, box, bPointAreaCast, bAutoPointCast, bAutoCastSelf, player, fnAction)
    local skill = GetSkill(nSkillID, nSkillLevel)
    local tRecipeKey = player.GetSkillRecipeKey(nSkillID, nSkillLevel)
    local hSkillInfo = GetSkillInfoEx(tRecipeKey, player.dwID)

    local fnCancel = function()
        Selection_HideSFX()
    end
    local bNormal = true
    local fnCondition = function(x, y, z)
        local skill = GetSkill_OnChekDis(nSkillID, nSkillLevel)
        if skill.CheckDistance(player.dwID, x, y, z) == SKILL_RESULT_CODE.SUCCESS then
            if not bNormal then
                Selection_HideSFX()
            end

            Skill_Selection_ShowSFX(nSkillID, nSkillLevel)
            bNormal = true
            return true
        else
            if bNormal then
                Selection_HideSFX()
            end
            Selection_ShowSFX(SKILL_SELECT_POINT_UNNORMAL.nSkillID, SKILL_SELECT_POINT_UNNORMAL.nLevel)
            bNormal = false
            return false
        end
    end

    if skill.UITestCast(player.dwID, IsSkillCastMyself(skill)) ~= SKILL_RESULT_CODE.SUCCESS then
        return
    end

    if IsSkillCastToMe(nSkillID) or bAutoCastSelf then
        if IsQiChangSkill(nSkillID) then
            fnAction(true, nMask)
        else
            local x, y, z = player.GetAbsoluteCoordinate()
            fnAction(x, y, z)
        end
        return
    end

    if not Skill_IsReady(player, nSkillID, nSkillLevel) and not bAutoPointCast then --对于宏的casttotarget不判cd
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_SKILL_SKILL_NOT_READY)
        return
    end

    Skill_Selection_ShowSFX(nSkillID, nSkillLevel)
    local nPointAreaCast, bRangePutOpti = Skill_GetPointAreaCastMode(nSkillID, skill, bPointAreaCast, bAutoPointCast)

    if nPointAreaCast == POINT_AREA_CAST_MODE.MOUSE then -- 简化模式，点击技能后立即在鼠标当前位置释放
        local DoSelect = function(x, y, z)
            if fnCondition(x, y, z) then
                fnAction(x, y, z)
            else
                Selection_HideSFX()
            end
        end

        local x, y = Cursor.GetPos(false)
        if bRangePutOpti then
            PostThreadCall(DoSelect, nil, "Scene_SelectRayGround", x, y, hSkillInfo.MaxRadius - 1) ---由于表现是浮点数计算，逻辑是整数计算，存在精度问题，导致最后给的坐标的还是不合法的，要把技能释放距离减1
        else
            PostThreadCall(DoSelect, nil, "Scene_SelectGround", x, y)
        end
        return
    end

    if nPointAreaCast == POINT_AREA_CAST_MODE.TARGET then -- 默认模式，在目标处释放，如果不符合条件就按传统模式释放
        local dwType, dwID = Skill_GetTargetData(bAutoPointCast)
        if dwType == TARGET.NPC or dwType == TARGET.PLAYER then
            local lTarget
            if dwType == TARGET.PLAYER then
                lTarget = GetPlayer(dwID)
            elseif dwType == TARGET.NPC then
                lTarget = GetNpc(dwID)
            end
            local x, y, z = lTarget.GetAbsoluteCoordinate()

            --对于vk技能做释放位置修正
            if dwType == TARGET.NPC and IsMobileSkill(nSkillID, nSkillLevel) then
                -- 修正默认目标点到目标角色的被击框的边缘, 参考vk UISkillDirection.lua
                local nTouch = math.max(128, lTarget.nTouchRange)
                local nX, nY, nZ = lTarget.GetAbsoluteCoordinate()
                local scene = player.GetScene()
                local nDeltaZ = scene.GetFloor(nX, nY, nZ) - nZ
                local nPlayerX, nPlayerY, nPlayerZ = player.GetAbsoluteCoordinate()

                nX = nX - nPlayerX
                nY = nY - nPlayerY
                nZ = (nZ - nPlayerZ) / 8  -- 逻辑高度单位与逻辑水平单位的转换系数

                local nLen = math.sqrt(nX * nX + nY * nY + nZ * nZ)
                if nLen < nTouch then
                    x, y, z = nPlayerX, nPlayerY, nPlayerZ
                elseif nLen > 0.01 and nLen < hSkillInfo.MaxRadius + nTouch then
                    local nDis = nLen - nTouch
                    x, y, z =
                    nPlayerX + nDis * nX / nLen,
                    nPlayerY + nDis * nY / nLen,
                    nPlayerZ + nDis * nZ / nLen * 8
                    local nFloorZ = scene.GetFloor(x, y, z + 512) or z
                    if math.abs(nDeltaZ) < 128 then    -- 0.25米
                        z = nFloorZ       --目标在地面则目标点也贴地
                    else
                        z = math.max(z, nFloorZ) -- 修正计算坐标可能在地底的问题
                    end
                end
            end

            if fnCondition(x, y, z) then
                if IsQiChangSkill(nSkillID) then
                    fnAction(false, nMask)
                else
                    fnAction(x, y, z)
                end
                return
            end
        end
    end

    --UserSelect.SelectPoint(fnAction, fnCancel, fnCondition, box) --传统模式
    if skill.nPlatformType == SkillPlatformType.Mobile then
        local releasePos = SkillData.GetCastPoint()
        fnAction(releasePos.x, releasePos.y, releasePos.z)
    end
end

local function Skill_CastNormalMode(nSkillID, nSkillLevel, nMask, box, bStartHoard, player, fnAction)
    local nCastResult = nil
    local skill = GetSkill(nSkillID, nSkillLevel)
    local bTargetSelf = IsSkillCastMyself(skill)
    local bCommonSkill, bMelee = IsCommonSkill(nSkillID)
    if bCommonSkill then
        nCastResult = CastCommonSkill(bMelee)
        CheckCastSkillResult(nCastResult, box)
        return nCastResult
    end

    if skill.bHoardSkill then
        if bStartHoard then
            if not Skill_NotInCountDown(nSkillID, nSkillLevel, player) then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_SKILL_SKILL_NOT_READY)
                return
            end

            nCastResult = player.StartHoardSkill(nSkillID, nSkillLevel)
            if nCastResult ~= SKILL_RESULT_CODE.SUCCESS then
                FireUIEvent("SYS_MSG", "UI_OME_SKILL_RESPOND", nRetCode)
            end
        else
            player.CastHoardSkill()
            nCastResult = SKILL_RESULT_CODE.SUCCESS
        end
        return nCastResult
    end

    if IsSkillCastToMe(nSkillID) then
        bTargetSelf = true
    end
    fnAction(bTargetSelf, nMask)
end

local function Skill_CastHoardPointAreaMode(nSkillID, nSkillLevel, nMask, box, bStartHoard, bPointAreaCast, bAutoPointCast, bAutoCastSelf, player, fnAction)
    local nCastResult = nil
    local skill = GetSkill(nSkillID, nSkillLevel)
    local tRecipeKey = player.GetSkillRecipeKey(nSkillID, nSkillLevel)
    local hSkillInfo = GetSkillInfoEx(tRecipeKey, player.dwID)

    if skill.UITestCast(player.dwID, IsSkillCastMyself(skill)) ~= SKILL_RESULT_CODE.SUCCESS then
        return
    end

    if not Skill_NotInCountDown(nSkillID, nSkillLevel, player) then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_SKILL_SKILL_NOT_READY)
        return
    end

    local nPointAreaCast, bRangePutOpti = Skill_GetPointAreaCastMode(nSkillID, skill, bPointAreaCast, bAutoPointCast)
    local bNormal = true
    local fnCondition = function(x, y, z, bTarget)
        local skill = GetSkill_OnChekDis(nSkillID, nSkillLevel)
        if skill.CheckDistance(player.dwID, x, y, z) == SKILL_RESULT_CODE.SUCCESS then
            if not bNormal then
                Selection_HideSFX()
            end

            if not (bTarget and Target_GetTargetID()) then
                Skill_Selection_ShowSFX(nSkillID, nSkillLevel)
            end
            bNormal = true
            return true
        else
            if bNormal then
                Selection_HideSFX()
            end

            if not (bTarget and Target_GetTargetID()) then
                Selection_ShowSFX(SKILL_SELECT_POINT_UNNORMAL.nSkillID, SKILL_SELECT_POINT_UNNORMAL.nLevel)
            end
            bNormal = false
            return false
        end
    end

    if bStartHoard then
        nCastResult = player.StartHoardSkill(nSkillID, nSkillLevel, TARGET.PLAYER, player.dwID)
        if nCastResult ~= SKILL_RESULT_CODE.SUCCESS then
            FireUIEvent("SYS_MSG", "UI_OME_SKILL_RESPOND", nRetCode)
        else
            --UserSelect.SelectPoint(function() end, function() Selection_HideSFX() end, function(x,y,z) fnCondition(x, y, z, nPointAreaCast == POINT_AREA_CAST_MODE.TARGET) return false end, box) --开始蓄力显示技能提示
            FireUIEvent("START_AREAPOINT_HOARDSKILL")
        end
        return nCastResult
    else
        if IsSkillCastToMe(nSkillID) or bAutoCastSelf then
            local x, y, z = player.GetAbsoluteCoordinate()
            fnAction(x, y, z)
            return
        end

        if nPointAreaCast == POINT_AREA_CAST_MODE.TARGET then --在目标处释放，如果不符合条件就在鼠标位置释放
            local dwType, dwID = Skill_GetTargetData(bAutoPointCast)
            if dwType == TARGET.NPC or dwType == TARGET.PLAYER then
                local lTarget
                if dwType == TARGET.PLAYER then
                    lTarget = GetPlayer(dwID)
                elseif dwType == TARGET.NPC then
                    lTarget = GetNpc(dwID)
                end
                local x, y, z = lTarget.GetAbsoluteCoordinate()

                if fnCondition(x, y, z) then
                    fnAction(x, y, z)
                    return
                end
            end
        end

        local DoSelect = function(x, y, z)
            if fnCondition(x, y, z) then
                fnAction(x, y, z)
            else
                Selection_HideSFX()
            end
        end

        local x, y = Cursor.GetPos(false)
        if bRangePutOpti then
            PostThreadCall(DoSelect, nil, "Scene_SelectRayGround", x, y, hSkillInfo.MaxRadius - 1)
        else
            PostThreadCall(DoSelect, nil, "Scene_SelectGround", x, y)
        end
    end
end

local function Skill_CastPointRectangleMode(nSkillID, nSkillLevel, nMask, box, bPointAreaCast, bAutoPointCast, player, fnAction)
    local skill = GetSkill(nSkillID, nSkillLevel)
    local tRecipeKey = player.GetSkillRecipeKey(nSkillID, nSkillLevel)
    local hSkillInfo = GetSkillInfoEx(tRecipeKey, player.dwID)

    if skill.UITestCast(player.dwID, IsSkillCastMyself(skill)) ~= SKILL_RESULT_CODE.SUCCESS then
        return
    end

    if IsSkillCastToMe(nSkillID) then
        local x, y, z = player.GetAbsoluteCoordinate()
        fnAction(x, y, z)
        return
    end

    if not Skill_IsReady(player, nSkillID, nSkillLevel) then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_SKILL_SKILL_NOT_READY)
        return
    end

    local nDir = math.pi * 2 * player.nFaceDirection / GLOBAL.DIRECTION_COUNT
    local nX, nY, nZ = player.GetAbsoluteCoordinate()
    nX = nX + math.cos(nDir) * (hSkillInfo.MaxRadius - 32) --精度问题，使用最大距离减去0.5尺应该能放出来
    nY = nY + math.sin(nDir) * (hSkillInfo.MaxRadius - 32)
    fnAction(nX, nY, nZ)
end

local function Skill_GetBoxAndLevel(nSkillID, box, player)
    local nSkillLevel = player.GetSkillLevel(nSkillID)

    if box and box.nSkillLevel then
        nSkillLevel = box.nSkillLevel
        if box._vir then
            box = nil
        end
    end

    --if not nSkillLevel or nSkillLevel == 0 and box and not box:IsEmpty() then
    --    local nSubType, dwItemIndex = box:GetObjectData()
    --    if IsPendantSub(nSubType) then
    --        local hSkill = GetPendentSkill(dwItemIndex)
    --        if hSkill then
    --            nSkillLevel = hSkill.dwLevel
    --        end
    --    end
    --end

    if not nSkillLevel or nSkillLevel == 0 then
        nSkillLevel = 1
    end

    return nSkillLevel, {}
end

local function CheckRideHorse(nSkillID)
    if nSkillID == 605 then  -- 上下马技能
        RideHorse()
        return true
    end

    return false
end

local function CheckSwitchMap(nSkillID)
    if nSkillID == 81 then -- 地图传送技能
        if IsInPVPField() then --项烤强烈要求
            LeavePVPField()
        elseif IsInGlobalRoomDungeon() then
            ConfirmLeaveRoomScene()
        else
            OpenWorldMap(true, 0, true)
        end
        return true
    end
    return false
end

local function CheckTrigger(nSkillID, nSkillLevel)
    for _, v in ipairs(aTriggerFun) do
        if v(nSkillID, nSkillLevel) == false then
            return true
        end
    end

    return false
end

function OnUseSkill(nSkillID, nMask, _box, bStartHoard, bPointAreaCast, bAutoPointCast, bAutoCastSelf)
    m_last_cast_skill = nSkillID

    if CheckRideHorse(nSkillID) then  -- 上下马技能
        return
    end

    if CheckSwitchMap(nSkillID) then -- 地图传送技能
        return
    end

    SpecialSettings.ChangeJianwuStatus(nSkillID)

    local player = GetControlPlayer()
    local nSkillLevel, box = Skill_GetBoxAndLevel(nSkillID, _box, player)

    local skill = GetSkill(nSkillID, nSkillLevel)
    if not skill or skill.bIsPassiveSkill then
        return
    end

    if CheckTrigger(nSkillID, nSkillLevel) then
        return
    end

    local tRecipeKey = player.GetSkillRecipeKey(nSkillID, nSkillLevel)
    local hSkillInfo = GetSkillInfoEx(tRecipeKey, player.dwID)

    Skill_AutoSearchEnemy(player, skill, nSkillID, nSkillLevel)

    ---- VK技能：自动索敌, 转向
    --if IsMobileSkill(nSkillID, nSkillLevel) then
    --    MobileSkill_AutoSearchEnemy(player, nSkillID, nSkillLevel)
    --end

    FireHelpEvent("OnUseSkill", nSkillID, nSkillLevel)

    local nSkillResult
    local fnAction = function(x, y, z)
        if skill and skill.bHoardSkill then
            player.CastHoardSkillXYZ(x, y, z)
            nSkillResult = SKILL_RESULT_CODE.SUCCESS
            return
        end

        if z then
            nSkillResult = CastSkillXYZ(nSkillID, nSkillLevel, x, y, z)
        else
            nSkillResult = CastSkill(nSkillID, nSkillLevel, x, y)
        end

        --蓬莱技能释放设置亮剑姿态，进行雕的表现召唤，很坑
        local tLine = g_tTable.PengLaiSkillCallIDList:Search(nSkillID)
        if nSkillResult == SKILL_RESULT_CODE.SUCCESS and tLine then
            if player.bSheathFlag then
                player.SetSheath(0)
            end
        end

        CheckCastSkillResult(nSkillResult, box)
    end

    if skill.nCastMode ==  SKILL_CAST_MODE.POINT_AREA and player.dwShapeShiftID > 0 then
        local x, y, z = SkillData.GetShootPoint()
        fnAction(x, y, z)
    elseif skill.nCastMode == SKILL_CAST_MODE.POINT_AREA or skill.nCastMode == SKILL_CAST_MODE.POINT then
        if skill.bHoardSkill then
            local nCastResult = Skill_CastHoardPointAreaMode(nSkillID, nSkillLevel, nMask, box, bStartHoard, bPointAreaCast, bAutoPointCast, bAutoCastSelf, player, fnAction)
            nSkillResult = nCastResult or nSkillResult
        else
            Skill_CastPointAreaMode(nSkillID, nSkillLevel, nMask, box, bPointAreaCast, bAutoPointCast, bAutoCastSelf, player, fnAction)
        end
    elseif skill.nCastMode == SKILL_CAST_MODE.POINT_RECTANGLE then
        Skill_CastPointRectangleMode(nSkillID, nSkillLevel, nMask, box, bPointAreaCast, bAutoPointCast, player, fnAction)
    else
        local nCastResult = Skill_CastNormalMode(nSkillID, nSkillLevel, nMask, box, bStartHoard, player, fnAction)
        nSkillResult = nCastResult or nSkillResult
    end
    return nSkillResult
end

function CheckCastSkillResult(nSkillResult, hBox)
    if hBox and hBox.bPetActionBar and nSkillResult and nSkillResult == SKILL_RESULT_CODE.SUCCESS then
        PetActionBar_UpdateBoxState(hBox)
    end
end

function UpdataPendantSkillCDProgress(hPlayer, hBox)
    if hBox:IsEmpty() then
        return
    end
    local _, dwItemIndex = hBox:GetObjectData()
    local hSkill = GetPendentSkill(dwItemIndex)

    return UpdataTheSkillCDProgress(hPlayer, hBox, hSkill, true)
end
function UpdataSkillCDProgress(player, box, bOther)
    local dwSkillID, dwSkillLevel = box:GetObjectData()
    local skill = GetSkill(dwSkillID, dwSkillLevel)
    return UpdataTheSkillCDProgress(player, box, skill, nil, bOther)
end

local CD_SPARKING_FRAME = GLOBAL.GAME_FPS * 4

local function GetCoolTimeText(nLeft)
    nLeft = nLeft or 0
    local szText = ""
    local nTimeType = 2
    local nH, nM, nS = GetTimeToHourMinuteSecond(nLeft, true)
    if nH > 0 then
        if nM > 0 or nS > 0 then
            nH = nH + 1
        end
        szText = nH .. 'h'
        nTimeType = 0
    elseif nM > 0 then
        if nS > 0 then
            nM = nM + 1
        end
        szText = nM .. 'm'
        nTimeType = 1
    elseif nS >= 0 then
        szText = nS
        if nS < 5 then
            nTimeType = 2
        else
            nTimeType = 3
        end
    end
    return szText, nTimeType
end

function UpdataTheSkillCDProgress(player, box, skill, bPendent, bOther)
    local nLeftTime
    if not skill then
        box:EnableObject(false)
        return
    end

    local dwSkillID, dwSkillLevel = skill.dwSkillID, skill.dwLevel
    if skill then
        if skill.bIsPassiveSkill or Table_IsSkillFormation(dwSkillID, dwSkillLevel) then
            box:EnableObject(true)
        else
            if skill.UITestCast(player.dwID, IsSkillCastMyself(skill)) == SKILL_RESULT_CODE.SUCCESS or bOther then
                box:EnableObject(true)
            else
                box:EnableObject(false)
            end
        end
    end
    if bPendent then
        local nPendentType, dwItemIndex = box:GetObjectData()
        local nRepresentType
        local nRepresentType = ExteriorView_GetRepresentSub(nPendentType)
        local itemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
        if player.GetSingleRepresentID(nRepresentType) ~= itemInfo.nRepresentID then
            box:EnableObject(false)
        end
    end
    local bCommon, bMelee = IsCommonSkill(dwSkillID)
    if bCommon and bMelee then
        if g_bCastCommonSkill then
            box:SetObjectInUse(true)
        else
            box:SetObjectInUse(false)
        end
        return nLeftTime
    end

    local nLeftCongNengCd
    local bCool, nLeft, nTotal = Skill_GetCDProgress(dwSkillID, dwSkillLevel, box._CDId, player)
    if box._CDId then
        local nMaxCount = player.GetCDMaxCount(skill.dwSkillID)

        local nCongNengCd, nCDCount = player.GetCDLeft(box._CDId)
        local nCongNengTotal = player.GetCDInterval(box._CDId)
        if nMaxCount > 1 then
            box:SetExtentLayer(2, CongNeng_GetBg())
            box:SetExtentLayer(3, CongNeng_GetPerImage())
            box:SetExtentImageType(3, IMAGE.REVERSE_TIMER_SHOW)
            box:SetExtentTimeStartAngle(3, math.pi * 135 / 180)
            box:SetOverTextFontScheme(1, 15)
            box:SetOverText(1, nCDCount .. " ")
        end

        if box:IsObjectEnable() and nCDCount == 0 then
            box:EnableObject(false)
        end
        box:SetExtentPercent(3, 1 - nCongNengCd / nCongNengTotal)
        if nCDCount == 0 then
            nLeftCongNengCd = nCongNengCd
        end
    elseif box._ODCDId then
        local nMaxOverDraftCount, nDraftCount = player.GetOverDraftCoolDown(box._ODCDId)
        if box:IsObjectEnable() and nDraftCount == nMaxOverDraftCount then
            box:EnableObject(false)
        end
        box:SetExtentPercent(4, 1 - math.max(nDraftCount - 1, 0) / (nMaxOverDraftCount - 1))
        box:SetExtentPercent(5, nDraftCount == 0 and 1 or 0)
    end

    if bCool then
        box:SetOverTextPosition(3, ITEM_POSITION.CENTER)
        if nLeft == 0 and nTotal == 0 then
            if box:IsObjectCoolDown() then
                box:SetObjectSparking(true)
                box:SetObjectCoolDown(false)
                box:SetCoolDownPercentage(0)
            end
            if box._ODCDId then
                box:SetExtentPercent(2, 0)
            end
            box:SetOverText(3, "")
        elseif box._ODCDId then
            box:SetExtentPercent(2, nLeft / nTotal)
        else
            box:SetObjectCoolDown(1)
            box:SetCoolDownPercentage(1 - nLeft / nTotal)
        end

        nLeftTime = nLeft
        if nLeftTime and nLeftTime > 0 and IsActionBarCoolDownShow() then
            if nLeftTime < CD_SPARKING_FRAME then
                -- CD倒计时
                if nLeftTime % GLOBAL.GAME_FPS > GLOBAL.GAME_FPS / 2 then
                    -- 最后三秒闪烁效果
                    box:SetOverTextFontScheme(3, 235)
                else
                    box:SetOverTextFontScheme(3, 23)
                end
            else
                box:SetOverTextFontScheme(3, 23)
            end
            box:SetOverText(3, (GetCoolTimeText(nLeftTime)))
        end
    else
        if box._ODCDId then
            box:SetExtentPercent(2, 0)
        end
        box:SetObjectCoolDown(0)
    end
    if nLeftCongNengCd then
        return nLeftCongNengCd
    else
        return nLeftTime
    end
end

function UpdateKungfuCDProgress(player, box)
    local dwSkillID, dwSkillLevel = box:GetObjectData()
    local bCool, nLeft, nTotal = Skill_GetCDProgress(dwSkillID, dwSkillLevel, nil, player)
    if bCool then
        if nLeft == 0 and nTotal == 0 then
            if box:IsObjectCoolDown() then
                box:SetObjectCoolDown(0)
                box:SetObjectSparking(1)
            end
        else
            box:SetObjectCoolDown(1)
            box:SetCoolDownPercentage(1 - nLeft / nTotal)
        end
    else
        box:SetObjectCoolDown(0)
    end
end

function GetSurplus(fParam)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return 0
	end
	return math.floor(fParam * hPlayer.nSurplusValue * SurplusParam)
end

function GetSkillkeyDescEx(dwSkillID, dwLevel, szKey1, szKey2, player)
    local player = player or GetClientPlayer()--<SKILL_{400_1, 401_1, 402_0} PhysicsDamage>
    local value, value1 = 0, 0
    local nMin, nMax = 0, 0
    local bExist = false;
    local tSkill = SplitString(szKey1, ";");
    for k, v in pairs(tSkill) do
        local skillid, level = string.match(v, "(%d+)_(%d+)")
        skillid = tonumber(skillid)
        level = tonumber(level)

        if level == 0 then
            level = dwLevel;
        end
        local skillkey = player.GetSkillRecipeKey(skillid, level)
        local skillInfo = GetSkillInfoEx(skillkey, player.dwID)

        if szKey2 == "BuffDurationFrame" then
            value = value + (skillInfo.BuffDurationFrame / GLOBAL.GAME_FPS)
        elseif szKey2 == "DebuffDurationFrame" then
            value = value + (skillInfo.DebuffDurationFrame / GLOBAL.GAME_FPS)
        elseif szKey2 == "Dot" then
            value = value + (skillInfo.DotCount * skillInfo.DotIntervalFrame / GLOBAL.GAME_FPS)
            value1 = value1 + (skillInfo.DotCount * skillInfo.DotDamage)
        elseif szKey2 == "Hot" then
            value = value + (skillInfo.HotCount * skillInfo.HotIntervalFrame / GLOBAL.GAME_FPS)
            value1 = value1 + (skillInfo.HotCount * skillInfo.HotTherapy)
        elseif skillInfo["Min" .. szKey2] and skillInfo["Max" .. szKey2] then
            nMin = nMin + skillInfo["Min" .. szKey2]
            nMax = nMax + skillInfo["Max" .. szKey2]
            bExist = true
        end
    end

    if bExist then
        if nMin == nMax then
            return math.abs(nMin)
        end
        return math.abs(nMin) .. "-" .. math.abs(nMax)
    end

    if szKey2 == "BuffDurationFrame" then
        return value
    elseif szKey2 == "DebuffDurationFrame" then
        return value
    elseif szKey2 == "Dot" then
        return FormatString(g_tStrings.STR_DOT_TIP_DAMAGE, value, value1)
    elseif szKey2 == "Hot" then
        return FormatString(g_tStrings.STR_HOT_TIP_THERAPY, value, value1)
    end
    return szKey2
end

function GetSkillkeyDesc(skillInfo, szkey)
    if not skillInfo then
        return ""
    end
    if szkey == "BuffDurationFrame" then
        return skillInfo.BuffDurationFrame / GLOBAL.GAME_FPS
    elseif szkey == "DebuffDurationFrame" then
        return skillInfo.DebuffDurationFrame / GLOBAL.GAME_FPS
    elseif szkey == "Dot" then
        return FormatString(g_tStrings.STR_DOT_TIP_DAMAGE, skillInfo.DotCount * skillInfo.DotIntervalFrame / GLOBAL.GAME_FPS, skillInfo.DotCount * skillInfo.DotDamage)
    elseif szkey == "Hot" then
        return FormatString(g_tStrings.STR_HOT_TIP_THERAPY, skillInfo.HotCount * skillInfo.HotIntervalFrame / GLOBAL.GAME_FPS, skillInfo.HotCount * skillInfo.HotTherapy)
    end

    local nMin, nMax = skillInfo["Min" .. szkey], skillInfo["Max" .. szkey]
    if nMin and nMax then
        if nMin == nMax then
            return math.abs(nMin)
        end
        return math.abs(nMin) .. "-" .. math.abs(nMax)
    end
    return szkey
end

function AnalyzeTipEx(hSkill, szKey1, szKey2)
    local hPlayer = GetClientPlayer()

    local fResult
    if szKey1 == "MaxLife" then
        fResult = hPlayer.nMaxLife * tonumber(szKey2)
        return fResult
    elseif szKey1 == "MaxMana" then
        fResult = hPlayer.nMaxMana * tonumber(szKey2)
        return fResult
    elseif szKey1 == "MaxLifeBase" then
        fResult = hPlayer.nMaxLifeBase * tonumber(szKey2)
        return fResult
    elseif szKey1 == "MaxManaBase" then
        fResult = hPlayer.nMaxManaBase * tonumber(szKey2)
        return fResult
    elseif szKey1 == "CurrentAgility" then
        fResult = hPlayer.nCurrentAgility * tonumber(szKey2)
        return fResult
    elseif szKey1 == "AgilityBase" then
        fResult = hPlayer.nAgilityBase * tonumber(szKey2)
        return fResult
    elseif szKey1 == "CurrentSpirit" then
        fResult = hPlayer.nCurrentSpirit * tonumber(szKey2)
        return fResult
    elseif szKey1 == "SpiritBase" then
        fResult = hPlayer.nSpiritBase * tonumber(szKey2)
        return fResult
    elseif szKey1 == "CurrentVitality" then
        fResult = hPlayer.nCurrentVitality * tonumber(szKey2)
        return fResult
    elseif szKey1 == "VitalityBase" then
        fResult = hPlayer.nVitalityBase * tonumber(szKey2)
        return fResult
    elseif szKey1 == "CurrentSpunk" then
        fResult = hPlayer.nCurrentSpunk * tonumber(szKey2)
        return fResult
    elseif szKey1 == "SpunkBase" then
        fResult = hPlayer.nSpunkBase * tonumber(szKey2)
        return fResult
    end

    local i, j
    i, j = string.find(szKey1, "Total.-AP")
    if i then
        fResult = string.gsub(
                szKey1,
                "Total(.-)AP",
                function(szKey1)
                    if szKey1 == "Therapy" then
                        return hPlayer["n" .. szKey1 .. "Power"] * tonumber(szKey2)
                    else
                        return hPlayer["n" .. szKey1 .. "AttackPower"] * tonumber(szKey2)
                    end
                end)
        return fResult
    end

    i, j = string.find(szKey1, "Basic.-AP")
    if i then
        fResult = string.gsub(
                szKey1,
                "Basic(.-)AP",
                function(szKey1)
                    if szKey1 == "Therapy" then
                        return hPlayer["n" .. szKey1 .. "PowerBase"] * tonumber(szKey2)
                    else
                        return hPlayer["n" .. szKey1 .. "AttackPowerBase"] * tonumber(szKey2)
                    end
                end)
        return fResult
    end

    i, j = string.find(szKey1, "Skill.-AP_%[.-%]")--"SkillTherapyAP_{400_1 401_1 402_1}"
    if i then
        fResult = string.gsub(
                szKey1,
                "Skill(.-)AP_%[(.-)%]",
                function(key, szKey2)
                    local tSkill = SplitString(szKey2, ";")
                    local SkillAP = 0
                    for k, v in pairs(tSkill) do
                        local skillid, level = string.match(v, "(%d+)_(%d+)")
                        skillid = tonumber(skillid)
                        level = tonumber(level)
                        if level == 0 then
                            level = hSkill.dwLevel;
                        end

                        local skill = GetSkill(skillid, level)
                        local WeaponFlag
                        if skill.dwWeaponRequest == 0 then
                            --判定技能是否需要武器
                            WeaponFlag = 0
                        else
                            WeaponFlag = 1
                        end
                        if key == "Physics" then
                            SkillAP = SkillAP + (math.max((skill.nChannelInterval + skill.nPrepareFrames) / 16, 1)) * hPlayer["n" .. key .. "AttackPower"] / 10
                        elseif key == "Therapy" then
                            SkillAP = SkillAP + (math.max((skill.nChannelInterval + skill.nPrepareFrames) / 16, 1)) * hPlayer["n" .. key .. "Power"] / 12
                        else
                            SkillAP = SkillAP + (math.max((skill.nChannelInterval + skill.nPrepareFrames) / 16, 1)) * hPlayer["n" .. key .. "AttackPower"] / 12
                        end
                    end
                    return SkillAP
                end)
        return fResult
    end

    i, j = string.find(szKey1, "Skill.-AP")--"SkillTherapyAP"
    if i then
        fResult = string.gsub(
                szKey1,
                "Skill(.-)AP",
                function(key)
                    local SkillAP = 0
                    local WeaponFlag
                    if hSkill.dwWeaponRequest == 0 then
                        --判定技能是否需要武器
                        WeaponFlag = 0
                    else
                        WeaponFlag = 1
                    end
                    if key == "Physics" then
                        SkillAP = (math.max((hSkill.nChannelInterval + hSkill.nPrepareFrames) / 16, 1)) * hPlayer["n" .. key .. "AttackPower"] / 10
                    elseif key == "Therapy" then
                        SkillAP = (math.max((hSkill.nChannelInterval + hSkill.nPrepareFrames) / 16, 1)) * hPlayer["n" .. key .. "Power"] / 12
                    else
                        SkillAP = (math.max((hSkill.nChannelInterval + hSkill.nPrepareFrames) / 16, 1)) * hPlayer["n" .. key .. "AttackPower"] / 12
                    end
                    return SkillAP
                end)
        return fResult
    end
end

function GetSkillTipEx(hSkill, szKey1, szKey2)
    tSplit = SplitString(szKey2, ",")
    local tSave = {}

    for i, v in ipairs(tSplit) do
        local i = string.find(v, " ")
        local fResult
        if i then
            fResult = string.gsub(v, "{(.-) (.-)}", function(szKey1, szKey2)
                return AnalyzeTipEx(_, szKey1, szKey2)
            end)
        else
            fResult = string.gsub(v, "{(.-)}", function(szKey1)
                return AnalyzeTipEx(hSkill, szKey1)
            end)
        end

        if fResult then
            table.insert(tSave, tonumber(fResult))
        end
    end

    local szData = FormatString(szKey1, unpack(tSave))
    return szData
end

function FormatSkillTipByRecipeKey(tRecipeKey, bNextLevelDesc, bShortDesc, bRecipeList, bShowProfit, nTalentSkillLevel, hPlayer)
    hPlayer = hPlayer or GetClientPlayer()
    if not hPlayer then
        return ""
    end

    local dwID = tRecipeKey.skill_id
    local nLevel = tRecipeKey.skill_level

    local hSkillInfo = GetSkillInfoEx(tRecipeKey, hPlayer.dwID)

    local tOriRecipeKey = clone(tRecipeKey)
    for nIndex = 1, 12, 1 do
        tOriRecipeKey["recipe" .. nIndex] = 0
    end
    local hOriSkillInfo = GetSkillInfoEx(tOriRecipeKey, hPlayer.dwID)

    local tSkillInfo = Table_GetSkill(dwID, nLevel)
    local hSkill = GetSkill(dwID, nLevel)
    local nMinPrepareTime = hSkill.nMinPrepareFrames

    local bHaveNextLevel = false
    local szTip = GetFormatText(tSkillInfo.szName, FONT_SKILL_NAME)

    local nCurrentTime = GetTickCount()
    --if IsAltKeyDown() and
    --        nCurrentTime > m_nLastAltDownTime + ALT_KEY_VALID_INTERVAL
    --then
        g_bMoreSkillInfo = not g_bMoreSkillInfo
        m_nLastAltDownTime = nCurrentTime
    --end
    local bSimpleDescEmpty = false
    if tSkillInfo.szSimpleDesc == "" then
        bSimpleDescEmpty = true
    end

    local dwDescLevel = 9999
    if hSkill.dwBelongKungfu == 0 then
        if hSkill.nUIType == SkillNUIType.XinFa then
            if tSkillInfo.bShowLevel then
                local szSkillLevel = FormatString(g_tStrings.STR_SKILL_H_THE_WHAT_LEVEL, NumberToChinese(nLevel))
                szTip = szTip .. GetFormatText(szSkillLevel, FONT_SKILL_LEVEL)
            end
            szTip = szTip .. GetFormatText("\n" .. g_tStrings.tMountRequestTable[hSkill.dwBelongSchool] .. "\n", 106)
            if not bShortDesc then
                dwDescLevel = nLevel
            end
        else
            local szSchool = Table_GetSkillSchoolName(hSkill.dwBelongSchool);
            szTip = szTip .. GetFormatText("\n" .. szSchool .. g_tStrings.STR_SKILL_ZS .. "\n", 106)
        end
    else
        if hSkill.bIsPassiveSkill then
            szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_SKILL_PASSIVE_SKILL, 106)
        elseif tSkillInfo.bFormation ~= 0 then
            szTip = szTip .. GetFormatText("\n" .. g_tStrings.FORMATION_GAMBIT, 106)
        elseif g_bMoreSkillInfo or bSimpleDescEmpty then
            if tSkillInfo.bShowLevel then
                local szSkillLevel = FormatString(g_tStrings.STR_SKILL_H_THE_WHAT_LEVEL, NumberToChinese(nLevel))
                if nTalentSkillLevel then
                    szSkillLevel = FormatString(g_tStrings.STR_SKILL_H_THE_WHAT_LEVEL, nTalentSkillLevel.."/"..hSkill.dwMaxLevel)
                end
                szTip = szTip .. GetFormatText(szSkillLevel, FONT_SKILL_LEVEL)
            end

            szTip = szTip .. GetFormatText("\n", 106) .. FormatCastRadius(hSkill.nCastMode, hSkillInfo, hOriSkillInfo, bShowProfit) .. GetFormatText("\t", 106)
            szTip = szTip .. FormatCastCost(hSkillInfo, hOriSkillInfo, bShowProfit, hSkill.nCostManaBasePercent) .. GetFormatText("\n", 106)

            szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_WEAPEN_REQUIRE, 106)
            local nWeaponFont = 102
            if hSkill.CheckWeaponRequest(hPlayer.dwID) == SKILL_RESULT_CODE.SUCCESS then
                nWeaponFont = 106
            end
            szTip = szTip .. GetFormatText(g_tStrings.tWeaponLimitTable[hSkill.dwWeaponRequest], nWeaponFont)

            szTip = szTip .. GetFormatText("\t", 106)
            if dwID == 605 then
                if hPlayer.bOnHorse then
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_IMMIDIATLY, 106)
                else
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_TIME .. 3 .. g_tStrings.STR_BUFF_H_TIME_S, 106)
                end
            else
                local nCastTime = hPlayer.GetSkillPrepare(dwID, nLevel)
                szTip = szTip .. FormatCastTime(hSkillInfo, hOriSkillInfo, bShowProfit, nCastTime) .. GetFormatText("\n", 106)
            end

            local szPose
            if hSkill.nNeedPoseState > 0 then
                local nPoseFont = 102
                if hSkill.nNeedPoseState == hPlayer.nPoseState then
                    nPoseFont = 106
                end

                szPose = GetFormatText(g_tStrings.STR_SKILL_H_POSE_REQUIRE, 106)
                szPose = szPose .. GetFormatText(g_tStrings.CANG_YUN_POSE[hSkill.nNeedPoseState], nPoseFont)
            end

            local szNKTitle = GetFormatText(g_tStrings.STR_SKILL_H_LEIGONG_REQUIRE, 106)
            local szText
            if hSkill.dwMountRequestDetail ~= 0 then
                szText = Table_GetSkillName(hSkill.dwMountRequestDetail, 1)
            else
                szText = g_tStrings.tMountRequestTable[hSkill.dwMountRequestType]
            end

            local nFont = 102
            if hSkill.CheckMountRequest(hPlayer.dwID) == SKILL_RESULT_CODE.SUCCESS then
                nFont = 106
            end

            local szCoolDown = FormatCooldown(dwID, nLevel, hSkillInfo, hOriSkillInfo, bShowProfit, hPlayer) .. GetFormatText("\n", 106)

            if szPose then
                szTip = szTip .. szPose .. GetFormatText("\t") .. szCoolDown .. szNKTitle .. GetFormatText(szText, nFont) .. GetFormatText("\n", 106)
            else
                szTip = szTip .. szNKTitle .. GetFormatText(szText .. "\t", nFont) ..  szCoolDown
            end

            bHaveNextLevel = true
        else
            szTip = szTip .. GetFormatText("\n", 106) .. FormatCastRadius(hSkill.nCastMode, hSkillInfo, hOriSkillInfo, bShowProfit) .. GetFormatText("\n", 106)

            local szCoolDown = FormatCooldown(dwID, nLevel, hSkillInfo, hOriSkillInfo, bShowProfit, hPlayer) .. GetFormatText("\t", 106)
            szTip = szTip .. szCoolDown

            if dwID == 605 then
                if hPlayer.bOnHorse then
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_IMMIDIATLY, 106)
                else
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_TIME .. 3 .. g_tStrings.STR_BUFF_H_TIME_S, 106)
                end
            else
                local nCastTime = hPlayer.GetSkillPrepare(dwID, nLevel)
                szTip = szTip .. FormatCastTime(hSkillInfo, hOriSkillInfo, bShowProfit, nCastTime) .. GetFormatText("\n", 106)
            end

            bHaveNextLevel = false
        end
        dwDescLevel = nLevel
    end

    local dwSkinGroup = Table_GetSkillSkinGroup(dwID)
    if g_bMoreSkillInfo and dwSkinGroup then
        local dwSkinID = hPlayer.GetActiveSkillSkinByGroupID(dwSkinGroup)
        if dwSkinID then
            local tSkillSkin = Table_GetSkillSkinInfo(dwSkinID)
            szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_SKILL_TIP_SKIN, tSkillSkin.szName) .. "\n", 106)
        end
    end

    local tDescSkillInfo = Table_GetSkill(dwID, dwDescLevel)
    if g_bMoreSkillInfo or bSimpleDescEmpty then
        if tDescSkillInfo.szSpecialDesc ~= "" then
            szTip = szTip .. GetFormatText(tDescSkillInfo.szSpecialDesc .. "\n", FONT_SKILL_SEP_DESC)
        end

        local szSkillDesc, szSkillDesc1 = GetSkillDesc(dwID, dwDescLevel, tRecipeKey, hSkillInfo, nil, hPlayer)
        szTip = szTip .. FormatSkillSpecialNoun(szSkillDesc .. "\n", FONT_SKILL_DESC)

        if szSkillDesc1 and szSkillDesc1 ~= "" then
            szTip = szTip .. FormatSkillSpecialNoun(szSkillDesc1, FONT_SKILL_DESC1)
        end

        local szRecipeDesc, szRecipeList = FormatRecipeList(tRecipeKey)
        szTip = szTip .. szRecipeDesc

        if tDescSkillInfo.szHelpDesc ~= "" then
            szTip = szTip .. GetFormatText(tDescSkillInfo.szHelpDesc .. "\n", FONT_SKILL_SEP_DESC)
        end
    else
        if tDescSkillInfo.szSimpleDesc ~= "" then
            szTip = szTip .. GetFormatText(tDescSkillInfo.szSimpleDesc .. "\n", FONT_SKILL_SEP_DESC)
        end

        szTip = szTip .. GetFormatText(g_tStrings.STR_WATCH_MORE_OPERATION .. "\n", FONT_SKILL_DESC1)
    end

    --以下为测试代码
    if IsCtrlKeyDown() then
        szTip = szTip .. GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n" .. "ID：      " .. dwID .. "\nLevel： " .. nLevel .. "\n", 102)
        local nIconID = Table_GetSkillIconID(dwID, nLevel)
        szTip = szTip .. GetFormatText("IconID：" .. tostring(nIconID) .. "\n", 102)
    end
    --以上为测试代码

    if bHaveNextLevel then
        szTip = szTip .. FormatNextLevelDesc(hSkill, bNextLevelDesc, bShowProfit, hPlayer)
    end
    if g_bMoreSkillInfo and not bSimpleDescEmpty then
        szTip = szTip .. GetFormatText(g_tStrings.STR_WATCH_LESS_OPERATION .. "\n", FONT_SKILL_DESC1)
    end
    --[[
    if bRecipeList then
        szTip = szTip .. szRecipeList
    end
    --]]
    return szTip
end

function FormatSkillTip(dwID, nLevel, bNextLevelDesc, bShortDesc, bRecipeList, bShowProfit, nTalentSkillLevel, hPlayer)
    hPlayer = hPlayer or GetClientPlayer()
    if not hPlayer then
        return ""
    end

    local tRecipeKey = hPlayer.GetSkillRecipeKey(dwID, nLevel)
    if tRecipeKey then
        return FormatSkillTipByRecipeKey(tRecipeKey, bNextLevelDesc, bShortDesc, bRecipeList, bShowProfit, nTalentSkillLevel, hPlayer)
    end
end

local function FormatKungFuTip(dwID, nLevel, tRect, bShortDesc, player)
    player = player or GetClientPlayer()

    local szTip = ""
    szTip = szTip .. FormatSkillTip(dwID, nLevel, tRect, bShortDesc, nil, nil, nil, player);

    local aSkill = player.GetSkillList(dwID)
    local tInfo = {}
    for dwSubID, dwSubLevel in pairs(aSkill) do
        local fSort = Table_GetSkillSortOrder(dwSubID, dwSubLevel);
        table.insert(tInfo, { dwID = dwSubID, dwLevel = dwSubLevel, fSort = fSort })
    end
    table.sort(tInfo, function(tA, tB)
        return tA.fSort < tB.fSort;
    end)

    FONT_SKILL_NAME = 37
    for _, tData in pairs(tInfo) do
        local dwSkillID, dwLevel = tData.dwID, tData.dwLevel
        if Table_IsSkillShow(dwSkillID, dwLevel) then
            szTip = szTip .. FormatSkillTip(dwSkillID, dwLevel, tRect, bShortDesc, nil, nil, nil, player);
        end
    end
    FONT_SKILL_NAME = 31

    return szTip;
end

function OutputSkillTip(dwID, nLevel, tRect, bNextLevelDesc, bShortDesc, bRecipeList, bShowProfit, nTalentSkillLevel, bLink, KPlayer, bVisibleWhenHideUI)
    local tSkillInfo = Table_GetSkill(dwID, nLevel)
    local hSkill = GetSkill(dwID, nLevel)
    if not (tSkillInfo and hSkill) then
        return
    end
    KPlayer = KPlayer or GetClientPlayer()

    local szTip = ""
    if hSkill.dwBelongKungfu == 0 and hSkill.nUIType == SkillNUIType.XinFa then
        szTip = FormatKungFuTip(dwID, nLevel, tRect, bNextLevelDesc, KPlayer)
    else
        szTip = FormatSkillTip(dwID, nLevel, bNextLevelDesc, bShortDesc, bRecipeList, bShowProfit, nTalentSkillLevel, KPlayer)
    end
    local szLink = "skill" .. dwID .. 'x' .. nLevel
    if tSkillInfo.bFormation ~= 0 then
        OutputTip(szTip, 2048, tRect, nil, bLink, szLink, nil, nil, nil, nil, nil, nil, nil, bVisibleWhenHideUI)
    else
        OutputTip(szTip, 400, tRect, nil, bLink, szLink, nil, nil, nil, nil, nil, nil, nil, bVisibleWhenHideUI)
    end
end

local function FormatValueText(nValue, nOriValue, nBaseFont, bShowProfit, bNegativeProfit, nDigits, bTimeText, bTimeGameFrame)
    if not nDigits then
        nDigits = 0
    end

    local nDiff = tonumber(FixFloat(nValue - nOriValue, nDigits))
    local nFont = nil
    if nDiff == 0 then
        nFont = nBaseFont
    elseif (nDiff > 0 and bNegativeProfit)
            or (nDiff < 0 and not bNegativeProfit) then
        nFont = 166
    else
        nFont = 165
    end

    if not bShowProfit or nDiff == 0 then
        local szValueText = FixFloat(nValue, nDigits)
        if bTimeText then
            szValueText = UIHelper.GetTimeSecondText(szValueText, bTimeGameFrame)
        end
        return GetFormatText(szValueText, nFont)
    end

    local szValueText = FixFloat(nOriValue, nDigits)
    if bTimeText then
        szValueText = UIHelper.GetTimeSecondText(szValueText, bTimeGameFrame)
    end

    local szDiffText = "("
    if nDiff < 0 then
        szDiffText = szDiffText .. "-"
    else
        szDiffText = szDiffText .. "+"
    end

    local szDiff = FixFloat(math.abs(nDiff), nDigits)
    if bTimeText then
        szDiff = UIHelper.GetTimeSecondText(szDiff, bTimeGameFrame)
    end
    szDiffText = szDiffText .. szDiff .. ")"

    return GetFormatText(szValueText, nBaseFont) .. GetFormatText(szDiffText, nFont)
end

function ConvertRadius(nRadius)
    return nRadius / GLOBAL.CELL_LENGTH * GLOBAL.LOGICAL_CELL_CM_LENGTH / 100
end

function FormatCastRadius(nCastMode, hSkillInfo, hOriSkillInfo, bShowProfit)
    if nCastMode ~= SKILL_CAST_MODE.TARGET_AREA
            and nCastMode ~= SKILL_CAST_MODE.POINT_AREA
            and nCastMode ~= SKILL_CAST_MODE.TARGET_SINGLE
            and nCastMode ~= SKILL_CAST_MODE.POINT
            and nCastMode ~= SKILL_CAST_MODE.TARGET_CHAIN
            and nCastMode ~= SKILL_CAST_MODE.TARGET_TEAM_AREA then
        return FormatHandle(GetFormatText(g_tStrings.STR_SKILL_H_CAST_DIS_NO, 106))
    end

    local szCastRadius = GetFormatText(g_tStrings.STR_SKILL_H_CAST_MAX_DIS1)
    if hSkillInfo.MinRadius ~= 0 or hOriSkillInfo.MinRadius ~= 0 then
        local nMin = ConvertRadius(hSkillInfo.MinRadius)
        local nOriMin = ConvertRadius(hOriSkillInfo.MinRadius)
        szCastRadius = szCastRadius .. FormatValueText(nMin, nOriMin, 106, bShowProfit, false, 1)
        szCastRadius = szCastRadius .. GetFormatText(" - ", 106)
    end

    local nMax = ConvertRadius(hSkillInfo.MaxRadius)
    local nOriMax = ConvertRadius(hOriSkillInfo.MaxRadius)
    szCastRadius = szCastRadius .. FormatValueText(nMax, nOriMax, 106, bShowProfit, false, 1)
    szCastRadius = szCastRadius .. GetFormatText(g_tStrings.STR_METER, 106)
    return FormatHandle(szCastRadius)
end

function FormatPureCastRadius(nCastMode, hSkillInfo, hOriSkillInfo, bShowProfit)
    if nCastMode ~= SKILL_CAST_MODE.TARGET_AREA
            and nCastMode ~= SKILL_CAST_MODE.POINT_AREA
            and nCastMode ~= SKILL_CAST_MODE.TARGET_SINGLE
            and nCastMode ~= SKILL_CAST_MODE.POINT
            and nCastMode ~= SKILL_CAST_MODE.TARGET_CHAIN
            and nCastMode ~= SKILL_CAST_MODE.TARGET_TEAM_AREA then
        return "无"
    end

    local szCastRadius = ""
    if hSkillInfo.MinRadius ~= 0 or hOriSkillInfo.MinRadius ~= 0 then
        local nMin = ConvertRadius(hSkillInfo.MinRadius)
        local nOriMin = ConvertRadius(hOriSkillInfo.MinRadius)
        szCastRadius = szCastRadius .. FormatValueText(nMin, nOriMin, 106, bShowProfit, false, 1)
        szCastRadius = szCastRadius .. GetFormatText(" - ", 106)
    end

    local nMax = ConvertRadius(hSkillInfo.MaxRadius)
    local nOriMax = ConvertRadius(hOriSkillInfo.MaxRadius)
    szCastRadius = szCastRadius .. FormatValueText(nMax, nOriMax, 106, bShowProfit, false, 1)
    szCastRadius = szCastRadius .. GetFormatText(g_tStrings.STR_METER, 106)
    return szCastRadius
end

function FormatCastCost(hSkillInfo, hOriSkillInfo, bShowProfit, nCostManaBasePercent)
    local szCastCost = nil

    if nCostManaBasePercent == 0 then
        if hSkillInfo.CostMana ~= 0 or hOriSkillInfo.CostMana ~= 0 then
            szCastCost = GetFormatText(g_tStrings.STR_SKILL_H_MANA_COST, 106)
            szCastCost = szCastCost .. FormatValueText(hSkillInfo.CostMana, hOriSkillInfo.CostMana, 106, bShowProfit, true)
        end
    elseif nCostManaBasePercent and (hSkillInfo.CostMana ~= 0 or hOriSkillInfo.CostMana ~= 0) then
        local nManaFont = 106
        local player = GetClientPlayer();
        local nDiff = tonumber(FixFloat(hSkillInfo.CostMana - hOriSkillInfo.CostMana, 0))
        if nDiff ~= 0 then
            nManaFont = 165
        end

        local nValue = hSkillInfo.CostMana
        szCastCost = FormatString(g_tStrings.STR_SKILL_PERCENT_MANA, 106, nManaFont, nValue)
    end

    if hSkillInfo.CostLife ~= 0 or hOriSkillInfo.CostLife ~= 0 then
        szCastCost = GetFormatText(g_tStrings.STR_SKILL_H_LIFE_COST, 106)
        szCastCost = szCastCost .. FormatValueText(hSkillInfo.CostLife, hOriSkillInfo.CostLife, 106, bShowProfit, true)
    end

    if not szCastCost then
        szCastCost = GetFormatText(g_tStrings.STR_SKILL_H_MANA_COST_NO, 106)
    end
    return FormatHandle(szCastCost)
end

function FormatPureCastCost(hSkillInfo, hOriSkillInfo, bShowProfit, nCostManaBasePercent)
    local szCastCost = nil

    if nCostManaBasePercent == 0 then
        if hSkillInfo.CostMana ~= 0 or hOriSkillInfo.CostMana ~= 0 then
            szCastCost = GetFormatText(g_tStrings.STR_SKILL_H_MANA_COST, 106)
            szCastCost = szCastCost .. FormatValueText(hSkillInfo.CostMana, hOriSkillInfo.CostMana, 106, bShowProfit, true)
        end
    elseif nCostManaBasePercent and (hSkillInfo.CostMana ~= 0 or hOriSkillInfo.CostMana ~= 0) then
        local nManaFont = 106
        local player = GetClientPlayer();
        local nDiff = tonumber(FixFloat(hSkillInfo.CostMana - hOriSkillInfo.CostMana, 0))
        if nDiff ~= 0 then
            nManaFont = 165
        end

        local nValue = hSkillInfo.CostMana
        szCastCost = FormatString(g_tStrings.STR_SKILL_PERCENT_MANA, 106, nManaFont, nValue)
    end

    if hSkillInfo.CostLife ~= 0 or hOriSkillInfo.CostLife ~= 0 then
        szCastCost = GetFormatText(g_tStrings.STR_SKILL_H_LIFE_COST, 106)
        szCastCost = szCastCost .. FormatValueText(hSkillInfo.CostLife, hOriSkillInfo.CostLife, 106, bShowProfit, true)
    end

    if not szCastCost then
        szCastCost = GetFormatText(g_tStrings.STR_SKILL_H_MANA_COST_NO, 106)
    end
    return szCastCost
end

function FormatCastTime(hSkillInfo, hOriSkillInfo, bShowProfit, nCastTime)
    if nCastTime == 0 and hOriSkillInfo.CastTime == 0 then
        return FormatHandle(GetFormatText(g_tStrings.STR_SKILL_H_CAST_IMMIDIATLY, 106))
    end

    local szCastTime = GetFormatText(g_tStrings.STR_SKILL_H_CAST_TIME, 106)
    szCastTime = szCastTime .. FormatValueText(nCastTime, hOriSkillInfo.CastTime, 106, bShowProfit, true, 1, true, true)
    return FormatHandle(szCastTime)
end

function FormatPureCastTime(hSkillInfo, hOriSkillInfo, bShowProfit, nCastTime)
    if nCastTime == 0 and hOriSkillInfo.CastTime == 0 then
        return g_tStrings.STR_SKILL_H_CAST_IMMIDIATLY
    end

    local szCastTime = GetFormatText(g_tStrings.STR_SKILL_H_CAST_TIME, 106)
    szCastTime = szCastTime .. FormatValueText(nCastTime, hOriSkillInfo.CastTime, 106, bShowProfit, true, 1, true, true)
    return szCastTime
end

function FormatCooldown(dwID, nLevel, hSkillInfo, hOriSkillInfo, bShowProfit, KPlayer)
    local nHasteRate = KPlayer.nCurrentHasteRate
    local nCooldown = 0
    local nMinCooldown = 0
    local nMaxCooldown = 0
    local nOriCooldown = 0
    local nCheckCoolDown = 0
    for i = 1, 3 do
        local szKey = "CoolDown" .. i
        local szCheckKey = "CheckCoolDown" .. i
        if hSkillInfo[szCheckKey] > nCheckCoolDown then
            nCheckCoolDown = hSkillInfo[szCheckKey]
        end

        if hSkillInfo[szKey] > nCooldown then
            nCooldown = hSkillInfo[szKey]
            nMinCooldown = hSkillInfo["MinCoolDown" .. i]
            nMaxCooldown = hSkillInfo["MaxCoolDown" .. i]
        end

        if hOriSkillInfo[szKey] > nOriCooldown then
            nOriCooldown = hOriSkillInfo[szKey]
        end
    end

    nMinCooldown = math.min(nMinCooldown, nCooldown)

    nHasteRate = nHasteRate or 0
    nCooldown = FormatHasteValue(nCooldown, nHasteRate);
    nCooldown = math.max(nMinCooldown, nCooldown)
    nCooldown = math.min(nMaxCooldown, nCooldown)

    if (nCooldown == 0 and nOriCooldown == 0) then
            -- or (nCooldown == 24 and nOriCooldown == 24) then -- 去掉端游把1.5秒cd视为公共cd特殊处理的做法
        if nCheckCoolDown > 40 then
            local szCooldown = FormatValueText(nCheckCoolDown, nCheckCoolDown, 106, bShowProfit, true, 1, true, true)
            local maxCount = KPlayer.GetCDMaxCount(dwID)
            if maxCount > 1 then
                szCooldown = GetFormatText(g_tStrings.STR_SKILL_NEED_CN_UNIT, 106) .. szCooldown
            else
                szCooldown = GetFormatText(g_tStrings.STR_SKILL_NEED_REST_UNIT, 106) .. szCooldown
            end

            local cd_count, cd_id = KPlayer.GetCDMaxCount(dwID)
            local od_count, od_id = KPlayer.GetCDMaxOverDraftCount(dwID)
            local nLeftTime, bCool, nLeft, nTotal, nCDCount, bPublicCD
            if cd_count > 1 then
                -- 充能技能CD刷新
                bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(dwID, dwLevel, cd_id, KPlayer)
                local cd_total = KPlayer.GetCDInterval(cd_id)
                local cd_time, cd_left = KPlayer.GetCDLeft(cd_id)
                if cd_left == 0 then
                    nLeftTime = cd_time
                end
            elseif od_count > 1 then
                -- 透支技能CD刷新
                bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(dwID, dwLevel, od_id, KPlayer)
                local od_count, od_left = KPlayer.GetOverDraftCoolDown(od_id)
                if od_left == od_count then
                    -- 透支用完了显示CD
                    bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(dwID, dwLevel, nil, KPlayer)
                end
            else
                -- 普通技能CD刷新
                bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(dwID, dwLevel, nil, KPlayer)
            end
            if not bPublicCD then
                nLeftTime = nLeftTime or nLeft
            end
            local szCurrentCooldown = ""
            --if nLeftTime > 0 then
            --    local szLeftTime = UIHelper.GetTimeSecondText(nLeftTime, true, false, true)
            --    szCurrentCooldown = GetFormatText(FormatString(g_tStrings.STR_SKILL_NEED_REST_LEFT, szLeftTime), 102)
            --end ---不展示调息剩余时间
            return szCooldown .. szCurrentCooldown
        else
            return GetFormatText(g_tStrings.STR_SKILL_NOT_NEED_REST, 106)
        end
    end
    local szCooldown = FormatValueText(nCooldown, nOriCooldown, 106, bShowProfit, true, 1, true, true)
    local maxCount = KPlayer.GetCDMaxCount(dwID)
    if maxCount > 1 then
        szCooldown = maxCount..GetFormatText(g_tStrings.STR_SKILL_NEED_CN_UNIT, 106) .. szCooldown
    else
        szCooldown = GetFormatText(g_tStrings.STR_SKILL_NEED_REST_UNIT, 106) .. szCooldown
    end

    local szCurrentCooldown = ""
    local bCooldown, nLeft, nTotal = Skill_GetCDProgress(dwID, nLevel, Skill_GetCongNengCDID(dwID, KPlayer), KPlayer)
    --if bCooldown and nLeft > 0 then
    --    local szLeftTime = UIHelper.GetTimeSecondText(nLeft, true, false, true)
    --    szCurrentCooldown = GetFormatText(FormatString(g_tStrings.STR_SKILL_NEED_REST_LEFT, szLeftTime), 102)
    --end  ---不展示调息剩余时间
    return szCooldown .. szCurrentCooldown

end

function FormatNextLevelDesc(hSkill, bNextLevelDesc, bShowProfit, hPlayer)
    local dwID = hSkill.dwSkillID
    local nLevel = hSkill.dwLevel
    local szNextLevelDesc = ""
    if nLevel == hSkill.dwMaxLevel then
        szNextLevelDesc = GetFormatText(g_tStrings.STR_SKILL_H_TOP_LEAVEL, 106)
    else
        nLevel = nLevel + 1
        local hPlayer = hPlayer or GetClientPlayer()
        local tRecipeKey = hPlayer.GetSkillRecipeKey(dwID, nLevel)
        local hSkillInfo = GetSkillInfoEx(tRecipeKey, hPlayer.dwID)

        local tOriRecipeKey = clone(tRecipeKey)
        for nIndex = 1, 12, 1 do
            tOriRecipeKey["recipe" .. nIndex] = 0
        end
        local hOriSkillInfo = GetSkillInfoEx(tOriRecipeKey, hPlayer.dwID)

        local szLevelExp = FormatString(g_tStrings.STR_SKILL_H_NEXT_LEVEL_EXP, hPlayer.GetSkillExp(dwID), hSkill.dwLevelUpExp)
        szNextLevelDesc = GetFormatText(szLevelExp, 106)
        if bNextLevelDesc then
            szNextLevelDesc = szNextLevelDesc .. GetFormatText("\t", 106)
            szNextLevelDesc = szNextLevelDesc .. FormatCastCost(hSkillInfo, hOriSkillInfo, bShowProfit, hSkill.nCostManaBasePercent)
            local szSkillDesc = GetSkillDesc(dwID, nLevel, tRecipeKey, hSkillInfo, nil, hPlayer)
            szNextLevelDesc = szNextLevelDesc .. GetFormatText(szSkillDesc .. "\n", 100)
        end
    end
    return szNextLevelDesc
end

function FormatRecipeList(tRecipeKey)
    local szDescList = ""
    local szRecipeList = ""
    for i = 1, 12 do
        local dwRID, dwRLevel = SkillRecipeKeyToIDAndLevel(tRecipeKey["recipe" .. i])
        if dwRID ~= 0 then
            local tSkillRecipe = Table_GetSkillRecipe(dwRID, dwRLevel)
            local szName = ""
            if tSkillRecipe then
                local tRecipeType = g_tTable.SkillRecipeType:Search(tSkillRecipe.dwTypeID)
                if tRecipeType and tRecipeType.nAddToTip == 1 then
                    szDescList = szDescList .. GetFormatText(tSkillRecipe.szDesc .. "\n", 165)
                end

                local szScript = "this.OnItemLButtonDown = function() "
                szScript = szScript .. "local x, y = this:GetAbsPos();"
                szScript = szScript .. "local w, h = this:GetSize();"
                szScript = szScript .. "OutputSkillRecipeTip(" .. dwRID .. ", " .. dwRLevel .. ", {x, y, w, h}, true);"
                szScript = szScript .. "end"

                local _, _, nSkillRecipeType, _ = GetSkillRecipeBaseInfo(dwRID, dwRLevel)
                if nSkillRecipeType ~= SKILL_RECIPE_TYPE.EQUIPMENT then
                    szRecipeList = szRecipeList .. GetFormatText(tSkillRecipe.szName .. "\n", 100, nil, nil, nil, 1, szScript)
                end
            end
        end
    end

    if szRecipeList ~= "" then
        szRecipeList = GetFormatText(g_tStrings.STR_SKILL_HAVE_RECIPE .. "\n", 106) .. szRecipeList
    end

    return szDescList, szRecipeList
end

function FormatHasteValue(nOrgValue, nHasteRate)
    nOrgValue = math.floor((nOrgValue * 1024) / (nHasteRate + 1024))
    return nOrgValue
end

function OutputSkillLink(tRecipeKey, tRect)
    local szTip = FormatSkillTipByRecipeKey(tRecipeKey, false, false, true, false)
    local tSkillInfo = Table_GetSkill(tRecipeKey.skill_id, tRecipeKey.skill_level)

    local szLink = "skill" .. tRecipeKey.skill_id .. "x" .. tRecipeKey.skill_level
    if tSkillInfo.bFormation ~= 0 then
        OutputTip(szTip, 10000, tRect, nil, true, szLink)
    else
        OutputTip(szTip, 400, tRect, nil, true, szLink)
    end
end

function GetSubSkillDesc(dwID, dwLevel, bShort, player)
    local player = player or GetClientPlayer()
    local skillkey = player.GetSkillRecipeKey(dwID, dwLevel)
    local skillInfo = GetSkillInfoEx(skillkey, player.dwID)
    return GetSkillDesc(dwID, dwLevel, skillkey, skillInfo, bShort, player)
end

function GetRadioSubSkillDesc(szKey, dwLevel, bShort, player)
    local player = player or GetClientPlayer()
    local dwCondition, dwSkillID1, dwLevel1, dwSkillID2, dwLevel2 = string.match(szKey, "(%d+)?(%d+)_(%d+);(%d+)_(%d+)")
    dwCondition = tonumber(dwCondition)
    local dwSkillLevel = player.GetSkillLevel(dwCondition)
    skillid = tonumber(dwSkillID2)
    level = tonumber(dwLevel2)
    if dwSkillLevel > 0 then
        skillid = tonumber(dwSkillID1)
        level = tonumber(dwLevel1)
    end
    if level == 0 then
        level = dwLevel
    end
    return GetSubSkillDesc(skillid, level, bShort, player)
end

DESC_CONTEXT_SOURCE =
{
    SKILL = "skill",
    BUFF = "buff",
    NOUN = "noun",
}

local DESC_CONTEXT_MODE =
{
    PLAIN = "plain",
    GLOSSARY = "glossary",
}

local function ResolveDescLevel(dwLevel, dwOwnerLevel)
    dwLevel = tonumber(dwLevel) or 0
    if dwLevel == 0 then
        return tonumber(dwOwnerLevel) or 0
    end
    return dwLevel
end

local function IsBuffPlainDescContext()
    return false
end

local function CloneDescContext(tDescCtx)
    if not tDescCtx then
        return nil
    end
    return clone(tDescCtx)
end

local function EnsureDescContext(tDescCtx, sourceType, displayMode, player, ownerID, ownerLevel, skillkey, skillInfo)
    local tCtx = CloneDescContext(tDescCtx) or {}
    tCtx.sourceType = tCtx.sourceType or sourceType or DESC_CONTEXT_SOURCE.SKILL
    tCtx.displayMode = tCtx.displayMode or displayMode or DESC_CONTEXT_MODE.GLOSSARY
    tCtx.player = tCtx.player or player or GetClientPlayer()
    if ownerID ~= nil and tCtx.ownerID == nil then
        tCtx.ownerID = ownerID
    end
    if ownerLevel ~= nil and tCtx.ownerLevel == nil then
        tCtx.ownerLevel = ownerLevel
    end
    if skillkey ~= nil and tCtx.skillkey == nil then
        tCtx.skillkey = skillkey
    end
    if skillInfo ~= nil and tCtx.skillInfo == nil then
        tCtx.skillInfo = skillInfo
    end
    return tCtx
end

function CreateBuffDescContext(dwBuffID, dwBuffLevel, player, tDescCtx)
    local displayMode = DESC_CONTEXT_MODE.PLAIN
    if tDescCtx and tDescCtx.displayMode then
        displayMode = tDescCtx.displayMode
    end
    return EnsureDescContext(
            tDescCtx,
            DESC_CONTEXT_SOURCE.BUFF,
            displayMode,
            player,
            dwBuffID,
            dwBuffLevel
    )
end

function CreateSkillDescContext(dwSkillID, dwSkillLevel, skillkey, skillInfo, player, tDescCtx)
    return EnsureDescContext(
            tDescCtx,
            DESC_CONTEXT_SOURCE.SKILL,
            DESC_CONTEXT_MODE.GLOSSARY,
            player,
            dwSkillID,
            dwSkillLevel,
            skillkey,
            skillInfo
    )
end

function ParseSkillDescCommonTokens(szDesc, dwSkillID, dwSkillLevel, skillkey, skillInfo, bShort, player, hSkill, tDescCtx)
    player = player or GetClientPlayer()
    local tParseInfo = {
        dwSkillID = dwSkillID,
        dwSkillLevel = dwSkillLevel,
        skillkey = skillkey,
        skillInfo = skillInfo,
        bShort = bShort,
        player = player,
    }
    local szOriginalDesc = szDesc

    local szSourceName = Table_GetSkillName(dwSkillID, dwSkillLevel)
    if tDescCtx and tDescCtx.sourceType == DESC_CONTEXT_SOURCE.BUFF then
        szSourceName = Table_GetBuffName(dwSkillID, dwSkillLevel)
    end
    local function fnCreateNounLink(szName)
        if szName == "" or not szName then
            LOG.ERROR("fnCreateNounLink falied!! %d %d", dwSkillID, dwSkillLevel)
        end
        local tbLinkData = { type = "ShowNounInfo", nNounID = szName, szSourceName = szSourceName
        , szOriginalDesc = szOriginalDesc, dwSkillID = dwSkillID, dwSkillLevel = dwSkillLevel,  szNoun = szName }
        local szLink = JsonEncode(tbLinkData)
        szLink = UrlEncode(szLink)
        return string.format("<href=%s><color=#FFE26E>[%s]</color></href>", szLink, szName)
    end

    szDesc = szDesc or ""
    szDesc = string.gsub(szDesc, "<SUB_NOUN (%d+) (%d+) (.-)>", function(dwID, dwLevel, szNoun)
        dwID = tonumber(dwID)
        if not dwID then
            return szNoun or ""
        end
        dwLevel = ResolveDescLevel(dwLevel, tDescCtx and tDescCtx.ownerLevel)
        local szName = szNoun or Table_GetSkillName(dwID, dwLevel) or ""
        SkillData.AddSkillToNounTable(szName, dwID, dwLevel, skillkey, skillInfo, bShort, player)
        return fnCreateNounLink(szName)
    end)
    szDesc = string.gsub(szDesc, "<BUFF_NOUN (%d+) (%d+) (.-)>", function(dwBuffID, dwBuffLevel, szNoun)
        dwBuffID = tonumber(dwBuffID)
        if not dwBuffID then
            return szNoun or ""
        end
        dwBuffLevel = ResolveDescLevel(dwBuffLevel, tDescCtx and tDescCtx.ownerLevel)
        local szName = szNoun or Table_GetBuffName(dwBuffID, dwBuffLevel) or ""
        SkillData.AddBuffToNounTable(szName, dwBuffID, dwBuffLevel, skillkey, skillInfo, bShort, player)
        return fnCreateNounLink(szName)
    end)
    --szDesc = string.gsub(szDesc, "<NOUN_DESC (%d+)>", function(nNounID) return ParseNounDescText(nNounID, tParseInfo) end)
    szDesc = string.gsub(szDesc, "<SKILL_%[(.-)%] (.-)>", function(szkey1, szkey2) return GetSkillkeyDescEx(dwSkillID, dwSkillLevel, szkey1, szkey2, player) end)
    szDesc = string.gsub(szDesc, "<SKILL (.-)>", function(szkey) return GetSkillkeyDesc(skillInfo, szkey) end)
    szDesc = string.gsub(szDesc, "<SUB (%d+) (%d+)>", function(dwID, dwLevel)
        dwLevel = ResolveDescLevel(dwLevel, dwSkillLevel)
        if IsBuffPlainDescContext(tDescCtx) then
            return ""
        end
        return GetSubSkillDesc(dwID, dwLevel, bShort, player, tDescCtx)
    end)
    szDesc = string.gsub(szDesc, "<SUB_RADIO %[(.-)%]>", function(szkey) return GetRadioSubSkillDesc(szkey, dwSkillLevel, bShort, player, tDescCtx) end)
    szDesc = string.gsub(szDesc, "<BUFF (%d+) (%d+) (%w+)>", function(dwID, nLevel, szKey)
        nLevel = ResolveDescLevel(nLevel, dwSkillLevel)
        if IsBuffPlainDescContext(tDescCtx) and szKey == "desc" then
            return ""
        end
        local tBuffCtx = CreateBuffDescContext(dwID, nLevel, player, {displayMode = tDescCtx and tDescCtx.displayMode})
        return GetBuffDesc(dwID, nLevel, szKey, tBuffCtx)
    end)
    szDesc = string.gsub(szDesc, "<BINDBUFF (%d+) (%d+) (%d+) (%w+)>", function(dwType, dwID, nLevel, szKey)
        nLevel = ResolveDescLevel(nLevel, dwSkillLevel)
        if IsBuffPlainDescContext(tDescCtx) and szKey == "desc" then
            return ""
        end
        return GetBindBuffDesc(dwType, dwID, nLevel, szKey, skillkey)
    end)
    szDesc = string.gsub(szDesc, "<SKILLEx ({.-}) (.-)>", function(szKey1, szKey2) return GetSkillTipEx(hSkill, szKey1, szKey2) end)
    szDesc = string.gsub(szDesc, "<PARRY (%d+)>", function(coff) return KeepTwoByteFloat(GetPlayerParryValue() * coff) end)
    szDesc = string.gsub(szDesc, "<BASE_ATTRI (.-)>", function(key) return player["nCurrent" .. key] end)
    szDesc = string.gsub(szDesc, "<MONSTER (%w-) -(%d-)>", function(szkey, dwSubSkillID)
        local nValue = GDAPI_GetMonsterSkillInfo(tonumber(dwSubSkillID) or dwSkillID, dwSkillLevel, szkey)
        local szValue = ParseTextHelper.FormatNumberToTenK(nValue, 2, true)
        return "<Mons" .. szValue .. ">"
    end)
    szDesc = string.gsub(szDesc, "<SUR (%-?%d+%.*%d*)>", function(fParam) return GetSurplus(fParam) end)
    szDesc = string.gsub(szDesc, "<NounID (%d+)>",
            function(szNounID)
                local nNounID = tonumber(szNounID)
                local tNounInfo = Table_GetSkillNouns(nNounID)
                if not tNounInfo then return "" end

                SkillData.AddToNounTable(szNounID, dwSkillID, dwSkillLevel, skillkey, skillInfo, bShort, player)
                return fnCreateNounLink(tNounInfo.szName)
            end)
    return szDesc
end

function GetSkillDesc(dwSkillID, dwSkillLevel, skillkey, skillInfo, bShort, player, tDescCtx)
    player = player or GetClientPlayer()
    local tSkillCtx = CreateSkillDescContext(dwSkillID, dwSkillLevel, skillkey, skillInfo, player, tDescCtx)
    local szDesc = ""
    local szDesc1 = ""
    local szAddDesc = ""
    local hSkill = GetSkill(dwSkillID, dwSkillLevel)
    if bShort then
        szDesc = Table_GetSkillSimpleDesc(dwSkillID, dwSkillLevel)
        if szDesc == "" then
            szDesc = Table_GetSkillDesc(dwSkillID, dwSkillLevel)
        end
    else
        szDesc = Table_GetSkillDesc(dwSkillID, dwSkillLevel)
    end

    szDesc = ParseSkillDescCommonTokens(szDesc, dwSkillID, dwSkillLevel, skillkey, skillInfo, bShort, player, hSkill, tSkillCtx)

    szDesc = string.gsub(szDesc, "<KUNGFU (%d+) (%d+) (.-)>", function(szKungFuID, szLevel, szShow)
        local Kungfu = player.GetActualKungfuMount()
        if Kungfu and Kungfu.dwSkillID == tonumber(szKungFuID) and Kungfu.dwLevel >= tonumber(szLevel) then
            szDesc1 = szDesc1 .. szShow .. "\n"
        end
        return ""
    end)

    szDesc = string.gsub(szDesc, "<TALENT (%d+) (%d+) (.-)>", function(szSkillID, szLevel, szShow)
        local nSkillID = tonumber(szSkillID)
        local nReLevel = tonumber(szLevel) or 1
        local nLevel = player.GetSkillLevel(nSkillID)
        if nLevel == nReLevel then
            local szDesc2 = Table_GetSkillDesc(nSkillID, nLevel)
            szDesc1 = szDesc1 .. ParseSkillDesc(szDesc2, nSkillID, nLevel, skillkey, skillInfo, bShort, player) .. "\n"
        end
        return ""
    end)

    szDesc = string.gsub(szDesc, "<EnchantID (%d+) (.-)>", function(id, desc)
        local res
        id = tonumber(id)
        local function IsHaveEnchantEffect(item)
            if (item.dwTemporaryEnchantID == id and player.IsTempEnchantValid(id))
                    or item.dwPermanentEnchantID == id then
                res = true
                return true
            end
        end
        Task_EquipedItem(IsHaveEnchantEffect)

        if res then
            szDesc1 = szDesc1 .. desc .. "\n"
        end
        return ""
    end)

    szDesc = string.gsub(szDesc, "<TALENT_CORE (%d+) (%d+)>", function(szSkillID, szLevel)
        local nSkillID = tonumber(szSkillID)
        local nLevel = tonumber(szLevel) or 1
        local szName = Table_GetSkillName(nSkillID, nLevel)
        local nLearnLevel = player.GetSkillLevel(nSkillID) or 0
        if nLearnLevel ~= nLevel then
            szAddDesc = szAddDesc .. UIHelper.UTF8ToGBK(g_tStrings.STR_TALENT_CORE) .. szName .. "\n"
        end
        return ""
    end)

    return szDesc, szDesc1, szAddDesc
end

function ParseSkillDesc(tInfo, dwSkillID, dwSkillLevel, skillkey, skillInfo, bShort, player, tSkillCtx)
    player = player or GetClientPlayer()
    local szDesc, szDesc1, szSourceName, szOriginalDesc = "", "", "", ""
    local hSkill = nil
    if dwSkillID and dwSkillLevel and dwSkillID ~= 0 and dwSkillLevel ~= 0 then
        hSkill = GetSkill(dwSkillID, dwSkillLevel)
    end

    if tInfo == nil then
        return
    end

    if IsTable(tInfo) then
        szDesc = tInfo.szDesc
        szSourceName = tInfo.szName
    else
        szSourceName = Table_GetSkillName(dwSkillID, dwSkillLevel)
        szDesc = tInfo
    end

    szOriginalDesc = szDesc
    szDesc = szDesc or ""

    szDesc = ParseSkillDescCommonTokens(szDesc, dwSkillID, dwSkillLevel, skillkey, skillInfo, bShort, player, hSkill, tSkillCtx)
    szDesc = string.gsub(szDesc, "<TALENT_CORE (%d+) (%d+)>", function() return "" end)

    szDesc = string.gsub(
            szDesc,
            "<KUNGFU (%d+) (%d+) (.-)>",
            function(szKungFuID, szLevel, szShow)
                local Kungfu = player.GetKungfuMount()
                if Kungfu and Kungfu.dwSkillID ==  tonumber(szKungFuID) and Kungfu.dwLevel >= tonumber(szLevel) then
                    szDesc1 = szDesc1..szShow .. "\n"
                end
                return ""
            end
    )
    szDesc = string.gsub(
            szDesc,
            "<TALENT (%d+) (%d+) (.-)>",
            function(szSkillID, szLevel, szShow)
                local nSkillID = tonumber(szSkillID)
                local nReLevel = tonumber(szLevel) or 1
                local nLevel = player.GetSkillLevel(nSkillID)
                if nLevel == nReLevel then
                    local szDesc2 = Table_GetSkillDesc(nSkillID, nLevel)
                    szDesc1 = szDesc1 .. ParseSkillDesc(szDesc2, nSkillID, nLevel, skillkey, skillInfo, bShort, player) .. "\n"
                end
                return ""
            end
    )
    szDesc = string.gsub(
            szDesc,
            "<EnchantID (%d+) (.-)>",
            function(id, desc)
                local res
                id = tonumber(id)
                local function IsHaveEnchantEffect(item)
                    if (item.dwTemporaryEnchantID == id and player.IsTempEnchantValid(id))
                            or item.dwPermanentEnchantID == id then
                        res = true
                        return true
                    end
                end
                Task_EquipedItem(IsHaveEnchantEffect)

                if res then
                    szDesc1 = szDesc1 .. desc .. "\n"
                end
                return ""
            end
    )

    return szDesc, szDesc1
end

function OutputSkillRecipeTip(dwID, dwLevel, Rect, bLink, tMoreInfo)
    local tSkillRecipe = Table_GetSkillRecipe(dwID, dwLevel)
    local szName = ""
    local szDesc = ""
    if tSkillRecipe then
        szName = tSkillRecipe.szName
        szDesc = tSkillRecipe.szDesc
    end
    local szTip = GetFormatText(szName .. "\n", 31)
    local dwSkillID, dwSkillLevel, _, dwSkillRecipeType = GetSkillRecipeBaseInfo(dwID, dwLevel)
    local szSkillName = ""
    if dwSkillRecipeType and dwSkillRecipeType ~= 0 then
        szSkillName = Table_GetSkillName(dwSkillRecipeType)
    elseif dwSkillID then
        if dwSkillLevel and dwSkillLevel ~= 0 then
            -- 0 表示不限制秘籍在技能上的使用等级
            szSkillName = Table_GetSkillName(dwSkillID, dwSkillLevel)
        else
            szSkillName = Table_GetSkillName(dwSkillID)
        end
    end
    szTip = szTip .. GetFormatText(szSkillName .. "\n", 162)
    szTip = szTip .. GetFormatText(szDesc .. "\n", 100)
    if tMoreInfo then
        if tMoreInfo.bHave then
            if tMoreInfo.bActive then
                szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_RECIPE_ACTIVE, 161)
            else
                szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_SKILL_RECIPE_NOT_ACTIVE_TIP, MAX_SKILL_REICPE_COUNT), 185)

            end
        else
            szTip = szTip .. GetFormatText(g_tStrings.TIP_UNREAD, 196)
            szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_SKILL_RECIPE_TRAIN_COST_TIP, tSkillRecipe.nTrainCost), 366)
        end
    end

    --以下为测试代码
    if IsCtrlKeyDown() then
        szTip = szTip .. GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n" .. "ID：      " .. dwID .. "\nLevel： " .. dwLevel .. "\n", 102)
    end
    --以上为测试代码
    OutputTip(szTip, 400, Rect, nil, bLink, "skillrecipe" .. dwID .. "x" .. dwLevel)
end

local tSkinQuilty = {
    [1] = { Font = 100, nFame = 11 },
    [2] = { Font = 285, nFame = 11 },
    [3] = { Font = 286, nFame = 11 },
}

function GetSkillSkinQuiltyInfo(nQuilty)
    return tSkinQuilty[nQuilty].nFont, tSkinQuilty[nQuilty].nFame
end

function OutputSkillSkinTip(dwID, Rect, bLink, tMoreInfo)
    local tSkillSkin = Table_GetSkillSkinInfo(dwID)

    local nFont = GetSkillSkinQuiltyInfo(tSkillSkin.nQuilty)
    local szTip = GetFormatText(tSkillSkin.szName .. "\n", nFont)
    szTip = szTip .. GetFormatText(tSkillSkin.szDesc .. "\n", 100)
    szTip = szTip .. GetFormatText(tSkillSkin.szSource .. "\n", 100)
    if tMoreInfo then
        if tMoreInfo.bHave then
            if tMoreInfo.bActive then
                szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_SKIN_ACTIVE, 161)
            else
                szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_SKIN_NOT_ACTIVE_TIP, 185)
            end
        else
            szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_SKIN_NOT_HAVE, 196)
        end
    end

    --以下为测试代码
    if IsCtrlKeyDown() then
        szTip = szTip .. GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n" .. "ID：      " .. dwID .. "\n", 102)
    end
    --以上为测试代码
    OutputTip(szTip, 400, Rect, nil, bLink, "skillskin" .. dwID)
end

function GetSkillByRecipe(dwRecipeID, nRecipeLevel)
    local hPlayer = GetClientPlayer()
    local tSchoolList = hPlayer.GetSchoolList()
    if tSchoolList then
        for _, dwSchoolID in pairs(tSchoolList) do
            local tKungfuList = hPlayer.GetKungfuList(dwSchoolID)
            if tKungfuList then
                for dwKungfuID, _ in pairs(tKungfuList) do
                    local tSkillList = hPlayer.GetSkillList(dwKungfuID)
                    if tSkillList then
                        for dwSkillID, nSkillLevel in pairs(tSkillList) do
                            local tRecipeList = hPlayer.GetSkillRecipeList(dwSkillID, nSkillLevel)
                            if tRecipeList then
                                for _, tRecipe in ipairs(tRecipeList) do
                                    if tRecipe and tRecipe.recipe_id and tRecipe.recipe_level
                                            and tRecipe.recipe_id == dwRecipeID and tRecipe.recipe_level == nRecipeLevel then
                                        return dwSkillID, nSkillLevel
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function GetSkillOTActionState(hPlayer)
    if not hPlayer then
        return
    end
    local nType, dwID, dwLevel, fP = hPlayer.GetSkillOTActionState()
    local bPrePare = nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
    return bPrePare, dwID, dwLevel, fP, nType
end

function SetAddonAreaCastMode(nSkillID, nMode)
    if type(nSkillID) == "table" then
        l_tAddonArenaCastMode = nSkillID
    else
        l_tAddonArenaCastMode[nSkillID] = nMode
    end
end

local nCloseUmbrellaDelay, bCloseUmbrellaFlag
function OnAutoCastPengLaiSKill()
    local nOpenSkillID = 20219    --自动开伞技能ID
    local nCloseSkillID = 19974    --自动收伞技能ID
    local nMinOpenHeight = 10       --自动开伞的最小高度，单位是尺
    local nMaxCloseHeight = 4        --自动收伞的最大高度，单位是尺
    local nMinCastSpeed = -40      --自动触发开伞的最小下落速度，为负值
    local nCastSkillCDTime = 16       --自动触发技能的CD帧数
    local nCloseUmbrellaDelayTime = 4        --收伞延迟帧数
    local pPlayer = GetClientPlayer()
    bCloseUmbrellaFlag = false

    if l_nAutoCastPengLaiSkillDelay > 0 then
        l_nAutoCastPengLaiSkillDelay = l_nAutoCastPengLaiSkillDelay - 1
        return
    end

    if pPlayer and
            pPlayer.dwForceID == FORCE_TYPE.PENG_LAI and
            pPlayer.bBirdMove and
            pPlayer.nMoveState == MOVE_STATE.ON_BIRD_FLOAT and
            pPlayer.bOnParachuteFlag and
            not pPlayer.IsHaveBuff(14029, 1) --在物化天行释放时禁用
    then
        local nAltitude, nType = pPlayer.GetAltitude()
        if nAltitude <= nMaxCloseHeight * 8 * 64 then
            bCloseUmbrellaFlag = true
            if nCloseUmbrellaDelay == 0 then
                OnUseSkill(nCloseSkillID, (nCloseSkillID * (nCloseSkillID % 10 + 1)))
                l_nAutoCastPengLaiSkillDelay = nCastSkillCDTime
            end
        end
    end

    if bCloseUmbrellaFlag and nCloseUmbrellaDelay > 0 then
        nCloseUmbrellaDelay = nCloseUmbrellaDelay - 1
    else
        nCloseUmbrellaDelay = nCloseUmbrellaDelayTime
    end

    --[[ if pPlayer and
        pPlayer.dwForceID == FORCE_TYPE.PENG_LAI and
        pPlayer.nMoveState == MOVE_STATE.ON_JUMP and
        not pPlayer.bSprintFlag and
        not pPlayer.bBirdMove and
        pPlayer.nVelocityZ < nMinCastSpeed
    then
        local nAltitude, nType = pPlayer.GetAltitude()
        if nAltitude > nMinOpenHeight * 8 * 64 then
            local pSkill = GetSkill(nOpenSkillID, 1)
            if pSkill.UITestCast(pPlayer.dwID, IsSkillCastMyself(pSkill)) == SKILL_RESULT_CODE.SUCCESS then
                OnUseSkill(nOpenSkillID, (nOpenSkillID * (nOpenSkillID % 10 + 1)))
                l_nAutoCastPengLaiSkillDelay = nCastSkillCDTime
            end
        end
    end ]]
end

function GetMultiStageSkillCanCastID(dwSkillID,player)
	if not dwSkillID then
		return
	end

	player = player or g_pClientPlayer
	if not player then
		return dwSkillID
	end

	local tChangeList = GetSkillChangeTableList()
	local tSkillList = tChangeList[dwSkillID]
	if not tSkillList then
		return dwSkillID
	end

	if player.CanUIShowSkill(dwSkillID) then
		_SaveSkillChangeList[dwSkillID] = dwSkillID
		return dwSkillID
	end

	for _,nID in ipairs(tSkillList) do
		if player.CanUIShowSkill(nID) then
			_SaveSkillChangeList[dwSkillID] = nID
			return nID
		end
	end

	dwSkillID = _SaveSkillChangeList[dwSkillID] or dwSkillID
	return dwSkillID
end

function GetDxBasicTips(dwID, nLevel, tSkillInfo, tRecipeKey, bShowProfit, nTalentSkillLevel, hPlayer)
    local dwDescLevel = 9999
    local hSkill = GetSkill(dwID, nLevel)
    local FONT_SKILL_LEVEL = 10
    local szTip = ""
    local bHaveNextLevel = false
    local g_bMoreSkillInfo = true

    local hSkillInfo = GetSkillInfoEx(tRecipeKey, hPlayer.dwID)

    local tOriRecipeKey = clone(tRecipeKey)
    for nIndex = 1, 12, 1 do
        tOriRecipeKey["recipe" .. nIndex] = 0
    end
    local hOriSkillInfo = GetSkillInfoEx(tOriRecipeKey, hPlayer.dwID)

    if hSkill.dwBelongKungfu == 0 then
        local szSchool = UIHelper.GBKToUTF8(Table_GetSkillSchoolName(hSkill.dwBelongSchool))
        szTip = szTip .. GetFormatText("\n" .. szSchool .. g_tStrings.STR_SKILL_ZS .. "\n", 106)
    else
        if hSkill.bIsPassiveSkill then
            szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_SKILL_PASSIVE_SKILL, 106)
        elseif tSkillInfo.bFormation ~= 0 then
            szTip = szTip .. GetFormatText("\n" .. g_tStrings.FORMATION_GAMBIT, 106)
        elseif g_bMoreSkillInfo or bSimpleDescEmpty then
            if tSkillInfo.bShowLevel then
                local szSkillLevel = FormatString(g_tStrings.STR_SKILL_H_THE_WHAT_LEVEL, UIHelper.NumberToChinese(nLevel))
                if nTalentSkillLevel then
                    szSkillLevel = FormatString(g_tStrings.STR_SKILL_H_THE_WHAT_LEVEL, nTalentSkillLevel .. "/" .. hSkill.dwMaxLevel)
                end
                szTip = szTip .. GetFormatText(szSkillLevel, FONT_SKILL_LEVEL)
            end

            szTip = szTip .. GetFormatText("\n", 106) .. FormatCastRadius(hSkill.nCastMode, hSkillInfo, hOriSkillInfo, bShowProfit) .. "\t"
            szTip = szTip .. ParseTextHelper.ParseNormalText(FormatCastCost(hSkillInfo, hOriSkillInfo, bShowProfit, hSkill.nCostManaBasePercent)) .. GetFormatText("\n", 106)

            szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_WEAPEN_REQUIRE, 106)
            local nWeaponFont = 102
            if hSkill.CheckWeaponRequest(hPlayer.dwID) == SKILL_RESULT_CODE.SUCCESS then
                nWeaponFont = 106
            end
            szTip = szTip .. GetFormatText(g_tStrings.tWeaponLimitTable[hSkill.dwWeaponRequest], nWeaponFont)

            szTip = szTip .. "\t"
            if dwID == 605 then
                if hPlayer.bOnHorse then
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_IMMIDIATLY, 106)
                else
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_TIME .. 3 .. g_tStrings.STR_BUFF_H_TIME_S, 106)
                end
            else
                local nCastTime = hPlayer.GetSkillPrepare(dwID, nLevel)
                szTip = szTip .. FormatCastTime(hSkillInfo, hOriSkillInfo, bShowProfit, nCastTime) .. GetFormatText("\n", 106)
            end

            --local szPose
            --if hSkill.nNeedPoseState > 0 then
            --    local nPoseFont = 102
            --    if hSkill.nNeedPoseState == hPlayer.nPoseState then
            --        nPoseFont = 106
            --    end
            --
            --    szPose = GetFormatText(g_tStrings.STR_SKILL_H_POSE_REQUIRE, 106)
            --    szPose = szPose .. GetFormatText(g_tStrings.CANG_YUN_POSE[hSkill.nNeedPoseState], nPoseFont)
            --end

            local szNKTitle = GetFormatText(g_tStrings.STR_SKILL_H_LEIGONG_REQUIRE, 106)
            local szText
            if hSkill.dwMountRequestDetail ~= 0 then
                szText = UIHelper.GBKToUTF8(Table_GetSkillName(hSkill.dwMountRequestDetail, 1))
            else
                szText = g_tStrings.tMountRequestTable[hSkill.dwMountRequestType]
            end

            --local nFont = 102
            --if hSkill.CheckMountRequest(hPlayer.dwID) == SKILL_RESULT_CODE.SUCCESS then
            --    nFont = 106
            --end

            --local szCoolDown = FormatCooldown(dwID, nLevel, hSkillInfo, hOriSkillInfo, bShowProfit, hPlayer) .. GetFormatText("\n", 106)

            --if szPose then
            --    szTip = szTip .. szPose .. GetFormatText("\t") .. szCoolDown .. szNKTitle .. GetFormatText(szText, nFont) .. GetFormatText("\n", 106)
            --else
            --    szTip = szTip .. szNKTitle .. GetFormatText(szText .. "\t", nFont) .. szCoolDown
            --end
            --szTip = szTip .. szNKTitle .. GetFormatText(szText .. "\t", nFont) .. "\n"

            bHaveNextLevel = true
        else
            szTip = szTip .. GetFormatText("\n", 106) .. FormatCastRadius(hSkill.nCastMode, hSkillInfo, hOriSkillInfo, bShowProfit) .. GetFormatText("\n", 106)

            local szCoolDown = FormatCooldown(dwID, nLevel, hSkillInfo, hOriSkillInfo, bShowProfit, hPlayer) .. GetFormatText("\t", 106)
            szTip = szTip .. szCoolDown

            if dwID == 605 then
                if hPlayer.bOnHorse then
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_IMMIDIATLY, 106)
                else
                    szTip = szTip .. GetFormatText(g_tStrings.STR_SKILL_H_CAST_TIME .. 3 .. g_tStrings.STR_BUFF_H_TIME_S, 106)
                end
            else
                local nCastTime = hPlayer.GetSkillPrepare(dwID, nLevel)
                szTip = szTip .. FormatCastTime(hSkillInfo, hOriSkillInfo, bShowProfit, nCastTime) .. GetFormatText("\n", 106)
            end

            bHaveNextLevel = false
        end
        dwDescLevel = nLevel
    end

    local dwSkinGroup = Table_GetSkillSkinGroup(dwID)
    if g_bMoreSkillInfo and dwSkinGroup then
        local dwSkinID = hPlayer.GetActiveSkillSkinByGroupID(dwSkinGroup)
        if dwSkinID then
            local tSkillSkin = Table_GetSkillSkinInfo(dwSkinID)
            szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_SKILL_TIP_SKIN, UIHelper.GBKToUTF8(tSkillSkin.szName)) .. "\n", 106)
        end
    end

    return szTip
end

--BreatheCall("AUTO_CAST_UMBRELLA_SKILL", OnAutoCastPengLaiSKill)