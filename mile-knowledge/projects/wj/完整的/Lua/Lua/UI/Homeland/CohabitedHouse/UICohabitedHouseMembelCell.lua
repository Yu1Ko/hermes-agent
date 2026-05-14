-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICohabitedHouseMembelCell
-- Date: 2023-07-19 16:38:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICohabitedHouseMembelCell = class("UICohabitedHouseMembelCell")

function UICohabitedHouseMembelCell:OnEnter(tbInfo, szLandID, bIsLandlordMyself, szKickOutLeftTime)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szLandID = szLandID
    self.szKickOutLeftTime = szKickOutLeftTime
    self.bIsLandlordMyself = bIsLandlordMyself
    self.tbInfo = tbInfo
    self:UpdateInfo()

    self.nDwellerCallUpCount = 0
end

function UICohabitedHouseMembelCell:OnExit()
    self.bInit = false
end

function UICohabitedHouseMembelCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSecretChat, EventType.OnClick, function ()
        local szName = UIHelper.GBKToUTF8(self.tbInfo.Name)
        local dwForceID = self.tbInfo.ForceID
        local dwMiniAvatarID = self.tbInfo.MiniAvatarID
        local nRoleType = self.tbInfo.Type
        local szGlobalID = self.tbInfo.szGlobalID
        local tbData = {szName = szName, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, szGlobalID = szGlobalID}

        ChatHelper.WhisperTo(szName, tbData)
    end)

    UIHelper.BindUIEvent(self.BtnGroup, EventType.OnClick, function ()
        TipsHelper.ShowNormalTip("已发送组队申请")
        TeamData.InviteJoinTeam(self.tbInfo.Name)
    end)

    UIHelper.BindUIEvent(self.BtnInvite, EventType.OnClick, function ()
        if self.nDwellerCallUpCount > 0 then
			RemoteCallToServer("On_HomeLand_CallUpApply", self.tbInfo.Name)
		else
            UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_COHABIT_CALL_COMFIRM, function ()
                RemoteCallToServer("On_HomeLand_CallUpApply", self.tbInfo.Name)
            end)
		end
    end)

    UIHelper.BindUIEvent(self.BtnStop, EventType.OnClick, function ()
        if not self.tbInfo.PlayerID then return end

        local dwMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.szLandID)

        UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_COHABIT_TERMINATE_CONFIRM_MESSAGE_22, function ()
            if not BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
                GetHomelandMgr().LandKickOutAllied(dwMapID, nCopyIndex, nLandIndex, self.tbInfo.PlayerID, false)
            end
        end, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnCancelStop, EventType.OnClick, function ()
        if not self.tbInfo.PlayerID then return end

        local dwMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.szLandID)

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
            return
        end
        GetHomelandMgr().LandKickOutAllied(dwMapID, nCopyIndex, nLandIndex, self.tbInfo.PlayerID, true)
    end)
end

function UICohabitedHouseMembelCell:RegEvent()
    Event.Reg(self, "On_HL_GetDwellerCallUpCount", function (nCount)
        self.nDwellerCallUpCount = nCount
        UIHelper.SetString(self.LabelInviteNum, math.max(0, nCount))
    end)
end

function UICohabitedHouseMembelCell:UpdateInfo()
    local bNotData = not self.tbInfo
    UIHelper.SetVisible(self.ImgTagBg, false)
    UIHelper.SetVisible(self.WidgetFriendInfo, not bNotData)
    UIHelper.SetVisible(self.BtnSecretChat, not bNotData)
    UIHelper.SetVisible(self.BtnGroup, not bNotData)
    UIHelper.SetVisible(self.BtnInvite, not bNotData)
    UIHelper.SetVisible(self.ImgFriendButton, not bNotData)
    UIHelper.SetVisible(self.LabelNotAcquired, bNotData)
    UIHelper.SetVisible(self.WidgetHead, not bNotData)
    UIHelper.SetVisible(self.LabelEndTime, false)
    UIHelper.SetVisible(self.WidgetStop, false)
    UIHelper.LayoutDoLayout(self.LayoutFriendInfo)

    if bNotData then return end

    UIHelper.SetVisible(self.ImgTagBg, self.tbInfo.JoinTime == nil)
    UIHelper.SetString(self.LabelRoleName, UIHelper.GBKToUTF8(self.tbInfo.Name), 8)
    if self.tbInfo.LastSaveTime == 0 then
        UIHelper.SetRichText(self.RichTextRoleCondition, string.format("<color=#e2f6fb>%s</c><color=#5ae3a2>%s</c>", g_tStrings.STR_HOMELAND_DWELLER_ONLINE_STATUS_TITLE_1, g_tStrings.STR_HOMELAND_DWELLER_IN_ONLINE_STATUS))
    else
        UIHelper.SetRichText(self.RichTextRoleCondition, string.format("<color=#e2f6fb>%s</c><color=#5ae3a2>%s</c>", g_tStrings.STR_HOMELAND_DWELLER_ONLINE_STATUS_TITLE_2, self:GetStringLastOnlineTime(self.tbInfo.LastSaveTime)))
    end

    if self.tbInfo.JoinTime then
        UIHelper.SetString(self.LabelRoleTime, string.format("入住时间：%s", self:GetStringMoveInDate(self.tbInfo.JoinTime)))
    else
        UIHelper.SetString(self.LabelRoleTime, "入住时间：暂无")
    end

    self.scriptHead = self.scriptHead or UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHead, self.tbInfo.PlayerID or PlayerData.GetPlayerID())
    self.scriptHead:SetHeadInfo(0, self.tbInfo.MiniAvatarID, self.tbInfo.Type, self.tbInfo.ForceID)
    UIHelper.SetTouchEnabled(self.scriptHead.BtnHead, false)

    local szMyName = PlayerData.GetPlayerName()
    local bIsMy = UIHelper.GBKToUTF8(self.tbInfo.Name) == UIHelper.GBKToUTF8(szMyName)
    UIHelper.SetVisible(self.ImgFriendButton, not bIsMy)

    if self.tbInfo.KickOutTime and self.tbInfo.KickOutTime > 0 then
        UIHelper.SetVisible(self.LabelEndTime, true)
        UIHelper.SetVisible(self.WidgetStop, bIsMy or self.bIsLandlordMyself)
        if bIsMy or self.bIsLandlordMyself then
            if self.tbInfo.KickOutDrawer then
                UIHelper.SetVisible(self.BtnStop, true)
                UIHelper.SetVisible(self.BtnCancelStop, false)
                UIHelper.SetRichText(self.LabelEndTime, string.format("<color=#d7f6ff>正退出共居，</c><color=#ffe26e>%s后将终止共居状态</c>", self.szKickOutLeftTime))
            else
                UIHelper.SetVisible(self.BtnStop, false)
                UIHelper.SetVisible(self.BtnCancelStop, true)
                UIHelper.SetRichText(self.LabelEndTime, string.format("<color=#d7f6ff>正在请门客离开，</c><color=#ffe26e>%s后或门客同意将生效</c>", self.szKickOutLeftTime))
            end
        else
            UIHelper.SetRichText(self.LabelEndTime, "<color=#d7f6ff>正与屋主终止共居状态</c>")
        end
    else
        UIHelper.SetVisible(self.LabelEndTime, false)
        UIHelper.SetVisible(self.WidgetStop, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutAll)
    UIHelper.LayoutDoLayout(self.LayoutFriendInfo)
end

function UICohabitedHouseMembelCell:GetStringLastOnlineTime(dwLastOnlineTime)
	if dwLastOnlineTime == 0 then
		return g_tStrings.STR_HOMELAND_DWELLER_LAST_ONLINE_TIME_UNKNOWN
	end
	local szTime = ""
	local nDelta = GetCurrentTime() - dwLastOnlineTime
	if nDelta < 0 then
		nDelta = 0
	end

	local nYears = math.floor(nDelta / (3600 * 24 * 365))
	if nYears > 0 then
		szTime = FormatString(g_tStrings.STR_HOMELAND_DWELLER_LAST_ONLINE_TIME_YEARS_AGO, nYears)
	else
		local nDays = math.floor(nDelta / (3600 * 24))
		if nDays > 0 then
			szTime = FormatString(g_tStrings.STR_HOMELAND_DWELLER_LAST_ONLINE_TIME_DAYS_AGO, nDays)
		else
			local nHours = math.floor(nDelta / 3600)
			if nHours > 0 then
				szTime = FormatString(g_tStrings.STR_HOMELAND_DWELLER_LAST_ONLINE_TIME_HOURS_AGO, nHours)
			else
				szTime = g_tStrings.STR_HOMELAND_DWELLER_LAST_ONLINE_LESS_THAN_ONE_HOUR_AGO
			end
		end
	end
	return szTime
end

function UICohabitedHouseMembelCell:GetStringMoveInDate(dwTimeStamp)
	local tTime = TimeToDate(dwTimeStamp)
	local szText = tTime.year .. "." .. tTime.month .. "." .. tTime.day
	return szText
end

function UICohabitedHouseMembelCell:SetUnloclDesc(szUnloclDesc)
	UIHelper.SetString(self.LabelNotAcquired, szUnloclDesc)
end

return UICohabitedHouseMembelCell