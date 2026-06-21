-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitPublishView
-- Date: 2023-02-07 17:00:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local function CheckPushAchievement(szAchi)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local tAchi = SplitString(szAchi, ";")

	if #tAchi == 0 then
		return true
	end

	for _, v in ipairs(tAchi) do
		if hPlayer.IsAchievementAcquired(v) then
			return true
		end
	end

	return false, tAchi
end

local UITeamRecruitPublishView = class("UITeamRecruitPublishView")

function UITeamRecruitPublishView:OnEnter(tbSelfRecruitInfo, dwLocateRecruitID, bFromRoom)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbBreadNaviCells = {}
    self.tbFilterItemCells = {}
    self.tbCheckedMenu = nil
    self.tbSelfRecruitInfo = clone(tbSelfRecruitInfo)
    self.dwLocateRecruitID = dwLocateRecruitID
    self.bFromRoom = bFromRoom or false

    local navigationFilter = UIHelper.GetBindScript(self.WidgetFilterLeft)
    local fnCheckedCallback = function (tbMenu)
        self:OnCheckedMenu(tbMenu)
    end
    navigationFilter:OnInit(PREFAB_ID.WidgetBreadNaviCell, PREFAB_ID.WidgetFilterItemCell, fnCheckedCallback, nil, nil, PREFAB_ID.WidgetBreadNaviCellLong)

    self:UpdateInfo()
end

function UITeamRecruitPublishView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitPublishView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReleaseRecruit, EventType.OnClick, function ()
        self:PublishTeam()
    end)

    UIHelper.BindUIEvent(self.BtnCrossServerRecruit, EventType.OnClick, function ()
        self:PublishTeam(true)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBox, function()
            self:UpdateEditBoxText()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBox, function()
            self:UpdateEditBoxText()
        end)
    end

    UIHelper.BindUIEvent(self.TogSelectBg01, EventType.OnSelectChanged, function(_, bSelected)
    end)

    UIHelper.BindUIEvent(self.TogSelectBg02, EventType.OnSelectChanged, function(_, bSelected)
        Timer.AddFrame(self, 1, function()
            self:UpdateButtonInfo()
        end)
    end)
end

function UITeamRecruitPublishView:RegEvent()
    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function()
		if arg0 == ACTIVITY_ID.ALLOW_EDIT then
			self:UpdateEditEnable()
		end
    end)
end

function UITeamRecruitPublishView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitPublishView:UpdateInfo()
    self:UpdateEditEnable()
    UIHelper.SetVisible(self.ImgTeachGroupMark, TeamBuilding.IsTeachLeader())

    local dwCheckedActivityID = -1
    if self.tbSelfRecruitInfo then
        dwCheckedActivityID = self.tbSelfRecruitInfo["dwActivityID"]
        local szComment, _ = TeamBuilding.GetTeamPushComment(self.tbSelfRecruitInfo)
        UIHelper.SetString(self.EditBox, szComment)
        local nFlag = self.tbSelfRecruitInfo["nFlag"]
        local bNeedTongMember = self.tbSelfRecruitInfo["bNeedTongMember"]
        UIHelper.SetSelected(self.TogSelectBg01, nFlag % 2 == 1)
        UIHelper.SetSelected(self.TogSelectBg02, bNeedTongMember)
    end

    local fnClickTag = function (tbTag)
        local szComment = UIHelper.GetString(self.EditBox)
        if TeamBuilding.GetStringCharCount(szComment) == 0 then
            szComment = tbTag.text
        else
            szComment = szComment .. g_tStrings.STR_ONE_CHINESE_SPACE .. tbTag.text
        end
        if TeamBuilding.GetStringCharCount(szComment) <= 30 then
            UIHelper.SetText(self.EditBox, szComment)
            self:UpdateEditBoxText()
        end
    end
    UIHelper.RemoveAllChildren(self.LayoutCommon)
    UIHelper.AddPrefab(PREFAB_ID.WidgetRecruitPopSubTitle, self.LayoutCommon, g_tStrings.tTeamBuildRecruitMsgAllGroupTags[1].Title)
    local tbTags1 = g_tStrings.tTeamBuildRecruitMsgAllGroupTags[1].Tags
    for i = 1, #tbTags1, 3 do
        UIHelper.AddPrefab(PREFAB_ID.WidgetQuickPhrasePop, self.LayoutCommon, { tbTags1[i], tbTags1[i+1], tbTags1[i+2] }, fnClickTag)
    end
    UIHelper.LayoutDoLayout(self.LayoutCommon)

    UIHelper.RemoveAllChildren(self.LayoutSchool)
    UIHelper.AddPrefab(PREFAB_ID.WidgetRecruitPopSubTitle, self.LayoutSchool, g_tStrings.tTeamBuildRecruitMsgAllGroupTags[2].Title)
    local tbTags2 = g_tStrings.tTeamBuildRecruitMsgAllGroupTags[2].Tags
    for i = 1, #tbTags2, 3 do
        UIHelper.AddPrefab(PREFAB_ID.WidgetQuickPhrasePop, self.LayoutSchool, { tbTags2[i], tbTags2[i+1], tbTags2[i+2] }, fnClickTag)
    end
    UIHelper.LayoutDoLayout(self.LayoutSchool)

    UIHelper.ScrollViewDoLayout(self.ScrollViewPublic)
    UIHelper.ScrollToTop(self.ScrollViewPublic, 0)

    local tbTotalMenu = {}
    local tbCheckedMenu = {}
    local tbAll = Table_GetTeamRecruit()
    for _, v1 in ipairs(tbAll) do
        local tbSuperMenu = {}
        local tbSuperID = {}
        for _, v2 in ipairs(v1) do
            local tbSubMenu = {}
            if v2.bParent then
                local tbSubID = {}
				for _, v3 in ipairs(v2) do
					local bShow = TeamBuilding.UseSubMenu(v3)
                    local bLocate = dwCheckedActivityID == v3.dwID or (self.dwLocateRecruitID and self.dwLocateRecruitID == v3.dwID)
					if bShow or bLocate then
                        local szName = UIHelper.GBKToUTF8(v3.szName)
                        if v3.bSwitchServer then
                            szName = g_tStrings.STR_SWICTH_SEVER .. szName
                        end
						local tbLastMenu = TeamBuilding.GetCheckedMenu(szName, true, false, {v3.dwID, v3.szName}, nil, v3.bMark)
						table.insert(tbSubMenu, tbLastMenu)
						table.insert(tbSubID, v3.dwID)
						table.insert(tbSuperID, v3.dwID)
                        if bLocate then
                            table.insert(tbCheckedMenu, 1, tbLastMenu)
                            table.insert(tbCheckedMenu, 1, tbSubMenu)
                            table.insert(tbCheckedMenu, 1, tbSuperMenu)
                        end
					end
				end
                if not table_is_empty(tbSubMenu) then
                    TeamBuilding.SetMenuInfo(tbSubMenu, UIHelper.GBKToUTF8(v2.SubTypeName), false, false, {v2.SubType, v2.SubTypeName}, nil, v2.bMark)
					table.insert(tbSuperMenu, tbSubMenu)
				end
            else
                local bShow = TeamBuilding.UseSubMenu(v2)
                local bLocate = dwCheckedActivityID == v2.dwID or (self.dwLocateRecruitID and self.dwLocateRecruitID == v2.dwID)
				if bShow or bLocate then
                    local szName = UIHelper.GBKToUTF8(v2.szName)
                    if v2.bSwitchServer then
                        szName = g_tStrings.STR_SWICTH_SEVER .. szName
                    end
					tbSubMenu = TeamBuilding.GetCheckedMenu(szName, true, false, {v2.dwID, v2.szName}, nil, v2.bMark)
					table.insert(tbSuperMenu, tbSubMenu)
					table.insert(tbSuperID, v2.dwID)
                    if bLocate then
                        table.insert(tbCheckedMenu, 1, tbSubMenu)
                        table.insert(tbCheckedMenu, 1, tbSuperMenu)
                    end
				end
            end
        end
        if not table_is_empty(tbSuperMenu) then
            TeamBuilding.SetMenuInfo(tbSuperMenu, UIHelper.GBKToUTF8(v1.TypeName), false, false, {v1.Type, v1.TypeName}, nil, v1.bMark)
            table.insert(tbTotalMenu, tbSuperMenu)
		end
    end
    TeamBuilding.SetMenuInfo(tbTotalMenu, "活动类型", false, false, {0, "活动类型"}, nil, false)
    table.insert(tbCheckedMenu, 1, tbTotalMenu)

    local navigationFilter = UIHelper.GetBindScript(self.WidgetFilterLeft)
    for _, tbMenu in ipairs(tbCheckedMenu) do
        navigationFilter:SetChecked(tbMenu, true)
    end
    self:UpdateButtonInfo()
end

function UITeamRecruitPublishView:OnCheckedMenu(tbMenu)
    self.tbCheckedMenu = tbMenu
    if tbMenu then
        local tbInfo = Table_GetTeamInfo(tbMenu.UserData[1])
        UIHelper.SetString(self.LabelGradeNum, tbInfo.dwMinLevel)
        UIHelper.SetString(self.LabelPeopleNum, tbInfo.dwMaxPlayerNum)
    else
        UIHelper.SetString(self.LabelGradeNum, "-")
        UIHelper.SetString(self.LabelPeopleNum, "-")
    end
    self:UpdateButtonInfo()
end

function UITeamRecruitPublishView:UpdateEditBoxText()
    local szContent = UIHelper.GetString(self.EditBox)
    local nCharNum = TeamBuilding.GetStringCharCount(szContent)
    UIHelper.SetString(self.LabelEditBoxNum, ""..nCharNum.. "/30")
end

function UITeamRecruitPublishView:UpdateButtonInfo()
    local bEnableTong = GetTongClient().dwTongID ~= 0
    if not bEnableTong then
        UIHelper.SetSelected(self.TogSelectBg02, false, false)
    end
    UIHelper.SetEnable(self.TogSelectBg02, bEnableTong)
    UIHelper.SetOpacity(self.TogSelectBg02, bEnableTong and 255 or 143)

    local bRemote = IsRemotePlayer(UI_GetClientPlayerID())

    local bEnableSwitchServer = not bRemote
    local bEnableLocalServer = not bRemote
    if self.bFromRoom then
        bEnableLocalServer = false
    end
    if self.tbSelfRecruitInfo then
        if self.tbSelfRecruitInfo["szRoomID"] then
            bEnableLocalServer = false
        else
            bEnableSwitchServer = false
        end
    end
    if UIHelper.GetSelected(self.TogSelectBg02) then
        bEnableSwitchServer = false
    end
    if self.tbCheckedMenu then
        local dwApplyID = self.tbCheckedMenu.UserData[1]
        local tInfo = Table_GetTeamInfo(dwApplyID)
        if not tInfo.bSwitchServer then
            bEnableSwitchServer = false
        end
    end
    UIHelper.SetButtonState(self.BtnReleaseRecruit, bEnableLocalServer and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnCrossServerRecruit, bEnableSwitchServer and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UITeamRecruitPublishView:UpdateEditEnable()
    local bEnable = ActivityData.IsMsgEditAllowed()
    UIHelper.SetEnable(self.EditBox, bEnable)
end

function UITeamRecruitPublishView:PublishTeam(bSwitchServer)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk")then
        return
    end

    if not self.tbCheckedMenu then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REMIND_SELECT)
        return
    end

    local dwApplyID = self.tbCheckedMenu.UserData[1]
    local hPlayer = GetClientPlayer()
    local tInfo = Table_GetTeamInfo(dwApplyID)
	local dwMinLevel = tInfo.dwMinLevel
	local nLevel = hPlayer.nLevel
	if nLevel < dwMinLevel then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MIN_LEVEL_LIMIT)
		return
	end

    local bFinish, tAchi = CheckPushAchievement(tInfo.szAchievementRequire)
	if not bFinish then
		local tMsg = {}
		for k, v in ipairs(tAchi) do
			local szName = Table_GetAchievementName(v)
			local szAchi = "[" .. UIHelper.GBKToUTF8(szName) .. "]"
			table.insert(tMsg, szAchi)
		end
		local szMsg = FormatString(g_tStrings.STR_TEAMBUILD_ACHIEVEMENT_LIMIT, table.concat(tMsg, g_tStrings.STR_OR))
		OutputMessage("MSG_SYS", szMsg)
		OutputMessage("MSG_ANNOUNCE_RED", szMsg)
		return
	end

    if bSwitchServer then
		if RoomData.IsHaveRoom() then
			if not RoomData.IsRoomOwner() then
				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_TEAM_BUILDING_ROOM_LIMIT)
				return
			end
		else
            UIHelper.ShowConfirm(g_tStrings.STR_TEAM_BUILDING_ROOM_LIMIT_1, function()
                RoomData.CreateRoom()
            end)
			return
		end
	end


    local nFlag = 0
    if UIHelper.GetSelected(self.TogSelectBg01) then
        nFlag = 1
    end
    local nCheckTong = 0
    if UIHelper.GetSelected(self.TogSelectBg02) then
        nCheckTong = 1
    end
    local pszComment = UIHelper.UTF8ToGBK(UIHelper.GetString(self.EditBox))
    if pszComment == "" then
        pszComment = UIHelper.UTF8ToGBK(self.EditBox:getPlaceHolder())
    end
    TeamBuilding.RegisterTeamPushInfo(dwApplyID, nFlag, nCheckTong, pszComment, bSwitchServer)
    UIMgr.Close(self)
end

return UITeamRecruitPublishView