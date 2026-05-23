

local CLIP_LIST = {
    'AniNormal1',
    'AniNormal2',
    'AniNormal3',
}

local THERAPY_CLIP_LIST = {
    'AniNormal4',
    'AniNormal5',
    'AniNormal6',
}

local HINT_CLIP_LIST = {
    'AniHint1',
    'AniHint2',
    'AniHint3',
}

local CRITICAL_CLIP_LIST = {
    'AniCritical1',
    'AniCritical2',
    'AniCritical3',
}

local THERAPY_CRITICAL_CLIP_LIST = {
    'AniCritical4',
    'AniCritical5',
    'AniCritical6',
}

local SPECIAL_DAMAGE_TYPE_NAME = {
    [SKILL_RESULT_TYPE.ABSORB_DAMAGE] = g_tStrings.STR_MSG_ABSORB,
    [SKILL_RESULT_TYPE.ABSORB_THERAPY] = g_tStrings.STR_MSG_ABSORB,
    [SKILL_RESULT_TYPE.PARRY_DAMAGE] = g_tStrings.STR_MSG_DEFENCE,
}

local m_tSpecialSkillMap = nil
local function InitSpecialSkillMap()
    if m_tSpecialSkillMap == nil then
        m_tSpecialSkillMap = {}
        local nCount = g_tTable.CombatTextSpecialSkill:GetRowCount()
        for i = 2, nCount do
            local tRow = g_tTable.CombatTextSpecialSkill:GetRow(i)
            local tColor = {}
            local szColor = tRow.SpecialColor
            if szColor then
                for id in string.gmatch(szColor, "%d+") do
                    table.insert(tColor, tonumber(id))
                end
            end
            m_tSpecialSkillMap[tRow.nSkillID] = tColor
        end
    end
end

local function IsOtherToMeTherapy(nDamageType, dwTargetID)
    return nDamageType == SKILL_RESULT_TYPE.THERAPY and dwTargetID == GetControlPlayerID()
end

local UIMainCityBleedNormal = class("UIMainCityBleedNormal")
function UIMainCityBleedNormal:OnEnter()
    if not self.bInit then
        InitSpecialSkillMap()

        Event.Reg(self, EventType.OnBattleInfoSettingChange, function(tInfo)
            self:SetFontSizeRatio(tInfo.fRatio)
        end)

        local fRatio = 1
        local tConfig = GameSettingData.GetNewValue(UISettingKey.BattleFontSize)
        if tConfig then
            fRatio = tConfig.fRatio
            self:SetFontSizeRatio(fRatio)
        end

        self.bInit = true
    end

    self._rootNode:setVisible(true)
end

function UIMainCityBleedNormal:GetRandomClipName()
    return CLIP_LIST[math.random(1, #CLIP_LIST)]
end

function UIMainCityBleedNormal:GetHintRandomClipName()
    return HINT_CLIP_LIST[math.random(1, #HINT_CLIP_LIST)]
end

function UIMainCityBleedNormal:GetCriticalRandomClipName()
    return CRITICAL_CLIP_LIST[math.random(1, #CRITICAL_CLIP_LIST)]
end

function UIMainCityBleedNormal:GetIncomingTherapyRandomClipName(bCritical)
    local lst = self.bCritical and THERAPY_CRITICAL_CLIP_LIST or THERAPY_CLIP_LIST
    return lst[math.random(1, #lst)]
end

local function OnUpdateTextPos(self, xScreen, yScreen, x, y, z)
    local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
    xScreen, yScreen = xScreen / nScaleX, yScreen / nScaleY
    local tPos = cc.Director:getInstance():convertToGL({ x = xScreen, y = yScreen })
    local widget = self._rootNode:getParent()
    local nX, nY = UIHelper.ConvertToNodeSpace(widget, tPos.x, tPos.y)
    local anchor = widget:getAnchorPointInPoints()

    local randomX = math.random(-20, 20)
    local randomY = math.random(-20, 20)

    self._rootNode:setPosition(nX + anchor.x + randomX, nY + anchor.y + randomY)
    self._rootNode:setVisible(true)
    local szClip = self:fnGetClipName(self.bCritical)
    UIHelper.StopAllAni(self)
    self.bIsPlaying = true
    UIHelper.PlayAni(self, self.WidgetAni, szClip, function()
        self.bIsPlaying = false
        UIHelper.SetVisible(self._rootNode, false)

        if IsFunction(self.fnCallback) then
            self.fnCallback()
        end
    end)
end

local function IsPartnerDisabled(dwCasterID)
    return GameSettingData.GetNewValue(UISettingKey.DisablePartnerBattleInfo) and PartnerData.IsPartnerNpc(dwCasterID)
end

local function GetDamageColor(dwSkillID, nDamageType, bActive)
    if m_tSpecialSkillMap and m_tSpecialSkillMap[dwSkillID] then
        local tData = m_tSpecialSkillMap[dwSkillID]
        return cc.c3b(tData[1], tData[2], tData[3]) -- 根据技能ID自定义颜色 主要用于大附魔技能
    end

    local bHealth = nDamageType == SKILL_RESULT_TYPE.THERAPY or nDamageType == SKILL_RESULT_TYPE.STEAL_LIFE
    local tFontData = Storage.BattleFontColor.Active

    if not bHealth and not bActive then
        return tFontData['DEFAULT']
    end

    if tFontData[nDamageType] then
        return tFontData[nDamageType]
    end

    return tFontData['DEFAULT']
end

local function GetDamageName(dwSkillID, dwLevel, nEffectType)
    -- local szValueLeft = Table_GetSkillDecoration(dwSkillID, dwLevel)

    local szSkillName = ""

    if nEffectType == SKILL_EFFECT_TYPE.BUFF then
        szSkillName = UIHelper.GBKToUTF8(Table_GetBuffName(dwSkillID, dwLevel))
    else
        local tSkill = TabHelper.GetDisplaySkill(dwSkillID)
        if tSkill then
            szSkillName = tSkill.szName
        else
            szSkillName = UIHelper.GBKToUTF8(Table_GetSkillName(dwSkillID, dwLevel) or "")
        end
    end

    return szSkillName
end

function UIMainCityBleedNormal:UpdateLabel(dwCasterID, dwTargetID, nDamage, nDamageType, nEffectType, dwSkillID, dwLevel, bCritical)
    UIHelper.SetVisible(self._rootNode, false)
    local bActive = PlayerData.IsMeOrMyEmployee(dwCasterID)
    local bHealth = nDamageType == SKILL_RESULT_TYPE.THERAPY or nDamageType == SKILL_RESULT_TYPE.STEAL_LIFE
    local nBattleInfo = bActive and BATTLE_INFO.ACTIVE_ATTACK or BATTLE_INFO.DAMAGED

    local tColor = GetDamageColor(dwSkillID, nDamageType, bActive)
    local tConfig = GameSettingData.GetNewValue(UISettingKey.BattleInfoNumberMeasureUnit)
    local bConvertToTenThousand = tConfig and tConfig.szDec == GameSettingType.BattleInfoNumberMeasureUnit.TenThousand.szDec
    local szDamageStr = bHealth and string.format("+%d", nDamage) or tostring(nDamage)
    if bConvertToTenThousand and nDamage > 10000 then
        szDamageStr = bHealth and string.format("+%d万", nDamage / 10000) or string.format("%d万", nDamage / 10000)
    end

    self.bCritical = bCritical
    self.szDamager = szDamageStr
    if self.LabelBleed then
        UIHelper.SetColor(self.LabelBleed, tColor)
        UIHelper.SetColor(self.LabelSkillName, tColor)
        UIHelper.SetString(self.LabelBleed, self.szDamager)
    end

    local szDisplayName = ""
    if GetGameSetting(SettingCategory.BattleInfo, nBattleInfo, "技能名字") and dwSkillID then
        local szName = GetDamageName(dwSkillID, dwLevel, nEffectType)
        if szName ~= "" then
            szDisplayName = szName .. "：" .. (bCritical and g_tStrings.MSG_CRITICALSTRIKE_TITLE or "")
        end
    end

    if SPECIAL_DAMAGE_TYPE_NAME[nDamageType] then
        szDisplayName = SPECIAL_DAMAGE_TYPE_NAME[nDamageType] .. "："
    end

    if self.LabelSkillName then
        UIHelper.SetString(self.LabelSkillName, szDisplayName)
    end
    -- 合并后的新Label
    if self.LabelBleed1 then
        UIHelper.SetString(self.LabelBleed1, szDisplayName .. self.szDamager)
        UIHelper.SetColor(self.LabelBleed1, tColor)
    end
end

function UIMainCityBleedNormal:UpdateInfo(dwCasterID, dwTargetID, nDamageType, nDamage, dwSkillID, dwLevel, nEffectType, callback)
    if IsPartnerDisabled(dwCasterID) then
        self.bIsPlaying = false
        UIHelper.SetVisible(self._rootNode, false)
        return -- 开关开启时不显示侠客战斗信息
    end

    self.bIsPlaying = true

    self:UpdateLabel(dwCasterID, dwTargetID, nDamage, nDamageType, nEffectType, dwSkillID, dwLevel, false)

    self.fnCallback = callback
    self.fnGetClipName = IsOtherToMeTherapy(nDamageType, dwTargetID) and self.GetIncomingTherapyRandomClipName or self.GetRandomClipName

    PostThreadCall(OnUpdateTextPos, self, "Scene_GetCharacterSkillEffectTextPos", dwTargetID)
end

function UIMainCityBleedNormal:UpdateHealthInfo(dwTargetID, nDeltaLife, nDamageType, callback)
    self.bIsPlaying = true

    self:UpdateLabel(-2, dwTargetID, nDeltaLife, nDamageType)

    self.fnCallback = callback
    self.fnGetClipName = IsOtherToMeTherapy(nDamageType, dwTargetID) and self.GetIncomingTherapyRandomClipName or self.GetRandomClipName

    PostThreadCall(OnUpdateTextPos, self, "Scene_GetCharacterSkillEffectTextPos", dwTargetID)
end

function UIMainCityBleedNormal:UpdateCriticalInfo(dwCasterID, dwTargetID, nDamageType, nDamage, dwSkillID, dwLevel, nEffectType, callback)
    if IsPartnerDisabled(dwCasterID) then
        self.bIsPlaying = false
        UIHelper.SetVisible(self._rootNode, false)
        return -- 开关开启时不显示侠客战斗信息
    end

    self.bIsPlaying = true

    self:UpdateLabel(dwCasterID, dwTargetID, nDamage, nDamageType, nEffectType, dwSkillID, dwLevel, true)

    self.fnCallback = callback
    self.fnGetClipName = IsOtherToMeTherapy(nDamageType, dwTargetID) and self.GetIncomingTherapyRandomClipName or self.GetCriticalRandomClipName

    PostThreadCall(OnUpdateTextPos, self, "Scene_GetCharacterSkillEffectTextPos", dwTargetID)
end

function UIMainCityBleedNormal:UpdateCombatStateInfo(dwCasterID, dwTargetID, szEvent, callback)
    self.bIsPlaying = true

    UIHelper.SetVisible(self._rootNode, false)
    if self.LabelSkillName then
        UIHelper.SetString(self.LabelSkillName, szEvent)
    end
    if self.LabelBleed1 then
        UIHelper.SetString(self.LabelBleed1, szEvent .. (self.szDamager or ""))
    end

    self.fnCallback = callback
    self.fnGetClipName = self.GetHintRandomClipName

    PostThreadCall(OnUpdateTextPos, self, "Scene_GetCharacterSkillEffectTextPos", dwTargetID)
end

function UIMainCityBleedNormal:UpdateCharacterHeadTip(dwCharacterID, szTip, szParam, tColor, callback)
    self.bIsPlaying = true

    UIHelper.SetVisible(self._rootNode, false)
    if self.LabelSkillName then
        UIHelper.SetString(self.LabelSkillName, szTip)
        if tColor then
            UIHelper.SetColor(self.LabelSkillName, cc.c3b(tColor[1] or 255, tColor[2] or 255, tColor[3] or 255))
        end
    end

    self.fnCallback = callback
    self.fnGetClipName = self.GetHintRandomClipName

    PostThreadCall(OnUpdateTextPos, self, "Scene_GetCharacterSkillEffectTextPos", dwCharacterID)
end

function UIMainCityBleedNormal:UpdateSpiritEnduranceInfo(dwCasterID, dwTargetID, bSpirit, nDelta, callback)
    self.bIsPlaying = true

    UIHelper.SetVisible(self._rootNode, false)
    local szText = "精力："
    if not bSpirit then
        szText = "耐力："
    end
    if nDelta < 0 then
        szText = szText .. nDelta
    else
        szText = szText .. "+" .. nDelta
    end
    if self.LabelBleed1 then
        UIHelper.SetColor(self.LabelBleed1, cc.WHITE)
        UIHelper.SetString(self.LabelBleed1, szText)
    end

    self.fnCallback = callback
    self.fnGetClipName = self.GetRandomClipName

    PostThreadCall(OnUpdateTextPos, self, "Scene_GetCharacterSkillEffectTextPos", dwTargetID)
end

function UIMainCityBleedNormal:Hide()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIMainCityBleedNormal:SetFontSizeRatio(fRatio)
    if not self.fBaseFontSize then
        if self.LabelBleed1 then
            self.fBaseFontSize = UIHelper.GetFontSize(self.LabelBleed1)
        elseif self.LabelSkillName then
            self.fBaseFontSize = UIHelper.GetFontSize(self.LabelSkillName)
        end
    end

    if not self.fBaseFontSize then
        return
    end

    local nFontSize = math.floor(self.fBaseFontSize * fRatio)
    if self.LabelBleed1 then
        UIHelper.SetFontSize(self.LabelBleed1, nFontSize)
    elseif self.LabelSkillName then
        UIHelper.SetFontSize(self.LabelSkillName, nFontSize)
    end
end

function UIMainCityBleedNormal:OnExit()
end

return UIMainCityBleedNormal