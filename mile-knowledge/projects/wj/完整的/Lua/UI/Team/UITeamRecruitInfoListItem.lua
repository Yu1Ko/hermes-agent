-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitInfoListItem
-- Date: 2023-02-06 16:32:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamRecruitInfoListItem = class("UITeamRecruitInfoListItem")

local PERSON_LABEL_IMG = {
    [0] = "UIAtlas2_Team_Team1_Img_GongZhanTuanZhang.png",
    [1] = "UIAtlas2_Team_Team1_Img_GoodShiFu.png",
    [2] = "UIAtlas2_Team_Team1_Img_GoodBiaoShi.png",
    [3] = "UIAtlas2_Team_Team1_Img_QunLongZhiShou.png",
    [4] = "UIAtlas2_Team_Team1_Img_YiDaiJunShi.png",
    [5] = "UIAtlas2_Team_Team1_MingJianMingXia.png",
    [6] = "UIAtlas2_Team_Team1_Img_ShaChangHaoJie.png",
    [7] = "UIAtlas2_Team_Team1_Img_XiaZheRenXin.png",
}

function UITeamRecruitInfoListItem:OnEnter(tbRecruitInfo, bLocate)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bLocate = bLocate
    self.tbRecruitInfo = tbRecruitInfo
    self.widgetHead = nil
    self:UpdateInfo()
end

function UITeamRecruitInfoListItem:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.widgetHead then
        UIHelper.RemoveFromParent(self.widgetHead._rootNode)
        self.widgetHead = nil
    end
end

function UITeamRecruitInfoListItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnApplication, EventType.OnClick, function ()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end

		local dwApplyID = self.tbRecruitInfo["dwRoleID"]
        local szRoomID = self.tbRecruitInfo["szRoomID"]
        local szGlobalID = self.tbRecruitInfo["szGlobalID"]
        local bApply = TeamBuilding.IsApply(dwApplyID, szRoomID)

        if dwApplyID then
            if UI_GetClientPlayerID() == dwApplyID then
				TeamBuilding.UnregisterTeamPushInfo()
            elseif bApply then
                TeamBuilding.UnregisterApply(self.tbRecruitInfo)
			else
				TeamBuilding.ApplyTeam(self.tbRecruitInfo)
			end
        else
            if UI_GetClientPlayerGlobalID() == szGlobalID then
                TeamBuilding.UnregisterTeamPushInfo()
            elseif bApply then
                TeamBuilding.UnregisterApply(self.tbRecruitInfo)
            else
                TeamBuilding.ApplyTeam(self.tbRecruitInfo)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnCaptainInformation, EventType.OnClick, function ()
        Timer.AddFrame(self, 1, function ()
            self:OnClickHead()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local szComment, szRealComment = TeamBuilding.GetTeamPushComment(self.tbRecruitInfo)
        local szTips = string.format("<color=#FEFEFE>%s</color>",  szComment)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnDetail, szTips)
        -- local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        -- tips:SetSize(nTipsWidth, nTipsHeight)
        -- tips:UpdatePosByNode(self.BtnDetail)
    end)
end

function UITeamRecruitInfoListItem:RegEvent()
    Event.Reg(self, EventType.OnSyncPlayerApplyList, function ()
        self:UpdateButtonState()
    end)

    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function()
		if arg0 == ACTIVITY_ID.ALLOW_EDIT then
            local szComment, bCommentLimit = self:GetFirstLineComment()
            UIHelper.SetString(self.LabelTeamRemark, szComment)
            UIHelper.SetVisible(self.BtnDetail, bCommentLimit)
		end
    end)

    -- Event.Reg(self, "CREATE_GLOBAL_ROOM",  function()
    --     self:UpdateButtonState()
    -- end)

    -- Event.Reg(self, "JOIN_GLOBAL_ROOM", function()
    --     self:UpdateButtonState()
    -- end)

    -- Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
    --     self:UpdateButtonState()
    -- end)

    -- Event.Reg(self, "LEAVE_GLOBAL_ROOM", function()
    --     self:UpdateButtonState()
    -- end)

    -- Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
    --     self:UpdateButtonState()
    -- end)

    -- Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID)
    --     self:UpdateButtonState()
    -- end)

    -- Event.Reg(self, "PARTY_DISBAND", function ()
    --     self:UpdateButtonState()
    -- end)

    Event.Reg(self, EventType.OnRecruitUpdatePraise, function ()
        self:UpdatePraiseInfo()
    end)
end

function UITeamRecruitInfoListItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitInfoListItem:UpdateInfo()
    local dwID = self.tbRecruitInfo["dwActivityID"]
    local tbTeamInfo = Table_GetTeamInfo(dwID)
    UIHelper.SetString(self.LabelDungeonTitle, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tbTeamInfo.szName), 13))
    if not self.widgetHead then
        self.widgetHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetMemberHead)
    end
    self.widgetHead:SetHeadInfo(nil, self.tbRecruitInfo["dwMiniAvatarID"], self.tbRecruitInfo["nRoleType"], self.tbRecruitInfo["nForceID"])
    self.widgetHead:SetClickCallback(function ()
        -- self:OnClickHead()
    end)
    -- UIHelper.SetSpriteFrame(self.ImgIcon01, PlayerKungfuImg[self.tbRecruitInfo["dwMountKungfuID"]])
    PlayerData.SetMountKungfuIcon(self.ImgIcon01, self.tbRecruitInfo["dwMountKungfuID"], self.tbRecruitInfo["nClientVersionType"])
    UIHelper.SetVisible(self.WidgetCrossServer, self.tbRecruitInfo["szGlobalID"] ~= nil)

    local nCamp = self.tbRecruitInfo["nCamp"]
    CampData.SetUICampImg(self.ImgIcon02, nCamp)

    UIHelper.SetString(self.LabelTeamNum, self.tbRecruitInfo["nCurrentMemberCount"] .. "/" .. tbTeamInfo.dwMaxPlayerNum)
    UIHelper.SetString(self.LabelGrade, tbTeamInfo.dwMinLevel .. "级")
    UIHelper.SetString(self.LabelRoleName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(self.tbRecruitInfo["szName"]), 9))

    local szComment, bCommentLimit = self:GetFirstLineComment()
    UIHelper.SetString(self.LabelTeamRemark, szComment)
    UIHelper.SetVisible(self.BtnDetail, bCommentLimit)

    local dwCurrentTime = GetCurrentTime()
    local szTime = TeamBuilding.GetCreateTime(dwCurrentTime, self.tbRecruitInfo["nLastModifyTime"])
    UIHelper.SetString(self.LabelTime, szTime)
    UIHelper.SetVisible(self.ImgLocatedBg, self.bLocate)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutInfoRight, true, false)

    PlayerData.SetPlayerLogionSite(self.ImgLoginSite , self.tbRecruitInfo["nClientVersionType"])

    UIHelper.SetVisible(self.ImgTeachGroupMark, self.tbRecruitInfo["bIsTeachingTeam"])

    self:UpdateButtonState()
    self:UpdatePraiseInfo()
end

function UITeamRecruitInfoListItem:GetFirstLineComment()
    local szComment, szRealComment = TeamBuilding.GetTeamPushComment(self.tbRecruitInfo)
    local szFirstLine = string.match(szComment, "^[^\r\n]*")
    local bMultiline = string.find(szComment, "[\r\n]") ~= nil
    if bMultiline then
        szFirstLine = szFirstLine .. "..."
    end
    return UIHelper.LimitUtf8Len(szFirstLine, 19), bMultiline or UIHelper.GetUtf8Len(szFirstLine) > 19
end

function UITeamRecruitInfoListItem:UpdateButtonState()
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

    local tbRecruitInfo = self.tbRecruitInfo
    local dwApplyID = tbRecruitInfo["dwRoleID"]
    local szRoomID = tbRecruitInfo["szRoomID"]
    local szGlobalID = tbRecruitInfo["szGlobalID"]
    local bApply = TeamBuilding.IsApply(dwApplyID, szRoomID)
	local dwMyTeamID = GetClientTeam().dwTeamID
    local szMyRoomID = hPlayer.GetGlobalRoomID()
    local bRemote = IsRemotePlayer(UI_GetClientPlayerID())

    if hPlayer.dwID == dwApplyID then
        UIHelper.SetString(self.LabelApplication, "撤销")
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Normal)
        return
    end

    if UI_GetClientPlayerGlobalID() == szGlobalID then
        UIHelper.SetString(self.LabelApplication, "撤销")
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Normal)
        return
    end

    if bApply then
        UIHelper.SetString(self.LabelApplication, g_tStrings.STR_CANCEL_APPLY)
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Normal)
        return
    end

    if dwMyTeamID > 0 and not szRoomID then
        UIHelper.SetString(self.LabelApplication, g_tStrings.STR_APPLY)
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Disable)
        return
    end

    if szMyRoomID and szMyRoomID ~= "" and szRoomID then
        UIHelper.SetString(self.LabelApplication, g_tStrings.STR_APPLY)
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Disable)
        return
    end

    if self.tbRecruitInfo["bNeedTongMember"] then
        local bMember = GetTongClient().IsMember(dwApplyID)
		if not bMember then
            UIHelper.SetString(self.LabelApplication, g_tStrings.STR_APPLY)
            UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Disable)
            return
		end
    end

    UIHelper.SetString(self.LabelApplication, g_tStrings.STR_APPLY)
    UIHelper.SetButtonState(self.BtnApplication, bRemote and BTN_STATE.Disable or BTN_STATE.Normal)
end

function UITeamRecruitInfoListItem:UpdateMyselfApply(dwMyTeamID)
    local tbRecruitInfo = self.tbRecruitInfo
	local dwApplyID = tbRecruitInfo["dwRoleID"]
	local szRoomID = tbRecruitInfo["szRoomID"]

	local bApply = TeamBuilding.IsApply(dwApplyID, szRoomID)
    local bDisable = false

	if (type(dwMyTeamID) == "number" and dwMyTeamID > 0 or tbRecruitInfo["bNeedTongMember"]) then
		bDisable = true
	end

	if (type(dwMyTeamID) ~= "number") then
		bDisable = true
	end
    self:UpdateJoinBututon(bApply, bDisable)
end

function UITeamRecruitInfoListItem:UpdateJoinBututon(bApply, bDisable)
	if bApply then
		UIHelper.SetString(self.LabelApplication, g_tStrings.STR_APPLYED)
		bDisable = bDisable or true
	else
        UIHelper.SetString(self.LabelApplication, g_tStrings.STR_APPLY)
		bDisable = bDisable or false
	end

    if IsRemotePlayer(UI_GetClientPlayerID()) then
		bDisable = bDisable or true
	end
	UIHelper.SetButtonState(self.BtnApplication, bDisable and BTN_STATE.Disable or BTN_STATE.Normal)
end

function UITeamRecruitInfoListItem:UpdateJoinBututonState(hButton)
	local hImg = hButton:Lookup(0)
	if not hImg then
		return
	end

	if IsRemotePlayer(UI_GetClientPlayerID()) then
		hButton.bDisable = true
	end

	if hButton.bDisable then
		hImg:SetFrame(20)
	elseif hButton.bClick then
		hImg:SetFrame(19)
	elseif hButton.bOver then
		hImg:SetFrame(2)
	else
		hImg:SetFrame(0)
	end
end

function UITeamRecruitInfoListItem:UpdatePraiseInfo()
    UIHelper.SetVisible(self.WidgetColonel, false)

    local dwID = self.tbRecruitInfo["dwActivityID"]
    local tbTeamInfo = Table_GetTeamInfo(dwID)
    if not tbTeamInfo.nPraiseType then
       return
    end

    local nType = tbTeamInfo.nPraiseType
    local dwApplyID = self.tbRecruitInfo["dwRoleID"] or self.tbRecruitInfo["szGlobalID"]
    if TeamBuilding.tbPraise[dwApplyID] then
        local aCard
        local hfellow = GetSocialManagerClient()
		if self.tbRecruitInfo["dwRoleID"] then
			aCard = hfellow.GetSocialInfo(dwApplyID)
		else
			aCard = hfellow.GetFellowshipCardInfo(dwApplyID)
		end
        UIHelper.SetVisible(self.WidgetColonel, true)
        local nCount = aCard.Praiseinfo[nType] or 0
        if nCount == 0 then
            UIHelper.SetString(self.LabelColonelNum, 1)
        else
            UIHelper.SetString(self.LabelColonelNum, PersonLabel_GetLevel(nCount, nType))
        end
        UIHelper.SetSpriteFrame(self.ImgColonelIcon, PERSON_LABEL_IMG[nType])
    end
end

function UITeamRecruitInfoListItem:OnClickHead()
    local hPlayer = GetClientPlayer()
    local dwApplyID = self.tbRecruitInfo["dwRoleID"]
    local szRoomID = self.tbRecruitInfo["szRoomID"]
    local szGlobalID = self.tbRecruitInfo["szGlobalID"]

    if szRoomID then
        if UI_GetClientPlayerGlobalID() == szGlobalID then
            return
        end
    else
        if hPlayer.dwID == dwApplyID then
            return
        end
    end

    local bApply = TeamBuilding.IsApply(dwApplyID, szRoomID)
    local tbAllMenuConfig = {}
    if bApply then
        table.insert(tbAllMenuConfig, {
            szName = "取消申请",
            bCloseOnClick = true,
            callback = function()
                TeamBuilding.UnregisterApply(self.tbRecruitInfo)
            end
        })
    else
        table.insert(tbAllMenuConfig, {
            szName = "申请入队",
            bCloseOnClick = true,
            callback = function()
                TeamBuilding.ApplyTeam(self.tbRecruitInfo)
            end
        })
    end
    table.insert(tbAllMenuConfig, {
        szName = "队伍配置",
        bCloseOnClick = true,
        callback = function ()
            if szRoomID then
                GetGlobalRoomPushClient().ApplyRoomMemberForceID(self.tbRecruitInfo["szRoomID"])
            else
                ApplyTeamMemberForceID(dwApplyID)
            end
        end
    })
    table.insert(tbAllMenuConfig, {
        szName = "加为好友",
        bCloseOnClick = true,
        callback = function ()
            GetSocialManagerClient().AddFellowship(self.tbRecruitInfo["szName"])
        end
    })
    table.insert(tbAllMenuConfig, {
        szName = "密聊",
        bCloseOnClick = true,
        callback = function ()
            local szName = UIHelper.GBKToUTF8(self.tbRecruitInfo["szName"])
            local dwTalkerID = dwApplyID
            local dwForceID = self.tbRecruitInfo["nForceID"]
            local dwMiniAvatarID = self.tbRecruitInfo["dwMiniAvatarID"]
            local nRoleType = self.tbRecruitInfo["nRoleType"]
            local nLevel = self.tbRecruitInfo["nLevel"]
            local dwCenterID = self.tbRecruitInfo["dwCenterID"]
            local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}
            ChatHelper.WhisperTo(szName, tbData)
        end
    })

    if self.tbRecruitInfo and self.tbRecruitInfo["dwCenterID"] then
        local dwCenterID = self.tbRecruitInfo["dwCenterID"]
        local szCenterName = GetCenterNameByCenterID(dwCenterID) or UIHelper.UTF8ToGBK("未知")
        table.insert(tbAllMenuConfig, {
            szName = "查看区服", bNesting = true, tbSubMenus =
            {
                { szName = UIHelper.GBKToUTF8(szCenterName), bCloseOnClick = true,
                    fnDisable = function()
                        return true
                    end
                },
            },
        })
    end

    table.insert(tbAllMenuConfig, {
        szName = "查看装备",
        bCloseOnClick = true,
        callback = function()
            if szGlobalID then
                UIMgr.Open(VIEW_ID.PanelOtherPlayer, nil, self.tbRecruitInfo["dwCenterID"], szGlobalID)
            else
                UIMgr.Open(VIEW_ID.PanelOtherPlayer, dwApplyID)
            end
        end
    })

    if ActivityData.IsMsgEditAllowed() then
        table.insert(tbAllMenuConfig, {
            szName = "举报不良消息",
            CloseOnClick = true,
            callback = function()
                local dwID = self.tbRecruitInfo["dwActivityID"]
                local tbTeamInfo = Table_GetTeamInfo(dwID)
                local szTeamName = UIHelper.GBKToUTF8(tbTeamInfo.szName)
                local szMinLevel = tbTeamInfo.dwMinLevel
                local szFriendName = UIHelper.GBKToUTF8(self.tbRecruitInfo["szName"])
                local szComment, szRealComment = TeamBuilding.GetTeamPushComment(self.tbRecruitInfo)

                local ReportContent = FormatString(g_tStrings.STR_TEAMBUILD_EDIT_LINK, szTeamName) .. "\n" ..
                g_tStrings.STR_REPORT_LEVEL .. szMinLevel .. "\n" ..
                g_tStrings.STR_REPORT_CAPTAIN .. szFriendName .. "\n" ..
                g_tStrings.STR_REPORT_TEAM_PUSH .. szComment

                local reportView = UIMgr.Open(VIEW_ID.PanelReportPop)
                reportView:UpdateReportInfo(szFriendName, ReportContent, dwApplyID, nil, nil, szGlobalID)
            end
        })
    end

    table.insert(tbAllMenuConfig, {
        szName = "查看百战信息",
        CloseOnClick = true,
        callback = function()
            MonsterBookData.CheckMonsterBookInfo(dwApplyID, self.tbRecruitInfo["dwCenterID"], szGlobalID)
        end
    })

    local tbPlayerCard = {
        dwMiniAvatarID = self.tbRecruitInfo["dwMiniAvatarID"],
        nRoleType = self.tbRecruitInfo["nRoleType"],
        nForceID = self.tbRecruitInfo["nForceID"],
        nLevel = self.tbRecruitInfo["nLevel"],
        szName = self.tbRecruitInfo["szName"],
        nCamp = self.tbRecruitInfo["nCamp"],
    }
    local prefabID = PREFAB_ID.WidgetPlayerPop
    local tips, _ = TipsHelper.ShowNodeHoverTips(prefabID, self.WidgetMemberHead, nil, tbAllMenuConfig, tbPlayerCard)
end

return UITeamRecruitInfoListItem