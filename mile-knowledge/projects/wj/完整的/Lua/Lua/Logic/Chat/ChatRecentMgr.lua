-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ChatRecentMgr
-- Date: 2024-09-12 15:15:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

ChatRecentMgr = ChatRecentMgr or {className = "ChatRecentMgr"}
local self = ChatRecentMgr

local tbTab = {
	RECENT = 1,
	FRIEND = 2,
	FOE = 3,
	AROUND = 5,
}

local l_aAllSafeLockEffectTypes = --- 一定要写全
{
	SAFE_LOCK_EFFECT_TYPE.TRADE, SAFE_LOCK_EFFECT_TYPE.AUCTION, SAFE_LOCK_EFFECT_TYPE.SHOP, SAFE_LOCK_EFFECT_TYPE.MAIL,
	SAFE_LOCK_EFFECT_TYPE.TONG_DONATE, SAFE_LOCK_EFFECT_TYPE.TONG_PAY_SALARY, SAFE_LOCK_EFFECT_TYPE.EQUIP, SAFE_LOCK_EFFECT_TYPE.BANK,
	SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY, SAFE_LOCK_EFFECT_TYPE.COIN, SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, SAFE_LOCK_EFFECT_TYPE.WANTED,
	SAFE_LOCK_EFFECT_TYPE.EXTERIOR, SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, SAFE_LOCK_EFFECT_TYPE.FELLOWSHIP, SAFE_LOCK_EFFECT_TYPE.ARENA,
	SAFE_LOCK_EFFECT_TYPE.TALK,
}

self.tbNewMsg = {}	--新消息
self.tbOffLineMsg = {} 	--离线消息
self.tbOffLineHint = {}	--用于离线消息提示铃铛

self.tbLoadHistoryIDList = {}	--需要自动加载历史消息

self.nTab = tbTab.FRIEND

self.tbRecentWhisperPlayerList = {}	--聊天密聊中的联系人列表

self.bHaveOpenDisturb = false	--是否上次游戏期间就已经开启免打扰

self.szCurSelectPlayer = nil	--密聊选中玩家

function ChatRecentMgr.Init()
	Event.Reg(self, EventType.OnReceiveChat, function(tbData)
		if not tbData then return end

		if tbData.nChannel == PLAYER_TALK_CHANNEL.WHISPER and not tbData.szGlobalID and tbData.bTongMsg then	--帮会群密
			local tbPlayerData = ChatData.GetWhisperPlayerData(tbData.szName)
			tbData.szGlobalID = tbPlayerData and tbPlayerData.szGlobalID or nil
		end

		if tbData.szGlobalID and tbData.nChannel == PLAYER_TALK_CHANNEL.WHISPER or tbData.bBeCalled then
			self.AddNewMsgCount(tbData.szGlobalID)
		end
	end)

	Event.Reg(self, "APPLY_RECENT_WHISPER_FINISH", function(bHaveOfflineWhisper)

		local tbRecentContactInfo = GetChatManager().GetRecentContactInfo()

		if bHaveOfflineWhisper then	--有离线消息
			self.SetOffLineWhisperCount(tbRecentContactInfo)
			Event.Dispatch(EventType.OnChatHintMsgUpdate)
		end
	end)

	Event.Reg(self, "SAFE_LOCK_TALK_UNLOCKED", function()
		local bLock = ChatRecentMgr.GetRecentLockState()
		if not bLock then
			local tList = GetChatManager().GetRecentContactInfo()
			self.SetOffLineWhisperCount(tList)
			Event.Dispatch(EventType.OnChatHintMsgUpdate)
		end

	end)

	Event.Reg(self, EventType.OnRoleLogin, function()
        Event.Reg(self, "LOADING_END", function()
			if ChatData.CheckWhisperIsOpenDisturb() then
				self.bHaveOpenDisturb = true
			end

		self.AddRecentPlayerToWhisper()
        end, true)
    end)

	Event.Reg(self, "BANK_LOCK_RESPOND", function(szResult, nCode)
		local bLock = ChatRecentMgr.GetRecentLockState()
        if (szResult == "VERIFY_BANK_PASSWORD_SUCCESS" or szResult == "SECURITY_VERIFY_PASSWORD_SUCCESS") and not bLock then
			local player = GetClientPlayer()
			if player then
				self.AddRecentPlayerToWhisper()
			end

			Event.Dispatch(EventType.OnChatWhisperMiBaoUnLockSuccessed)
        end
    end)

	Event.Reg(self, EventType.OnAccountLogout, function()
		self.tbNewMsg = {}
		self.tbOffLineMsg = {}
		self.tbOffLineHint = {}
		self.tbLoadHistoryIDList = {}
		self.nTab = tbTab.FRIEND
		self.tbRecentWhisperPlayerList = {}
		self.bHaveOpenDisturb = false
		self.szCurSelectPlayer = nil
	end)

	Event.Reg(self, "LOAD_LOCAL_WHISPER_FINISH", function ()
		local szGlobalID = arg0
		local bResult = ChatRecentMgr.TryLoadLocalChatData(szGlobalID)
		if not bResult then
			Event.Dispatch("RECENTLY_MSG_CHANGE", szGlobalID)
		end
	end)
end

function ChatRecentMgr.UnInit()

end

function ChatRecentMgr.SetOffLineWhisperCount(tbRecentContactInfo)
	--self.tbNewMsg = {}
	for k, tbInfo in pairs(tbRecentContactInfo) do
		if tbInfo then
			local nOfflineWhisperCount = tbInfo.nOfflineWhisperCount or 0
			--self.tbNewMsg[tbInfo.szGlobalID] = nOfflineWhisperCount
			self.tbOffLineMsg[tbInfo.szGlobalID] = nOfflineWhisperCount
			self.tbOffLineHint[tbInfo.szGlobalID] = nOfflineWhisperCount
		end
	end
end

function ChatRecentMgr.UpdatePlayerListNewMsgCount(tbPlayerList)
	if not tbPlayerList then return end

	for k, tbPlayerInfo in pairs(tbPlayerList) do
		local szGlobalID = tbPlayerInfo.szGlobalID
		local nNewCount = self.tbNewMsg[szGlobalID] or 0
		local nOffLineCount = self.tbOffLineHint[szGlobalID] or 0
		tbPlayerList[k].nNewMsgCount = nOffLineCount + nNewCount
	end

	return tbPlayerList
end

function ChatRecentMgr.GetRecentWhisperPlayerList()
	local tbPlayerList = GetChatManager().GetRecentContactInfo() or {}
    tbPlayerList = self.UpdatePlayerListNewMsgCount(tbPlayerList)

	return tbPlayerList
end

function ChatRecentMgr.GetContactRecentWhisperInfoByIndex(szGlobal, szCurWhisper, nIndex)	
	local hCM = GetChatManager()
    local nLocal, nOnline = hCM.GetContectRecentWhisperSize(szGlobal)
	local tbWhisperInfo = {}
	local tInfo1, tInfo2 = nil, nil
	local nCurCount = self.GetCurWhisperSize(szCurWhisper)
	local nTotalCount = 0
	--if self.IsExistRecentPlayer(szGlobal) then
	--	nTotalCount = ChatRecentMgr.GetContectRecentWhisperSize(szGlobal)
	--end
	--if nTotalCount > nCurCount and nIndex <= nTotalCount - nCurCount then
		--local tbInfo, tbContentInfo = GetChatManager().GetContactRecentWhisperByIndex(szGlobal, nIndex - 1, true)
		nIndex = nIndex - 1
		if nIndex < nOnline then
			nIndex = nOnline - 1 - nIndex
			tInfo1, tInfo2 = hCM.GetContactRecentWhisperByIndex(szGlobal, nIndex, false)
		else
			nIndex = nIndex - nOnline
			tInfo1, tInfo2 = hCM.GetContactRecentWhisperByIndex(szGlobal, nIndex, true)
		end
		if nIndex > nOnline then
			
		end
		if tInfo1 and tInfo2 then
			table.insert(tbWhisperInfo, {tbInfo = tInfo1, tbContentInfo = tInfo2})
		end
	--end

	return tbWhisperInfo[1]
end

function ChatRecentMgr.ClearNewMsg(szGlobal)
	if not szGlobal then
		return
	end
	self.tbNewMsg[szGlobal] = 0
	self.tbOffLineHint[szGlobal] = 0
	Event.Dispatch(EventType.OnChatRecentWhisperUnreadRemove, szGlobal)
	Event.Dispatch(EventType.OnChatHintMsgUpdate)
end

function ChatRecentMgr.AddNewMsgCount(szGlobal)
	local nCount = self.tbNewMsg[szGlobal] or 0
	self.tbNewMsg[szGlobal] = nCount + 1
	Event.Dispatch(EventType.OnChatRecentWhisperUnreadAdd, szGlobal)
end

function ChatRecentMgr.HasNewMsgRedPoint()
	local bResult = false
    local nLen = 0
	local player = GetClientPlayer()
	if not player then
		return
	end
	local szGlobalID = g_pClientPlayer.GetGlobalID()
	local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()
	for k, v in pairs(self.tbNewMsg) do
		if v > 0 and k ~= szGlobalID then
			local bFriend = FellowshipData.IsFriend(k)
			if bFriend or (not nOpenDisturbTime) then
				nLen = nLen + 1
			end
		end
	end

	bResult = nLen > 0

	return bResult, nLen
end

function ChatRecentMgr.HasOffLineMsgRedPoint()	--是否有离线消息
	local bResult = false
	for k, v in pairs(self.tbOffLineHint) do
		if v > 0 then
			bResult = true
		end
	end

	return bResult
end

function ChatRecentMgr.GetNewMsgCount(szGlobal)
	local nCount = self.tbNewMsg[szGlobal] or 0
	return nCount
end

function ChatRecentMgr.GetOffLineMsgCount(szGlobal)
	local nCount = self.tbOffLineHint[szGlobal] or 0
	return nCount
end

function ChatRecentMgr.GetCurWhisperSize(szCurWhisper)
	local nCount = 0

	local tbOneChannelData = ChatData.GetDataList(UI_Chat_Channel.Whisper, szCurWhisper)
	if tbOneChannelData and not table.is_empty(tbOneChannelData) then
		for k, tbData in pairs(tbOneChannelData) do
			if tbData.nPrefabID ~= PREFAB_ID.WidgetChatTime then
				nCount = nCount + 1
			end
		end
	end

	return nCount
end

function ChatRecentMgr.GetPrefabID(szGlobalID, tbMsg)
    local nPrefabID = PREFAB_ID.WidgetChatPlayer
    local bIsSelf = szGlobalID == UI_GetClientPlayerGlobalID()
    local bIsVoice = tbMsg and tbMsg[1] and (tbMsg[1].type == "voice")
    if bIsVoice then
        nPrefabID = bIsSelf and PREFAB_ID.WidgetChatSelfVoice or PREFAB_ID.WidgetChatPlayerVoice
    else
        nPrefabID = bIsSelf and PREFAB_ID.WidgetChatSelf or PREFAB_ID.WidgetChatPlayer
    end

    return nPrefabID
end

function ChatRecentMgr.HasWhisperUnread(szGlobal)
	local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()
	local bFriend = FellowshipData.IsFriend(szGlobal)
	local nCount = self.tbNewMsg[szGlobal] or 0
	if nOpenDisturbTime and not bFriend then
		nCount = 0
	end
    return nCount > 0
end

function ChatRecentMgr.GetTotalOffLineMsgCount()
	local nCount = 0
	local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()
	for k, v in pairs(self.tbOffLineHint) do
		local bFriend = FellowshipData.IsFriend(k)
		if not nOpenDisturbTime or (nOpenDisturbTime and bFriend) then
			nCount = nCount + v
		end
	end

	return nCount
end

function ChatRecentMgr.Check_ChatIsLocked(fnUnLockAction)
	local bTalkLocked = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.TALK)
	if bTalkLocked then
		UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, SAFE_LOCK_EFFECT_TYPE.TALK)
		return true
	end

	return false
end

function ChatRecentMgr.Check_WhisperIsLocked(bOpenMiBaoUI, fnUnLockAction)
	local bResult = ChatRecentMgr.GetRecentLockState()
	if bResult and bOpenMiBaoUI then
		if BankLock.IsPhoneLock() then
			UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, nil, fnUnLockAction)
		else
			UIMgr.OpenSingle(false, VIEW_ID.PanelPasswordUnlockPop, fnUnLockAction)
		end
	end

	return bResult
end

function ChatRecentMgr.SortPlayerList(tbPlayerList, bWhisper)
	if not tbPlayerList or table.is_empty(tbPlayerList) then
		return {}
	end

	local fnSort = function(a, b)
		--获取最后一条信息时间
		if a and b then
			local nATime = self.GetLastWhisperInfo(a.szGlobalID)
			local nBTime = self.GetLastWhisperInfo(b.szGlobalID)
			return nATime > nBTime
		end
    end

    table.sort(tbPlayerList, fnSort)

	return tbPlayerList
end

function ChatRecentMgr.IsNeedLoadHistoryChat(szGlobalID)
	local bResult = table.contain_value(self.tbLoadHistoryIDList, szGlobalID)

	return bResult
end

function ChatRecentMgr.AddGlobalID(szGlobalID)
    if not self.tbLoadHistoryIDList then
        self.tbLoadHistoryIDList = {}
    end

	table.insert(self.tbLoadHistoryIDList, szGlobalID)
end

function ChatRecentMgr.SetCurContactsTab(nTab)
	if not nTab or not table.contain_value(tbTab, nTab) then
		return
	end

	self.nTab = nTab
end

function ChatRecentMgr.GetCurContactsTab()
	return self.nTab
end

function ChatRecentMgr.GetContectRecentWhisperSize(szGlobalID)
	if ChatRecentMgr.Check_WhisperIsLocked() then
		return 0, 0
	end

	local nLocalSize, nCurrSize = GetChatManager().GetContectRecentWhisperSize(szGlobalID)
	if nLocalSize == nil then
		nLocalSize = 0
	end
	if nCurrSize == nil then
		nCurrSize = 0
	end

	--LOG.INFO("QH, nLocalSize = %d, nCurrSize = %d", nLocalSize, nCurrSize)

	--return nLocalSize, nCurrSize
	return nLocalSize + nCurrSize
end

function ChatRecentMgr.GetLastWhisperInfo(szGlobalID)	--获取该联系人最后一条历史聊天时间
	if self.IsExistRecentPlayer(szGlobalID) then
		local tInfo1, tInfo2 = nil, nil
		local nLocal, nOnline = GetChatManager().GetContectRecentWhisperSize(szGlobalID)
		if nOnline > 0 then
			tInfo1, tInfo2 = GetChatManager().GetContactRecentWhisperByIndex(szGlobalID, nOnline - 1, false)
		else
			tInfo1, tInfo2 = GetChatManager().GetContactRecentWhisperByIndex(szGlobalID, 0, true)
		end
		return tInfo2 and tInfo2.nTalkTime or GetCurrentTime()
	else
		return GetCurrentTime()
	end

end

function ChatRecentMgr.GetWhisperPlayerList()
	return self.tbRecentWhisperPlayerList
end

function ChatRecentMgr.RemoveWhisperPlayer(szName)
	if string.is_nil(szName) then
        return
    end

    for k, v in ipairs(self.tbRecentWhisperPlayerList) do
        if UIHelper.GBKToUTF8(v.szName) == szName then
            table.remove(self.tbRecentWhisperPlayerList, k)
            break
        end
    end
end

function ChatRecentMgr.AddWhisperPlayer(tbInfo)
	if not tbInfo or table.is_empty(tbInfo) then
		return
	end

	for k, v in pairs(self.tbRecentWhisperPlayerList) do
		if v.szGlobalID == tbInfo.szGlobalID then
			return
		end
	end

	table.insert(self.tbRecentWhisperPlayerList, tbInfo)
end

function ChatRecentMgr.GetLastChatTimeByName(szName)	--szname带后缀
	if not szName then
		return
	end

	local nTime = GetCurrentTime()
	local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()

	local tbPlayerList = GetChatManager().GetRecentContactInfo() or {}	--改名前的名称，好友需要更新名字再排
	for k, v in pairs(tbPlayerList) do
		local bFriend = FellowshipData.IsFriend(v.szGlobalID)
		local tRoleEntryInfo = FellowshipData.GetRoleEntryInfo(v.szGlobalID) or {}
		if tRoleEntryInfo and not table.is_empty(tRoleEntryInfo) and bFriend then
			v.szName = tRoleEntryInfo.szName
			v.dwCenterID = tRoleEntryInfo.dwCenterID
		end
		local szPlayerName = GBKToUTF8(v.szName)
		if bFriend then
			szPlayerName = RoomData.GetGlobalName(v.szName, v.dwCenterID)
			szPlayerName = GBKToUTF8(szPlayerName)
		end
		if szPlayerName == szName then
			nTime = self.GetLastWhisperInfo(v.szGlobalID)
			if nOpenDisturbTime and not bFriend then
				nTime = nTime > nOpenDisturbTime and nOpenDisturbTime or nTime
			end
			return nTime
		end
	end

	return nTime
end

function ChatRecentMgr.GetLastChatTimeByGlobalID(szGlobalID)
	if not szGlobalID then
		return
	end

	local nTime = GetCurrentTime()
	local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()

	nTime = self.GetLastWhisperInfo(szGlobalID)
	if nOpenDisturbTime then
		nTime = nTime > nOpenDisturbTime and nOpenDisturbTime or nTime
	end

	return nTime
end

function ChatRecentMgr.IsExistRecentPlayer(szGlobalID)	--该id是否存在于最近联系人列表
	local tbPlayerList = GetChatManager().GetRecentContactInfo() or {}
	for k, v in pairs(tbPlayerList) do
		if szGlobalID == v.szGlobalID then
			return true
		end
	end

	return false
end

function ChatRecentMgr.GetCurWhisperPlayerName()
	return self.szCurSelectPlayer
end

function ChatRecentMgr.SetCurWhisperPlayerName(szName)
	self.szCurSelectPlayer = szName
end

function ChatRecentMgr.GetWhisperHaveOpenDisturb()
	return self.bHaveOpenDisturb
end

function ChatRecentMgr.GetPlayerRemarkNameByGlobalID(szUtf8Name, szGlobalID, nDisplayMode)
	if not szGlobalID then
		return
	end
	local tbFriendList = FellowshipData.GetFellowshipInfoList() or {}
	local szDisplayName = szUtf8Name
	local szUtf8Remark = ""
	for i, v in ipairs(tbFriendList) do
        if v.id == szGlobalID and v.remark then
            szUtf8Remark = UIHelper.GBKToUTF8(v.remark)
            break
        end
    end

	if nDisplayMode == SOCIALPANEL_NAME_DISPLAY.NICKNAME then
        szDisplayName = szUtf8Name
    elseif nDisplayMode == SOCIALPANEL_NAME_DISPLAY.REMARK then
        szDisplayName = szUtf8Remark == "" and szUtf8Name or szUtf8Remark
    elseif nDisplayMode == SOCIALPANEL_NAME_DISPLAY.NICKNAME_AND_REMARK then
        szDisplayName = szUtf8Remark == "" and szUtf8Name or string.format("%s(%s)", szUtf8Name, szUtf8Remark)
    elseif nDisplayMode == SOCIALPANEL_NAME_DISPLAY.REMARK_AND_NICKNAME then
        szDisplayName = szUtf8Remark == "" and szUtf8Name or string.format("%s(%s)", szUtf8Remark, szUtf8Name)
    else
        szDisplayName = szUtf8Name
    end

	return szDisplayName
end

function ChatRecentMgr.IsFriendByName(szName)
	local tbFriendList = FellowshipData.GetFellowshipInfoList() or {}
	for _, tbFriendInfo in ipairs(tbFriendList) do
		local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(tbFriendInfo.id)
		if tbRoleEntryInfo then
			local szFriendName = tbRoleEntryInfo.szName
			szFriendName = UIHelper.GBKToUTF8(szFriendName)
			if szFriendName == szName then
				return true
			end
		end
	end

	return false
end

function ChatRecentMgr.AddRecentPlayerToWhisper()
	local bResult = ChatRecentMgr.GetRecentLockState()
	if bResult then
		return
	end
	local tbPlayerList = self.GetRecentWhisperPlayerList()
	self.tbRecentWhisperPlayerList = ChatRecentMgr.SortPlayerList(tbPlayerList, true)

	local tbPlayerList = ChatRecentMgr.GetWhisperPlayerList()

	local bHaveOpenDisturb = ChatRecentMgr.GetWhisperHaveOpenDisturb()
	local nOpenDisturbTime = ChatData.CheckWhisperIsOpenDisturb()

	for i, v in ipairs(tbPlayerList) do --最近联系人加入密聊列表
		local szName = UIHelper.GBKToUTF8(v.szName)
		local dwTalkerID = nil
		local dwForceID = v.byForceID
		local dwMiniAvatarID = v.dwMiniAvatarID
		local nRoleType = v.byRoleType
		local nLevel = v.byLevel
		local szGlobalID = v.szGlobalID
		local dwCenterID = v.dwCenterID
		local nCamp = v.byCamp

		local bFriend = FellowshipData.IsFriend(szGlobalID) or ChatRecentMgr.IsFriendByName(szName)
		if bFriend then
			local tbPlayerInfo = FellowshipData.GetRoleEntryInfo(v.szGlobalID)
			if tbPlayerInfo and tbPlayerInfo.szName ~= "" then
				szName = UIHelper.GBKToUTF8(tbPlayerInfo.szName)
				dwForceID = tbPlayerInfo.nForceID
				dwMiniAvatarID = tbPlayerInfo.dwMiniAvatarID
				nRoleType = tbPlayerInfo.nRoleType
				nLevel = tbPlayerInfo.nLevel
				dwCenterID = tbPlayerInfo.dwCenterID
				nCamp = tbPlayerInfo.nCamp
			end
			szName = UTF8ToGBK(szName)
			szName = RoomData.GetGlobalName(szName, dwCenterID)
			szName = GBKToUTF8(szName)
		end
		local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID, nCamp = nCamp}

		if bHaveOpenDisturb and (not nOpenDisturbTime or bFriend) or not bHaveOpenDisturb then
			ChatData.AddWhisper(szName, tbData, true)
		end
	end
	Storage.ChatWhisper.bInit = true
	Storage.ChatWhisper.Flush()
end

function ChatRecentMgr.SortPlayerIDList(tbPlayerIDList)
    if not tbPlayerIDList or table.is_empty(tbPlayerIDList) then
        return {}
    end
    local fnSort = function(a, b)
		--获取最后一条信息时间
		local tbAInfo = ChatData.GetWhisperPlayerData(a)
		local tbBInfo = ChatData.GetWhisperPlayerData(b)

        local nATime = tbAInfo and ChatRecentMgr.GetLastChatTimeByGlobalID(tbAInfo.szGlobalID) or GetCurrentTime()
        local nBTime = tbBInfo and ChatRecentMgr.GetLastChatTimeByGlobalID(tbBInfo.szGlobalID) or GetCurrentTime()
        return nATime > nBTime
    end

    table.sort(tbPlayerIDList, fnSort)

	return tbPlayerIDList
end

function ChatRecentMgr.GetRecentGlobalIDByName(szName)	--通过名称匹配最近联系人获取globalid
	if not szName then
		return ""
	end

	local szGlobalID = ""

	local tbPlayerList = GetChatManager().GetRecentContactInfo() or {}
	for k, v in pairs(tbPlayerList) do
		local bFriend = FellowshipData.IsFriend(v.szGlobalID)
		local tRoleEntryInfo = FellowshipData.GetRoleEntryInfo(v.szGlobalID) or {}
		if tRoleEntryInfo and not table.is_empty(tRoleEntryInfo) and bFriend then
			v.szName = tRoleEntryInfo.szName
			v.dwCenterID = tRoleEntryInfo.dwCenterID
		end
		local szPlayerName = GBKToUTF8(v.szName)
		if bFriend then
			szPlayerName = RoomData.GetGlobalName(v.szName, v.dwCenterID)
			szPlayerName = GBKToUTF8(szPlayerName)
		end
		if szPlayerName == szName then
			szGlobalID = v.szGlobalID
			break
		end
	end

	return szGlobalID
end

function ChatRecentMgr.DelChatHistory(szGlobalID, szName)
	if not szGlobalID or not szName then
		return
	end
	GetChatManager().DeleteContactRecentWhisper(szGlobalID)
	ChatData.RemoveWhisper(szName)
	ChatData.RemoveWhisperData(UI_Chat_Channel.Whisper, szName)
	Event.Dispatch(EventType.OnChatWhisperDeleted, szName)
	Event.Dispatch(EventType.OnUpdateFellowShip)
end

function ChatRecentMgr.TryLoadLocalChatData(szGlobalID)	--加载部分本地密聊旧消息
	if not Platform.IsWindows() then
		return
	end
    local hCM = GetChatManager()
    return hCM.TryLoadLocalChatData(szGlobalID)
end

function ChatRecentMgr.GetSpecialMsgSize(szName)	--点名消息以及群密消息不会记录到历史记录长度，需要额外计算
	local nSpecialSize = 0
	if szName then
		local tbOneChannelData = ChatData.GetDataList(UI_Chat_Channel.Whisper, szName)
		for k, v in pairs(tbOneChannelData) do
			if v.bBeCalled or v.bTongMsg then
				nSpecialSize = nSpecialSize + 1
			end
		end
	end

	return nSpecialSize
end

function ChatRecentMgr.GetRecentLockState()
	if BankLock.IsAccountDanger() then
		return true
	end

	local player = GetClientPlayer()
	if not player then
		return
	end

	local bLocked = false
	for _, nSafeLockType in ipairs(l_aAllSafeLockEffectTypes) do
		if not player.CheckSafeLock(nSafeLockType) then
			bLocked = true
			break
		end
	end

	return bLocked
end