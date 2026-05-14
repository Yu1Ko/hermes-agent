-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterKungfuTips
-- Date: 2024-02-19 17:36:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterKungfuTips = class("UICharacterKungfuTips")

function UICharacterKungfuTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local player = PlayerData.GetClientPlayer()
    if not player then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetXinFaTips)
        return
    end

    local skill = player.GetActualKungfuMount()

    self.dwSkillID      = skill.dwSkillID
    self.dwLevel   = skill.dwLevel
    self:UpdateInfo()
end

function UICharacterKungfuTips:OnExit()
    self.bInit = false
end

function UICharacterKungfuTips:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
end

function UICharacterKungfuTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICharacterKungfuTips:UpdateInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetXinFaTips)
        return
    end

    local tSkillInfo = TabHelper.GetUISkill(self.dwSkillID)
    local szIconPath = TabHelper.GetSkillIconPath(self.dwSkillID)
    local szIconPath = PlayerKungfuImg[self.dwSkillID]
    UIHelper.SetSpriteFrame(self.ImgSkillIcon, szIconPath)
    if tSkillInfo then
        UIHelper.SetString(self.LabelSkillName, tSkillInfo.szName)
    end
    UIHelper.SetSpriteFrame(self.ImgSchoolIcon, PlayerForceID2SchoolImg2[player.dwForceID])

    -- 后续部分读取端游的
    local skill = player.GetKungfuMount()
    local hSkill = GetSkill(skill.dwSkillID, skill.dwLevel)
	local tSkillInfo2 = Table_GetSkill(skill.dwSkillID, skill.dwLevel)
    local szDesc = UIHelper.GBKToUTF8(tSkillInfo2.szDesc)
    if hSkill then
        UIHelper.SetString(self.LabelSchoolName, g_tStrings.tMountRequestTable[hSkill.dwBelongSchool])
    end

    local aSkill = player.GetSkillList(skill.dwSkillID)
	local tInfo = {}
	for dwSubID, dwSubLevel in pairs(aSkill) do
		local fSort = Table_GetSkillSortOrder(dwSubID, dwSubLevel);
		table.insert(tInfo, {dwID=dwSubID, dwLevel=dwSubLevel, fSort = fSort})
	end
	table.sort(tInfo, function(tA, tB) return tA.fSort < tB.fSort end)


    local szName = ""
    local szAttrs = ""

    local skillInfoList = SkillData.GetCurrentPlayerSkillList(self.dwSkillID)
    for _, tSkill in ipairs(skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if skillInfo.nType == UISkillType.Passive and skillInfo.nDamageParentID == self.dwSkillID then
            local tSkillInfo = TabHelper.GetUISkill(nSkillID)
            local nSkillLevel = player.GetSkillLevel(self.dwSkillID)
            szAttrs = tSkillInfo.tbExtraDescText[nSkillLevel]
            szAttrs = SkillData.FormSpecialNoun(szAttrs, nSkillID)
        end
    end

    for _, tData in pairs(tInfo) do
		local dwSkillID, dwLevel = tData.dwID, tData.dwLevel

        if Table_IsSkillShow(dwSkillID, dwLevel) then
	        local hSkill = GetSkill(dwSkillID, dwLevel)
            local tSkillInfo = Table_GetSkill(dwSkillID, dwLevel)

            szName = szName .. UIHelper.GBKToUTF8(tSkillInfo.szName)
            if hSkill.dwBelongKungfu ~= 0 then
                if hSkill.bIsPassiveSkill then
                    szName = szName .. "\n" .. g_tStrings.STR_SKILL_PASSIVE_SKILL
                elseif tSkillInfo.bFormation ~= 0 then
                    szName = szName .. "\n" .. g_tStrings.FORMATION_GAMBIT
                end
            end
		end
	end

    UIHelper.SetRichText(self.RichTextDesc, string.format("<color=#D7F6FF>%s</c>\n\n<color=#FFFFFF>%s</c>\n<color=#FFE26E>%s</c>", szDesc, szName, szAttrs))
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end


return UICharacterKungfuTips