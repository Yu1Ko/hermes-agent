local UIWidgetMonsterBookDetailTop = class("UIWidgetMonsterBookDetailTop")

local szLeftFormat = "<color=#D7F6FF>距离：<color=#ffffff>%s</c>\n<color=#D7F6FF>武器：<color=#ffffff>%s</c>\n<color=#D7F6FF>内功：<color=#ffffff>%s</c>"
local szRightFormat = "<color=#AED9E0>%s\n%s\n%s</c>"

function UIWidgetMonsterBookDetailTop:OnEnter(tRecipeKey)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tRecipeKey)
end

function UIWidgetMonsterBookDetailTop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookDetailTop:BindUIEvent()

end

function UIWidgetMonsterBookDetailTop:RegEvent()

end

function UIWidgetMonsterBookDetailTop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookDetailTop:UpdateInfo(tRecipeKey)
	local hPlayer = GetClientPlayer()
	if not hPlayer or not tRecipeKey then
		return
	end

	local dwID = tRecipeKey.skill_id
	local nLevel = tRecipeKey.skill_level

	local hSkillInfo = GetSkillInfoEx(tRecipeKey, hPlayer.dwID)

	local tOriRecipeKey = clone(tRecipeKey)
	for nIndex = 1, 12, 1 do
		tOriRecipeKey["recipe"..nIndex] = 0
	end
	local hOriSkillInfo = GetSkillInfoEx(tOriRecipeKey, hPlayer.dwID)

	local hSkill = GetSkill(dwID, nLevel)

    local szCastRadius = FormatPureCastRadius(hSkill.nCastMode, hSkillInfo, hOriSkillInfo, false)
    local szWeaponRequest = g_tStrings.tWeaponLimitTable[hSkill.dwWeaponRequest] or g_tStrings.tWeaponLimitTable[0]
    local szKungfuRequest = g_tStrings.tMountRequestTable[hSkill.dwBelongSchool] or g_tStrings.tMountRequestTable[0]
    local szCastCost = FormatPureCastCost(hSkillInfo, hOriSkillInfo, false, hSkill.nCostManaBasePercent)
    local szCastTime = g_tStrings.STR_SKILL_H_CAST_IMMIDIATLY
    local szCoolDown = FormatCooldown(dwID, nLevel, hSkillInfo, hOriSkillInfo, false, hPlayer)

    if dwID == 605 then
        if not hPlayer.bOnHorse then
            szCastTime = g_tStrings.STR_SKILL_H_CAST_TIME .. 3 .. g_tStrings.STR_BUFF_H_TIME_S
        end
    else
        local nCastTime = hPlayer.GetSkillPrepare(dwID, nLevel)
        szCastTime = FormatPureCastTime(hSkillInfo, hOriSkillInfo, false, nCastTime)
    end

    local szLeft = string.format(szLeftFormat, szCastRadius, szWeaponRequest, szKungfuRequest)
    local szRight = string.format(szRightFormat, szCastCost, szCastTime, szCoolDown)
    UIHelper.SetRichText(self.RichTextLeft, szLeft)
    UIHelper.SetRichText(self.RichTextRight, szRight)
end

return UIWidgetMonsterBookDetailTop