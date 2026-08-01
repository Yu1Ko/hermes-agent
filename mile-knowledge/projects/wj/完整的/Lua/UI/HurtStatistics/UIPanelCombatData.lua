-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMBallView
-- Date: 2022-11-07 20:11:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelCombatData = class("UIPanelCombatData")

local nStatType2Background = {
    [STAT_TYPE.BE_THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_img_cl01_772.png",
    [STAT_TYPE.BE_DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_img_cs01_772.png",
    [STAT_TYPE.DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_img_sh01_772.png",
    [STAT_TYPE.THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_img_zl01_772.png",
}

local nStatType2TitleBackground = {
    [STAT_TYPE.BE_THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_img_cl03_740.png",
    [STAT_TYPE.BE_DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_img_cs03_740.png",
    [STAT_TYPE.DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_img_sh03_740.png",
    [STAT_TYPE.THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_img_zl03_740.png",
}

local nStatType2CellBackground = {
    [STAT_TYPE.BE_THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_img_cl02_580.png",
    [STAT_TYPE.BE_DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_img_cs02_580.png",
    [STAT_TYPE.DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_img_sh02_580.png",
    [STAT_TYPE.THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_img_zl02_580.png",
}

function UIPanelCombatData:OnEnter(szName, dwID, nStatType, tHistoryData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.szName = szName
        self.dwID = dwID
        self.nStatType = nStatType
        self.tHistoryData = tHistoryData

        UIHelper.ToggleGroupAddToggle(self.TopToggleGroup, self.TogBeTherapy)
        UIHelper.ToggleGroupAddToggle(self.TopToggleGroup, self.TogBeDamage)
        UIHelper.ToggleGroupAddToggle(self.TopToggleGroup, self.TogTherapy)
        UIHelper.ToggleGroupAddToggle(self.TopToggleGroup, self.TogDamage)

        self.dict = {
            [STAT_TYPE.DAMAGE] = self.TogDamage,
            [STAT_TYPE.THERAPY] = self.TogTherapy,
            [STAT_TYPE.BE_DAMAGE] = self.TogBeDamage,
            [STAT_TYPE.BE_THERAPY] = self.TogBeTherapy,
        }

        UIHelper.SetToggleGroupSelectedToggle(self.TopToggleGroup, self.dict[nStatType])
        self:UpdateDamageInfo(STAT_TYPE.DAMAGE)
    end
    --self:UpdateInfo()
end

local STAT_TYPE2DESC = {
    [STAT_TYPE.DAMAGE] = "伤害",
    [STAT_TYPE.THERAPY] = "治疗",
    [STAT_TYPE.BE_DAMAGE] = "承伤",
    [STAT_TYPE.BE_THERAPY] = "承疗",
}

function UIPanelCombatData:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCombatData:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogDamage, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateDamageInfo(STAT_TYPE.DAMAGE)
        end
    end)

    UIHelper.BindUIEvent(self.TogTherapy, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateDamageInfo(STAT_TYPE.THERAPY)
        end
    end)

    UIHelper.BindUIEvent(self.TogBeDamage, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateDamageInfo(STAT_TYPE.BE_DAMAGE)
        end
    end)

    UIHelper.BindUIEvent(self.TogBeTherapy, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateDamageInfo(STAT_TYPE.BE_THERAPY)
        end
    end)
end

function UIPanelCombatData:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelCombatData:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function GetSkillName(dwSkillID, nEffType, dwSkillLevel)
    local tSkillTab = TabHelper.GetUISkillMap(dwSkillID)
    local szSkillName = (tSkillTab and tSkillTab.szName) or ""
    local dwSkillLevel = dwSkillLevel or 1

    if szSkillName == "" then
        if nEffType == SKILL_EFFECT_TYPE.SKILL then
            szSkillName = Table_GetSkillName(dwSkillID, dwSkillLevel)
            szSkillName = szSkillName ~= "" and UIHelper.GBKToUTF8(szSkillName) or ""
        else
            szSkillName = Table_GetBuffName(dwSkillID, dwSkillLevel)
            szSkillName = szSkillName ~= "" and UIHelper.GBKToUTF8(szSkillName) or ""
        end
    end

    return szSkillName
end

function UIPanelCombatData:UpdateDamageInfo(nStatType)
    local bIsBeType = nStatType == STAT_TYPE.BE_DAMAGE or nStatType == STAT_TYPE.BE_THERAPY
    UIHelper.SetSpriteFrame(self.ImgLeftBg, nStatType2Background[nStatType])
    UIHelper.SetSpriteFrame(self.ImgTitleBg, nStatType2TitleBackground[nStatType])
    UIHelper.SetString(self.LabelTarget, bIsBeType and "技能" or "目标")
    UIHelper.SetString(self.LabelMaxHarm, "最大" .. STAT_TYPE2DESC[nStatType])
    UIHelper.SetString(self.LabelMinHarm, "最小" .. STAT_TYPE2DESC[nStatType])
    UIHelper.SetString(self.LabelAvgHarm, "平均" .. STAT_TYPE2DESC[nStatType])
    UIHelper.RemoveAllChildren(self.ScrollViewSkill)
    UIHelper.RemoveAllChildren(self.ScrollViewData)

    local sortFunc = function(a, b)
        return a.nTotalDamage > b.nTotalDamage
    end

    if self.dwID and self.szName and self.tHistoryData then
        local nGlobalCount, nGlobalDamage = 0, 0
        local tFirstToggle = nil
        local tCasterData = FightSkillLog.GetDataByDwIDFromHistory(self.tHistoryData, self.dwID, nStatType)

        if tCasterData then
            local newList = {}
            for _, data in pairs(tCasterData.tList) do
                table.insert(newList, data)
            end
            table.sort(newList, sortFunc)

            for _, tInfo in ipairs(newList) do
                local nTotalCount = tInfo.nHit + tInfo.nDoge + tInfo.nCritical
                nGlobalCount = nGlobalCount + nTotalCount
                nGlobalDamage = nGlobalDamage + tInfo.nTotalDamage
            end

            ---@param tInfo BasicDamage
            for _, tInfo in ipairs(newList) do
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCombatDataLeftListCell, self.ScrollViewSkill)
                local nTotalCount = tInfo.nHit + tInfo.nDoge + tInfo.nCritical
                local szCellName = bIsBeType and FightSkillLog.GetCharacterInfoFromHistory(self.tHistoryData, tInfo.dwTargetID).szName 
                        or GetSkillName(tInfo.dwSkillID, tInfo.nEffectType, tInfo.dwSkillLevel)

                self:SetLeftCellInfo(script, szCellName, STAT_TYPE2DESC[nStatType], nTotalCount, tInfo.nTotalDamage, nGlobalDamage, nStatType)

                tFirstToggle = tFirstToggle or script.TogLeftList
                UIHelper.BindUIEvent(script.TogLeftList, EventType.OnSelectChanged, function(_, bSelected)
                    if bSelected then
                        if bIsBeType then
                            self:UpdateSkillData_Be(tInfo)
                        else
                            self:UpdateSkillData(tInfo)
                        end
                    end
                end)
            end
        end

        --默认选中第一个Toggle
        UIHelper.SetSelected(tFirstToggle, true)

        UIHelper.SetString(self.LabelName, UIHelper.LimitUtf8Len(self.szName, 8))
        UIHelper.SetString(self.LabelHarm, "总" .. STAT_TYPE2DESC[nStatType])
        UIHelper.SetString(self.LabelNum01, UIHelper.NumberToTenThousand(nGlobalDamage, 1))
        UIHelper.SetString(self.LabelNum02, nGlobalCount .. "次")

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkill)
    end
end

function UIPanelCombatData:SetLeftCellInfo(script, szName, szType, nTotalCount, nTotalDamage, nGlobalDamage, nStatType)
    local szLimitedName = UIHelper.LimitUtf8Len(szName, 8)
    UIHelper.SetString(script.LabelName, szLimitedName)
    UIHelper.SetString(script.LabelName1, szLimitedName)

    UIHelper.SetString(script.LabelTotal, szType)
    UIHelper.SetString(script.LabelTotal1, szType)

    UIHelper.SetString(script.LabelFrequency, nTotalCount)
    UIHelper.SetString(script.LabelFrequency1, nTotalCount)

    local nPercentage = nGlobalDamage > 0 and nTotalDamage / nGlobalDamage * 100 or 0
    nTotalDamage = UIHelper.NumberToTenThousand(nTotalDamage, 1)

    local szDamage = string.format("%s(%.1f%%)", nTotalDamage, nPercentage)
    UIHelper.SetString(script.LabelNum, szDamage)
    UIHelper.SetString(script.LabelNum1, szDamage)

    UIHelper.SetSpriteFrame(script.ImgNormalBg, nStatType2CellBackground[nStatType])
end

function UIPanelCombatData:UpdateSkillData(tBasic)
    UIHelper.RemoveAllChildren(self.ScrollViewData)

    local tTargets = tBasic.tTargetsData
    ---@param tTargetData DamageTargetData
    for dwTargetID, tTargetData in pairs(tTargets) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCombatDataRightListCell, self.ScrollViewData)

        local tInfo = FightSkillLog.GetCharacterInfoFromHistory(self.tHistoryData, dwTargetID)
        local nAverageDamage = (tTargetData.nTotalDamage / (tTargetData.nHit + tTargetData.nCritical))
        --local szLimitedName = UIHelper.LimitUtf8Len(tInfo.szName, 7)
        UIHelper.SetString(script.LabelTarget, tInfo.szName)
        UIHelper.SetString(script.LabelMaxHarm, UIHelper.NumberToTenThousand(tTargetData.nBiggestDamage, 1))
        UIHelper.SetString(script.LabelMinHarm, UIHelper.NumberToTenThousand(tTargetData.nSmallestDamage, 1))
        UIHelper.SetString(script.LabelAvgHarm, UIHelper.NumberToTenThousand(nAverageDamage, 1))
        UIHelper.SetString(script.LabelHit, tTargetData.nHit)
        UIHelper.SetString(script.LabelKnowing, tTargetData.nCritical)
        UIHelper.SetString(script.LabelDeviation, tTargetData.nDoge)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end

---@param tTarget BeDamageTargetData
function UIPanelCombatData:UpdateSkillData_Be(tTarget)
    UIHelper.RemoveAllChildren(self.ScrollViewData)

    local tSkills = tTarget.tSkills
    ---@param tSkillData BeDamageSkillData
    for dwSkillID, tSkillData in pairs(tSkills) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCombatDataRightListCell, self.ScrollViewData)

        local nAverageDamage = (tSkillData.nTotalDamage / (tSkillData.nHit + tSkillData.nCritical))
        --local szLimitedName = UIHelper.LimitUtf8Len(GetSkillName(dwSkillID), 7)
        UIHelper.SetString(script.LabelTarget, GetSkillName(dwSkillID, tSkillData.nEffectType, tSkillData.dwSkillLevel))
        UIHelper.SetString(script.LabelMaxHarm, UIHelper.NumberToTenThousand(tSkillData.nBiggestDamage, 1))
        UIHelper.SetString(script.LabelMinHarm, UIHelper.NumberToTenThousand(tSkillData.nSmallestDamage, 1))
        UIHelper.SetString(script.LabelAvgHarm, UIHelper.NumberToTenThousand(nAverageDamage, 1))
        UIHelper.SetString(script.LabelHit, tSkillData.nHit)
        UIHelper.SetString(script.LabelKnowing, tSkillData.nCritical)
        UIHelper.SetString(script.LabelDeviation, tSkillData.nDoge)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end

return UIPanelCombatData