-- Author:      Jiang Zhenghao
-- Date:        2019-11-12
-- Version:     1.0
-- Description: 金团分配基础脚本（各种全局事件处理及全局函数定义等）

----------------------------------------------------------------------
------------------------------- 数据部分 ------------------------------
local _aWaitingStartBiddingParamsQueue = --- 编辑记录时辅助用的保存参数的数据（因为需要先EndBidding()，等成功后再StartBidding()，故必须保存参数）
{
	---{nPrevBidInfoIndex, dwDoodadID, nItemLootIndex, nPriceInGolds, dwDestPlayerID, szComment},
}

local _aContributionParams = --- 需要马上付款的自罚单（亦即“捐款”）的参数列表
{
	---{nGolds, szComment}, --- 不够准确，但现在别无他法了
}

--[[
	用于储存拍团的道具分配信息被编辑前的信息：
	① 每次调用 EndBidding() 之前增加一条记录（并且需要同时删除掉它的上一个版本(同时匹配 dwDoodadID 和 dwItemID 的)）；
	② 收到 StartBidding() 成功的事件后，取得当前的拍卖纪录并与其前一个版本进行对比，并直接删除保存的对应记录；
	③ 移交分配者权限、自己退队和队伍解散之后，删除所有信息；
	④ 如果没有收到 EndBidding() 成功的事件，不需要管，下次再次尝试编辑时会把过时的数据清除；
	⑤ 如果没有收到 StartBidding() 成功的事件，也不需要管，没什么问题
--]]
local _aLastItemBiddingInfos =
{
	--[[
	{dwDoodadID=0, dwItemID=0,
	dwDestPlayerID=0, nPrice=0, szComment=0,},
	--]]
}

local function _FindStartBidParamsByBidInfoIndex(nBidInfoIndex)
	local tParams, nIndex = FindTableValueByKey(_aWaitingStartBiddingParamsQueue, 1, nBidInfoIndex)
	return tParams, nIndex
end

------------------------------- 对外接口 ------------------------------
--- 辅助函数
local function _GetGoldText(nTotalGolds, bUseBrackets, bUseShortName)
	local nGBricks , nGolds = ConvertGoldToGBrick(nTotalGolds)
	local szText = ""
	if nGBricks > 0 then
		szText = szText .. nGBricks .. (bUseShortName and g_tStrings.STR_GOLD_BRICK_SHORT or g_tStrings.STR_GOLD_BRICK)
	end
	if szText == "" or nGolds > 0 then
		szText = szText .. nGolds .. g_tStrings.STR_GOLD
	end
	if bUseBrackets then
		szText = "[" .. szText .. "]"
	end
	return szText
end

--- 先检查，并决定是直接付款还是打开部分付款界面
function GoldTeamBase_BidItem(tBidInfo)
	local teamBidMgr = GetTeamBiddingMgr()
	local nBidInfoIndex = tBidInfo.nBiddingInfoIndex
	local nPrice = tBidInfo.nPrice
	local nPaidMoney = tBidInfo.nPaidMoney
	local player = GetClientPlayer()
	local tMoney = player.GetMoney()
	local nGold, nSilver, nCopper = UnpackMoney(tMoney)
	local nRequiredGold = nPrice - nPaidMoney

	if nRequiredGold > 0 and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
		return
	end
	if nGold >= nRequiredGold then
		local nRetCode = teamBidMgr.CanRiseMoney(nBidInfoIndex, nRequiredGold)
		if nRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
			teamBidMgr.RiseMoney(nBidInfoIndex, nRequiredGold)
		else
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GOLD_TEAM_BID_ITEM_FAIL)
		end
	else
		local nPlayerMoneyLimit = player.GetMoneyLimitByGold()

		if nRequiredGold < nPlayerMoneyLimit then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GOLD_TEAM_MUST_PAY_ALL_AMOUNT_2)
		else
			OpenGoldTeamPartialPayment(nBidInfoIndex)
		end
	end
end

function GoldTeamBase_GetRequiredGold(tBidInfo)
	local nState = tBidInfo.nState
	local nPrice = tBidInfo.nPrice
	local nPaidMoney = tBidInfo.nPaidMoney

	if nState == BIDDING_INFO_STATE.WAIT_PAYMENT then
		return nPrice - nPaidMoney, nPaidMoney
	else
		return 0, nPrice
	end
end

function GoldTeamBase_GetPaidGold(tBidInfo)
	local nState = tBidInfo.nState
	local nPrice = tBidInfo.nPrice
	local nPaidMoney = tBidInfo.nPaidMoney

	if nState == BIDDING_INFO_STATE.WAIT_PAYMENT then
		return nPaidMoney
	elseif nState == BIDDING_INFO_STATE.PAID then
		return nPrice
	else
		return 0
	end
end

--- 输出频道
function GoldTeamBase_GetChannel()
	if RoomData.IsInGlobalRoomDungeon() then
		return PLAYER_TALK_CHANNEL.ROOM
	else
		return PLAYER_TALK_CHANNEL.RAID
	end
end

function GoldTeamBase_GetAllBiddingInfos()
	local teamBidMgr = GetTeamBiddingMgr()
	local aAllBiddingInfos = teamBidMgr.GetAllBiddingInfo() or {}  --- 逻辑可能什么都不返回
	return aAllBiddingInfos
end

function GoldTeam_SaveStartBiddingParams(nPrevBidInfoIndex, dwDoodadID, nItemLootIndex, nPriceInGolds,
										 dwDestPlayerID, szComment)
	local _, nParamsIndex = _FindStartBidParamsByBidInfoIndex(nPrevBidInfoIndex)
	if nParamsIndex then
		table.remove(_aWaitingStartBiddingParamsQueue, nParamsIndex) --- 以后面新加的为准
	end
	table.insert(_aWaitingStartBiddingParamsQueue, {nPrevBidInfoIndex, dwDoodadID, nItemLootIndex, nPriceInGolds,
											 dwDestPlayerID, szComment})

	Log("==== 往 _aWaitingStartBiddingParamsQueue 中新加了一个元素，现在它成为了：")
	UILog(_aWaitingStartBiddingParamsQueue)
end

local function _fnFindContributionParamsIndex(nGolds, szComment) --- 有可能 szComment 被服务端修改了
	for i, t in ipairs(_aContributionParams) do
		if nGolds == t[1] and ((not szComment) or szComment == t[2]) then
			return i
		end
	end

	return nil
end

function GoldTeam_SaveAddContributionParams(nGolds, szComment)
	local nIndex = _fnFindContributionParamsIndex(nGolds, szComment)
	if nIndex then
		table.remove(_aContributionParams, nIndex)
	end

	table.insert(_aContributionParams, {nGolds, szComment})
end

function GoldTeam_SaveEditedBiddingInfo(tBidInfo)
	local dwDoodadID = tBidInfo.dwDoodadID
	local dwItemID = tBidInfo.dwItemID
	local nPrice = tBidInfo.nPrice
	local dwDestPlayerID = tBidInfo.dwDestPlayerID
	local szComment = tBidInfo.szComment

	for nIndex, tInfo in ipairs(_aLastItemBiddingInfos) do --- 一山不容二虎
		if tInfo.dwDoodadID == dwDoodadID and tInfo.dwItemID == dwItemID then
			table.remove(_aLastItemBiddingInfos, nIndex)
			break
		end
	end

	table.insert(_aLastItemBiddingInfos, {dwDoodadID=dwDoodadID, dwItemID=dwItemID,
										  dwDestPlayerID=dwDestPlayerID, nPrice=nPrice, szComment=szComment})
end

function GoldTeam_GetItemNameAndColor(dwItemID, dwItemTabType, dwItemTabIndex, bBrackets)
	local szItemName = ""
	local nItemR, nItemG, nItemB
	local bCanGetItem
	local item = GetItem(dwItemID)
	if item then
		szItemName = ItemData.GetItemNameByItem(item)
		if bBrackets then
			szItemName = "[" .. szItemName .. "]"
		end
		if item.bCanStack and item.nStackNum > 1 then
			szItemName = szItemName .. "x" .. item.nStackNum
		end
		nItemR, nItemG, nItemB = GetItemFontColorByQuality(item.nQuality)
		bCanGetItem = true
	else
		local itemInfo = GetItemInfo(dwItemTabType, dwItemTabIndex)
		szItemName = ItemData.GetItemNameByItemInfo(itemInfo)
		if bBrackets then
			szItemName = "[" .. szItemName .. "]"
		end
		nItemR, nItemG, nItemB = GetItemFontColorByQuality(itemInfo.nQuality)
		bCanGetItem = false
	end
	return szItemName, nItemR, nItemG, nItemB, bCanGetItem
end

function GoldTeam_SaveRecordsToFile(aBidInfoList, bDeleteBySelf)
	local player = GetClientPlayer()
	local i, folder, file = 0, GetStreamAdaptiveDirPath(GetFilePath("GoldTeamBidRecord")) .. "/"
	local dt = TimeToDate(GetCurrentTime())
	CPath.MakeDir(folder)

	local nYear, nMonth, nDay, nHour, nMinute, nSecond = dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
	local szFilePrefix = folder .. (player and player.szName or "UnknownPlayer") .. "_"
	file = szFilePrefix .. ("%04d-%02d-%02d_%02d-%02d-%02d.txt"):format(nYear, nMonth, nDay, nHour, nMinute, nSecond)
	if IsLocalFileExist(file) then
		repeat
			file, i = szFilePrefix .. ("%04d-%02d-%02d_%02d-%02d-%02d-%03d.txt"):format(
					nYear, nMonth, nDay, nHour, nMinute, nSecond, i), i + 1
		until not IsLocalFileExist(file)
	end

	local szDistributorName = "?"
	local team = GetClientTeam()
	if team then
		local dwDistributor = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
		if dwDistributor ~= 0 then
			local tDitributorInfo = team.GetMemberInfo(dwDistributor)
			szDistributorName = tDitributorInfo.szName
		end
	end

	local szProduceTime = ("%04d-%02d-%02d %02d:%02d:%02d"):format(nYear, nMonth, nDay, nHour, nMinute, nSecond)
	local szText = FormatString(g_tStrings.GOLD_TEAM_BID_RECORD_FILE_DESC, szDistributorName, szProduceTime)
	local szTitles = g_tStrings.GOLD_TEAM_BID_RECORD_FILE_TITLE_1 .. "\t" .. g_tStrings.GOLD_TEAM_BID_RECORD_FILE_TITLE_2 ..
			"\t" .. g_tStrings.GOLD_TEAM_BID_RECORD_FILE_TITLE_3 .. "\t" .. g_tStrings.GOLD_TEAM_BID_RECORD_FILE_TITLE_4 ..
			"\t" .. g_tStrings.GOLD_TEAM_BID_RECORD_FILE_TITLE_5 .. "\t" .. g_tStrings.GOLD_TEAM_BID_RECORD_FILE_TITLE_6 ..
			"\t" .. g_tStrings.GOLD_TEAM_BID_RECORD_FILE_TITLE_7 .. "\n"
	szText = szText .. szTitles

	for _, tBidInfo in ipairs(aBidInfoList) do
		local szLine = ""
		local nType = tBidInfo.nType
		local nState = tBidInfo.nState
		local dwItemID = tBidInfo.dwItemID
		local dwItemTabType = tBidInfo.dwItemTabType
		local dwItemTabIndex = tBidInfo.dwItemTabIndex
		local nPrice = tBidInfo.nPrice
		local dwNpcTID = tBidInfo.dwNpcTemplateID
		local szDestPlayerName = tBidInfo.szDestPlayerName
		local szPayerName = tBidInfo.szPayerName
		local nStartTime = tBidInfo.nStartTime
		local szComment = tBidInfo.szComment

		local bIsBidTypeItem = nType == BIDDING_INFO_TYPE.ITEM

		if bIsBidTypeItem then
			szLine = szLine .. GoldTeam_GetItemNameAndColor(dwItemID, dwItemTabType, dwItemTabIndex, true)
		end
		szLine = szLine .. "\t" .. szDestPlayerName
		szLine = szLine .. "\t" .. _GetGoldText(nPrice, false)

		local szSource
		if dwNpcTID and dwNpcTID > 0 then
			szSource = Table_GetBidNpcName(dwNpcTID)
		else
			szSource = tBidInfo.szSource or ""
		end
		szLine = szLine .. "\t" .. szSource

		local t = TimeToDate(nStartTime)
		szLine = szLine .. "\t" .. string.format("%04d/%02d/%02d %02d-%02d-%02d", t.year, t.month, t.day, t.hour, t.minute, t.second)
		szLine = szLine .. "\t" .. szComment
		if nState == BIDDING_INFO_STATE.INVALID then
			szLine = szLine .. "\t" .. g_tStrings.GOLD_TEAM_BID_RECORD_INVALID
		else
			szLine = szLine .. "\t" .. szPayerName
		end

		szText = szText .. szLine .. "\n"
	end

	SaveDataToFile(szText, file)

	local szMsg
	if bDeleteBySelf then
		szMsg = FormatString(g_tStrings.GOLD_TEAM_BID_RECORD_FILE_CREATE_SUCCESS, file)
	else
		szMsg = FormatString(g_tStrings.GOLD_TEAM_BID_RECORD_FILE_CREATE_SUCCESS_2, file)
	end
	local fnOpenFolder = function()
		OpenFolder(file)
	end
	local tMsg =
	{
		bModal = true,
		szName = "goldteam_bidrecord_export",
		szMessage = szMsg,
		{szOption = g_tStrings.GOLD_TEAM_BID_RECORD_OPEN_FOLDER, fnAction = fnOpenFolder},
		{szOption = g_tStrings.STR_CLOSE},
	}
	MessageBox(tMsg)
end

_G.GoldTeam_GetGoldText = _GetGoldText

----------------------------- 全局事件响应 ----------------------------
--- 辅助用函数
local function _AnnounceOnDistributing(tBidInfo, player)
	local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)
	local tTextItem
	if bCanGetItem then
		tTextItem = {type="item", args={szItemName, tBidInfo.dwItemID}}
	else
		tTextItem = {type="iteminfo", args={szItemName, 0, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex}}
	end

	local tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_DISTRIBUTE_ITEM_SUCCESS_MSG,
			{type="name", args={player.szName}}, tTextItem,
			{type="text", args={_GetGoldText(tBidInfo.nPrice, true)}},
			{type="name", args={tBidInfo.szDestPlayerName}})
	Player_Talk(player, PLAYER_TALK_CHANNEL.RAID, "", tText)
end

local function _CompareBidInfoAfterEditing(tCurBidInfo, player)
	local bHasPrevVersion = false
	local dwDoodadID = tCurBidInfo.dwDoodadID
	local dwItemID = tCurBidInfo.dwItemID
	local nPrice = tCurBidInfo.nPrice
	local dwDestPlayerID = tCurBidInfo.dwDestPlayerID
	local szComment = tCurBidInfo.szComment

	local tLastBidInfo
	for nIndex, tInfo in ipairs(_aLastItemBiddingInfos) do
		if tInfo.dwDoodadID == dwDoodadID and tInfo.dwItemID == dwItemID then
			tLastBidInfo = clone(tInfo)
			table.remove(_aLastItemBiddingInfos, nIndex)
			break
		end
	end

	if tLastBidInfo then
		local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tCurBidInfo.dwItemID, tCurBidInfo.dwItemTabType, tCurBidInfo.dwItemTabIndex, true)
		if tLastBidInfo.dwDestPlayerID ~= dwDestPlayerID then
			--- 无法直接同步通知给队友，需要做则走远程调用
			--- 也无法直接以系统通知的形式通知对应玩家，可以考虑改成密聊
			local tTextItem
			if bCanGetItem then
				tTextItem = {type="item", args={szItemName, tCurBidInfo.dwItemID}}
			else
				tTextItem = {type="iteminfo", args={szItemName, 0, tCurBidInfo.dwItemTabType, tCurBidInfo.dwItemTabIndex}}
			end

			local tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_CHANGE_DISTRIBUTE_DEST_SUCCESS_MSG,
					{type="name", args={player.szName}}, tTextItem,
					{type="text", args={_GetGoldText(tCurBidInfo.nPrice, true)}},
					{type="name", args={tCurBidInfo.szDestPlayerName}})
			Player_Talk(player, PLAYER_TALK_CHANNEL.RAID, "", tText)
		else
			local bPriceChange = tLastBidInfo.nPrice ~= nPrice
			local bCommentChange = tLastBidInfo.szComment ~= szComment
			if bPriceChange or bCommentChange then
				local tTextItem
				if bCanGetItem then
					tTextItem = {type="item", args={szItemName, dwItemID}}
				else
					tTextItem = {type="iteminfo", args={szItemName, 0, tCurBidInfo.dwItemTabType, tCurBidInfo.dwItemTabIndex}}
				end

				local tText
				if bPriceChange then
					tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_CHANGE_DISTRIBUTE_PRICE_SUCCESS_MSG,
							{type="name", args={player.szName}},
							{type="name", args={tCurBidInfo.szDestPlayerName}},
							tTextItem,
							{type="text", args={_GetGoldText(tLastBidInfo.nPrice, true)}},
							{type="text", args={_GetGoldText(tCurBidInfo.nPrice, true)}})
					Player_Talk(player, PLAYER_TALK_CHANNEL.RAID, "", tText)
				end
				if bCommentChange then
					tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_CHANGE_DISTRIBUTE_COMMENT_SUCCESS_MSG,
							{type="name", args={player.szName}},
							{type="name", args={tCurBidInfo.szDestPlayerName}},
							tTextItem,
							{type="text", args={"[" .. tLastBidInfo.szComment .. "]"}},
							{type="text", args={"[" .. szComment .. "]"}})
					Player_Talk(player, PLAYER_TALK_CHANNEL.RAID, "", tText)
				end
			end
		end

		bHasPrevVersion = true
	end

	return bHasPrevVersion
end

local function _ShowBuyItemMessageBox(tBidInfo)
	local item = GetItem(tBidInfo.dwItemID)
	local szItemName, szItemColor = "", ""
	if item then
		szItemName = GetItemNameByItem(item)
		szItemName = "[" .. szItemName .. "]"
		if item.bCanStack and item.nStackNum > 1 then
			szItemName = szItemName .. "x" .. item.nStackNum
		end
		szItemColor = GetItemFontColorByQuality(item.nQuality, true)
	else
		local itemInfo = GetItemInfo(tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex)
		szItemName = GetItemNameByItemInfo(itemInfo)
		szItemName = "[" .. szItemName .. "]"
		szItemColor = GetItemFontColorByQuality(itemInfo.nQuality, true)
	end

	local tMsg =
	{
		szMessage = FormatLinkString(
				tBidInfo.nPaidMoney > 0 and g_tStrings.PARTY_GOLD_TEAM_BID_BUY_NOW2 or g_tStrings.PARTY_GOLD_TEAM_BID_BUY_NOW,
				"font=162",
				GetMoneyText({nGold=tBidInfo.nPrice}, "font=162", "cut_front2"),
				GetFormatText(szItemName, "166" .. szItemColor)
		),
		szName = "GoldTeam_BuyItem_Sure" .. tBidInfo.dwItemID,
		bRichText = true,
		bForbidConfirmByEnter = true,

		{szOption = g_tStrings.PARTY_GOLD_TEAM_BID_CHECK_BEFORE_PAY_NOW, nCountDownTime = 3, bDelayCountDown = true,
		 fnAction = function()
			 GoldTeamBase_BidItem(tBidInfo)
		 end,
		 fnCountDownEnd = function(hBtn)
			 local hHndl = hBtn:Lookup("", "")
			 local hText
			 for i = 0, hHndl:GetItemCount() - 1 do
				 hText = hHndl:Lookup(i)
				 if hText:GetType() == "Text" then
					 break
				 end
			 end

			 hText:SetText(g_tStrings.PARTY_GOLD_TEAM_BID_PAY_NOW)
		 end,
		},
		{szOption = g_tStrings.PARTY_GOLD_TEAM_BID_PAY_LATER},
	}
	MessageBox(tMsg)
end

local function _ShowPayPenaltyMessageBox(tBidInfo)
	local tMsg =
	{
		szMessage = FormatLinkString(
				g_tStrings.PARTY_GOLD_TEAM_BID_PAY_FINE_NOW,
				"font=162",
				GetMoneyText({nGold=tBidInfo.nPrice}, "font=162", "cut_front2")
		),
		szName = "GoldTeam_PayFine_Sure" .. tBidInfo.nBiddingInfoIndex,
		bRichText = true,

		{szOption = g_tStrings.STR_HOTKEY_SURE,
		 fnAction = function()
			 GoldTeamBase_BidItem(tBidInfo)
		 end,
		},
		{szOption = g_tStrings.STR_HOTKEY_CANCEL},
	}
	MessageBox(tMsg)
end

local function _AnnounceOnAddingPenalty(tBidInfo, player)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.PARTY_GOLD_TEAM_ADD_PENALTY_SUCCESS_MSG, szGolds))

	local tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_ADD_PENALTY_SUCCESS_CHAT_MSG,
			{type="name", args={player.szName}},
			{type="name", args={tBidInfo.szDestPlayerName}},
			{type="text", args={szGolds}})
	Player_Talk(player, PLAYER_TALK_CHANNEL.RAID, "", tText)
end

local function _AnnounceOnBoughtItem(tBidInfo, player)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)

	local tTextItem
	if bCanGetItem then
		tTextItem = {type="item", args={szItemName, tBidInfo.dwItemID}}
	else
		tTextItem = {type="iteminfo", args={szItemName, 0, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex}}
	end

	local tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_SUCCESS_CHAT_MSG,
			{type="name", args={tBidInfo.szPayerName}},
			{type="text", args={szGolds}},
			tTextItem)
	Player_Talk(player, PLAYER_TALK_CHANNEL.RAID, "", tText)

	OutputMessage("MSG_SYS", FormatString(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_SUCCESS_MSG, szGolds, szItemName)) --- IMPORTANT  以后考虑也做成支持链接功能（但是不能用Player_Talk()机制）
end

local function _AnnounceOnBoughtItemForHim(tBidInfo, playerPayer)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)

	local tTextItem
	if bCanGetItem then
		tTextItem = {type="item", args={szItemName, tBidInfo.dwItemID}}
	else
		tTextItem = {type="iteminfo", args={szItemName, 0, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex}}
	end

	local tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_FOR_HIM_SUCCESS_CHAT_MSG,
			{type="name", args={tBidInfo.szPayerName}},
			{type="text", args={szGolds}},
			{type="name", args={tBidInfo.szDestPlayerName}},
			tTextItem)
	Player_Talk(playerPayer, PLAYER_TALK_CHANNEL.RAID, "", tText)
end

local function _AnnounceOnBoughtItemForMe(tBidInfo)
	local szGolds = _GetGoldText(tBidInfo.nPrice, true)
	local szItemName, _, _, _, bCanGetItem = GoldTeam_GetItemNameAndColor(tBidInfo.dwItemID, tBidInfo.dwItemTabType, tBidInfo.dwItemTabIndex, true)
	local szMsg = FormatString(g_tStrings.PARTY_GOLD_TEAM_BUY_ITEM_FOR_ME_SUCCESS_MSG, "[" .. tBidInfo.szPayerName .. "]",
			szGolds, szItemName)
	OutputMessage("MSG_SYS", szMsg) --- IMPORTANT  以后考虑也做成支持链接功能（但是不能用Player_Talk()机制）
end


local function _AnnounceOnContributionSuccess(tBidInfo, player, bIsDestPlayerSelf)
	local szMsg = FormatString(g_tStrings.PARTY_GOLD_TEAM_MAKE_CONTRIBUTION_SUCCESS_MSG, "[" .. tBidInfo.szPayerName .. "]")
	OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)

	if bIsDestPlayerSelf then
		local scene = GetClientScene()
		local szMapName = scene and Table_GetMapName(scene.dwMapID) or g_tStrings.STR_QUESTION_M
		local nChannel = GoldTeamBase_GetChannel()

		local tText = GetTalkTextsFromString(g_tStrings.PARTY_GOLD_TEAM_MAKE_CONTRIBUTION_SUCCESS_CHAT_MSG,
				{type="name", args={player.szName}},
				{type="text", args={szMapName}},
				{type="text", args={_GetGoldText(tBidInfo.nPrice, true)}},
				{type="text", args={szMapName}})
		Player_Talk(player, nChannel, "", tText)
	end
end

local function _OnBiddingOperationSuccess()
	Log("==== 响应了事件 BIDDING_OPERATION，参数 eBidOperationType == " .. tostring(arg0))
	local eBidOperationType, dwOperatorPlayerID, nBidInfoIndex, nOperationTimestamp = arg0, arg1, arg2, arg3
	local player = GetClientPlayer()
	local dwPlayerID = player.dwID
	local bIsOperatorSelf = dwOperatorPlayerID == dwPlayerID
	local teamBidMgr = GetTeamBiddingMgr()
	local tBidInfo = teamBidMgr.GetBiddingInfo(nBidInfoIndex)
	if not tBidInfo or IsTableEmpty(tBidInfo) then
		return
	end

	local bIsDestPlayerSelf = tBidInfo.dwDestPlayerID == dwPlayerID
	local bIsPayerSelf = tBidInfo.dwPayerID == dwPlayerID

	if eBidOperationType == BIDDING_OPERATION_TYPE.FINISH then
		if bIsOperatorSelf and GoldTeamDistribution_IsOpen() then
			GoldTeamDistribution_Close(true)
		end

		local bIsSelfPenaltyStarter = false

		if bIsOperatorSelf then
			if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
				if not _CompareBidInfoAfterEditing(tBidInfo, player) then
					_AnnounceOnDistributing(tBidInfo, player)
				end
			else
				bIsSelfPenaltyStarter = true
			end
		end

		if bIsDestPlayerSelf then
			local fnBuy = function()
				GoldTeamBase_BidItem(tBidInfo)
			end

			if GoldTeamBase_GetRequiredGold(tBidInfo) == 0 then
				fnBuy() --- 免费的直接付
				return
			end

			local nType = tBidInfo.nType
			if nType == BIDDING_INFO_TYPE.ITEM then
				_ShowBuyItemMessageBox(tBidInfo)
			else --- 罚款类型
				if bIsOperatorSelf then
					local nRequiredGold = GoldTeamBase_GetRequiredGold(tBidInfo)
					local nIndex = _fnFindContributionParamsIndex(nRequiredGold)
					if nIndex then --- 说明是自己发起的捐款
						bIsSelfPenaltyStarter = false

						if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
							return
						end

						table.remove(_aContributionParams, nIndex)

						--- 说明自己发起的捐款成功了，需要马上付款
						local tMoney = player.GetMoney()
						local nPlayerGold, nPlayerSilver, nPlayerCopper = UnpackMoney(tMoney)

						if nPlayerGold >= nRequiredGold then
							local nRetCode = teamBidMgr.CanRiseMoney(nBidInfoIndex, nRequiredGold)
							if nRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
								Log("==== 在 GoldTeamAddMoney 界面中，即将进行捐款")
								teamBidMgr.RiseMoney(nBidInfoIndex, nRequiredGold)
							else
								OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GOLD_TEAM_MAKE_CONTRIBUTION_FAIL)
							end
						end
					else
						_ShowPayPenaltyMessageBox(tBidInfo)
					end
				else
					_ShowPayPenaltyMessageBox(tBidInfo)
				end
			end
		end

		if bIsSelfPenaltyStarter then
			_AnnounceOnAddingPenalty(tBidInfo, player)
		end
	elseif eBidOperationType == BIDDING_OPERATION_TYPE.RISE_MONEY then
		if bIsOperatorSelf then
			if IsGoldTeamAddMoneyOpened() and tBidInfo.nType == BIDDING_INFO_TYPE.PENALTY and bIsDestPlayerSelf then
				CloseGoldTeamAddMoney(true)
			end
		end

		if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
			if tBidInfo.nState == BIDDING_INFO_STATE.PAID then
				if tBidInfo.dwDestPlayerID == tBidInfo.dwPayerID then
					if bIsPayerSelf then --- 自己给自己支付
						_AnnounceOnBoughtItem(tBidInfo, player)
					end
				else
					if bIsPayerSelf then -- 自己给别人代付
						_AnnounceOnBoughtItemForHim(tBidInfo, player)
					elseif bIsDestPlayerSelf then
						_AnnounceOnBoughtItemForMe(tBidInfo)
					end
				end
			end
		else
			if tBidInfo.dwDestPlayerID == tBidInfo.dwPayerID then --- 说明是捐款（也可能就是普通的罚款，现在不予区分）
				_AnnounceOnContributionSuccess(tBidInfo, player, bIsDestPlayerSelf)
			end
		end
	elseif eBidOperationType == BIDDING_OPERATION_TYPE.END then
		if bIsOperatorSelf then
			local tParams, nParamsIndex = _FindStartBidParamsByBidInfoIndex(nBidInfoIndex)
			if tParams then
				local dwDoodadID, nItemLootIndex, nPriceInGolds, dwDestPlayerID, szComment = tParams[2], tParams[3],
				tParams[4], tParams[5], tParams[6]
				local eRetCode
				if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
					assert(dwDoodadID > 0)
					eRetCode = teamBidMgr.CanFinishBidding(dwDoodadID, nItemLootIndex, nPriceInGolds, dwDestPlayerID)
					if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
						teamBidMgr.FinishBidding(dwDoodadID, dwDestPlayerID, nPriceInGolds, nItemLootIndex, szComment)
					else
						GoldTeamBase_OnBiddingStartError(eRetCode)
					end
				else
					--- 对应于罚款
					eRetCode = teamBidMgr.CanAddPenaltyRecord(nPriceInGolds, dwDestPlayerID)
					if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
						teamBidMgr.AddPenaltyRecord(dwDestPlayerID, nPriceInGolds, szComment)
					else
						GoldTeamBase_OnBiddingStartError(eRetCode)
					end
				end
			else
				--- 肯定是来自于修改后金额为0的罚款
				GoldTeamDistribution_Close(true)
			end
		end
	end
end

function GoldTeamBase_OnBiddingStartError(nErrCode)
	local szErrString = g_tStrings.tTeamBiddingStartError[nErrCode]
	if szErrString then
		OutputMessage("MSG_ANNOUNCE_NORMAL", szErrString)
	else
		UILog("Unrecognized Bidding Start Error Code: " .. tostring(nErrCode))
	end
end

function GoldTeamBase_OnBiddingItemError(nErrCode)
	local szErrString = g_tStrings.tTeamBiddingStartError[nErrCode]
	if szErrString then
		OutputMessage("MSG_ANNOUNCE_NORMAL", szErrString)
	else
		UILog("Unrecognized Bidding Start Error Code: " .. tostring(nErrCode))
	end
end

function GoldTeamBase_OnBiddingEndError(nErrCode)
	local szErrString = g_tStrings.tTeamBiddingStartError[nErrCode]
	if szErrString then
		OutputMessage("MSG_ANNOUNCE_NORMAL", szErrString)
	else
		UILog("Unrecognized Bidding Start Error Code: " .. tostring(nErrCode))
	end
end

Event.Reg(AuctionData, "BIDDING_OPERATION", _OnBiddingOperationSuccess)
Event.Reg(AuctionData, "BIDDING_START_RETURN_CODE", function() GoldTeamBase_OnBiddingStartError(arg0) end)
Event.Reg(AuctionData, "RISE_MONEY_RETURN_CODE", function() GoldTeamBase_OnBiddingItemError(arg0) end)
Event.Reg(AuctionData, "BIDDING_END_RETURN_CODE", function() GoldTeamBase_OnBiddingEndError(arg0) end)

local function _OnEventLinkNotify()
	if arg0 == "OpenGoldTeam" then
		GoldTeam_GoToRecordsPage()
	end
end

local function _OnTeamAuthorityChange()
	if arg0 == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
		_aLastItemBiddingInfos = {}
	end
end

local function _OnPartyDisband()
	_aLastItemBiddingInfos = {}
end

local function _OnPartyDeleteMember()
	if UI_GetClientPlayerID() == arg1 then
		_aLastItemBiddingInfos = {}
	end
end

local function _ControlPanel()
	local pPlayer = GetClientPlayer()
    local dwMapId = pPlayer.GetMapID()
    local _, nMapType = GetMapParams(dwMapId)
    if nMapType == MAP_TYPE.DUNGEON then
        local clientTeam = GetClientTeam()
        if not clientTeam then
			Storage.Auction.tNoPromotDoodadList = {}
        end
    else
		Storage.Auction.tNoPromotDoodadList = {}
    end
end

Event.Reg(AuctionData, "EVENT_LINK_NOTIFY", _OnEventLinkNotify)
Event.Reg(AuctionData, "TEAM_AUTHORITY_CHANGED", _OnTeamAuthorityChange)
Event.Reg(AuctionData, "PARTY_DISBAND", _OnPartyDisband)
Event.Reg(AuctionData, "PARTY_DELETE_MEMBER", _OnPartyDeleteMember)
Event.Reg(AuctionData, "LOADING_END", _ControlPanel)

----------- 测试用
