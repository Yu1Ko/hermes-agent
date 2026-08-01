-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetTongLog
-- Date: 2023-01-06
-- Desc: 帮会日志页
-- Prefab: WidgetFactionManagementRecord
-- ---------------------------------------------------------------------------------

local UIWidgetTongLog = class("UIWidgetTongLog")

local g2u = UIHelper.GBKToUTF8

local function _fnGetMemberName(dwID)
	local szName = ""
	local guild = GetTongClient()
	if guild then
		szName = guild.GetMemberName(dwID) or ""
	end
	return szName
end

local function _fnIsArrow(nType, itemInfo)
	return nType == ITEM_INFO_TYPE.CUSTEQUIP_INFO and itemInfo.nSub == EQUIPMENT_SUB.ARROW
end

function UIWidgetTongLog:Init()
	self.m = {}
	self.m.tRecordCount = {}

	self:RegEvent()
	self:BindUIEvent()

	--self:UpdateMainTab()
	self:UpdateSubTab()
	self:UpdateList()

end


function UIWidgetTongLog:UpdateMainTab()
	local root = self.WidgetAnchorNavigation
	assert(root)
	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupNavigation)
	local children = UIHelper.GetChildren(root)
	for i, child in ipairs(children) do
		if UIHelper.GetVisible(child) then
			UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, child)
		end
	end

	if not self.m.szMainType then
		self.m.bDoNothing = true
		UIHelper.SetToggleGroupSelected(self.ToggleGroupNavigation, 0)
		self.m.bDoNothing = false
	end
end

function UIWidgetTongLog:UpdateSubTab()
	local root = self.WidgetTitle
	assert(root)
	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupTitle)
	local children = UIHelper.GetChildren(root)
	for i, child in ipairs(children) do
		UIHelper.ToggleGroupAddToggle(self.ToggleGroupTitle, child)
	end

	if not self.m.szSubType then
		self.m.bDoNothing = true
		UIHelper.SetToggleGroupSelected(self.ToggleGroupTitle, 0)
		self.m.bDoNothing = false
	end

end


function UIWidgetTongLog:UnInit()
	self:UnRegEvent()
	UIHelper.RemoveFromParent(self._rootNode)
	self.m = nil
end

function UIWidgetTongLog:BindUIEvent()
    self.ToggleGroupNavigation:addEventListener(function (toggle, nIndexBaseZero)
		self:OnMainTabSelectChanged(nIndexBaseZero + 1)
    end)
    self.ToggleGroupTitle:addEventListener(function (toggle, nIndexBaseZero)
		self:OnSubTabSelectChanged(nIndexBaseZero + 1)
    end)

end

local function _fnSortSystemRecord(tLeft, tRight)
	return tLeft.time > tRight.time
end

function UIWidgetTongLog:RegEvent()
	Event.Reg(self, "SwitchTongRecordTab", function (nIndex)
		self:OnMainTabSelectChanged(nIndex)
	end)
	Event.Reg(self, "ON_SYNC_CUSTOM_RECORDING", function ()
		if arg0 == CUSTOM_RECORDING_TYPE.TONG_SYSTEM then
			print("====> CUSTOM_RECORDING_TYPE.TONG_SYSTEM: ", #arg2)
			table.sort(arg2, _fnSortSystemRecord)
			self.m.tBigRecordArr = arg2
			self:UpdateBigRecordList()
		end
	end)
	Event.Reg(self, "SYNC_TONG_HISTORY", function ()
		-- GuildMainPanel.UpdateHistory
		--print("====> SYNC_TONG_HISTORY: ", arg0, arg1, arg2)
		local eHistoryType, nStartIndex, nCount = arg0, arg1, arg2
		if nStartIndex and nCount then
			nCount = nStartIndex + nCount
			if eHistoryType == TONG_HISTORY_TYPE.DONATE_FUND then
				self.m.tRecordCount.nPersonFundRecord = nCount
			elseif eHistoryType == TONG_HISTORY_TYPE.SYSTEM_CHANGE_FUND then
				self.m.tRecordCount.nSystemFundRecord = nCount
			elseif eHistoryType == TONG_HISTORY_TYPE.ITEM_CHANGE then
				self.m.tRecordCount.nPersonItemRecord = nCount
			elseif eHistoryType == TONG_HISTORY_TYPE.SYSTEM_ITEM_CHANGE then
				self.m.tRecordCount.nSystemItemRecord = nCount
			elseif eHistoryType == TONG_HISTORY_TYPE.JOIN_OR_LEAVE then
				self.m.tRecordCount.nMemberRecord = nCount
			elseif eHistoryType == TONG_HISTORY_TYPE.FIGURE_CHANGED then
				self.m.tRecordCount.nGroupMemberRecord = nCount
			elseif eHistoryType == TONG_HISTORY_TYPE.GROUP_PERMISSION_CHANGED then
				self.m.tRecordCount.nGroupPermissionRecord = nCount
			end
			self:UpdateList()
		end
	end)
end

function UIWidgetTongLog:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTongLog:RequestHistory(nType)
	-- _fnApplyHistoryData
	GetTongClient().SyncHistory(nType)
end

local _tMainTabKeyArr = {
	"Big",
	"Fund",
	"Item",
	"Member",
	"GroupMember",
	"GroupPermission",
}
function UIWidgetTongLog:OnMainTabSelectChanged(nSelectIndex)
	local szType = _tMainTabKeyArr[nSelectIndex]
	assert(szType)
	self.m.szMainType = szType

	self.m.tRecordCount = {}
	self:UpdateList(szType)
end

function UIWidgetTongLog:OnSubTabSelectChanged(nSelectIndex)
	local szType
	if 1 == nSelectIndex then
		szType = "Person"
	elseif 2 == nSelectIndex then
		szType = "System"
	end
	assert(szType)
	self.m.szSubType = szType

	self.m.tRecordCount = {}
	self:UpdateList()
end

function UIWidgetTongLog:UpdateList(szType)
	if self.m.bDoNothing then return end

	szType = szType or self.m.szMainType or "Big"
	UIHelper.SetVisible(self.WidgetAnchorRecord, false)
	UIHelper.SetVisible(self.WidgetAnchorRecord01, false)

	if "Big" == szType then
		self:UpdateBigRecordList()
	elseif "Fund" == szType then
		self:UpdateFundRecordList()
	elseif "Item" == szType then
		self:UpdateItemRecordList()
	elseif "Member" == szType then
		self:UpdateMemberRecordList()
	elseif "GroupMember" == szType then
		self:UpdateGroupMemberRecordList()
	elseif "GroupPermission" == szType then
		self:UpdateGroupPermissionRecordList()
	end
end

local _tCellFieldNameArr = {
	--"Container",
	"LabelTime",
	"LabelText",
}

function UIWidgetTongLog:UpdateTimeLabel(label, nTime)
	local time = TimeToDate(nTime)
	--local szTime = FormatString(g_tStrings.STR_TONG_RECORD_TIME, time.year, time.month, time.day, time.hour, time.minute, time.second)
	local szTime = string.format(g_tStrings.STR_TIME_STANDARD, time.year, time.month, time.day, time.hour, time.minute, time.second)
	UIHelper.SetString(label, szTime)
end


function UIWidgetTongLog:UpdateBigRecordList()
	UIHelper.SetVisible(self.WidgetAnchorRecord01, true)

	local list = self.ScrollViewRecordFactionRecord01
	assert(list)
	UIHelper.RemoveAllChildren(list)

	-- 未同步数据, 先请求
	local arr = self.m.tBigRecordArr
	if not arr then
		GetCustomRecording(CUSTOM_RECORDING_TYPE.TONG_SYSTEM)
		return
	end

	for i, tData in ipairs(arr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRecordFactionRecord, list)
		assert(cell)
		self:UpdateBigRecordCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0)

	UIHelper.SetVisible(self.WidgetDescibe, #arr == 0)
end

function UIWidgetTongLog:UpdateBigRecordCell(cell, tData)
	assert(cell)
	local tCell = {}
	UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

	-- time
	self:UpdateTimeLabel(tCell.LabelTime, tData.time)

	-- text
	local szText = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tData.text))
	UIHelper.SetRichText(tCell.LabelText, szText)
end

function UIWidgetTongLog:UpdateFundRecordList()
	UIHelper.SetVisible(self.WidgetAnchorRecord, true)

	local list = self.ScrollViewRecordFactionRecord
	assert(list)

	-- 未同步数据, 先请求
	local tong = GetTongClient()
	local szSubType = self.m.szSubType or "Person"
	local nCount, nType
	if szSubType == "Person" then
		nCount = self.m.tRecordCount.nPersonFundRecord
		nType = TONG_HISTORY_TYPE.DONATE_FUND
	else
		nCount = self.m.tRecordCount.nSystemFundRecord
		nType = TONG_HISTORY_TYPE.SYSTEM_CHANGE_FUND
	end
	if not nCount then
		UIHelper.RemoveAllChildren(list)
		self:RequestHistory(nType)
		return
	end

	local nStartIndex = list:getChildrenCount()
	for i = nStartIndex, nCount - 1 do
		local tData = tong.GetHistoryRecord(nType, i)
		assert(tData)
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRecordFactionRecord, list)
		assert(cell)
		self:UpdateFundRecordCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0)

	UIHelper.SetVisible(self.WidgetDescibe, nCount == 0)
end

function UIWidgetTongLog:UpdateFundRecordCell(cell, tData)
	assert(cell)
	local tCell = {}
	UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

	-- time
	self:UpdateTimeLabel(tCell.LabelTime, tData.nTime)

	-- text
	local szMsg = ""
	---- 个人
	if self.m.szSubType == "Person" then
		local szName = g2u(_fnGetMemberName(tData.dwPlayer))
		if szName == "" then
			szName = g_tStrings.GUILD_UNKNOWN_MEMBER
		end
		szName = string.format("[%s]", tostring(szName))

		if tData.nMoney >= 0 then
			local szMoney = UIHelper.GetGoldText(tData.nMoney)
			--szMsg = FormatLinkString(g_tStrings.GUILD_ADD_FUND, "font=162", szTime, szName, szMoney)
			szMsg = string.format("%s贡献%s。", tostring(szName), tostring(szMoney))
		else
			local szMoney = UIHelper.GetGoldText(-tData.nMoney)
			--szMsg = FormatLinkString(g_tStrings.GUILD_TAKE_FUND, "font=162", szTime, szName, szMoney)
			szMsg = string.format("%s取出%s。", tostring(szName), tostring(szMoney))
		end
	---- 系统
	else
		local szEvent = g_tStrings.GUILD_EVENT_TYPE[tData.wType]
		if tData.nMoney >= 0 then
			local szMoney = UIHelper.GetGoldText(tData.nMoney)
			--szMsg = FormatLinkString(g_tStrings.GUILD_SYS_ADD_FUND, "font=162", szTime, szEvent, szMoney)
			szMsg = string.format("%s中获得%s。", tostring(szEvent), tostring(szMoney))
		else
			local szMoney = UIHelper.GetGoldText(-tData.nMoney)
			--szMsg = FormatLinkString(g_tStrings.GUILD_SYS_TAKE_FUND, "font=162", szTime, szEvent, szMoney)
			szMsg = string.format("%s中消耗%s。", tostring(szEvent), tostring(szMoney))
		end
	end

	UIHelper.SetRichText(tCell.LabelText, szMsg)
end

function UIWidgetTongLog:UpdateItemRecordList()
	UIHelper.SetVisible(self.WidgetAnchorRecord, true)

	local list = self.ScrollViewRecordFactionRecord
	assert(list)

	-- 未同步数据, 先请求
	local tong = GetTongClient()
	local szSubType = self.m.szSubType or "Person"
	local nCount, nType
	if szSubType == "Person" then
		nCount = self.m.tRecordCount.nPersonItemRecord
		nType = TONG_HISTORY_TYPE.ITEM_CHANGE
	else
		nCount = self.m.tRecordCount.nSystemItemRecord
		nType = TONG_HISTORY_TYPE.SYSTEM_ITEM_CHANGE
	end
	if not nCount then
		UIHelper.RemoveAllChildren(list)
		self:RequestHistory(nType)
		return
	end

	local nStartIndex = list:getChildrenCount()
	for i = nStartIndex, nCount - 1 do
		local tData = tong.GetHistoryRecord(nType, i)
		assert(tData)
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRecordFactionRecord, list)
		assert(cell)
        self:UpdateItemRecordCell(cell, tData)
    end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0)

	UIHelper.SetVisible(self.WidgetDescibe, nCount == 0)
end

function UIWidgetTongLog:UpdateItemRecordCell(cell, tData)
	assert(cell)
	local tCell = {}
	UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

	-- time
	self:UpdateTimeLabel(tCell.LabelTime, tData.nTime)

	-- text
	local szName = g2u(_fnGetMemberName(tData.dwPlayer))
	if szName == "" then
		szName = g_tStrings.GUILD_UNKNOWN_MEMBER
	end
	szName = string.format("[%s]", szName)

	local szMsg = ""
	local itemInfo, nType = ItemData.GetItemInfo(tData.nItemType, tData.nItemIndex)
	if itemInfo then
		local szItemName = ItemData.GetItemNameByItemInfo(itemInfo, tData.nStackNum)
		--local szColor = GetItemFontColorByQuality(itemInfo.nQuality, true)
		local szItem = ""
		-- if itemInfo.nGenre == ITEM_GENRE.BOOK then
		-- 	szItem = MakeBookLink("["..szItemName.."]", "font=164 "..szColor, 0, tData.nItemType, tData.nItemIndex, tData.nStackNum)
		-- else
		-- 	szItem = MakeItemInfoLink("["..szItemName.."]", "font=164 "..szColor, 0, tData.nItemType, tData.nItemIndex)
		-- end
		szItem = "[" .. g2u(szItemName) .. "]"
		if not _fnIsArrow(nType, itemInfo) and not itemInfo.bCanStack then
			tData.nStackNum = 1
		end

		if self.m.szSubType == "Person" then
			if tData.bTake then
				--szMsg = FormatLinkString(g_tStrings.GUILD_TAKE_ITEM, "font=162", szTime, szName, szItem, tData.nStackNum)
				szMsg = string.format("%s取出%s X %d。", szName, szItem, tData.nStackNum)
			else
				--szMsg = FormatLinkString(g_tStrings.GUILD_ADD_ITEM, "font=162", szTime, szName, szItem, tData.nStackNum)
				szMsg = string.format("%s存入%s X %d。", szName, szItem, tData.nStackNum)
			end
		else
			if tData.bAdd then
				--szMsg = FormatLinkString(g_tStrings.GUILD_SYS_ADD_ITEM, "font=162", szTime, szItem, tData.nStackNum)
				szMsg = string.format("系统生成%s X %d。", szItem, tData.nStackNum)
			else
				--szMsg = FormatLinkString(g_tStrings.GUILD_SYS_TAKE_ITEM, "font=162", szTime, szItem, tData.nStackNum)
				szMsg = string.format("系统消耗%s X %d。", szItem, tData.nStackNum)
			end
		end
	end

	UIHelper.SetRichText(tCell.LabelText, szMsg)
end

function UIWidgetTongLog:UpdateMemberRecordList()
	UIHelper.SetVisible(self.WidgetAnchorRecord01, true)

	local list = self.ScrollViewRecordFactionRecord01

	-- 未同步数据, 先请求
	local tong = GetTongClient()
	local nCount, nType = self.m.tRecordCount.nMemberRecord, TONG_HISTORY_TYPE.JOIN_OR_LEAVE
	if not nCount then
		UIHelper.RemoveAllChildren(list)
		self:RequestHistory(nType)
		return
	end

	local nStartIndex = list:getChildrenCount()
	for i = nStartIndex, nCount - 1 do
		local tData = tong.GetHistoryRecord(nType, i)
		assert(tData)
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRecordFactionRecord, list)
		assert(cell)
		self:UpdateMemberRecordCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0)

	UIHelper.SetVisible(self.WidgetDescibe, nCount == 0)
end

function UIWidgetTongLog:UpdateMemberRecordCell(cell, tData)
	assert(cell)
	local tCell = {}
	UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

	-- time
	self:UpdateTimeLabel(tCell.LabelTime, tData.nTime)

	-- text
	local szName = g2u(_fnGetMemberName(tData.dwPlayerID))
	local szNameOp = g2u(_fnGetMemberName(tData.dwOperatorID))

	if szName == "" then
		szName = g_tStrings.GUILD_UNKNOWN_MEMBER
	end
	if szNameOp == "" then
		szNameOp = g_tStrings.GUILD_UNKNOWN_MEMBER
	end

	local szMsg = ""
	if tData.nType == TONG_HISTORY_JOIN_OR_LEAVE_DESC.INVITE_JOIN then
		szMsg = string.format("[%s]与本帮同声相应，同气相求，受[%s]之邀加入帮会。", szName, szNameOp)
	elseif tData.nType == TONG_HISTORY_JOIN_OR_LEAVE_DESC.ACCEPT_JOIN then
		szMsg = string.format("[%s]慕名而来，被[%s]批准加入帮会。", szName, szNameOp)
	elseif tData.nType == TONG_HISTORY_JOIN_OR_LEAVE_DESC.QUIT_LEAVE then
		szMsg = string.format("[%s]与本帮志不同道不合，自行离开了帮会。", szName)
	elseif tData.nType == TONG_HISTORY_JOIN_OR_LEAVE_DESC.KICK_LEAVE then
		szMsg = string.format("[%s]触犯帮规，被[%s]踢出了帮会！", szName, szNameOp)
	elseif tData.nType == TONG_HISTORY_JOIN_OR_LEAVE_DESC.SYSTEM_LEAVE then
		szMsg = string.format("[%s]被系统移除出帮。", szName)
	end
	UIHelper.SetRichText(tCell.LabelText, szMsg)
end

function UIWidgetTongLog:UpdateGroupMemberRecordList()
	UIHelper.SetVisible(self.WidgetAnchorRecord01, true)

	local list = self.ScrollViewRecordFactionRecord01

	-- 未同步数据, 先请求
	local tong = GetTongClient()
	local nCount, nType = self.m.tRecordCount.nGroupMemberRecord, TONG_HISTORY_TYPE.FIGURE_CHANGED
	if not nCount then
		UIHelper.RemoveAllChildren(list)
		self:RequestHistory(nType)
		return
	end

	local nStartIndex = list:getChildrenCount()
	for i = nStartIndex, nCount - 1 do
		local tData = tong.GetHistoryRecord(nType, i)
		assert(tData)
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRecordFactionRecord, list)
		assert(cell)
		self:UpdateGroupMemberRecordCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0)

	UIHelper.SetVisible(self.WidgetDescibe, nCount == 0)
end

function UIWidgetTongLog:UpdateGroupMemberRecordCell(cell, tData)
	assert(cell)
	local tCell = {}
	UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

	-- time
	self:UpdateTimeLabel(tCell.LabelTime, tData.nTime)

	-- text
	local tong = GetTongClient()
	local szOperatorName = g2u(tData.szPlayerName)
	local szTargetPlayerName = g2u(tData.szTargetPlayerName)

	if szOperatorName == "" then
		szOperatorName = g_tStrings.GUILD_UNKNOWN_MEMBER
	end
	szOperatorName = string.format("[%s]", szOperatorName)

	if szTargetPlayerName == "" then
		szTargetPlayerName = g_tStrings.GUILD_UNKNOWN_MEMBER
	end
	szTargetPlayerName = string.format("[%s]", szTargetPlayerName)

	local nOrgGroup, nTargetGroup = tData.nGroup, tData.nTargetGroup
	local szOrgGroup, szTargetGroup
	local groupInfo = tong.GetGroupInfo(nOrgGroup)
	szOrgGroup = "[" .. (groupInfo and g2u(groupInfo.szName) or g_tStrings.GUILD_UNKNOWN_GROUP) .. "]"
	groupInfo = tong.GetGroupInfo(nTargetGroup)
	szTargetGroup = "[" .. (groupInfo and g2u(groupInfo.szName) or g_tStrings.GUILD_UNKNOWN_GROUP) .. "]"

	-- local szMsg = FormatLinkString(g_tStrings.GUILD_LOG_PERSON_GROUP_CHANGE, "font=162", szTime, szOperatorName,
	-- 		szTargetPlayerName, szOrgGroup, szTargetGroup)
	local szMsg = string.format("%s将%s的头衔从%s变更成了%s。",
		szOperatorName,
		szTargetPlayerName,
		szOrgGroup,
		szTargetGroup)
	UIHelper.SetRichText(tCell.LabelText, szMsg)
end

function UIWidgetTongLog:UpdateGroupPermissionRecordList()
	UIHelper.SetVisible(self.WidgetAnchorRecord01, true)

	local list = self.ScrollViewRecordFactionRecord01

	-- 未同步数据, 先请求
	local tong = GetTongClient()
	local nCount, nType = self.m.tRecordCount.nGroupPermissionRecord, TONG_HISTORY_TYPE.GROUP_PERMISSION_CHANGED
	if not nCount then
		UIHelper.RemoveAllChildren(list)
		self:RequestHistory(nType)
		return
	end

	local nStartIndex = list:getChildrenCount()
	for i = nStartIndex, nCount - 1 do
		local tData = tong.GetHistoryRecord(nType, i)
		assert(tData)
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRecordFactionRecord, list)
		assert(cell)
		self:UpdateGroupPermissionRecordCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0)

	UIHelper.SetVisible(self.WidgetDescibe, nCount == 0)
end

function UIWidgetTongLog:UpdateGroupPermissionRecordCell(cell, tData)
	assert(cell)
	local tCell = {}
	UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

	-- time
	self:UpdateTimeLabel(tCell.LabelTime, tData.nTime)

	-- text
	local tong = GetTongClient()
	local szOperatorName = g2u(tData.szPlayerName)
	if szOperatorName == "" then
		szOperatorName = g_tStrings.GUILD_UNKNOWN_MEMBER
	end
	szOperatorName = string.format("[%s]", szOperatorName)

	local szMsg
	local bBasicOperation = tData.bBase
	local nPermissionIndex = tData.nIndex
	local bPermissionOpened = tData.bValue
	if bBasicOperation then
		local nGroup = tData.nGroup
		local groupInfo = tong.GetGroupInfo(nGroup)
		local szGroup = "[" .. (groupInfo and g2u(groupInfo.szName) or g_tStrings.GUILD_UNKNOWN_GROUP) .. "]"
		local szPermission = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[nPermissionIndex]

		-- szMsg = FormatLinkString(g_tStrings.GUILD_LOG_GROUP_BASIC_PERMISSION_CHANGE, "font=162", szTime, szOperatorName,
		-- 		bPermissionOpened and g_tStrings.GUILD_LOG_PERMISSION_OPEN or g_tStrings.GUILD_LOG_PERMISSION_CLOSE,
		-- 		szGroup, szPermission)
		szMsg = string.format("%s%s了头衔%s的<D4>权限。",
			szOperatorName,
			bPermissionOpened and g_tStrings.GUILD_LOG_PERMISSION_OPEN or g_tStrings.GUILD_LOG_PERMISSION_CLOSE,
			szGroup,
			szPermission)

	else
		local nOrigGroup = tData.nGroup
		local nTargetGroup = tData.nTargetGroup

		local groupInfo = tong.GetGroupInfo(nOrigGroup)
		local szOrigGroup = "[" .. (groupInfo and g2u(groupInfo.szName) or g_tStrings.GUILD_UNKNOWN_GROUP) .. "]"
		groupInfo = tong.GetGroupInfo(nTargetGroup)
		local szTargetGroup = "[" .. (groupInfo and g2u(groupInfo.szName) or g_tStrings.GUILD_UNKNOWN_GROUP) .. "]"

		local szPermissionOpened = bPermissionOpened and g_tStrings.GUILD_LOG_PERMISSION_OPEN or g_tStrings.GUILD_LOG_PERMISSION_CLOSE
		-- 重要：待正式化
		if nPermissionIndex == 0 then
			-- szMsg = FormatLinkString(g_tStrings.GUILD_LOG_GROUP_ADVANCED_PERMISSION_CHANGE_1, "font=162", szTime, szOperatorName,
			-- 		szPermissionOpened, szOrigGroup, szTargetGroup)
			szMsg = string.format("%s%s了头衔%s向头衔%s中增减人员的权限。",
				szOperatorName,
				szPermissionOpened,
				szOrigGroup,
				szTargetGroup)

		elseif nPermissionIndex == 2 then
			-- szMsg = FormatLinkString(g_tStrings.GUILD_LOG_GROUP_ADVANCED_PERMISSION_CHANGE_2, "font=162", szTime, szOperatorName,
			-- 		szPermissionOpened, szOrigGroup, szTargetGroup)
			szMsg = string.format("%s%s了头衔%s对头衔%s的备注进行修改的权限。",
				szOperatorName,
				szPermissionOpened,
				szOrigGroup,
				szTargetGroup)

		elseif nPermissionIndex == 3 then
			-- szMsg = FormatLinkString(g_tStrings.GUILD_LOG_GROUP_ADVANCED_PERMISSION_CHANGE_3, "font=162", szTime, szOperatorName,
			-- 		szPermissionOpened, szOrigGroup, szTargetGroup)
			szMsg = string.format("%s%s了头衔%s对头衔%s名称进行修改的权限。",
				szOperatorName,
				szPermissionOpened,
				szOrigGroup,
				szTargetGroup)

		end
	end

	UIHelper.SetRichText(tCell.LabelText, szMsg)
end

return UIWidgetTongLog