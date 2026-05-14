-- ---------------------------------------------------------------------------------
-- Author: LiuYuMin
-- Name: SpecialDXSkillData
-- Date: 2025-07-23 16:57:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

SpecialDXSkillData = SpecialDXSkillData or { className = "SpecialDXSkillData" }
local self = SpecialDXSkillData

local nSpecialSlotBase = 1000
SpecialDXSkillData.nLatestSpecialSlot = nSpecialSlotBase -- 用于给特殊技能动态分配槽位

---------------------------------------五毒---------------------------------------------------

SpecialDXSkillData.tCallUpPetSkill = {
    [1] = 2225,
    [2] = 2221,
    [3] = 2224,
    [4] = 2223,
    [5] = 2222,
    [6] = 2965,
    [7] = 32824,
}

SpecialDXSkillData.tPetNPCID = {
    [1] = 9997,
    [2] = 9956,
    [3] = 9996,
    [4] = 9998,
    [5] = 9999,
    [6] = 12944,
    [7] = 111963,
}

SpecialDXSkillData.tPetList = {
    {
        nSkillID = SpecialDXSkillData.tCallUpPetSkill[1],
        nShortcutIndex = 120
    },
    {
        nSkillID = SpecialDXSkillData.tCallUpPetSkill[2],
        nShortcutIndex = 121
    },
    {
        nSkillID = SpecialDXSkillData.tCallUpPetSkill[3],
        nShortcutIndex = 122
    },
    {
        nSkillID = SpecialDXSkillData.tCallUpPetSkill[4],
        nShortcutIndex = 123
    },
    {
        nSkillID = SpecialDXSkillData.tCallUpPetSkill[5],
        nShortcutIndex = 124
    },
    {
        nSkillID = SpecialDXSkillData.tCallUpPetSkill[6],
        nShortcutIndex = 125
    },
    {
        nSkillID = SpecialDXSkillData.tCallUpPetSkill[7],
        nShortcutIndex = 126
    }
}

SpecialDXSkillData.tPetSkillList = {
    [1] = { 127, 128, 129 },
    [2] = { 130, 131, 132 },
    [3] = { 133, 134, 135 },
}

SpecialDXSkillData.tbCurChildSkillList = {
    [1] = {},
    [2] = {},
    [3] = {}
}

SpecialDXSkillData.tPetSkillChange = {}
SpecialDXSkillData.tCurrentPetSkill = {}

function SpecialDXSkillData.IsHavePetSkill()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    for _, v in ipairs(self.tCallUpPetSkill) do
        if (hPlayer.GetSkillLevel(v) >= 1) then
            return true
        end
    end
    return false
end

function SpecialDXSkillData.IsPetSkill(dwSkillID)
    for _, v in ipairs(self.tCallUpPetSkill) do
        if dwSkillID == v then
            return true
        end
    end
    return false
end

function SpecialDXSkillData.GetSpecialSkillSlotID()
    local nLast = self.nLatestSpecialSlot
    self.nLatestSpecialSlot = self.nLatestSpecialSlot + 1
    return nLast
end

function SpecialDXSkillData.SetChildSkillInfo(nIndex, nSkillID, nLevel)
    if not nIndex or not nSkillID or not nLevel then
        return
    end

    if nIndex < 1 or nIndex > 3 then
        return
    end

    SpecialDXSkillData.tbCurChildSkillList[nIndex] = {
        nSkillID = nSkillID,
        nLevel = nLevel
    }
end

function SpecialDXSkillData.GetChildSkillInfo(nIndex)
    if not nIndex then
        return
    end

    return SpecialDXSkillData.tbCurChildSkillList[nIndex] or {}
end

function SpecialDXSkillData.InitPetSkillChangeList(dwNpcTemplateID)
    local SortByQiXueListLength = function(tLeft, tRight)
        return #(tLeft.tQixueSkillList) > #(tRight.tQixueSkillList)
    end

    self.tPetSkillChange = Table_GetPetSkillChange(dwNpcTemplateID)
    table.sort(self.tPetSkillChange, SortByQiXueListLength)
end

function SpecialDXSkillData.GetPetSkillChangeList()
    return SpecialDXSkillData.tPetSkillChange
end

function SpecialDXSkillData.CheckPetSkillChange(tChangeList)
    local bRet = true
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    for _, tQixueSkillID in pairs(tChangeList.tQixueSkillList) do
        local nLevel = hPlayer.GetSkillLevel(tQixueSkillID[1])
        if nLevel == 0 then
            bRet = false
        end
    end
    return bRet
end

function SpecialDXSkillData.IsKungFuMatched(nTargetKungFu)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    local nCurKungFuID = hPlayer.GetActualKungfuMountID()
    if not nCurKungFuID then
        return false
    end

    if IsTable(nTargetKungFu) then
        local tKungFus = nTargetKungFu
        for _, nTargetID in ipairs(tKungFus) do
            if nTargetID == nCurKungFuID then
                return true
            end
        end
    elseif IsNumber(nTargetKungFu) then
        return nCurKungFuID == nTargetKungFu
    end

    return false
end

---------------------------------------唐门---------------------------------------------------

SpecialDXSkillData.tPuppetShortcutIndexList = {
    [16174] = { 120, 121, 122 },
    [16175] = { 120, 121, 122, 123, 124 },
    [16176] = { 120, 121, 122, 123, 124 },
    [16177] = { 120 },
}

SpecialDXSkillData.tFlyStartShortcutIndexList = {
    125, 126
}

---------------------------------------天策---------------------------------------------------

function SpecialDXSkillData.GetTianCeMainSkill()
    local nSkillID = 605
    local nShortcutIndex = 120
    return nSkillID, nShortcutIndex
end

function SpecialDXSkillData.OnReload()

end

Event.Reg(self, EventType.OnRoleLogin, function()
    self.nLatestSpecialSlot = nSpecialSlotBase -- 用于给特殊技能动态分配槽位
end)

---------------------------------------衍天---------------------------------------------------

function SpecialDXSkillData.GetLampLeftFrame(nSkillID)
    local tBuffID = {
        [24858] = 17743,
        [24859] = 17744,
        [24860] = 17745
    }
    local nBuffID = tBuffID[nSkillID]
    if nBuffID and g_pClientPlayer then
        local tBuffInfo = {}
        Buffer_GetByID(g_pClientPlayer, nBuffID, 1, tBuffInfo)
        if tBuffInfo.dwID then
            return Buffer_GetLeftFrame(tBuffInfo)
        end
    end
end

---------------------------------------长歌---------------------------------------------------
SpecialDXSkillData.tShadowShortcutIndexList = {
    120, 121, 122, 123, 124, 125
}

local tBuffToTimeLimit = {
    [10134] = 35000, --白
    [10135] = 35000, --粉
    [10136] = 35000, --红
    [10137] = 35000, --绿
    [10138] = 35000, --蓝
    [10139] = 35000, --黄
    [11887] = 40000, --飞星
    [11886] = 40000, --飞星
}

local m_nBuffToHighlight = 16765

local m_tSkillIDToHighlightBuffLevel = {
    [15039] = 1,
    [15040] = 2,
    [15041] = 3,
    [15042] = 4,
    [15043] = 5,
    [15044] = 6,
    [17587] = 7,
    [17588] = 8,
}

local tbChangGeSkillIconList = {
    [10134] = { "UIAtlas2_SkillDX_SpecialSkill_ChangGe_7", "UIAtlas2_SkillDX_SpecialSkill_ChangGe_[ChangGe.UITex_58]圈3" }, --白
    [10135] = { "UIAtlas2_SkillDX_SpecialSkill_ChangGe_4", "UIAtlas2_SkillDX_SpecialSkill_ChangGe_[ChangGe.UITex_58]圈3" }, --粉
    [10136] = { "UIAtlas2_SkillDX_SpecialSkill_ChangGe_5", "UIAtlas2_SkillDX_SpecialSkill_ChangGe_[ChangGe.UITex_58]圈3" }, --红
    [10137] = { "UIAtlas2_SkillDX_SpecialSkill_ChangGe_2", "UIAtlas2_SkillDX_SpecialSkill_ChangGe_[ChangGe.UITex_58]圈3" }, --绿
    [10138] = { "UIAtlas2_SkillDX_SpecialSkill_ChangGe_3", "UIAtlas2_SkillDX_SpecialSkill_ChangGe_[ChangGe.UITex_58]圈3" }, --蓝
    [10139] = { "UIAtlas2_SkillDX_SpecialSkill_ChangGe_1", "UIAtlas2_SkillDX_SpecialSkill_ChangGe_[ChangGe.UITex_58]圈3" }, --黄
}

local m_tBuffToDisableBuff = {
    [11886] = 11898, --唐门黄
    [11887] = 11899, --唐门蓝
}

local m_tBuffToShowNumber = {
    [11886] = 29356, --唐门黄
    [11887] = 29357 --唐门蓝
}

SpecialDXSkillData.tTimeLimit = {}

function SpecialDXSkillData.SetSkillBuffTimeEnd(nSkillID, nBuff)
    if not nSkillID or not nBuff then
        return
    end
    local nTotalTime = nBuff and tBuffToTimeLimit[nBuff]
    if not SpecialDXSkillData.tTimeLimit[nSkillID] and nTotalTime then
        SpecialDXSkillData.tTimeLimit[nSkillID] = {
            nEndTime = GetTickCount() + nTotalTime,
            nTotalTime = nTotalTime,
            nBuff = nBuff
        }
    end
end

function SpecialDXSkillData.GetSkillBuffTimeEnd(nSkillID)
    if not nSkillID then
        return
    end

    local tbTime = SpecialDXSkillData.tTimeLimit[nSkillID] or {}
    return tbTime
end

function SpecialDXSkillData.GetSkillDisableBuff(nSkillID)
    if not nSkillID then
        return
    end

    local tbTime = SpecialDXSkillData.tTimeLimit[nSkillID] or {}
    return tbTime.nBuff and m_tBuffToDisableBuff[tbTime.nBuff]
end

function SpecialDXSkillData.GetSkillCountBuff(nSkillID)
    if not nSkillID then
        return
    end

    local tbTime = SpecialDXSkillData.tTimeLimit[nSkillID] or {}
    return tbTime.nBuff and m_tBuffToShowNumber[tbTime.nBuff]
end

function SpecialDXSkillData.ClearSkillBuffTimeEnd(nSkillID)
    SpecialDXSkillData.tTimeLimit[nSkillID] = nil
end

function SpecialDXSkillData.IsHighLightSkill(nSkillID)
    if not nSkillID then
        return false
    end

    local player = GetClientPlayer()
    if not player then
        return false
    end

    local tbHighlightBuff = player.GetBuff(m_nBuffToHighlight, 0)
    local bHighLight = tbHighlightBuff and m_tSkillIDToHighlightBuffLevel[nSkillID] == tbHighlightBuff.nLevel
    return bHighLight
end

function SpecialDXSkillData.GetSkillIconByBuff(nBuff)
    if not nBuff or not tbChangGeSkillIconList[nBuff] then
        return nil
    end

    local tbIconList = tbChangGeSkillIconList[nBuff]
    if not tbIconList then
        return nil
    end

    return tbIconList[1], tbIconList[2]
end

function SpecialDXSkillData.GetBaseSlot()
    return nSpecialSlotBase
end

---------------------------------------长歌平沙-----------------------------------------------
local m_tReplaceData
local function GetProxySkillList()
    local aSkill = GetClientPlayer().GetProxySkillList()
    local tSkillMap = {}
    for _, tSkill in ipairs(aSkill) do
        tSkillMap[tSkill.dwSkillID] = tSkill
    end
    return tSkillMap
end

local function GetReplaceSkill(tReplaceData, dwSkillID, player)
    if not tReplaceData then
        return
    end

    for _, tData in ipairs(tReplaceData) do
        if tData.skill_id == dwSkillID then
            local dwCLevel = 0
            local dwBLevel = 0
            if tData.condition_skill_id ~= 0 then
                dwCLevel = player.GetSkillLevel(tData.condition_skill_id)
            end
            if tData.condition_buff_id ~= 0 then
                local tBuff = player.GetBuff(tData.condition_buff_id, 0)
                if tBuff then
                    dwBLevel = tBuff.nLevel
                end
            end
            if dwCLevel ~= 0 or dwBLevel ~= 0 then
                local dwLevel = player.GetSkillLevel(tData.replace_skill_id)
                if dwLevel ~= 0 then
                    return tData.replace_skill_id, dwLevel
                end
            end
        end
    end
end
local function GetReplaceData()
    local tab = g_tTable.SkillQiXueReplace
    local count = tab:GetRowCount()
    local tRes = {}
    local t
    for i = 2, count, 1 do
        t = tab:GetRow(i)
        table.insert(tRes, t)
    end
    return tRes
end

local function DrawSkillBar()
    local me = GetClientPlayer()
    local aSkillMap = GetProxySkillList()
    local aSkill = me.GetProxySkillListInfo()
    local player = GetControlPlayer()

    local dwSkillID, dwSkillID1, dwLevel, dwLevel1, tData
    self.tbSkilllist = {}
    for k, tbSkillInfo in ipairs(aSkill) do
        dwSkillID = tbSkillInfo.dwSkillID
        dwLevel = nil

        local tSkill = aSkillMap[dwSkillID]
        dwSkillID1, dwLevel1 = GetReplaceSkill(m_tReplaceData, dwSkillID, player)
        if dwSkillID1 then
            dwSkillID, dwLevel = dwSkillID1, dwLevel1
        elseif tSkill then
            dwLevel = tSkill.dwLevel
        end

        if dwSkillID and dwLevel then
            table.insert(self.tbSkilllist, k, { id = dwSkillID, level = dwLevel })
        end
    end

    local tbSKillInfo = {
        tbSkilllist = self.tbSkilllist,
        CanCastSkill = false,
        canuserchange = false
    }

    QTEMgr.OnSwitchDynamicSkillStateBySkills(tbSKillInfo)

end

Event.Reg(self, "ON_NEW_PROXY_SKILL_LIST_NOTIFY", function()
    local KPlayer = GetControlPlayer()
    if not KPlayer then
        return
    end

    SpecialDXSkillData.bOpenControlActionBar = true

    EnableControlOther(true)
    SpecialDXSkillData.OpenControlActionBar()
end)

Event.Reg(self, "ON_CLEAR_PROXY_SKILL_LIST_NOTIFY", function()
    SpecialDXSkillData.bOpenControlActionBar = false

    EnableControlOther(false)
    SpecialDXSkillData.CloseControlActionBar()
end)

Event.Reg(self, "ON_SKILL_REPLACE", function()
    local bOpen = SpecialDXSkillData.bOpenControlActionBar
    if bOpen then
        SpecialDXSkillData.OpenControlActionBar()
    end
end)

Event.Reg(self, "ON_ACTIONBAR_SKILL_REPLACE", function()
    local bOpen = SpecialDXSkillData.bOpenControlActionBar
    if bOpen then
        SpecialDXSkillData.OpenControlActionBar()
    end
end)

function SpecialDXSkillData.OpenControlActionBar()
    local KPlayer = GetControlPlayer()
    if not KPlayer then
        return
    end

    if not m_tReplaceData then
        m_tReplaceData = GetReplaceData()
    end

    DrawSkillBar(KPlayer)

    if self.nControlTimer then
        Timer.DelTimer(SpecialDXSkillData, self.nControlTimer)
        self.nControlTimer = nil
    end
    self.nControlTimer = Timer.AddFrameCycle(SpecialDXSkillData, 1, function()
        local KPlayer = GetControlPlayer()
        if not KPlayer then
            return
        end
        if not self.tbSkilllist then
            return
        end
        local bChange = false
        for i, tbSKillInfo in ipairs(self.tbSkilllist) do
            local dwSkillID = tbSKillInfo.id
            local dwNewSkillID = GetMultiStageSkillCanCastID(dwSkillID, KPlayer)
            if dwNewSkillID ~= dwSkillID then
                local dwNewSkillLevel = KPlayer.GetSkillLevel(dwNewSkillID)
                self.tbSkilllist[i] = { id = dwNewSkillID, level = dwNewSkillLevel }
                bChange = true
            end
        end

        if bChange then
            local tbSKillInfo = {
                tbSkilllist = self.tbSkilllist,
                CanCastSkill = false,
                canuserchange = false
            }

            QTEMgr.OnSwitchDynamicSkillStateBySkills(tbSKillInfo)
        end
    end)
end

function SpecialDXSkillData.CloseControlActionBar()
    QTEMgr.OnSwitchDynamicSkillStateBySkills()

    if self.nControlTimer then
        Timer.DelTimer(SpecialDXSkillData, self.nControlTimer)
        self.nControlTimer = nil
    end
end

---------------------------------------药宗---------------------------------------------------
local tTemplateID2Plant = {
    [10626] = {
        [106623] = { dwSkillID = 27674, dwBuffID = 30571 }, --草
        [133952] = { dwSkillID = 27669, dwBuffID = 29398 }, --莲花
    },
    [10627] = {
        [106623] = { dwSkillID = 27674, dwBuffID = 30571 }, --草
        [106107] = { dwSkillID = 27652, dwBuffID = 30572 }, --苍棘
    },
}

local tChangeTemplateID = {
    [133952] = { dwChangeSkillID = 28739, dwNewTemplateID = 106110 }, --莲花
}

Event.Reg(self, "ON_UPDATE_TALENT", function()
    if arg0 == UI_GetClientPlayerID() and SpecialDXSkillData.IsKungFuMatched({ 10626, 10627 }) then
        SpecialDXSkillData.UpdatePlantList()
        SpecialDXSkillData.InitPlantList()
    end
end)

function SpecialDXSkillData.InitYaoZong()
    SpecialDXSkillData.dwKungfuID = 0
    SpecialDXSkillData.dwTargetNpcID = 0
    SpecialDXSkillData.tPlantList = {}
    SpecialDXSkillData.tCallPlant = {}
    SpecialDXSkillData.tNowPlant = {}
    SpecialDXSkillData.tCurPlantList = {}

    local player = GetClientPlayer()
    if not player then
        return
    end
    SpecialDXSkillData.dwKungfuID = player.GetActualKungfuMountID()
    SpecialDXSkillData.UpdatePlantList()

    SpecialDXSkillData.InitPlantList()
end

function SpecialDXSkillData.UnInitYaoZong()
    SpecialDXSkillData.dwKungfuID = nil
    SpecialDXSkillData.dwTargetNpcID = nil
    SpecialDXSkillData.tPlantList = nil
    SpecialDXSkillData.tCallPlant = nil
    SpecialDXSkillData.tNowPlant = nil
end

function SpecialDXSkillData.UpdatePlantList()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tPlantList = clone(tTemplateID2Plant[SpecialDXSkillData.dwKungfuID]) or {}
    for dwTemplateID, tPlant in pairs(tPlantList) do
        if tChangeTemplateID[dwTemplateID] then
            local tChange = tChangeTemplateID[dwTemplateID]
            if player.GetSkillLevel(tChange.dwChangeSkillID) > 0 then
                tPlantList[tChange.dwNewTemplateID] = tPlantList[dwTemplateID]
                tPlantList[dwTemplateID] = nil
            end
        end
    end

    SpecialDXSkillData.tPlantList = tPlantList
    SpecialDXSkillData.UpdateNowPlant()
end

function SpecialDXSkillData.UpdateNowPlant()
    local tNowPlant = {}
    for _, dwNpcID in ipairs(SpecialDXSkillData.tCallPlant) do
        local tBeast = GetNpc(dwNpcID)
        if tBeast and SpecialDXSkillData.tPlantList[tBeast.dwTemplateID] then
            local tPlant = {}
            tPlant.dwID = tBeast.dwID
            tPlant.nCurrentLife = tBeast.nCurrentLife
            tPlant.nMaxLife = tBeast.nMaxLife
            tPlant.dwTemplateID = tBeast.dwTemplateID

            tNowPlant[tBeast.dwTemplateID] = tPlant
        end
    end
    SpecialDXSkillData.tNowPlant = tNowPlant
end

function SpecialDXSkillData.UpdatePlantLM()
    for _, tPlant in pairs(SpecialDXSkillData.tNowPlant) do
        local tBeast = GetNpc(tPlant.dwID)
        if tBeast and SpecialDXSkillData.tPlantList[tBeast.dwTemplateID] then
            tPlant.nCurrentLife = tBeast.nCurrentLife
            tPlant.nMaxLife = tBeast.nMaxLife
        end
    end
end

function SpecialDXSkillData.InitPlantList()
    SpecialDXSkillData.tCurPlantList = {}
    local nIndex = 1
    for dwTemplateID, tPlant in pairs(SpecialDXSkillData.tPlantList) do
        local nIconID = Table_GetSkillIconID(tPlant.dwSkillID, 1)
        SpecialDXSkillData.tCurPlantList[nIndex] = {
            dwTemplateID = dwTemplateID,
            dwBuffID = tPlant.dwBuffID,
            dwSkillID = tPlant.dwSkillID
        }
        nIndex = nIndex + 1
    end
end

