
require("../scripts/Tong/include/TongTechTree.lh")

TongData = TongData or {}
local self = TongData

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK

TongData.tbSortType = {
    Name = "name",
    Level = "level",
    School = "school",
    Map = "map",
    Remark = "remark",
    Group = "group",
    JoinTime = "join_time",
    LastOfflineTime = "last_offline_time",
    DevelopmentContribution = "development_contribution",
    Score = "score",
    TitlePoint = "title_point",
}

--- 头衔的最大数目
TongData.TOTAL_GROUP_CNT = 16
TongData.DEMESNE_MAP_ID = 74
TongData.TOTAL_BANK_CNT = 9

--- PanelFactionManagementFilterScreen 的筛选类型
TongData.tFilterScreenType = {
    --- 目标头衔（用于移动至指定头衔）
    Permissions = 1,
    --- 成员筛选（门派/头衔）
    Member = 2,
}

--- 成员筛选的类别
TongData.tMemberFilterType = {
    --- 门派
    School = 1,
    --- 头衔
    Group = 2,
}

--- 成员筛选-门派-选择全部
TongData.nMemberFilterSchoolAll = -1
--- 成员筛选-头衔-选择全部
TongData.nMemberFilterGroupAll = -1

function TongData.Init()

end

function TongData.UnInit()
    TongData.ResetActivityTimeData()
end

--- note: 该接口中 nGroupFilter 和 nSchoolFilter 两参数不会同时生效，若两者均不是-1，则仅处理 nGroupFilter
function TongData.GetMemberList(bOffline, szSortType, bSortRiseOrder, nGroupFilter, nSchoolFilter, ...)
    return GetTongClient().GetMemberList(bOffline, szSortType, bSortRiseOrder, nGroupFilter, nSchoolFilter, ...)
end

function TongData.GetMemberInfo(dwID)
    -- {szName = "", dwID = 1, dwMapID = 100, bIsOnline = true, nLevel = 35, nForceID = 1, szRemark = "remark", nGroupID = 1, nJoinTime = 11111, nLastOfflineTime = 123333, nDevelopmentContribution = 50, nFundContribution = 960, nEquipScore = 10250, nTitlePoint = 555}
    return GetTongClient().GetMemberInfo(dwID)
end

function TongData.GetName(dwTongID, nUIGetType)
	local tong = GetTongClient()
	if not dwTongID or dwTongID == tong.dwTongID then
		return tong.szTongName
	else
		return tong.ApplyGetTongName(dwTongID, nUIGetType)
	end
end

function TongData.GetRenameChanceCount()
	return GetTongClient().nRenameChanceCount
end

function TongData.GetLeagueTime()
	if self.IsLeagued() then
		local tParamArr = self.GetDiplomacyRelationList("同盟")
		return TableGet(tParamArr, 1, "nStartTime")
	end
end

function TongData.GetLeagueTimeString()
	local szDate = ""
	local nTime = self:GetLeagueTime()
	if nTime then
		szDate = self.GetDateString(nTime)
	end
	return szDate
end

function TongData.GetDateString(nTime)
	local tDate = TimeToDate(nTime)
	local szDate = FormatString(
		g_tStrings.STR_TIME_3,
		tDate.year,
		tDate.month,
		tDate.day
	)
	return szDate
end

function TongData.GetTimeString(nTime)
    local tFightTime = TimeToDate(nTime)
    local szTime = tFightTime.hour..g_tStrings.STR_TIME_HOUR..tFightTime.minute..g_tStrings.STR_TIME_MINUTE
    return szTime
end


function TongData.GetFund()
    return GetTongClient().nFund
end

function TongData.GetTodayRemainFund()
	return GetTongClient().GetFundTodayRemainCanUse()
end

function TongData.HavePlayerJoinedTong()
	local tong = GetTongClient()
    if tong and tong.dwTongID and tong.dwTongID > 0
	then
        return true
    end
    return false
end

function TongData.GetOtherTongMemberInfo(dwID, dwTongID)
    return GetTongClient().GetMemberInfo(dwID, dwTongID)
end

function TongData.RequestBaseData()
    local tong = GetTongClient()
    tong.ApplyTongInfo()
    tong.ApplyTongRoster()
end

function TongData.RequestTongMemberData(dwTongID)
    local tong = GetTongClient()
    tong.ApplyTongRoster(dwTongID)
end

function TongData.CanBaseOperate(nPlayerID, nTONG_OPERATION_INDEX)
    local tong = GetTongClient()
    local nGroupID = tong.GetGroupID(nPlayerID)
    return tong.CanBaseOperate(nGroupID, nTONG_OPERATION_INDEX)
end

function TongData.GetJoinTimeString(nJoinTime)
    local time = TimeToDate(nJoinTime)
    return FormatString(g_tStrings.STR_TIME_3, string.format("%02d", time.year - 2000), time.month, time.day)
end


function TongData.GetLastOnLineTimeText(nTime)
	if nTime == 0 then
		return g_tStrings.STR_GUILD_LAST_ONLINE_TIME_UNKNOWN
	end
	local szTime = ""
	local nDelta = GetCurrentTime() - nTime
	if nDelta < 0 then
		nDelta = 0
	end

	local nYear = math.floor(nDelta / (3600 * 24 * 365))
	if nYear > 0 then
		szTime = FormatString(g_tStrings.STR_GUILD_TIME_YEAR_BEFORE, nYear)
	else
		local nD = math.floor(nDelta / (3600 * 24))
		if nD > 0 then
			szTime = FormatString(g_tStrings.STR_GUILD_TIME_DAY_BEFORE, nD)
		else
			local nH = math.floor(nDelta / 3600)
			if nH > 0 then
				szTime = FormatString(g_tStrings.STR_GUILD_TIME_HOUR_BEFORE, nH)
			else
				szTime = g_tStrings.STR_GUILD_TIME_IN_ONE_HOUR
			end
		end
	end
	return szTime
end

function TongData.GetMasterChangeLeaveTime()
	local hTongClient = GetTongClient()
	local szTime = ""

	if hTongClient.dwNextMaster > 0 then
		szTime = ""
		local nDelta = hTongClient.nChangeMasterTime - GetCurrentTime()
		if nDelta < 0 then
			nDelta = 0
		end
		local nD = math.floor(nDelta / (3600 * 24))
		if nD > 0 then
			local nL = math.floor((nDelta % (3600 * 24)) / 3600)
			szTime = FormatString(g_tStrings.STR_GUILD_TIME_DAY_LATER, nD, nL)
		else
			local nH = math.floor(nDelta / 3600)
			if nH > 0 then
				szTime = FormatString(g_tStrings.STR_GUILD_TIME_HOUR_LATER, nH)
			else
				szTime = g_tStrings.STR_GUILD_TIME_IN_ONE_HOUR
			end
		end
	end
	return szTime
end


function TongData.GetLevel()
    return GetTongClient().nLevel
end

function TongData:GetMaxLevel()
    return 8
end

function TongData.GetCamp()
    return GetTongClient().nCamp
end

function TongData.GetCustomData()
    return self.tCustomData
end
function TongData.SetCustomData(tData)
    self.tCustomData = tData
end

-- 扩展点存的是本周还可获得资金的剩余上限
function TongData.GetWeeklyPoint()
	return self.nWeeklyPoint or 0
end
function TongData.SetWeeklyPoint(nValue)
	self.nWeeklyPoint = nValue
end

function TongData.GetMasterInfo()
    local tong = GetTongClient()
    if tong then
        return tong.GetMemberInfo(tong.dwMaster)
    end
end

function TongData.GetMemberCount(dwTongID)
	local tong = GetTongClient()
	if not dwTongID or dwTongID == tong.dwTongID then
		return tong.GetMemberCount()
	else
		return tong.GetMemberCount(dwTongID)
	end
end

function TongData.OpenTongPanel()
    -- 打开条件判断
	local player = g_pClientPlayer
    if not player then return end
	if player.nLevel < CAN_APPLY_JOIN_LEVEL then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.TONG_REQUEST_TOO_LOW)
		return
	end

    -- 跨服判断
	if CheckPlayerIsRemote(nil, g_tStrings.STR_REMOTE_NOT_TIP1) then
		return
	end

	-- if IsOptionOrOptionChildPanelOpened() then
	-- 	return
	-- end

    -- 防重开
	-- if IsGuildMainPanelOpened() then
	-- 	GuildMainPanel.HelpEvent()
	-- 	InitTrackingData()
	-- 	return
	-- end

	-- local player = GetClientPlayer()
	-- if not player or not player.dwTongID or player.dwTongID == 0 then
	-- 	if IsGuildListPanelOpened() then
	-- 		CloseGuildListPanel()
	-- 	else
	-- 		GuildMainPanel.HelpEvent()
	-- 		OpenGuildListPanel(nil, false)
	-- 	end
	-- 	return
	-- end

	--HideGuildSysBtnAnimate()

    local nViewID
    if self.HavePlayerJoinedTong() then
        -- 已加入帮会
		nViewID = VIEW_ID.PanelFactionManagement
    else
        -- 未加入帮会
		nViewID = VIEW_ID.PanelFactionList
    end

	if UIMgr.GetView(nViewID) then
		UIMgr.Close(nViewID)
	else
		UIMgr.Open(nViewID)
	end
end

function TongData.Quit()
    GetTongClient().Quit()
    --UIMgr.Close(VIEW_ID.PanelFactionManagement)
end

function TongData.GetGroupInfo()
    local tbGroupInfo = {}
	local nPlayerGroupID = self.GetCurMemberInfo().nGroupID
    for i = 0, TongData.TOTAL_GROUP_CNT - 1, 1 do
		local groupInfo = GetTongClient().GetGroupInfo(i)
        local nMemberCount = GetTongClient().GetGroupMemberCount(i)
        local nRepairMoney = GetTongClient().GetGroupRepairLimit(i)
        table.insert(tbGroupInfo,
            {
                szName = groupInfo.szName,
                nGroup = i,
                nNumber = nMemberCount,
                nRepair = nRepairMoney,
                bEnable = groupInfo.bEnable,
				bSelfGroup = nPlayerGroupID == i + 1,
            }
        )
	end
    return tbGroupInfo
end

function TongData.CheckBaseOperationGroup(dwGroupIndex, nPermissionIndex)
	return GetTongClient().CheckBaseOperationGroup(dwGroupIndex, nPermissionIndex)
end

function TongData.CheckAdvanceOperationGroup(nGroupIndex, nGroupID, nPermissionIndex)
	return GetTongClient().CheckAdvanceOperationGroup(nGroupIndex, nGroupID, nPermissionIndex)
end

function TongData.CanBaseGrant(nGroupID, dwGroupIndex, nPermissionIndex)
	return GetTongClient().CanBaseGrant(nGroupID, dwGroupIndex, nPermissionIndex)
end

function TongData.CanAdvanceGrant(nGroupID, dwGroupIndex, TargetGroupID, nPermissionIndex)
	return GetTongClient().CanAdvanceGrant(nGroupID, dwGroupIndex, TargetGroupID, nPermissionIndex)
end

function TongData.GetGroupInfoByID(nID)
	return GetTongClient().GetGroupInfo(nID)
end

function TongData.ModifyAdvanceOperationMask(dwGroupIndex, nGroupID, nPermissionIndex, bIsSelect)
	GetTongClient().ModifyAdvanceOperationMask(dwGroupIndex, nGroupID, nPermissionIndex, bIsSelect)
end

function TongData.ModifyBaseOperationMask(dwGroupIndex, nPermissionIndex,bIsSelect)
	GetTongClient().ModifyBaseOperationMask(dwGroupIndex, nPermissionIndex, bIsSelect)
end

function TongData.ApplyTongInfo()
	GetTongClient().ApplyTongInfo()
end

function TongData.ApplyTongRoster()
	GetTongClient().ApplyTongRoster()
end

function TongData.GetMemberListByKey(szSearchkey, nGroupIndex)
	local tbPlayerList = TongData.GetMemberList(true, "score", true, nGroupIndex - 1, -1)
	local tbInfo = {}
	if tbPlayerList then
        for _, nID in pairs(tbPlayerList) do
            local info = TongData.GetMemberInfo(nID)
			info.nEquipScore = info.nEquipScore or 9999
			if string.match(UIHelper.GBKToUTF8(info.szName), szSearchkey) then
				table.insert(tbInfo, info)
			end
        end
	end
	return tbInfo
end

function TongData.ChangeMemberGroup(dwTargetMemberID, nTargetGroup)
	GetTongClient().ChangeMemberGroup(dwTargetMemberID, nTargetGroup)
end

function TongData.ModifyGroupName(nGroupIndex, cpszGroupName)
	GetTongClient().ModifyGroupName(nGroupIndex, cpszGroupName)
end

--当前账号角色信息
function TongData.GetCurMemberInfo()
	local player = g_pClientPlayer
	if player then
		local tong = GetTongClient()
		if tong then
			return tong.GetMemberInfo(player.dwID)
		end
	end
	return nil
end

function TongData.GetCurBasicPermission(nGroupIndex, bOnlyShowOpenAuthority)
	local tbBasicPermission = {}
	local tbPermissions =
    {
        {nPermissionIndex = 0, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[0]},		-- 频道发言
        --{nPermissionIndex = 1, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[1], bAdvance = true},		-- 官员权力
        {nPermissionIndex = 2, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[2]},		-- 管理帮会信息
        {nPermissionIndex = 4, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[4]},		-- 管理活动
        {nPermissionIndex = 3, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[3]},		-- 管理天工树
        {nPermissionIndex = 25, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[25]},	-- 管理帮会资金
        {nPermissionIndex = 26, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[26]}, -- 管理帮会外交
        {nPermissionIndex = 27, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[27]},	-- 帮会据点地图优先进入
        {nPermissionIndex = 28, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[28]}, -- 可参与帮会联赛
        {nPermissionIndex = 29, szName = g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[29]},	-- 帮会联赛核心成员
    }

	local nPlayerGroupID = self.GetCurMemberInfo().nGroupID

    for index, value in ipairs(tbPermissions) do
        local bPermission = self.CheckBaseOperationGroup(nGroupIndex, value.nPermissionIndex)
		local bCanGrant = self.CanBaseGrant(nPlayerGroupID, nGroupIndex, value.nPermissionIndex)
		if bPermission or  bCanGrant then
			if (not bPermission) and (bOnlyShowOpenAuthority) then--没有权限被开启且当前仅选择显示已开启权限

			else
				local info = {}
				info.szName = value.szName
				info.bPermission = bPermission
				info.bCanGrant = bCanGrant
				info.callback = function (bSelect)
					self.ModifyBaseOperationMask(nGroupIndex, value.nPermissionIndex, bSelect)
				end
				info.tips = nil
				if not bCanGrant then
					info.tips = function ()
						if nPlayerGroupID == self.GetMasterInfo().nGroupID then
							TipsHelper.ShowNormalTip("帮主默认拥有所有权限，无需设置")
						else
							TipsHelper.ShowNormalTip("你当前没有更改权限")
						end
					end
				end
				table.insert(tbBasicPermission, info)
			end
		end
    end
	return tbBasicPermission
end

function TongData.GetCurGroupPermissionList(nGroupIndex, bOnlyShowOpenAuthority)

	local tbGroupPermission = {}
	local nPlayerGroupID = self.GetCurMemberInfo().nGroupID

	for i = 0, self.TOTAL_GROUP_CNT - 1, 1 do
        local groupInfo = self.GetGroupInfoByID(i)
        if groupInfo.bEnable then
			local info = {}
			info.szName = UIHelper.GBKToUTF8(groupInfo.szName)
			info.tbName = {"管理帮众", "管理备注", "修改组名"}
			info.tbPermission = {}
			info.tbCanGrant = {}
			info.Tips = {}

			local tbPermissionIndex = {0, 2, 3}
			local bCanAddToGroupPermission = false --只要满足可以修改或者已经勾选的任意一项条件，则加入列表
			local nPermissionCount = 0
			for index, nPermissionIndex in ipairs(tbPermissionIndex) do
				local bPermission = self.CheckAdvanceOperationGroup(nGroupIndex, i, nPermissionIndex)
				local bCanGrant = self.CanAdvanceGrant(nPlayerGroupID, nGroupIndex, i, nPermissionIndex)
				table.insert(info.tbPermission, bPermission)
				table.insert(info.tbCanGrant, bCanGrant)

				local tip = nil
				if not bCanGrant then
					tip = function ()
						if nPlayerGroupID == self.GetMasterInfo().nGroupID then
							TipsHelper.ShowNormalTip("帮主默认拥有所有权限，无需设置")
						else
							TipsHelper.ShowNormalTip("你当前没有更改权限")
						end
					end
				end
				table.insert(info.Tips, tip)
				if bPermission or bCanGrant then
					bCanAddToGroupPermission = true
				end
				nPermissionCount = nPermissionCount + (bPermission and 1 or 0)
			end

			info.callback = function (tbSelect)
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, nil) then
                    return
                end

                for index, nPermissionIndex in ipairs(tbPermissionIndex) do
					self.ModifyAdvanceOperationMask(nGroupIndex, i, nPermissionIndex, tbSelect[index])
				end
			end

			if bCanAddToGroupPermission then
				if ( nPermissionCount == 0) and (bOnlyShowOpenAuthority) then--没有权限被开启且当前仅选择显示已开启权限

				else
					table.insert(tbGroupPermission, info)
				end
			end
        end
    end
	return tbGroupPermission
end

function TongData.GetWarehousePermissionList(nGroupIndex, bOnlyShowOpenAuthority)

	local tbGroupPermission = {}
	local nPlayerGroupID = self.GetCurMemberInfo().nGroupID

	for i = 1, TongData.TOTAL_BANK_CNT, 1 do
		local info = {}
		info.szName = string.format("仓库%s", tostring(i))
		info.tbName = {"存入", "取出"}
		info.tbPermission = {}
		info.tbCanGrant = {}
		info.Tips = {}
        local tbPermissionIndex = {5 + ((i - 1) * 2), 6 + ((i - 1) * 2)}

		local bCanAddToGroupPermission = false --只要满足可以修改或者已经勾选的任意一项条件，则加入列表

		local nPermissionCount = 0
		for index, nPermissionIndex in ipairs(tbPermissionIndex) do
			local bPermission = self.CheckBaseOperationGroup(nGroupIndex, nPermissionIndex)
			local bCanGrant = self.CanBaseGrant(nPlayerGroupID, nGroupIndex, nPermissionIndex)
			table.insert(info.tbPermission, bPermission)
			table.insert(info.tbCanGrant, bCanGrant)

			local tip = nil
			if not bCanGrant then
				tip = function ()
					if nPlayerGroupID == self.GetMasterInfo().nGroupID then
						TipsHelper.ShowNormalTip("帮主默认拥有所有权限，无需设置")
					else
						TipsHelper.ShowNormalTip("你当前没有更改权限")
					end
				end
			end
			table.insert(info.Tips, tip)
			if bPermission or bCanGrant then
				bCanAddToGroupPermission = true
			end
			nPermissionCount = nPermissionCount + (bPermission and 1 or 0)
		end

        info.callback = function(tbSelect)
			if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, nil) then
				return
			end

			for index, nPermissionIndex in ipairs(tbPermissionIndex) do
				self.ModifyBaseOperationMask(nGroupIndex, nPermissionIndex, tbSelect[index])
			end
		end

		if bCanAddToGroupPermission then
			if ( nPermissionCount == 0) and (bOnlyShowOpenAuthority) then--没有权限被开启且当前仅选择显示已开启权限

			else
				table.insert(tbGroupPermission, info)
			end
		end
    end
	return tbGroupPermission
end

--nGroupID：当前准备移除成员的组ID
function TongData.GetCanAddMemberGroupList(nGroupID)
	local tbGroupList = {}
	local nPlayerGroupID = self.GetCurMemberInfo().nGroupID
	for i = 1, TongData.TOTAL_GROUP_CNT - 1, 1 do
        local groupInfo = TongData.GetGroupInfoByID(i)
        if groupInfo.bEnable and nGroupID ~= i and nPlayerGroupID ~= i then
            local bPermission = GetTongClient().CanAdvanceOperate(nPlayerGroupID, i, TONG_OPERATION_INDEX.ADD_TO_GROUP)
			if bPermission then
				local info = {}
				info.nGroupIndex = i
				info.szName = self.GetGroupInfoByID(i).szName
				table.insert(tbGroupList, info)
			end
		end
	end
	return tbGroupList
end

function TongData.CanChangeMemberGroup(nGroupID)
	--当前账号可以从当前组移动人
	local nPlayerGroupID = self.GetCurMemberInfo().nGroupID
	return GetTongClient().CanAdvanceOperate(nPlayerGroupID, nGroupID, TONG_OPERATION_INDEX.MOVE_FROM_GROUP) and nGroupID ~= 0
end

function TongData.CanChangeGroupName(nGroupID)
	--当前账号是否可以修改当前组的名字
	local nPlayerGroupID = self.GetCurMemberInfo().nGroupID
	return GetTongClient().CanAdvanceOperate(nPlayerGroupID, nGroupID, TONG_OPERATION_INDEX.MODIFY_GROUP_NAME)
end

function TongData.OnInviteJoinTong(dwInviterID, dwTongID, szInviterName, szTongName)
	-- local player = GetClientPlayer()
	 if not IsRegisterEvent("INVITE_JOIN_TONG_REQUEST") then
	 	--GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, false)
	 	--FireUIEvent("FILTER_INVITE_JOIN_TONG_REQUEST", dwInviterID, dwTongID, szInviterName, szTongName)
	 	return
	 end

	-- if not player.IsExistFellowshipList(szInviterName) and player.nLevel < 20 then
	-- 	local msg = FormatString(g_tStrings.STR_GUILD_REFUSE, g2u(szInviterName), g2u(szTongName))
	-- 	OutputMessage("MSG_SYS", msg)
	-- 	GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, false)
	-- 	return
	-- end

	if IsFilterOperate("INVITE_JOIN_TONG_REQUEST") then
		GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, false)
		return
	end

	if FellowshipData.IsInBlackListByPlayerID(dwInviterID) then 
		GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, false)
		return 
	end

	local dwStartTime = GetTickCount()
	BubbleMsgData.PushMsgWithType("TongInviteTips", {
		szType = "TongInviteTips"..g2u(szInviterName)..g2u(szTongName), 		-- 类型(用于排重)
		nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
		-- szContent = FormatString(g_tStrings.STR_GUILD_INVITE, g2u(szInviterName), g2u(szTongName)),
		szContent = "[" .. g2u(szTongName) .. "]",
		fnAutoClose = function() return GetTickCount() - dwStartTime > 2 * 60 * 1000 end,
		szAction = function ()
			UIHelper.ShowConfirm(
				FormatString(g_tStrings.STR_GUILD_INVITE, g2u(szInviterName), g2u(szTongName)),
				function () GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, true) end,
				function () GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, false) end,
				false
			)
			BubbleMsgData.RemoveMsg("TongInviteTips"..g2u(szInviterName)..g2u(szTongName))
		end,
		nLifeTime = 60, 						-- 存在时长, 单位为秒
		fnConfirmAction = function () GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, true) end,
		fnCancelAction = function () GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, false) end,
		nPlayerID = dwInviterID,
		fnMoreAction = function()
			local szContent = string.format("是否将【%s】加入黑名单，你将不再接收到来自他的聊天信息\n游戏设置中勿扰选项也对其全部生效", UIHelper.GBKToUTF8(szInviterName))
			local script = UIHelper.ShowConfirm(szContent, function()
				GetTongClient().RespondInviteJoinTong(dwInviterID, dwTongID, false)--自动拒绝
				FellowshipData.AddBlackList(szInviterName)--加入黑名单
				local szType = "TongInviteTips"..g2u(szInviterName)..g2u(szTongName)
				BubbleMsgData.RemoveMsg(szType)
				Event.Dispatch(EventType.TryCloseBubbleMsgOnly, szType)
			end)
			script:ShowTogOption("开启屏蔽帮会申请", not IsRegisterEvent("INVITE_JOIN_TONG_REQUEST"))
			script:SetTogSelectedFunc(function(bSelected)
                if bSelected then
                    Event.Dispatch("ENABLE_INVITE_JOIN_TONG_REQUEST", false)
					TipsHelper.ShowNormalTip("后续可在设置-综合设置-勿扰设置关闭选项")
                else
                    Event.Dispatch("ENABLE_INVITE_JOIN_TONG_REQUEST", true)
                end
            end)
		end,
	})
end

function TongData.CanSpeakAtChat()
    local tong = GetTongClient()
    local nGroupID = tong.GetGroupID(g_pClientPlayer.dwID)
    local bOK = self.CheckBaseOperationGroup(nGroupID, 0)
    return bOK
end

function TongData.GetNewAnnouncement()
	local tong = GetTongClient()
	return tong and tong.szAnnouncement
end
function TongData.SetNewAnnouncement(sz)
	local tong = GetTongClient()
	if tong then
		tong.ApplyModifyAnnouncement(sz)
	end
end

function TongData.GetOnlineAnnouncement()
	local tong = GetTongClient()
	return tong and tong.szOnlineMessage
end
function TongData.SetOnlineAnnouncement(sz)
	local tong = GetTongClient()
	if tong then
		tong.ApplyModifyOnlineMessage(sz)
	end
end

function TongData.InvitePlayerJoinTong(szName)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
        return
    end

    GetTongClient().InvitePlayerJoinTong(szName)
end



function TongData.ShowTongMessage()
	local player = GetClientPlayer()
	local guild = GetTongClient()

	if not player or player.dwTongID == 0 then
		return
	end

	if not guild then
		return
	end

	local szMessage = guild.szOnlineMessage
	if szMessage and szMessage ~= "" then
		_, szMessage = TextFilterReplace(szMessage)
		local szMsg = g_tStrings.STR_GUILD_ONLINE_MSG..g2u(szMessage)
		if string.sub(szMessage, -1, -1) ~= "\n" then
			szMsg = szMsg .."\n"
		end
		--OutputMessage("MSG_GUILD", szMsg)
		ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.TONG, false, "")
	end
end

local _tFilterSchoolArr = {
	-1,
	FORCE_TYPE.JIANG_HU,
	FORCE_TYPE.SHAO_LIN,
	FORCE_TYPE.WAN_HUA,
	FORCE_TYPE.TIAN_CE,
	FORCE_TYPE.CHUN_YANG,
	FORCE_TYPE.QI_XIU,
	FORCE_TYPE.WU_DU,
	FORCE_TYPE.TANG_MEN,
	FORCE_TYPE.CANG_JIAN,
	FORCE_TYPE.GAI_BANG,
	FORCE_TYPE.MING_JIAO,
	FORCE_TYPE.CANG_YUN,
	FORCE_TYPE.CHANG_GE,
	FORCE_TYPE.BA_DAO,
	FORCE_TYPE.PENG_LAI,
	FORCE_TYPE.LING_XUE,
	FORCE_TYPE.YAN_TIAN,
	FORCE_TYPE.YAO_ZONG,
	FORCE_TYPE.DAO_ZONG,
}
function TongData.GetFilterSchoolArr()
	return _tFilterSchoolArr
end


-- 领地 beg ------------------------
local _tDemesneNpcArr = {}
function TongData.ShowDemesneNpcMenu(menuNode)
	UIHelper.SetVisible(menuNode, true)
	UIHelper.SetTouchLikeTips(menuNode, UIMgr.GetLayer(UILayer.Page), function ()
		UIHelper.SetVisible(menuNode, false)
	end)

	local tNpcMap = Table_GetNpcTypeInfoMap()
	local nCount = 0
	local list = UIHelper.FindChildByName(menuNode, "ScrollViewActivity")
	_tDemesneNpcArr = {}
	UIHelper.RemoveAllChildren(list)
	for _, tNpc in pairs(tNpcMap) do
		for _, v in pairs(tNpc.tNpcList) do
			if v.dwNpcID == 4714 then
				table.insert(_tDemesneNpcArr, v)
				local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForTipsBtn, list)
				assert(cell)
				nCount = nCount + 1
				self.UpdateDemesneNpcCell(cell, v, nCount)
			end
		end
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false)

end

local _tNpcCellFieldNameArr = {
	"BtnLeaveFor",
	"LableLeaveFor",
}
function TongData.UpdateDemesneNpcCell(cell, tNpc, nIndex)
	assert(cell)

	local szMapName = g2u(Table_GetMapName(tNpc.dwMapID))
	local _, _, sz = string.find(g2u(tNpc.szTypeName), "·(.+)$")
	sz = sz .. string.format(" (%s)", szMapName)


    cell:OnEnter(sz)
    UIHelper.BindUIEvent(cell.BtnLeaveFor, EventType.OnClick, function()
        self.OnClickDemesneNpcCell(nIndex)
    end)
end

function TongData.OnClickDemesneNpcCell(nIndex)
	assert(nIndex)
	local tNpc = _tDemesneNpcArr[nIndex]
	assert(tNpc, "invalid select index: " .. nIndex)

	-- position
	local arr = string.split(tNpc.szPosition, ";")
	assert(#arr > 0)
	arr = string.split(arr[1], ",")
	assert(#arr >= 2)

	--打开中地图travel
	MapMgr.SetTracePoint(g2u(tNpc.szTypeName), tNpc.dwMapID, tNpc.tPoint)
	UIMgr.Open(VIEW_ID.PanelMiddleMap, tNpc.dwMapID, 0)

end

TongData.bIsDemesnePurchased = false

function TongData.IsDemesnePurchased()
	-- 是否已购买帮会领地
	return TongData.bIsDemesnePurchased
end

function TongData.ShowDemesneEntry()
	MapMgr.OpenWorldMapTransportPanel(TongData.DEMESNE_MAP_ID, true)
	-- Event.Dispatch("ON_MAP_OPEN_PERIPHERA", "帮会领地")
end
-- 领地 end ------------------------



-- 天工树 beg ------------------------

local _tBranchDataOfTrunk
local _tBranchDataOfBorn
function TongData.GetBranchData(nBranch)
	if nBranch == 1 then
		if not _tBranchDataOfTrunk then
			local tList = Table_GetTongTechNodeList()
			_tBranchDataOfTrunk = tList[1]  -- 主干分支
		end
		return _tBranchDataOfTrunk
	elseif nBranch == 2 then
		if not _tBranchDataOfBorn then
			local tList = Table_GetTongTechNodeList()
			_tBranchDataOfBorn = tList[3] -- 涅槃分支
		end
		return _tBranchDataOfBorn
	end
end

function TongData.GetBranchFilterTypeArr(nBranch)
	if nBranch == 1 then
		return g_tStrings.STR_TONG_TREE_SEARCH_TRUNK
	elseif nBranch == 2 then
		return g_tStrings.STR_TONG_TREE_SEARCH_REBORN
	end
end

-- 是否是帮会领地中
function TongData.IsInDemesne()
	return g_pClientPlayer.GetMapID() == TongData.DEMESNE_MAP_ID
end

function TongData.SortNode(tTreeNode)
	local tong = GetTongClient()
	Global.SortStably(tTreeNode, function (a, b)
		local nA = tong.GetTechNodeLevel(a) > 0 and 1 or 0
		local nB = tong.GetTechNodeLevel(b) > 0 and 1 or 0
		return nA >= nB
	end)
	return tTreeNode
end


function TongData.GetUpdateNode(tTreeNode)
	local TongClient = GetTongClient()
	local tResult = {}

	for k ,v in ipairs(tTreeNode) do
		local nLevel = TongClient.GetTechNodeLevel(v)
		if nLevel > 0 then
			table.insert(tResult, v)
		end
	end
	return tResult
end

function TongData.GetCanUpdateNode(tTreeNode)
	local TongClient = GetTongClient()
	local tResult = {}

	for k ,nNodeID in ipairs(tTreeNode) do
		local nLevel = TongClient.GetTechNodeLevel(nNodeID)
		local nMaxLevel = TongData.GetTreeNodeMaxLevel(nNodeID)

		local nTongLevel = TongClient.nLevel
		local nRequireLevel = TongData.GetTongTechTreeNodeLevelLimit(nNodeID, nLevel + 1)

		local dwFund = TongClient.nFund
		local dwRequireFund = TongData.GetTongTechTreeNodeCost(nNodeID, nLevel + 1)

		if nLevel < nMaxLevel and nTongLevel >= nRequireLevel and dwFund >= dwRequireFund then
			table.insert(tResult, nNodeID)
		end
	end

	return tResult
end

function TongData.GetTypeNode(tTreeNode, nDstType)
	local tResult = {}

	for k ,nNodeID in ipairs(tTreeNode) do
		local nType = TongData.GetNodeType(nNodeID)
		if nType == nDstType then
			table.insert(tResult, nNodeID)
		end
	end

	tResult = TongData.SortNode(tResult)

	return tResult
end

function TongData.GetSearchNode(nType, tNode)
	local tTrunkNode = TongData.GetBranchData(1)
	local tTreeNode
	if nType == 1 then		--全部
		tTreeNode = TongData.SortNode(tNode)
	elseif nType == 2 then	--已升级
		tTreeNode = TongData.GetUpdateNode(tNode)
	elseif nType == 3 then	--可升级
		tTreeNode = TongData.GetCanUpdateNode(tNode)
	elseif nType == 4 then	--功能分支/涅槃分支
		if tNode == tTrunkNode then
			tTreeNode = TongData.GetTypeNode(tNode, 1)
		else
			tTreeNode = TongData.GetTypeNode(tNode, 3)
		end
	elseif nType == 5 then	--福利分支/问鼎分支
		if tNode == tTrunkNode then
			tTreeNode = TongData.GetTypeNode(tNode, 2)
		else
			tTreeNode = TongData.GetTypeNode(tNode, 4)
		end
	end
	return tTreeNode
end

function TongData.GetTreeNodeMaxLevel(nNodeID)
	local Node = TongTechTreeNode[nNodeID]
	local nMaxLevel = Node.Max

	return nMaxLevel
end

function TongData.GetTongTechTreeNodeLevelLimit(nNodeID, nLevel)
	local Node = TongTechTreeNode[nNodeID]
	local nRequireTongLevel = GetTongTechTreeNodeLevelLimit(Node, nLevel)

	return nRequireTongLevel
end

function TongData.GetTongTechTreeNodeCost(nNodeID, nLevel)
	local Node = TongTechTreeNode[nNodeID]
	local nRequireFund = GetTongTechTreeNodeCost(Node, nLevel)

	return nRequireFund
end

function TongData.GetNodeType(nNodeID)
	local Node = TongTechTreeNode[nNodeID]

	return Node.Type
end

local _tTreeCellNameArr = {
	"WidgetItem",
	"ImgTreeTypeMainFunction",
	"LabelTreeType",
	"ImgTreeType",
	"LayoutRebornTreeState",
	"ImgSelect",
	"LabelTreeName",
	"ImgRedDot",
	"Icon",
}
local _tTreeTypeConfig = {
	[1] = { Title = "功能", Frame = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabL03.png", },
	[2] = { Title = "福利", Frame = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabL06.png", },
	[3] = { Title = "涅槃", Frame = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabL04.png", },
	[4] = { Title = "问鼎", Frame = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabL02.png", },
}
function TongData.GetTreeTypeConfig(nType)
	return _tTreeTypeConfig[nType]
end

function TongData.GetNodeIconFrame(tNodeInfo)
	local szFileKey = (string.find(tNodeInfo.szImagePath, "Node2")) and "2" or ""
	local szIcon = string.format("UIAtlas2_Faction_ScienceTreeNode%s_ScienceTreeNode%s_%d.png",
		szFileKey, szFileKey, tNodeInfo.nFrame)
	return szIcon
end

function TongData.UpdateTreeCell(cell, nNodeID, bSelected, bHideRedPoint, bPreviewState)
	assert(cell)
	assert(nNodeID)

	local tNodes = {}
	UIHelper.FindNodeByNameArr(cell, tNodes, _tTreeCellNameArr)

	local nNodeType = self.GetNodeType(nNodeID)
	assert(nNodeType)
	local tNodeCfg = self.GetTreeTypeConfig(nNodeType)
	assert(tNodeCfg)
	local nLevel = self.GetNodeLevel(nNodeID, bPreviewState)
	local nMaxLevel = self.GetTreeNodeMaxLevel(nNodeID)
	local tNodeInfo = Table_GetTongTechTreeNodeInfo(nNodeID, nLevel)
	assert(tNodeInfo)

	UIHelper.SetSpriteFrame(tNodes.ImgTreeType, tNodeCfg.Frame)
	UIHelper.SetString(tNodes.LabelTreeType, tNodeCfg.Title)
	UIHelper.SetString(tNodes.LabelTreeName, g2u(tNodeInfo.szName))
	UIHelper.SetVisible(tNodes.ImgSelect, bSelected == true)

	local children = UIHelper.GetChildren(tNodes.LayoutRebornTreeState)
	for i, child in ipairs(children) do
		UIHelper.SetVisible(UIHelper.FindChildByName(child, "ImgDarkDot"), i <= nMaxLevel)
		UIHelper.SetVisible(UIHelper.FindChildByName(child, "ImgActivatedDot"), i <= nLevel)
        UIHelper.SetVisible(child, i <= nMaxLevel or i <= nLevel)
	end
    UIHelper.LayoutDoLayout(tNodes.LayoutRebornTreeState)

	-- Icon
	local szIcon = TongData.GetNodeIconFrame(tNodeInfo)
	UIHelper.SetSpriteFrame(tNodes.Icon, szIcon)

    local bGray = nLevel == 0
    if bPreviewState and not bGray then
        local nActualLevel = self.GetNodeLevel(nNodeID, false)
        bGray              = nActualLevel == 0
    end
    UIHelper.SetNodeGray(tNodes.Icon, bGray)

	-- ImgRedDot
	local nNeedTongLevel = nLevel < nMaxLevel and TongData.GetTongTechTreeNodeLevelLimit(nNodeID, nLevel + 1) or 0
	local nNeedFund = nLevel < nMaxLevel and TongData.GetTongTechTreeNodeCost(nNodeID, nLevel + 1) or 0
	UIHelper.SetVisible(tNodes.ImgRedDot,
		not bHideRedPoint
		and nNeedTongLevel > 0 and nNeedTongLevel <= TongData.GetLevel()
		and nNeedFund > 0 and nNeedFund <= TongData.GetFund())
end



-- 天工树 end ------------------------




-- 外交 beg ------------------------
function TongData.GetTimeText(nTime, bFrame)
	if bFrame then
		nTime = nTime / GLOBAL.GAME_FPS
	end

	--local nD = math.floor(nTime / 3600 / 24)
	local nH = math.floor(nTime / 3600)
	local nM = math.floor((nTime % 3600) / 60)
	local nS = (nTime % 3600) % 60

	local szTimeText = ""
	if nH < 10 then
        nH = "0"..nH
    end

    if nM < 10 then
        nM = "0"..nM
    end

    if nS < 10 then
        nS = "0"..nS
    end
	return nH .. ":" .. nM .. ":" .. nS
end

function TongData.GetDiplomacyRelationList(szRelation)
	local tong = GetTongClient()
	if "同盟" == szRelation then
		return GetTongDiplomacyList(tong.dwTongID, TONG_DIPLOMACY_RELATION_TYPE.ALLIANCE)
	elseif "宣战" == szRelation then
		return GetTongDiplomacyList(tong.dwTongID, TONG_DIPLOMACY_RELATION_TYPE.WAR)
	elseif "约战" == szRelation then
		return GetTongDiplomacyList(tong.dwTongID, TONG_DIPLOMACY_RELATION_TYPE.CONTRACT_WAR)
	end
end

function TongData.IsInDeclarationState()
	local player = GetClientPlayer()
    if player.dwTongID <= 0 then
        return false;
    end

    local tWar = GetTongDiplomacyList(player.dwTongID, TONG_DIPLOMACY_RELATION_TYPE.WAR)
	local tCastleWar = GetTongDiplomacyList(player.dwTongID, TONG_DIPLOMACY_RELATION_TYPE.CASTLE_WAR)
    if (tWar and #tWar > 0) or (tCastleWar and #tCastleWar > 0) then
        return true
    end
    return false
end

function TongData.GetAllDiplomacyRelationList()
	local tbRelationList = {}
	local tong = GetTongClient()
	local tbRelationType = {
		["同盟"] = TONG_DIPLOMACY_RELATION_TYPE.ALLIANCE,
		["宣战"] = TONG_DIPLOMACY_RELATION_TYPE.WAR,
		["约战"] = TONG_DIPLOMACY_RELATION_TYPE.CONTRACT_WAR,
	}

	for _, dwType in pairs(tbRelationType) do
		local tbInfo = GetTongDiplomacyList(tong.dwTongID, dwType)
		if not table.is_empty(tbInfo) then
			table.insert(tbRelationList, tbInfo)
		end
	end
	return tbRelationList
end

function TongData.GetContractWarInvitedDataArr()
    local tDataArr = {}
    local dwTongID = g_pClientPlayer.dwTongID
    local arr = TongData.GetDiplomacyRelationList("约战")
    for i, tData in ipairs(arr) do
       if tData.dwSrcTongID  ~= dwTongID and tData.dwDstTongID == dwTongID and tData.nStartTime == 0 then
            table.insert(tDataArr, tData)
       end
    end
    return tDataArr
end

function TongData.GetContractWarDataArr()
    local tDataArr = {}
    local dwTongID = g_pClientPlayer.dwTongID
    local arr = TongData.GetDiplomacyRelationList("约战")
    for i, tData in ipairs(arr) do
       if tData.nStartTime > 0 then
            table.insert(tDataArr, tData)
       end
    end
    return tDataArr
end

function TongData.GetLeagueDataArr()
    local tDataArr = {}
    local dwTongID = g_pClientPlayer.dwTongID
    local arr = TongData.GetDiplomacyRelationList("同盟")
    for i, tData in ipairs(arr) do
       if tData.dwSrcTongID  ~= dwTongID and tData.dwDstTongID == dwTongID then
            table.insert(tDataArr, tData)
       end
    end
    return tDataArr
end

function TongData.GetNextDiplomacyWarTime()
	return GetTongClient().nNextDiplomacyWarTime or 0
end

function TongData.GetWarCDTime()
    local nEndTime = self.GetNextDiplomacyWarTime()
    local nLeftTime = nEndTime - GetCurrentTime()
	return math.max(nLeftTime, 0)
end

local _tDeclarationParam =
{
    {nIndex=0, time=1, cost=500, cost1=1000},
    {nIndex=1, time=3, cost=1500, cost1=3000},
    {nIndex=2, time=5, cost=2500, cost1=5000},
}
function TongData.SetDeclarationParam(tDeclarationParam)
	_tDeclarationParam = tDeclarationParam
end
function TongData.GetDeclarationParam()
	return _tDeclarationParam
end

function TongData.IsLeagued()
	local tong = GetTongClient()
	local dwAllianceTongID = tong.dwAllianceTongID
	return dwAllianceTongID and dwAllianceTongID > 0
end

function TongData.GetAllianceTongID()
	return GetTongClient().dwAllianceTongID
end


-- 外交 end ------------------------


-- 活动 beg ------------------------
TongData.ACTIVITY_STATE = {
    --- 未开启
    NotOpen = 0,
    --- 正在进行
    Opening = 1,
    --- 已结束
    Closed = 2,
}

-- 当该标记为true时，说明数据已经获取到，不需要再更新。否则需要重新请求数据，直到获取到数据后再置为true
TongData.bUpdateActivity = nil

function TongData.SetActivityTimeData(tData)
    -- 标记数据已经获取到
    TongData.bUpdateActivity = true

    -- 与端游保持一致，先显示未配置 nActivityID 的活动
    local tPreprocessedData = {}

    -- 预处理下通过关联活动id来配置时间的帮会活动，填充其实际结束时间
    local nCurTime = GetCurrentTime()
    local tDate    = TimeToDate(nCurTime)
    local nTailTime
    if tDate.weekday == 0 then
        nTailTime = nCurTime + 86400
    else
        nTailTime = nCurTime + (7 - tDate.weekday + 1) * 86400
    end
    local hCalendar        = GetActivityMgrClient()
    local tActivity        = hCalendar.GetActivityOfPeriod(nCurTime, nTailTime)

    local tDoubleCheckFlag = {}
    for _, v in pairs(tData) do
        if v.nActivityID ~= 0 then
            tDoubleCheckFlag[v.nActivityID] = v
        else
            table.insert(tPreprocessedData, v)
        end
    end

    for _, v in pairs(tActivity) do
        local tTongActivityData = tDoubleCheckFlag[v.dwID]
        if tTongActivityData then
            if v.TimeInfo[1].nEndTime < nCurTime then
                tTongActivityData.nTime = -1
                tTongActivityData.nFlag = 2
            elseif v.TimeInfo[1].nStartTime < nCurTime then
                tTongActivityData.nTime = v.TimeInfo[1].nEndTime
                tTongActivityData.nFlag = 1
            else
                tTongActivityData.nTime = v.TimeInfo[1].nStartTime
                tTongActivityData.nFlag = 0
            end

            table.insert(tPreprocessedData, tTongActivityData)
        end
    end

    TongData.tActivityTimeData = tPreprocessedData
end

function TongData.GetActivityTimeData()
    return TongData.tActivityTimeData
end

function TongData.ResetActivityTimeData()
    TongData.tActivityTimeData = nil
    TongData.bUpdateActivity = nil
end

--- 某个类别的活动是否有任意一个处于开启状态
function TongData.IsAnyActivityOpenOfClassID(nClassID)
    local tData = TongData.GetActivityTimeData()
    for _, v in pairs(tData) do
        if v.nID1 == nClassID and v.nFlag == TongData.ACTIVITY_STATE.Opening then
            return true
        end
    end

    return false
end

--- 某个类别的活动是否有任意一个处于某个状态
function TongData.IsAnyActivityInStateOfClassID(nClassID, nState)
    local tData = TongData.GetActivityTimeData()
    for _, v in pairs(tData) do
        if v.nID1 == nClassID and v.nFlag == nState then
            return true
        end
    end

    return false
end

--- 获取指定id的活动的数据
function TongData.GetActivityTimeDataByClassID(nClassID, nSubClassID)
    local tData = TongData.GetActivityTimeData()
    for _, v in pairs(tData) do
        if v.nID1 == nClassID and v.nID2 == nSubClassID then
            return v
        end
    end

    return nil
end

function TongData.StartActivity(nClassID, nSubClassID)
    local fnAction
    local player = GetClientPlayer()
    if nClassID == 5 then
        fnAction = function()
            RemoteCallToServer("On_Tong_StartZhuJiuJieRequest")
        end
    elseif nClassID == 8 then
        fnAction = function()
			RemoteCallToServer("On_Tong_StartPigRunRequest")
        end
    elseif nClassID == 11 then
        fnAction = function()
            RemoteCallToServer("On_Tong_StartActivityRequest", nClassID, nSubClassID)
        end
    end

    if not fnAction then
        return
    end

	if nClassID == 8 and player and player.nLevel < 110 then	--特判小猪快跑需要玩家达到110级
		TipsHelper.ShowNormalTip("侠士达到110级后方可参与小猪快跑")
		return
	else
		UIHelper.ShowConfirm(g_tStrings.GUILP_PANEL_START_ACTIVITY, function()
			fnAction()

			TongData.bUpdateActivity = nil

			RemoteCallToServer("On_Tong_GetActivityTimeRequest")

			Event.Dispatch(EventType.TongClickOpenActivity)
		end, nil, false)
	end

end


-- 活动 end ------------------------

TongData.bHasApplyList = false

function TongData.HasApplyRedPoint()
    local tMemberInfo = TongData.GetCurMemberInfo()
    if not tMemberInfo then
        return false
    end
    
    local nPlayerGroupID = tMemberInfo.nGroupID
    local nGroupID       = GetTongClient().GetDefaultGroupID()
    local bPermission    = GetTongClient().CanAdvanceOperate(nPlayerGroupID, nGroupID, TONG_OPERATION_INDEX.ADD_TO_GROUP)

    --- 有申请信息，且未禁用申请推送，且有操作权限
    return TongData.bHasApplyList and Storage.Tong.bReceiveJoinApplyMsg and bPermission
end

function TongData.TryGetApplyJoinInList()
    if not self.HavePlayerJoinedTong() then
        return
    end

    if Storage.Tong.bReceiveJoinApplyMsg then
        RemoteCallToServer("On_Tong_GetApplyJoinInList")
    end
end

Event.Reg(self, "ON_GET_APPLY_JOININ_TONGLIST", function(tApplyList)
    TongData.bHasApplyList = tApplyList and #tApplyList > 0
    Event.Dispatch("OnTongApplyListRedPointUpdate")
end)

Event.Reg(self, "ON_APPLICATION_TO_TONG_READ_MSG", function()
    TongData.bHasApplyList = true
    Event.Dispatch("OnTongApplyListRedPointUpdate")
end)

--- 获取上周的天工树方案
function TongData.GetLastWeekRebornTreePlan()
    TongData.TryUpdateLastWeekRebornTreePlan()

    return Storage.TongRebornTree.tLastWeekPlan
end

function TongData.GetNodeLevel(nNodeID, bPreview)
    local TongClient    = GetTongClient()
    local tLastWeekPlan = TongData.GetLastWeekRebornTreePlan()

    local nLevel
    if bPreview then
        nLevel = tLastWeekPlan[nNodeID] or TongClient.GetTechNodeLevel(nNodeID)
    else
        nLevel = TongClient.GetTechNodeLevel(nNodeID)
    end
    return nLevel
end

function TongData.GetPreviewCost()
    local TongClient    = GetTongClient()
    local tLastWeekPlan = TongData.GetLastWeekRebornTreePlan()

    local nCost         = 0
    for nNodeID, nLevel in pairs(tLastWeekPlan) do
        if nLevel > 0 then
            local Node        = TongTechTreeNode[nNodeID]
            local nStartLevel = TongClient.GetTechNodeLevel(nNodeID) + 1

            for i = nStartLevel, nLevel do
                nCost = nCost + GetTongTechTreeNodeCost(Node, i)
            end
        end
    end

    return nCost
end

function TongData.GetPreviewNode()
    local TongClient    = GetTongClient()
    local tLastWeekPlan = TongData.GetLastWeekRebornTreePlan()

    local tRet          = {}
    for nNodeID, nLevel in pairs(tLastWeekPlan) do
        if nLevel > 0 then
            local nStartLevel = TongClient.GetTechNodeLevel(nNodeID) + 1

            if nLevel >= nStartLevel then
                tRet[nNodeID] = nLevel
            end
        end
    end

    return tRet
end

--- 当获取到最新的帮会数据时，确保本周的存盘数据与其一致
Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function()
    TongData.SaveRebornTreeData()
end)

function TongData.SaveRebornTreeData()
    TongData.TryUpdateLastWeekRebornTreePlan()

    local bChanged    = false

    local tRebornNode = TongData.GetBranchData(2)
    local tSavedPlan  = Storage.TongRebornTree.tThisWeekPlan

    local TongClient  = GetTongClient()

    for _, nNodeID in pairs(tRebornNode) do
        local nLevel      = TongClient.GetTechNodeLevel(nNodeID)
        local nSavedLevel = tSavedPlan[nNodeID]

        if nLevel == 0 and nSavedLevel then
            --- 如果当前该节点未点亮，但之前保存的数据有值，则将其移除
            tSavedPlan[nNodeID] = nil
            bChanged            = true
        elseif nLevel > 0 and nLevel ~= nSavedLevel then
            --- 否则，若之前的值与当前值不一致，则更新为新的值
            tSavedPlan[nNodeID] = nLevel
            bChanged            = true
        end
    end

    if bChanged then
        LOG.DEBUG("天工树涅槃分支数据有变化，最新值如下")
        LOG.TABLE(tSavedPlan)

        Storage.TongRebornTree.Dirty()
    end
end

--- 若周数变更，则尝试更新上周的天工树方案
function TongData.TryUpdateLastWeekRebornTreePlan()
    local tData                   = Storage.TongRebornTree

    local nCurrentWeekIndexInYear = TimeLib.TimeToWeekCount(GetCurrentTime())
    if tData.nWeekIndexInYearWhenLastSave ~= nCurrentWeekIndexInYear then
        --- todo: 后面确认下，如果N周有方案数据，后面几周没有设置过，比如第N+2周上来的时候，是继续使用N周的方案作为上周方案，还是使用N+1的空方案作为新的上周方案
        ---     若以最近一次有实际数据的周方案，则判断条件增加判断 tThisWeek 大小是否>0，并修改变量名为 tLastValidWeekPlan

        LOG.DEBUG("新的一周，尝试保存上周的天工树方案 nWeekIndexInYearWhenLastSave=%d nCurrentWeekIndexInYear=%d", tData.nWeekIndexInYearWhenLastSave, nCurrentWeekIndexInYear)
        LOG.DEBUG("更新前，本周和上周的数据分别如下")
        LOG.TABLE(tData.tThisWeekPlan)
        LOG.TABLE(tData.tLastWeekPlan)

        -- 某些天工树可能被移除，不在配置表中了，这里顺带删除它
        local tLastWeekPlan = clone(tData.tThisWeekPlan)
        if tLastWeekPlan ~= nil then
            local tNodeMap = Table_GetTongTechNodeMap()
            for nNodeID, nLevel in pairs(tLastWeekPlan) do
                if tNodeMap[nNodeID] == nil then
                    tLastWeekPlan[nNodeID] = nil
                    LOG.DEBUG("节点 %d 不在配置表中，移除该节点", nNodeID)
                end
            end
        end

        -- 实际更替数据
        tData.nWeekIndexInYearWhenLastSave = nCurrentWeekIndexInYear
        tData.tLastWeekPlan                = tLastWeekPlan
        tData.tThisWeekPlan                = {}

        tData.Dirty()
    end
end

--帮会联赛海选活动
local tTongGuildActivity = {
    [694] = true,
    [695] = true,
    [1008] = true,
    [1009] = true,
}

local function OnActivityStateChanged()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local dwActivityID = arg0
    local bOpen        = arg1
    if tTongGuildActivity[dwActivityID] and bOpen then --帮会联赛报名开启
        --没帮会
        if hPlayer.dwTongID == 0 then
            return
        end

        --跨服
        if IsRemotePlayer(hPlayer.dwID) then
            return
        end

        --副本
        local dwMapID = hPlayer.GetMapID()
        local _, nMapType = GetMapParams(dwMapID)
        if nMapType == MAP_TYPE.DUNGEON then
            return
        end

        local hTongClient = GetTongClient()
        if not hTongClient then
            return
        end

        --非帮主或核心成员
        if not hTongClient.CanMemberBaseOperate(hPlayer.dwID, TONG_OPERATION_INDEX.TONG_LEAGUE_CORE) then
            return
        end
        UIMgr.Open(VIEW_ID.PanelFactionChampionshipHintPop, 14)
    end
end

Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", OnActivityStateChanged)