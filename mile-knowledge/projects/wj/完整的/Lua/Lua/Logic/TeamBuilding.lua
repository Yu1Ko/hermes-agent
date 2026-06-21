-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TeamBuilding
-- Date: 2023-02-07 10:16:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local FRESH_MEN_BUFF 	= 3219
local FRESH_MEN_LEVEL 	= 10
local TEACH_LEADER = 643	--引路人称号

TEAMBUILD_PANEL_APPLY   = 2

TeamBuilding = TeamBuilding or {className = "TeamBuilding"}
local self = TeamBuilding

TeamBuilding.tbTagIDs = {}
TeamBuilding.tbPraise = {}
TeamBuilding.szMySelfRoomID = nil 	--我发布的跨服招募房间ID
TeamBuilding.nMySelfRoleID  = nil	--我发布的本服招募
TeamBuilding.tbSelfRecruitInfo = {}	--我发布的招募信息
TeamBuilding.tbAppliedPlayerList = {}
TeamBuilding.bLocalServer 	= nil	--是否要显示本服招募List
TeamBuilding.bSwitchServer 	= nil	--是否要显示跨服招募List
TeamBuilding.bCheckAll 		= nil
TeamBuilding.tbMyApply		= nil	--自己已申请的本服招募
TeamBuilding.tbMyApplyRoom	= nil   --自己已申请的跨服招募
TeamBuilding.bFilterTeachTeam = false

local m_nApplyDst = nil

-- ApplyTeamList 我申请的人
-- SyncPlayerApplyList 申请我的人

-------------------------------- 消息定义 --------------------------------
TeamBuilding.Event = {}
TeamBuilding.Event.XXX = "TeamBuilding.Msg.XXX"
local _REQUIRED_PLAYER_LEVEL = 18

function TeamBuilding.Init()
end

function TeamBuilding.UnInit()
	Timer.DelAllTimer(self)
end

function TeamBuilding.OnLogin()
end

function TeamBuilding.OnFirstLoadEnd()
end

------------------------招募相关--------------------------
-- 我申请的
function TeamBuilding.OnApplyInfo(fnLocalApply, fnServerApply)
	if not IsRemotePlayer(UI_GetClientPlayerID()) then
		fnLocalApply()
	end

	fnServerApply()
end

-- 申请我的
function TeamBuilding.OnApplyList()
	if TeamBuilding.szMySelfRoomID then
		GetGlobalRoomPushClient().SyncRoomPushPlayerApplyList()
	end

	if TeamBuilding.nMySelfRoleID then
		SyncPlayerApplyList()
	end
end

function TeamBuilding.OnApplyMyPushList()
	if TeamBuilding.szMySelfRoomID then
		GetGlobalRoomPushClient().ApplyRoomPushSingle(TeamBuilding.szMySelfRoomID)
	end

	if TeamBuilding.nMySelfRoleID then
		ApplyTeamPushSingle(TeamBuilding.nMySelfRoleID)
	end
end

function TeamBuilding.OnGetAppliedList()
	local tList
	if TeamBuilding.szMySelfRoomID then
		tList = GetGlobalRoomPushClient().GetRoomPushApplyPlayerList()
	end

	if not IsRemotePlayer(UI_GetClientPlayerID()) and TeamBuilding.nMySelfRoleID then
		tList = GetApplyPlayerList()
	end
	return tList
end

function TeamBuilding.OnReceiveTeamInfo()
	if arg0 == "all" then
		if m_nApplyDst then
			TeamBuilding.tbFoundRecruitList = GetTeamPushList(m_nApplyDst)
		else
			TeamBuilding.tbFoundRecruitList = GetTeamPushList()
		end
	elseif arg0 == "single" then
		local dwRoleID = UI_GetClientPlayerID()
		if arg1 == dwRoleID and not IsRemotePlayer(dwRoleID) then
			local tList = GetTeamPushInfoSingle(dwRoleID)
			if tList and tList.dwRoleID == dwRoleID then
				TeamBuilding.szMySelfRoomID = nil
				TeamBuilding.nMySelfRoleID = dwRoleID
				TeamBuilding.tbSelfRecruitInfo = tList
			else
				if TeamBuilding.nMySelfRoleID then
					TeamBuilding.nMySelfRoleID = nil
					TeamBuilding.tbSelfRecruitInfo = {}
					TeamBuilding.tbAppliedPlayerList = {}
				end
			end
		end
	end

	TeamBuilding.CheckTalkToWolrd()
	if table_is_empty(TeamBuilding.tbSelfRecruitInfo) then
		TeamBuilding.SetApplyCount(0)
	end
	Event.Dispatch(EventType.OnRecruitPushTeam)
end

--获取所有跨服的队伍招募信息
function TeamBuilding.OnReceiveServerTeamInfo()
	if arg0 == "all" then
		if m_nApplyDst then
			TeamBuilding.tbSwitchServerList = GetGlobalRoomPushClient().GetRoomPushList(m_nApplyDst)
		else
			TeamBuilding.tbSwitchServerList = GetGlobalRoomPushClient().GetRoomPushList()
		end
	elseif arg0 == "single" then
		local hPlayer = GetClientPlayer()
		if not hPlayer then
			return
		end
		local szGlobalRoomID = hPlayer.GetGlobalRoomID()
		if szGlobalRoomID and arg1 == szGlobalRoomID then
			local tList = GetGlobalRoomPushClient().GetRoomPushInfoSingle(szGlobalRoomID)
			if tList and tList.szGlobalID == hPlayer.GetGlobalID() then
				TeamBuilding.tbSelfRecruitInfo = tList
				TeamBuilding.szMySelfRoomID = szGlobalRoomID
				TeamBuilding.nMySelfRoleID = nil
			else
				if TeamBuilding.szMySelfRoomID then
					TeamBuilding.szMySelfRoomID = nil
					TeamBuilding.tbSelfRecruitInfo = {}
					TeamBuilding.tbAppliedPlayerList = {}
				end
			end
		end
		if not szGlobalRoomID then
			if TeamBuilding.szMySelfRoomID then
				TeamBuilding.szMySelfRoomID = nil
				TeamBuilding.tbSelfRecruitInfo = {}
				TeamBuilding.tbAppliedPlayerList = {}
			end
		end
	end

	TeamBuilding.CheckTalkToWolrd()
	if table_is_empty(TeamBuilding.tbSelfRecruitInfo) then
		TeamBuilding.SetApplyCount(0)
	end
	Event.Dispatch(EventType.OnRecruitPushTeam)
end

function TeamBuilding.CleanMyselfPush()
	TeamBuilding.tbSelfRecruitInfo = {}
end

function TeamBuilding.CheckTalkToWolrd()
	TeamBuilding.tbSelfRecruitInfo = TeamBuilding.tbSelfRecruitInfo or {}
	if TeamBuilding.bPushSuccess and not table_is_empty(TeamBuilding.tbSelfRecruitInfo) then
		TeamBuilding.Share(true)
		TeamBuilding.bPushSuccess = false
	end
end

function TeamBuilding.Share(bDirectWorld)
	TeamBuilding.tbSelfRecruitInfo = TeamBuilding.tbSelfRecruitInfo or {}
	if not table_is_empty(TeamBuilding.tbSelfRecruitInfo) then
		local tbSelfRecruitInfo = TeamBuilding.tbSelfRecruitInfo
		local bRoom = tbSelfRecruitInfo.szRoomID ~= nil
		local dwID = tbSelfRecruitInfo.dwActivityID
		local szCommentUTF8 = TeamBuilding.GetTeamPushComment(tbSelfRecruitInfo)
		if bRoom then
			ChatHelper.SendRoomBuildToChat(dwID, tbSelfRecruitInfo.szRoomID, UIHelper.UTF8ToGBK(szCommentUTF8), bDirectWorld)
		else
			ChatHelper.SendTeamBuildToChat(dwID, UIHelper.UTF8ToGBK(szCommentUTF8), bDirectWorld)
		end
	end
end

function TeamBuilding.LocateApply(dwLocateApplyID)
	if UIMgr.IsViewOpened(VIEW_ID.PanelTeam) then
		Event.Dispatch(EventType.OnRecruitLocate, dwLocateApplyID)
	else
		UIMgr.Open(VIEW_ID.PanelTeam, 1, dwLocateApplyID)
	end
end

--获取向我队伍申请的人
function TeamBuilding.OnSyncPlayerList()
	TeamBuilding.tbAppliedPlayerList = TeamBuilding.OnGetAppliedList()
	Event.Dispatch(EventType.OnSyncApplyPlayerList)

	TeamBuilding.SetApplyCount(0)
end

--获取 我申请的队伍
function TeamBuilding.OnSyncSelfApplyTeamList()
	TeamBuilding.tbMyApply = GetPlayerApplyTeamList()
	Event.Dispatch(EventType.OnSyncPlayerApplyList)
end

--获取 我跨服申请的队伍
function TeamBuilding.OnSyncSelfApplyRoomTeamList()
	TeamBuilding.tbMyApplyRoom = GetGlobalRoomPushClient().GetPlayerApplyRoomPushList()
	Event.Dispatch(EventType.OnSyncPlayerApplyList)
end

function TeamBuilding.OnUpdateFellowShipCard()
	for _, id in pairs(arg0) do
		TeamBuilding.tbPraise[id] = 1
	end
	Event.Dispatch(EventType.OnRecruitUpdatePraise)
end

function TeamBuilding.SetApplyDst(nApplyDst)
	if type(nApplyDst) == "number" then
		nApplyDst = {nApplyDst}
	end
	m_nApplyDst = nApplyDst
end

--获取招募列表
function TeamBuilding.OnApplyTeamList()
	if not IsRemotePlayer(UI_GetClientPlayerID()) and TeamBuilding.bLocalServer then
		if m_nApplyDst then
			ApplyTeamPushList(m_nApplyDst)
		else
			ApplyTeamPushList()
		end
	end

	if TeamBuilding.bSwitchServer then
		if m_nApplyDst then
			GetGlobalRoomPushClient().ApplyRoomPushList(m_nApplyDst)
		else
			GetGlobalRoomPushClient().ApplyRoomPushList()
		end
	end
end

function TeamBuilding.GetRequiredPlayerLevel()
	return _REQUIRED_PLAYER_LEVEL
end

function TeamBuilding.GetStringCharCount(str, topCharNum)
    local lenInByte = #str
    local charCount = 0
    local i = 1
    local szTopChars = ""
    while (i <= lenInByte)
    do
        local curByte = string.byte(str, i)
        local byteCount = 1;
        if curByte > 0 and curByte <= 127 then
            byteCount = 1                                               --1字节字符
        elseif curByte >= 192 and curByte < 223 then
            byteCount = 2                                               --双字节字符
        elseif curByte >= 224 and curByte < 239 then
            byteCount = 3                                               --汉字
        elseif curByte >= 240 and curByte <= 247 then
            byteCount = 4                                               --4字节字符
        end

        local char = string.sub(str, i, i + byteCount - 1)
        if not topCharNum or charCount<topCharNum then
            szTopChars = szTopChars..char
        end
        i = i + byteCount                                               -- 重置下一字节的索引
        charCount = charCount + 1                                       -- 字符的个数（长度）
    end
    return charCount, szTopChars
end

function TeamBuilding.IsSafeLockTalkUnlocked()
	return not BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.TALK)
end

function TeamBuilding.IsEditingCommentEnabled()
	return ActivityData.IsMsgEditAllowed() and TeamBuilding.IsSafeLockTalkUnlocked()
end

function TeamBuilding.GetTagTextFromID(nTagID)
	local aTags = g_tStrings.tTeamBuildRecruitMsgAllGroupTags[1].Tags
	if nTagID > aTags[#aTags].id then
		aTags = g_tStrings.tTeamBuildRecruitMsgAllGroupTags[2].Tags
	end

	for k, v in ipairs(aTags) do
		if v.id == nTagID then
			return v.text
		end
	end

	return ""
end

function TeamBuilding.GetTeamPushComment(tbTeamPushInfo)
	local szComment = ""
	local szRealComment
	local tbLabelIDTable = tbTeamPushInfo.tLabelIDTable
	if type(tbLabelIDTable) ~= "table" or IsTableEmpty(tbLabelIDTable) then
		szRealComment = UIHelper.GBKToUTF8(tbTeamPushInfo.szComment)
		--szComment = IsMsgEditAllowed() and szRealComment or ""
		szComment = ActivityData.IsMsgEditAllowed() and szRealComment or ""
	else
		for k, nTagID in ipairs(tbLabelIDTable) do
			local szTag = TeamBuilding.GetTagTextFromID(nTagID)
			if szComment ~= "" then
				szComment = szComment .. g_tStrings.STR_ONE_CHINESE_SPACE
			end
			szComment = szComment .. szTag
		end
		szRealComment = nil
	end

	return szComment, szRealComment
end

local function GetTimeToHourMinuteSecond(nTime)
	local nHour   = math.floor(nTime / 3600)
	nTime = nTime - nHour * 3600
	local nMinute = math.floor(nTime / 60)
	nTime = nTime - nMinute * 60
	local nSecond = math.floor(nTime)
	return nHour, nMinute, nSecond
end

function TeamBuilding.GetCreateTime(dwCurrentTime, nCreateTime)
	local dwLeft = dwCurrentTime - nCreateTime
	if dwLeft < 0 then
		dwLeft = 0
	end
	local nH, nM, nS = GetTimeToHourMinuteSecond(dwLeft)
	local szTime
	if nH > 0 then
		szTime = nH..g_tStrings.STR_BUFF_H_TIME_H
	elseif nM > 0 then
		szTime = nM..g_tStrings.STR_BUFF_H_TIME_M
	elseif nS >= 0 then
		szTime = nS..g_tStrings.STR_BUFF_H_TIME_S
	end
	szTime = szTime .. g_tStrings.STR_QIAN
	return szTime
end

function TeamBuilding.IsApply(dwID, szRoomID)
	return TeamBuilding.IsApplyLocal(dwID) or TeamBuilding.IsApplyRoom(szRoomID)
end

function TeamBuilding.IsApplyLocal(dwID)
	local tbMyApply = TeamBuilding.tbMyApply
	for k , v in pairs(tbMyApply) do
		if v == dwID then
			return true
		end
	end
	return false
end

function TeamBuilding.IsApplyRoom(szRoomID)
	if not szRoomID then
		return
	end
	local tMyApply = TeamBuilding.tbMyApplyRoom
	for k , v in pairs(tMyApply) do
		if v == szRoomID then
			return true
		end
	end
	return false
end


function TeamBuilding.GetSelfTeamRecruitInfo()
	local dwID = GetClientPlayer().dwID
	local hTeam = GetClientTeam()
	local dwTeamID = hTeam.dwTeamID

	local dwSearchID = 0
	if dwTeamID == 0 then
		dwSearchID = dwID
	elseif dwTeamID > 0 then
		if dwID == hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) then
			dwSearchID = dwID
		end
	end

	local tbAllRecruitList = TeamBuilding.GetAllRecruitList()
	for k, tbRecruitInfo in ipairs(tbAllRecruitList) do
		if tbRecruitInfo.dwRoleID == dwSearchID then
			return tbRecruitInfo
		end
	end

	return {}
end

function TeamBuilding.ApplyLeaderPraise(tbRecruitList, nStart, nEnd)
	local tRetLocal = {}
	local tRetServer = {}

	local hFellow = GetSocialManagerClient()
	for i = nStart, nEnd do
		local v = tbRecruitList[i]
		local dwRoleID = v["dwRoleID"]
		local szGlobalID = v["szGlobalID"]
		if dwRoleID then
			if not TeamBuilding.tbPraise[dwRoleID] then
				local aCard = hFellow.GetSocialInfo(dwRoleID)
				if aCard then
					TeamBuilding.tbPraise[dwRoleID] = true
				else
					table.insert(tRetLocal, dwRoleID)
				end
			end
		elseif szGlobalID then
			if not TeamBuilding.tbPraise[szGlobalID] then
				local aCard = hFellow.GetFellowshipCardInfo(szGlobalID)
				if aCard then
					TeamBuilding.tbPraise[szGlobalID] = true
				else
					table.insert(tRetServer, szGlobalID)
				end
			end
		end
	end

	if not IsTableEmpty(tRetLocal) then
		hFellow.ApplySocialInfo(tRetLocal)
	end

	if not IsTableEmpty(tRetServer) then
		hFellow.ApplyFellowshipCard(tRetServer)
	end
end

function TeamBuilding.HasBuff()
	local hBuff = Table_GetTeamSpecialBuff()
	local dwBuffID, dwBuffLevel = hBuff.dwBuffID, hBuff.dwBuffLevel

	local hPlayer = GetClientPlayer()
    return hPlayer.IsHaveBuff(dwBuffID, dwBuffLevel) and 1 or 0
end

function TeamBuilding.ApplyTeam(tbRecruitInfo)
	if TeamData.CheckInSingleFB(true) then
		return
	end
	local dwApplyID = tbRecruitInfo["dwRoleID"]
	local szRoomID = tbRecruitInfo["szRoomID"]
	local nFlag = tbRecruitInfo["nFlag"]
	if nFlag then
		if nFlag % 2 == 0 then
			local hPlayer = GetClientPlayer()
			local hKungfu = hPlayer.GetActualKungfuMount() or {}
			local dwKungfuID = hKungfu.dwSkillID or 0

			local dwHDKungfuID = TabHelper.GetHDKungfuID(dwKungfuID)
			local nMask = Table_GetTeamPosition_KungFu(dwHDKungfuID)

			local nHas = TeamBuilding.HasBuff()
			if szRoomID then
				GetGlobalRoomPushClient().RegisterRoomPushApply(szRoomID, nMask, nHas, "")
			else
				RegisterApply(dwApplyID, nMask, nHas, "")
			end
		elseif nFlag % 2 == 1 then
			TeamBuilding.ShowJoinPlane(tbRecruitInfo)
		end
	end
end

function TeamBuilding.UnregisterApply(tbRecruitInfo)
	local dwApplyID = tbRecruitInfo["dwRoleID"]
	local szRoomID = tbRecruitInfo["szRoomID"]
	if szRoomID then
		GetGlobalRoomPushClient().UnRegisterRoomPushApply(szRoomID)
	else
		UnregisterApply(dwApplyID)
	end
	-- TeamBuilding.OnApplyInfo(ApplyTeamList, GetGlobalRoomPushClient().SyncPlayerApplyRoomPushList)
	for k, v in pairs(TeamBuilding.tbMyApply) do
		if dwApplyID and v == dwApplyID then
			TeamBuilding.tbMyApply[k] = nil
			break
		end
	end

	for k, v in pairs(TeamBuilding.tbMyApplyRoom) do
		if szRoomID and v == szRoomID then
			TeamBuilding.tbMyApplyRoom[k] = nil
			break
		end
	end

	Event.Dispatch(EventType.OnSyncPlayerApplyList)
end

function TeamBuilding.ShowJoinPlane(tbRecruitInfo)
    UIMgr.Open(VIEW_ID.PanelApplicationPop, tbRecruitInfo)
end

local function RemoveAppliedList(bServer, dwApplySrc)
	local tbAppliedPlayerList = TeamBuilding.tbAppliedPlayerList
	for k, tbPlayerInfo in pairs(tbAppliedPlayerList) do
		if (bServer and tbPlayerInfo["szGlobalID"] == dwApplySrc) or
			(not bServer and tbPlayerInfo["dwRoleID"] == dwApplySrc) then
			table.remove(TeamBuilding.tbAppliedPlayerList, k)
			break
		end
	end
end

function TeamBuilding.RespondTeamApply(tbPlayerInfo, nAgree)
	local dwApplySrc = tbPlayerInfo["dwRoleID"]
	local szGlobalID = tbPlayerInfo.szGlobalID
	if szGlobalID then
		GetGlobalRoomPushClient().RespondRoomPushApply(szGlobalID, nAgree) -- 同意1, 拒绝0
		RemoveAppliedList(true, szGlobalID)
	else
		RespondTeamApply(dwApplySrc, nAgree) -- 同意1, 拒绝0
		RemoveAppliedList(false, dwApplySrc)
	end
end

function TeamBuilding.GetAllRecruitList()
	return TeamBuilding.tbFoundRecruitList or {}
end

function TeamBuilding.GetAllSwitchServerList()
	return TeamBuilding.tbSwitchServerList or {}
end

function TeamBuilding.GetAllList()
	return table.AddRange(TeamBuilding.GetAllRecruitList(), TeamBuilding.GetAllSwitchServerList())
end

local function IncludeID(tList, dwID)
	for k, v in ipairs(tList) do
		if v == dwID then
			return true
		end
	end
	return false
end

function TeamBuilding.SortByPlayerNumber(tList, bDescend)
	if bDescend == 1 then
		table.sort(tList, function(a, b) return a.nCurrentMemberCount < b.nCurrentMemberCount end)
	elseif bDescend == 0 then
		table.sort(tList, function(a, b) return a.nCurrentMemberCount > b.nCurrentMemberCount end)
	end
end

function TeamBuilding.SortByCreateTime(tList, bDescend)
	if bDescend == 1 then
		table.sort(tList, function(a, b) return a.nLastModifyTime > b.nLastModifyTime end)
	elseif bDescend == 0 then
		table.sort(tList, function(a, b) return a.nLastModifyTime < b.nLastModifyTime end)
	end
end

local function MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false
	end

	return true
end

function TeamBuilding.GetFilteredRecruitList(szSearch, dwSearchID)
    local tbResList = {}

    local tbAllRecruitList = {}

	if TeamBuilding.bLocalServer and TeamBuilding.bSwitchServer then
		tbAllRecruitList = TeamBuilding.GetAllList()
	elseif TeamBuilding.bLocalServer then
		tbAllRecruitList = TeamBuilding.GetAllRecruitList()
	elseif TeamBuilding.bSwitchServer then
		tbAllRecruitList = TeamBuilding.GetAllSwitchServerList()
	end

	for k, tbRecruitInfo in ipairs(tbAllRecruitList) do
		local dwID = tbRecruitInfo["dwActivityID"]
		local tbInfo = Table_GetTeamInfo(dwID)
		local bIsTeachingTeam = tbRecruitInfo["bIsTeachingTeam"]
        local bShow = true
		local bBlocked = false
		if not tbInfo then
			bShow = false
        elseif szSearch and szSearch ~= "" then
			local szText
			if not m_nApplyDst then
				local szActivityName = tbInfo.szName
				szText = UIHelper.GBKToUTF8(szActivityName) .. UIHelper.GBKToUTF8(tbRecruitInfo.szName) .. (TeamBuilding.GetTeamPushComment(tbRecruitInfo))
			else
				szText = UIHelper.GBKToUTF8(tbRecruitInfo.szName) .. (TeamBuilding.GetTeamPushComment(tbRecruitInfo))
			end
			if not MatchString(szText, szSearch) then
				bShow = false
			end
		end

		if TeamBuilding.bFilterTeachTeam and not bIsTeachingTeam then
			bShow = false
		end

		if dwSearchID and ((type(dwSearchID) == "number" and dwSearchID ~= dwID) or (type(dwSearchID) == "table" and not IncludeID(dwSearchID, dwID))) then
			bShow = false
        end

		bShow = bShow and TeamBuilding.CanShowTeam(tbInfo["nCamp"], tbRecruitInfo["nCamp"])

		if bShow and tbInfo then
			local szGlobalID = tbRecruitInfo["szGlobalID"]
			local dwRoleID = tbRecruitInfo["dwRoleID"]
			local bCross = szGlobalID ~= nil
			local bIsMineRecruit = bCross and APIHelper.IsSelfByGlobalID(szGlobalID) or APIHelper.IsSelf(dwRoleID)
			if not bIsMineRecruit then
				local szComment = TeamBuilding.GetTeamPushComment(tbRecruitInfo) or ""
				bBlocked = WordBlockMgr.HasWordBlockedInRecruit(szComment) or WordBlockMgr.HasWordBlockedInRecruit(GBKToUTF8(tbInfo.szName))
			end
		end

		bShow = bShow and not bBlocked

		if bShow then
			table.insert(tbResList, tbRecruitInfo)
		end
    end

    return tbResList
end

local function GetShowQuestID(tLine, pPlayer)
	local tList = SplitString(tLine.szQuest_ReID, ";")
	local tID = {}
	for _, szSub in pairs(tList) do
		local t = SplitString(szSub, "|")
		local dwQuestID = tonumber(t[1])
		local dwID = tonumber(t[2])
		local nResult = pPlayer.CanAcceptQuest(dwQuestID)
		if nResult == QUEST_RESULT.SUCCESS or
			nResult == QUEST_RESULT.ALREADY_ACCEPTED or
			nResult == QUEST_RESULT.ALREADY_FINISHED or
			nResult == QUEST_RESULT.FINISHED_MAX_COUNT then
			local nQuestID, nQusetState = ActivityData.GetQuestState(dwQuestID)
			if nQuestID == dwQuestID then
				table.insert(tID, dwID)
			end
		end
	end
	return tID
end

function TeamBuilding.OnGetTeamRecruitDynamic(tbMenu)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local nCount = g_tTable.TeamRecruitDynamic:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TeamRecruitDynamic:GetRow(i)
		local tID = GetShowQuestID(tLine, hPlayer)
		if tID and not IsTableEmpty(tID) then
			local tbActivityMenu = TeamBuilding.GetCheckedMenu(UIHelper.GBKToUTF8(tLine.szName), true, false, {tID, tLine.szName}, nil, false)
			table.insert(tbMenu, tbActivityMenu)
		end
	end
end

function TeamBuilding.OnGetRecruitDynamic()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	local tList = {}
	local nCount = g_tTable.TeamRecruitDynamic:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TeamRecruitDynamic:GetRow(i)
		local tID = GetShowQuestID(tLine, pPlayer)
		if tID and not IsTableEmpty(tID) then
			tList = table.AddRange(tList, tID)
		end
	end
	return tList
end

function TeamBuilding.GetCheckedMenu(szName, bChecked, bDisable, UserData, fnAction, bMark)
    return {
		szOption = szName,
		bChecked = false,
		bDisable = bDisable,
		UserData = UserData,
		fnAction = fnAction,
		bMark = bMark,
	}
end

function TeamBuilding.SetMenuInfo(tbMenu, szName, bChecked, bDisable, UserData, fnAction, bMark)
	tbMenu.szOption = szName
	tbMenu.bChecked = false
	tbMenu.bDisable = bDisable
	tbMenu.UserData = UserData
	tbMenu.fnAction = fnAction
	tbMenu.bMark = bMark
end

function TeamBuilding.UseSubMenu(tInfo)
	local nCampLimit 	= tInfo.nCamp
	local dwMapID 		= tInfo.dwMapID or 0
	local nMinLevel 	= tInfo.dwMinLevel
	local szDay 		= tInfo.szDay
	local nStartTime 	= tInfo.nStartTime
	local nLastTime 	= tInfo.nLastTime

	local bShow = TeamBuilding.MenuCampLimit(nCampLimit)

	bShow = bShow and TeamBuilding.MenuLevelLimit(nMinLevel)

	bShow = bShow and TeamBuilding.TimeLimit(szDay, nStartTime, nLastTime)

	bShow = bShow and TeamBuilding.IsZhanChangLimit(dwMapID)

	return bShow
end

function TeamBuilding.MenuCampLimit(nCampLimit)
	local nCamp = GetClientPlayer().nCamp
	if nCampLimit == 1 then		--只有阵营为中立的玩家，可以看到
		if nCamp == 0 then
			return true
		end
	elseif nCampLimit == 2 then	--只有阵营为浩气盟的玩家，可以看到
		if nCamp == 1 then
			return true
		end
	elseif nCampLimit == 3 then	--只有阵营不为恶人谷的玩家，可以看到
		if nCamp ~= 2 then
			return true
		end
	elseif nCampLimit == 4 then	--只有阵营为恶人谷的玩家，可以看到
		if nCamp == 2 then
			return true
		end
	elseif nCampLimit == 5 then	--只有阵营不为浩气盟的玩家，可以看到
		if nCamp ~= 1 then
			return true
		end
	elseif nCampLimit == 6 then	--只有浩气、恶人的玩家，可以看到
		if nCamp ~= 0 then
			return true
		end
	elseif nCampLimit == 7 then	--不做阵营匹配显示，即全部显示
		return true
	end
	return false
end

function TeamBuilding.CanShowTeam(nCampLimit, nApplyCamp)
	local nCamp = GetClientPlayer().nCamp
	if nCampLimit == 1 then		--只有阵营为中立的玩家，可以看到
		if nCamp == 0 then
			return true
		end
	elseif nCampLimit == 2 then	--只有阵营为浩气盟的玩家，可以看到
		if nCamp == 1 then
			return true
		end
	elseif nCampLimit == 3 then	--只有阵营不为恶人谷的玩家，可以看到
		if nCamp ~= 2 then
			return true
		end
	elseif nCampLimit == 4 then	--只有阵营为恶人谷的玩家，可以看到
		if nCamp == 2 then
			return true
		end
	elseif nCampLimit == 5 then	--只有阵营不为浩气盟的玩家，可以看到
		if nCamp ~= 1 then
			return true
		end
	elseif nCampLimit == 6 then	--匹配玩家和发布者的阵营，只显示相同阵营
		if nCamp ~= 0 and nCamp == nApplyCamp then
			return true
		end
	elseif nCampLimit == 7 then	--不做阵营匹配显示，即全部显示
		return true
	end
	return false
end

function TeamBuilding.TimeLimit(szDay, nStartTime, nLastTime)
	local weekday = TimeLib.GetCurrentWeekday()
	local hour = GetCurrentHour()
	local nTime = GetCurrentTime()
	local aTime = TimeToDate(nTime)
	local tDay = SplitString(szDay, ";")

	for k, v in pairs(tDay) do
		if weekday == tonumber(v) then
			if nLastTime ~= 24 then
				local dwStartTime = DateToTime(aTime.year, aTime.month, aTime.day, nStartTime, 0, 0)
				local dwEndTime = dwStartTime + nLastTime * 60 * 60

				local dwStartTime1, dwEndTime1
				if nStartTime + nLastTime > 24 then
					dwStartTime1 = DateToTime(aTime.year, aTime.month, aTime.day - 1, nStartTime, 0, 0)
					dwEndTime1 = dwStartTime1 + nLastTime * 60 * 60
				end

				if nTime >= dwStartTime and nTime <= dwEndTime then
					return true
				elseif dwStartTime1 and dwEndTime1 and nTime >= dwStartTime1 and nTime <= dwEndTime1 then
					return true
				end
			else
				return true
			end
		end
	end
	return false
end

function TeamBuilding.MenuLevelLimit(nMinLevel)
	local hPlayer = GetClientPlayer()
	local nLevel = hPlayer.nLevel
	if nLevel >= nMinLevel then
		return true
	else
		return false
	end
end

function TeamBuilding.IsZhanChangLimit(dwMapID)
	local t = TeamBuilding.tBattleOpen
	for dwZhanChangID, bOpen in pairs(t) do
		if dwMapID == dwZhanChangID and not bOpen then
			return false
		end
	end
	return true
end

function TeamBuilding.IsFreshMen()
	local hPlayer = GetClientPlayer()
	return hPlayer.IsHaveBuff(FRESH_MEN_BUFF, FRESH_MEN_LEVEL)
end

function TeamBuilding.IsTeachLeader()
	local hPlayer = GetClientPlayer()

	if not hPlayer then
		return
	end

	local nPrefix = hPlayer.GetCurrentDesignationPrefix()

	return nPrefix == TEACH_LEADER
end

local function CheckCommentForLabels(pszComment)
	if IsTableEmpty(TeamBuilding.tbTagIDs) then
		pszComment = string.trim(pszComment, " ")
		pszComment = string.trim(pszComment, g_tStrings.STR_ONE_CHINESE_SPACE)
		local aTexts = {}
		aTexts = string.split(pszComment, g_tStrings.STR_ONE_CHINESE_SPACE) -- 先只简单处理中间只有中文空格的情况，其他的空白分隔符暂且无视

		local aTags1 = g_tStrings.tTeamBuildRecruitMsgAllGroupTags[1].Tags
		local aTags2 = g_tStrings.tTeamBuildRecruitMsgAllGroupTags[2].Tags

		for k, szText in ipairs(aTexts) do
			local t = FindTableValueByKey(aTags1, "text", szText)
			if t then
				table.insert(TeamBuilding.tbTagIDs, t.id)
			else
				t = FindTableValueByKey(aTags2, "text", szText)
				if t then
					table.insert(TeamBuilding.tbTagIDs, t.id)
				else
					TeamBuilding.tbTagIDs = {}
					return
				end
			end
		end
	end
end

function TeamBuilding.RegisterTeamPushInfo(dwApplyID, nFlag, nCheckTong, pszComment, bSwitchServer)
	local bFreshMen = TeamBuilding.IsFreshMen()
	local nTeachTeamFlag = 0
	if bFreshMen then
		nFlag = nFlag + 2
	end

	if TeamBuilding.IsTeachLeader() then
		nTeachTeamFlag = 1
	end

	TeamBuilding.tbTagIDs = {}
	CheckCommentForLabels(UIHelper.GBKToUTF8(pszComment))

	if #TeamBuilding.tbTagIDs > 0 then
		if bSwitchServer then
			GetGlobalRoomPushClient().RegisterRoomPushInfoWithLabelID(dwApplyID, nFlag, nCheckTong, nTeachTeamFlag, TeamBuilding.tbTagIDs)
		else
			if not IsRemotePlayer(UI_GetClientPlayerID()) then
				RegisterTeamPushInfoWithLabelID(dwApplyID, nFlag, nCheckTong, nTeachTeamFlag, TeamBuilding.tbTagIDs)
			end
		end
	else
		if TextFilterCheck(pszComment) == false then
			local dummy
			dummy, pszComment = TextFilterReplace(pszComment)
		end
		if bSwitchServer then
			GetGlobalRoomPushClient().RegisterRoomPushInfo(dwApplyID, nFlag, nCheckTong, nTeachTeamFlag, pszComment)
		else
			if not IsRemotePlayer(UI_GetClientPlayerID()) then
				RegisterTeamPushInfo(dwApplyID, nFlag, nCheckTong, nTeachTeamFlag, pszComment)
			end
		end
	end
end

function TeamBuilding.UnregisterTeamPushInfo()
	if TeamBuilding.szMySelfRoomID then --跨服的注销太慢了，等事件回来再刷新
		GetGlobalRoomPushClient().UnRegisterRoomPushInfo()
	else
		UnregisterTeamPushInfo()
		TeamBuilding.OnApplyTeamList()
	end

	TeamBuilding.SetApplyCount(0)
end

function TeamBuilding.UpdateApplyCount()
	local nNum = TeamBuilding.nApplyCount or 0
	TeamBuilding.SetApplyCount(nNum + 1)
end

function TeamBuilding.SetApplyCount(nNum)
	TeamBuilding.nApplyCount = nNum
	Event.Dispatch(EventType.OnRecruitApplyCountUpdate)
end

function TeamBuilding.GetApplyCount()
	return TeamBuilding.nApplyCount or 0
end

function TeamBuilding.OnTeamPushMessageNotify(nRet, bRoom)
	if (not bRoom and arg0 == TEAM_PUSH_NOTIFY_CODE.APPLY_SUCCESS) or
		(bRoom and arg0 == GLOBAL_ROOM_PUSH_RESULT_CODE.APPLY_SUCCESS) then
			if UIMgr.GetView(VIEW_ID.PanelTeam) then
				TeamBuilding.OnApplyInfo(ApplyTeamList, GetGlobalRoomPushClient().SyncPlayerApplyRoomPushList)
			end
	elseif (not bRoom and arg0 == TEAM_PUSH_NOTIFY_CODE.PUSH_TEAM_SUCCESS) or
		(bRoom and arg0 == GLOBAL_ROOM_PUSH_RESULT_CODE.REGISTER_ROOM_PUSH_SUCCESS) then
		TeamBuilding.OnApplyTeamList()
		TeamBuilding.CleanMyselfPush()
		TeamBuilding.bPushSuccess = true
	elseif (not bRoom and arg0 == TEAM_PUSH_NOTIFY_CODE.SOMEONE_APPLY) or
		(bRoom and arg0 == GLOBAL_ROOM_PUSH_RESULT_CODE.SOMEONE_APPLY) then
		local script = UIMgr.GetViewScript(VIEW_ID.PanelTeam)
		if script and UIHelper.GetSelected(script.TogTabList02) then
			TeamBuilding.OnApplyList()
		else
			TeamBuilding.UpdateApplyCount()
		end
		BubbleMsgData.PushMsgWithType("TeamBuildingApplyTips", {
			nBarTime = 5, 							-- 显示在气泡栏的时长, 单位为秒
			szContent = "收到组队邀请，点击查看详情。",
			szAction = function ()
				UIMgr.Open(VIEW_ID.PanelTeam, 3)
				BubbleMsgData.RemoveMsg("TeamBuildingApplyTips")
			end,
		})
	elseif (not bRoom and arg0 == TEAM_PUSH_NOTIFY_CODE.APPLICATION_AGREED) then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tTeamBuildRespond[arg0])
		if TeamData.CheckInSingleFB(true) then
			return
		end
		local hTeam = GetClientTeam()
		local dwID = TeamBuilding.tbSelfRecruitInfo["dwActivityID"]
		hTeam.InviteJoinTeam(2, dwID, arg1)
	elseif (not bRoom and arg0 == TEAM_PUSH_NOTIFY_CODE.APPLICATION_DENIED) or
		(bRoom and arg0 == GLOBAL_ROOM_PUSH_RESULT_CODE.APPLICATION_DENIED) then
		local szName = arg1
		if bRoom then
			OutputMessage("MSG_ANNOUNCE_RED", UIHelper.GBKToUTF8(szName) .. g_tStrings.tRoomBuildError[arg0])
		else
			OutputMessage("MSG_ANNOUNCE_RED", UIHelper.GBKToUTF8(szName) .. g_tStrings.tTeamBuildError[arg0])
		end
		if UIMgr.GetView(VIEW_ID.PanelTeam) then
			TeamBuilding.OnApplyInfo(ApplyTeamList, GetGlobalRoomPushClient().SyncPlayerApplyRoomPushList)
		end
		return
	elseif (bRoom and arg0 == GLOBAL_ROOM_PUSH_RESULT_CODE.UNREGISTER_ROOM_PUSH_SUCCESS) then
		TeamBuilding.OnApplyTeamList()
	end

	if bRoom then
		local szError = g_tStrings.tRoomBuildRespond[arg0]
		if szError then
			OutputMessage("MSG_ANNOUNCE_YELLOW", szError)
		else
			szError = g_tStrings.tRoomBuildError[arg0]
			if szError then
				OutputMessage("MSG_ANNOUNCE_RED", szError)
			end
		end
	else
		local szError = g_tStrings.tTeamBuildRespond[arg0]
		if szError then
			OutputMessage("MSG_ANNOUNCE_YELLOW", szError)
		else
			szError = g_tStrings.tTeamBuildError[arg0]
			if szError then
				OutputMessage("MSG_ANNOUNCE_RED", szError)
			end
		end
	end
end

Event.Reg(TeamBuilding, "ON_TEAM_PUSH_MESSAGE_NOTIFY", function()
	TeamBuilding.OnTeamPushMessageNotify(arg0, false)
end)

Event.Reg(TeamBuilding, "ON_ROOM_PUSH_MESSAGE_NOTIFY", function()
	TeamBuilding.OnTeamPushMessageNotify(arg0, true)
end)

Event.Reg(TeamBuilding, "ON_PUSH_TEAM_NOTIFY", TeamBuilding.OnReceiveTeamInfo)

Event.Reg(TeamBuilding, "ON_PUSH_ROOM_PUSH_NOTIFY", TeamBuilding.OnReceiveServerTeamInfo)

Event.Reg(TeamBuilding, "ON_SYNC_APPLY_PLAYER_LIST_NOTIFY", TeamBuilding.OnSyncPlayerList)

Event.Reg(TeamBuilding, "ON_SYNC_ROOM_PUSH_APPLY_PLAYER_LIST_NOTIFY", TeamBuilding.OnSyncPlayerList)

Event.Reg(TeamBuilding, "ON_SYNC_PLAYER_APPLY_TEAM_LIST_NOTIFY", TeamBuilding.OnSyncSelfApplyTeamList)

Event.Reg(TeamBuilding, "ON_SYNC_PLAYER_APPLY_ROOM_PUSH_LIST_NOTIFY", TeamBuilding.OnSyncSelfApplyRoomTeamList)

Event.Reg(TeamBuilding, "APPLY_SOCIAL_INFO_RESPOND", TeamBuilding.OnUpdateFellowShipCard)

Event.Reg(TeamBuilding, "UPDATE_FELLOWSHIP_CARD", TeamBuilding.OnUpdateFellowShipCard)

Event.Reg(TeamBuilding, "GET_TODAY_ZHANCHANG_RESPOND", function ()
	TeamBuilding.tBattleOpen = arg0 or {}
end)