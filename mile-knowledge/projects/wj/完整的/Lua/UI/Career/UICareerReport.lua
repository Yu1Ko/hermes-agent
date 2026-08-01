-- WidgetCareerReport
local UICareerReport = class("UICareerReport")

function UICareerReport:OnEnter()
    self.player = GetClientPlayer()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateData()
end

function UICareerReport:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerReport:BindUIEvent()
    --
end

function UICareerReport:RegEvent()
    Event.Reg(self, "ON_GET_DOCUMENT", function(dwPlayerID, tInfo)
        CareerData.tReportInfo = tInfo
		CareerData.tReportInfoTime = GetCurrentTime()
        self:UpdateReport(tInfo)
    end)

	Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 3, function()
			UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCareerReport, true, true)
        	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCareerReport)
		end)
    end)
end

function UICareerReport:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerReport:UpdateData()
	local bApplyData = true
	if CareerData.tReportInfo then
        local nowTime = GetCurrentTime()
        local nDelta = nowTime - CareerData.tReportInfoTime
        if nDelta <= 60 then
            bApplyData = false
        end
    end

    if bApplyData and self.player then
        RemoteCallToServer("On_Achievement_GetDocumentInfo", self.player.dwID)
	end

	UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetPlayerIcon, self.player.dwID)
	UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(self.player.szName))

	if CareerData.tReportInfo then
		self:UpdateReport(CareerData.tReportInfo)
	end
end


local function GetColorString(stInfo, bData)
	if bData == true then
		return string.format("<color=#d08b57>%s</color>", stInfo)
	else
		return string.format("<color=#ceeaff>%s</color>", stInfo)
	end
end

function UICareerReport:UpdateReport(tInfo)

    UIHelper.RemoveAllChildren(self.ScrollViewCareerReport)

    local szText = ""

    if tInfo.nCreateTime then
		local tStartTime = TimeToDate(tInfo.nCreateTime)
		local szCreateTime = g_tStrings.STR_TIME_7 .. FormatString(g_tStrings.STR_TIME_3, tStartTime.year,
			tStartTime.month, tStartTime.day)
        szText = GetColorString(szCreateTime, true) .. GetColorString(g_tStrings.STR_DOCUMENT_BUILD_ACCOUNT_TIME)
		szText = string.gsub(szText, "\n", "")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    if tInfo.dwForceID and tInfo.dwForceID ~= 0 then
		local szGenerationName = UIHelper.GBKToUTF8(Table_GetDesignationGeneration(tInfo.dwForceID, tInfo.nForceGeneration))
		if tInfo.dwForceID == FORCE_TYPE.SHAO_LIN then
			szGenerationName =  szGenerationName ..g_tStrings.STR_WORD
		end
        szGenerationName =  Table_GetForceName(tInfo.dwForceID) .. szGenerationName
        szText = GetColorString(g_tStrings.STR_DOCUMENT_FORCE_1) .. GetColorString(szGenerationName,true) .. GetColorString(g_tStrings.STR_DOCUMENT_FORCE_2)
		szText = string.gsub(szText, "\n", "")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, GetColorString(g_tStrings.STR_VERSION_DESC .. "；"))

    if tInfo.nApprenticeCount and tInfo.nApprenticeCount ~= 0 then
		szText = GetColorString(g_tStrings.STR_DOCUMENT_APPRENTICE_1) .. GetColorString(tInfo.nApprenticeCount, true) ..
			GetColorString(g_tStrings.STR_DOCUMENT_APPRENTICE_2 .. "；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

	if tInfo.nBossCount and tInfo.nBossCount ~= 0 then
		szText = GetColorString(g_tStrings.STR_DOCUMENT_KILL_1) .. GetColorString(tInfo.nBossCount,true) .. GetColorString(g_tStrings.STR_DOCUMENT_KILL_2 .. "；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    if tInfo.nCamp and (tInfo.nCamp == CAMP.GOOD or tInfo.nCamp == CAMP.EVIL) then
		if tInfo.nCamp == CAMP.GOOD then
            szText = GetColorString(g_tStrings.STR_DOCUMENT_CAMP_1) .. GetColorString(g_tStrings.STR_DOCUMENT_CAMP_2,true) ..
				GetColorString(g_tStrings.STR_DOCUMENT_CAMP_4) .. GetColorString(g_tStrings.STR_CAMP_TITLE[tInfo.nCamp],true)
		elseif tInfo.nCamp == CAMP.EVIL then
			szText = GetColorString(g_tStrings.STR_DOCUMENT_CAMP_1) .. GetColorString(g_tStrings.STR_DOCUMENT_CAMP_3,true) ..
			GetColorString(g_tStrings.STR_DOCUMENT_CAMP_4) .. GetColorString(g_tStrings.STR_CAMP_TITLE[tInfo.nCamp],true)
		end

		if tInfo.nKilledCount and tInfo.nKilledCount ~= 0 then
            szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_CAMP_5) .. GetColorString(tInfo.nKilledCount,true) .. GetColorString(g_tStrings.STR_DOCUMENT_CAMP_6 .. "；")
		end

        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    if tInfo.nTongID and tInfo.nTongID ~= 0 then
        local tInTongTime = TimeToDate(tInfo.nJoinTongTime)
		local szJoinTongTime = g_tStrings.STR_TIME_7 .. FormatString(g_tStrings.STR_TIME_3, tInTongTime.year, tInTongTime.month, tInTongTime.day)
		szText = GetColorString(szJoinTongTime,true) .. GetColorString(g_tStrings.STR_DOCUMENT_TONG_1) .. GetColorString(UIHelper.GBKToUTF8(GetTongClient().ApplyGetTongName(tInfo.nTongID)) or "", true)
		if tInfo.szCastleName and tInfo.szCastleName ~= 0 then
			szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_TONG_2) .. GetColorString(tInfo.szCastleName)
		else
			szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_TONG_3)
		end

        szText = szText .. GetColorString("；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    if tInfo.nQuestCount and tInfo.nQuestCount ~= 0 then
		szText = GetColorString(g_tStrings.STR_DOCUMENT_QUEST_1) .. GetColorString(tInfo.nQuestCount, true) .. GetColorString(g_tStrings.STR_DOCUMENT_QUEST_2)
		if tInfo.nAdventureCount and tInfo.nAdventureCount ~= 0 then
			szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_QUEST_3) .. GetColorString(tInfo.nAdventureCount, true) .. GetColorString(g_tStrings.STR_DOCUMENT_QUEST_4)
		end

        szText = szText .. GetColorString("；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

	if (tInfo.nReputeCount and tInfo.nReputeCount ~= 0) or (tInfo.szPlayerDesignation ~= "") or (tInfo.nCloseFellowship and tInfo.nCloseFellowship ~= 0) then
		local bComma = false
		if tInfo.nReputeCount and tInfo.nReputeCount ~= 0 then
			bComma = true
            szText = GetColorString(g_tStrings.STR_DOCUMENT_REPUTATION_1) .. GetColorString(tInfo.nReputeCount,true) .. GetColorString(g_tStrings.STR_DOCUMENT_REPUTATION_2)
		end
		if tInfo.nCloseFellowship and tInfo.nCloseFellowship ~= 0 then
			if bComma then
				szText = szText .. GetColorString("，")
			end
			bComma= true
			szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_REPUTATION_3) .. GetColorString(tInfo.nCloseFellowship,true) .. GetColorString(g_tStrings.STR_DOCUMENT_REPUTATION_4)
		end
		if tInfo.szPlayerDesignation and tInfo.szPlayerDesignation ~= "" then
			if bComma then
				szText = szText .. GetColorString("，")
			end
            szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_REPUTATION_5) .. GetColorString(UIHelper.GBKToUTF8(tInfo.szPlayerDesignation),true)
		end

        if bComma then
            szText = szText .. GetColorString("；")
            UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
        end
	end

    if tInfo.nEquipScore and tInfo.nEquipScore ~= 0 then
        szText = GetColorString(g_tStrings.STR_DOCUMENT_EQUIPMENT_1) .. GetColorString(tInfo.nEquipScore,true) .. GetColorString(g_tStrings.STR_DOCUMENT_EQUIPMENT_2 .. "；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

	if tInfo.nPendentCount and tInfo.nPendentCount ~= 0 then
        szText = GetColorString(g_tStrings.STR_DOCUMENT_PENDANT_1) .. GetColorString(tInfo.nPendentCount,true) .. GetColorString(g_tStrings.STR_DOCUMENT_PENDANT_2)

        if tInfo.nFellowPetCount and tInfo.nFellowPetCount ~= 0 then
            szText = szText .. GetColorString(tInfo.nFellowPetCount, true) .. GetColorString(g_tStrings.STR_DOCUMENT_PENDANT_3 .. "；")
        	UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
        end
	end

	if tInfo.nBookCount and tInfo.nBookCount ~= 0 then
        szText = GetColorString(g_tStrings.STR_DOCUMENT_BOOK_1) .. GetColorString(tInfo.nBookCount, true) .. GetColorString(g_tStrings.STR_DOCUMENT_BOOK_2 .. "；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

	if tInfo.nMaxProfessionLevelCount and tInfo.nMaxProfessionLevelCount ~= 0 then

        szText = GetColorString(g_tStrings.STR_DOCUMENT_LIFE_SKILL_1) .. GetColorString(tInfo.nMaxProfessionLevelCount, true) .. GetColorString(g_tStrings.STR_DOCUMENT_LIFE_SKILL_2)
        if tInfo.szProfessionExpertiseName and tInfo.szProfessionExpertiseName ~= 0 then
			szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_LIFE_SKILL_3) .. GetColorString(UIHelper.GBKToUTF8(tInfo.szProfessionExpertiseName), true) .. GetColorString(g_tStrings.STR_DOCUMENT_LIFE_SKILL_4)
		end
        szText = szText .. GetColorString("；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    if tInfo.nExteriorCount and tInfo.nExteriorCount ~= 0 then
        szText = GetColorString(g_tStrings.STR_DOCUMENT_EXTERIOR_1) .. GetColorString(tInfo.nExteriorCount, true) .. GetColorString(g_tStrings.STR_DOCUMENT_EXTERIOR_2)
        szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_EXTERIOR_ROLETYPE[tInfo.nRoleType]) .. GetColorString("；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    if tInfo.nAchievementPoint and tInfo.nAchievementPoint ~= 0 then
        szText = GetColorString(g_tStrings.STR_DOCUMENT_ACHIEVEMENT_1) .. GetColorString(tInfo.nAchievementPoint, true)
		szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_ACHIEVEMENT_2) .. GetColorString(UIHelper.GBKToUTF8(tInfo.szAchievementStage), true)
        szText = szText .. GetColorString("；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

    if (tInfo.szHorseName and tInfo.szHorseName ~= 0) or (tInfo.szWeaponName and tInfo.szWeaponName ~= 0) then
		local bComma = false
		szText = ""
		if tInfo.szHorseName and tInfo.szHorseName ~= 0 then
			bComma = true
            szText = GetColorString(g_tStrings.STR_DOCUMENT_RIDE_1) .. GetColorString(UIHelper.GBKToUTF8(tInfo.szHorseName),true)
		end
		if tInfo.szWeaponName and tInfo.szWeaponName ~= 0 then
			if bComma then
                szText = szText .. GetColorString("，")
			end
			bComma = true
            szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_RIDE_2) .. GetColorString(UIHelper.GBKToUTF8(tInfo.szWeaponName),true)
		end
		if bComma then
			szText = szText .. GetColorString("，")
		end
        szText = szText .. GetColorString(g_tStrings.STR_DOCUMENT_RIDE_3 .. "；")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerReportCell, self.ScrollViewCareerReport, szText)
	end

	Timer.AddFrame(self, 3, function()
		UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCareerReport, true, true)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCareerReport)
    end)
end

return UICareerReport