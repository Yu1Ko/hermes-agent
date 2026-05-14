MatrixData = MatrixData or {}

local self = MatrixData
-- {
-- bLearn
-- dwFormationLeader

-- }

function MatrixData.Init()
    MatrixData.TestLearnedFormation()
	MatrixData.RegEvent()
end

function MatrixData.RegEvent()
    Event.Reg(self, "SKILL_UPDATE", function(bSuccess, dwImageIndex)
        MatrixData.TestLearnedFormation()
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function()
        MatrixData.TestLearnedFormation()
    end)

    Event.Reg(self, "PARTY_DISBAND", function()
        self.dwFormationLeader = nil
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function(_, nMemberID, _, _)
        local hPlayer = GetClientPlayer()
		if nMemberID == hPlayer.dwID then
			self.dwFormationLeader = nil
		end
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_INFO", function()
        local hPlayer = GetClientPlayer()
		if hPlayer and hPlayer.IsInParty() then
			local hTeam = GetClientTeam()
			local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
			local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
			self.dwFormationLeader = tGroupInfo.dwFormationLeader
		else
			self.dwFormationLeader = nil
		end
    end)

    Event.Reg(self, "PARTY_SET_FORMATION_LEADER", function()
        local hPlayer = GetClientPlayer()
		if hPlayer and hPlayer.IsInParty() then
			local hTeam = GetClientTeam()
			local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
			local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
			self.dwFormationLeader = tGroupInfo.dwFormationLeader
		else
			self.dwFormationLeader = nil
		end
    end)

    Event.Reg(self, "LOADING_END", function()
        local hPlayer = GetClientPlayer()
		if hPlayer and hPlayer.IsInParty() then
			local hTeam = GetClientTeam()
			local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
			local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
			self.dwFormationLeader = tGroupInfo.dwFormationLeader
		else
			self.dwFormationLeader = nil
		end
    end)
end

function MatrixData.TestLearnedFormation()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	
	local aSkill = pPlayer.GetAllSkillList()
	if not aSkill then
		return
	end
	
	for k, v in pairs(aSkill) do
		local skill = GetSkill(k, v)
		if skill.dwBelongKungfu ~= 0 and Table_IsSkillFormationCaster(k, v) then
			self.bLearn = true
			return
		end
	end
	self.bLearn = false
end

function MatrixData.GetSchoolID()
	local dwSchool = nil
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

	if self.dwFormationLeader == pPlayer.dwID then --如果自己是阵眼
		return
		-- if not self.bLearn then

		-- elseif pPlayer.dwFormationEffectID == 0 then
		-- 	local skillKungfu = pPlayer.GetKungfuMount()
		-- 	if skillKungfu then
		-- 		dwSchool = skillKungfu.dwBelongSchool
		-- 	end
		-- else
		-- 	local skill = GetSkill(pPlayer.dwFormationEffectID, 1)
		-- 	if skill then
		-- 		dwSchool = skill.dwBelongSchool
		-- 	else
		-- 		local skillKungfu = pPlayer.GetKungfuMount()
		-- 		if skillKungfu then
		-- 			dwSchool = skillKungfu.dwBelongSchool
		-- 		end
		-- 	end
		-- end
	elseif self.dwFormationLeader then
		local aPlayer = GetPlayer(self.dwFormationLeader)
		if aPlayer and aPlayer.dwFormationEffectID ~= 0 then
			self.dwFormationEffectID = aPlayer.dwFormationEffectID
			self.dwMentorFormationEffectID = aPlayer.dwMentorFormationEffectID
			local skill = GetSkill(self.dwFormationEffectID, 1)
			if skill then
				dwSchool = skill.dwBelongSchool
			end
		end
	end
	return dwSchool
end

function MatrixData.GetImg()
	local szPath
	if self.dwFormationEffectID then
		szPath = Table_GetSkillIconID(self.dwFormationEffectID, 1)
		szPath = UIHelper.GetIconPathByIconID(szPath)
    end
	return szPath
end

function MatrixData.GetTips()
	local szTip
    if self.dwFormationEffectID then
		szTip = ""
		
        for i = 1, 7, 1 do
            local szDesc = UIHelper.GBKToUTF8(Table_GetSkillDesc(self.dwFormationEffectID, i))
            szTip = szTip .. g_tStrings.tFormationTitle[i] .. szDesc .. "\n"
        end
        
        local szDesc = Table_GetSkillDesc(self.dwMentorFormationEffectID, 1)
        if szDesc and szDesc ~= "" then
            szTip = szTip .. g_tStrings.FORMATION_SPLIT .. "\n"
            szTip = szTip .. g_tStrings.MENTOR_FORMATION .. "\n"
            szTip = szTip .. szDesc.."\n"
        end
    end
	return szTip
end

function MatrixData.GetTitle()
	local szTitle
    if self.dwFormationEffectID then
        szTitle = UIHelper.GBKToUTF8(Table_GetSkillName(self.dwFormationEffectID, 1))
        szTitle = szTitle .. g_tStrings.SCHOOL_FORMATION
    end
	return szTitle
end

function MatrixData.GetShowState()
	local bShow = true
	local bChange = false
    if not self.dwFormationLeader then
		bShow = false
	end

	local dwSchool = MatrixData.GetSchoolID()

	if not dwSchool then
		bShow = false
	end
	
	if MatrixData.bOldShow == nil then
		bChange = true
	else
		bChange = self.bOldShow ~= bShow
	end
	MatrixData.bOldShow = bShow

    return bShow, bChange
end