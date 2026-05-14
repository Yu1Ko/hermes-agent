-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAuctionStatsPage
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAuctionStatsPage = class("UIWidgetAuctionStatsPage")

local DELETE_CD_TIME = 60 -- 删除操作的执行CD(秒)
local UNPAID_CD_TIME = 30 -- 发布未付操作的执行CD(秒)
function UIWidgetAuctionStatsPage:OnEnter(fAddRecord, fOnDeleteRecord)
    if not fAddRecord then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tDeleteBidInfoMap = {}
    self.fAddRecord = fAddRecord
    self.fOnDeleteRecord = fOnDeleteRecord
    self:UpdateInfo()

    Timer.AddCycle(self, 1, function ()
        self:RefreshDeleteRecordButton()
        self:RefreshUnpaidRecordButton()
    end)
end

function UIWidgetAuctionStatsPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetAuctionStatsPage:BindUIEvent()
    UIHelper.BindUIEvent(self.TogChooseAll, EventType.OnSelectChanged, function (_, bSelected)
        if not self.tAllBiddingInfo then
            return
        end
        for _, tBidInfo in ipairs(self.tAllBiddingInfo) do
            self:OnDeleteRecordSeleted(tBidInfo, bSelected)
        end
        self:UpdateRecordInfo()
        self:UpdateButtonState()
    end)

    UIHelper.BindUIEvent(self.BtnAddMoney, EventType.OnClick, function ()
        local nSize = GetClientTeam().GetTeamSize()
        local nSum = GetTableCount(AuctionData.tCheckTeamers)
        if nSize then
            if nSize < 2 then
                TipsHelper.ShowImportantYellowTip("团队成员不少于2人才可以追加收入。")
                return
            elseif nSize < nSum * 0.5 then
                UIHelper.ShowConfirm("当前团队人数较少，资金可能无法进行分配，是否仍然选择追加收入？", function ()
                    UIMgr.Open(VIEW_ID.PanelAddIncomePop)
                end)
                return
            end
        end
        UIMgr.Open(VIEW_ID.PanelAddIncomePop)
    end)

    UIHelper.BindUIEvent(self.BtnAddRecord, EventType.OnClick, function ()
        local nSize = GetClientTeam().GetTeamSize()
        if nSize and nSize < 2 then 
            TipsHelper.ShowImportantYellowTip("团队成员不少于2人才可以追加收入。")
            return
        end
        self.fAddRecord()
    end)

    UIHelper.BindUIEvent(self.BtnDelRecord, EventType.OnClick, function ()
        self.bDeleteState = true
        self.tDeleteBidInfoMap = {}
        UIHelper.SetVisible(self.WidgetNormalButtons, false)
        UIHelper.SetVisible(self.WidgetDeleteButtons, true)
        self.fOnDeleteRecord(self.bDeleteState)
        self:UpdateRecordInfo()
        self:UpdateButtonState()
        UIHelper.SetSelected(self.TogChooseAll, false)
    end)

    UIHelper.BindUIEvent(self.BtnDelFinish, EventType.OnClick, function ()
        self.bDeleteState = false
        UIHelper.SetVisible(self.WidgetNormalButtons, true)
        UIHelper.SetVisible(self.WidgetDeleteButtons, false)
        self.fOnDeleteRecord(self.bDeleteState)
        self:UpdateRecordInfo()
        self:UpdateButtonState()
    end)

    UIHelper.BindUIEvent(self.BtnDoDelete, EventType.OnClick, function ()
        self:DoDeleteRecord()
        UIHelper.SetSelected(self.TogChooseAll, false)
    end)

    UIHelper.BindUIEvent(self.BtnUnpaidRecord, EventType.OnClick, function ()
        self:DispatchUnpaidRecord()
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewRecord, function(tableView, nIndex, script, node, cell)
        local tBidInfo = self.tAllBiddingInfo[nIndex]
        if not tBidInfo or not script or tBidInfo.nState == BIDDING_INFO_STATE.BIDDING then
            return
        end

        local tData = {
            tBidInfo = tBidInfo,            
            bDeleteState = self.bDeleteState,
            bSelected = self.tDeleteBidInfoMap[tBidInfo.nBiddingInfoIndex],
        }
        tData.bSelected = tData.bSelected or false
        tData.fOnDeleteRecordSeleted = function (tInfo, bSelected)
            self:OnDeleteRecordSeleted(tInfo, bSelected)
        end
        script:OnEnter(tData)
    end)
end

function UIWidgetAuctionStatsPage:RegEvent()
    Event.Reg(self, "BIDDING_OPERATION", function (eBidOperationType, dwOperatorPlayerID, nBidInfoIndex, nOperationTimestamp)
        if eBidOperationType == BIDDING_OPERATION_TYPE.FINISH then
            self:UpdateRecordInfo()
            self:UpdateButtonState()
        end
    end)
    Event.Reg(self, "BIDDING_INFO_CHANGE", function (bAll, nBidInfoIndex)
        if bAll then
            self:UpdateRecordInfo()
            self:UpdateButtonState()
        end
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (nAuthorityType)
        if nAuthorityType == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
            self:UpdateButtonState()
        end
    end)
end

function UIWidgetAuctionStatsPage:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAuctionStatsPage:UpdateInfo()
    self:UpdateRecordInfo()
    self:UpdateButtonState()
end

function UIWidgetAuctionStatsPage:UpdateRecordInfo()
    local teamBidMgr = GetTeamBiddingMgr()
    local team = GetClientTeam()
    self.tAllBiddingInfo = {}
    for _, tBidInfo in ipairs(teamBidMgr.GetAllBiddingInfo()) do
        if tBidInfo.nState ~= BIDDING_INFO_STATE.BIDDING and tBidInfo.nState ~= BIDDING_INFO_STATE.COUNT_DOWN then table.insert(self.tAllBiddingInfo, tBidInfo) end
    end
    table.sort(self.tAllBiddingInfo, function (tInfo1, tInfo2)
        local nVal1 = 0
        local nVal2 = 0
        if tInfo1.nState == BIDDING_INFO_STATE.WAIT_PAYMENT then nVal1 = 10 end
        if tInfo2.nState == BIDDING_INFO_STATE.WAIT_PAYMENT then nVal2 = 10 end
        if UI_GetClientPlayerID() == tInfo1.dwDestPlayerID then nVal1 = nVal1 + 1 end
        if UI_GetClientPlayerID() == tInfo2.dwDestPlayerID then nVal2 = nVal2 + 1 end

        return nVal1 > nVal2
    end)

    local bEmpty = not self.tAllBiddingInfo or #self.tAllBiddingInfo == 0
    UIHelper.SetVisible(self.WidgetAnchorEmpty, bEmpty)

    local bCanAuction = team.nLootMode == PARTY_LOOT_MODE.BIDDING or team.nLootMode == PARTY_LOOT_MODE.DISTRIBUTE
    UIHelper.SetVisible(self.BtnAddMoney, bCanAuction)
    
    UIHelper.TableView_init(self.TableViewRecord, #self.tAllBiddingInfo, PREFAB_ID.WidgetAuctionStatsItem)
    UIHelper.TableView_reloadData(self.TableViewRecord)
end

function UIWidgetAuctionStatsPage:UpdateButtonState()
    local bDistributer = AuctionData.IsDistributeMan()
    UIHelper.SetVisible(self.BtnAddRecord, bDistributer)
    UIHelper.SetVisible(self.BtnDelRecord, bDistributer)
    UIHelper.SetVisible(self.BtnUnpaidRecord, bDistributer)

    UIHelper.SetVisible(self.TogChooseAll, self:CanDeleteAnyRecord())
    UIHelper.LayoutDoLayout(self.LayoutButton)
end

function UIWidgetAuctionStatsPage:CanDeleteAnyRecord()
    for _, tBidInfo in ipairs(self.tAllBiddingInfo or {}) do
        if tBidInfo.nState == BIDDING_INFO_STATE.PAID or tBidInfo.nState == BIDDING_INFO_STATE.INVALID then return true end
    end

    return false
end

function UIWidgetAuctionStatsPage:OnDeleteRecordSeleted(tBidInfo, bSelected)
    if tBidInfo.nState == BIDDING_INFO_STATE.PAID or tBidInfo.nState == BIDDING_INFO_STATE.INVALID then
        self.tDeleteBidInfoMap[tBidInfo.nBiddingInfoIndex] = bSelected
    end    
end

function UIWidgetAuctionStatsPage:DoDeleteRecord()
    if table.GetCount(self.tDeleteBidInfoMap) == 0 then
        TipsHelper.ShowNormalTip("请选择有效的记录进行删除")
        return
    end
    local teamBidMgr = GetTeamBiddingMgr()
    local aDeletedBidInfos = {}
    local aDeletedBidIndexs = {}

    for nBidIndex, bSelected in pairs(self.tDeleteBidInfoMap) do
        if bSelected then
            local bRes = teamBidMgr.CanDeleteBiddingInfo(nBidIndex)
            if bRes then
                table.insert(aDeletedBidInfos, clone(teamBidMgr.GetBiddingInfo(nBidIndex)))
                table.insert(aDeletedBidIndexs, nBidIndex)
            else
                self.tDeleteBidInfoMap[nBidIndex] = nil
                local szErrMsg = FormatString(g_tStrings.GOLD_TEAM_CANT_DELETE_BID_INFO, nBidIndex)
                OutputMessage("MSG_ANNOUNCE_NORMAL", szErrMsg)
                UILog(szErrMsg)
            end
        end
    end

    RemoteCallToServer("On_Team_SendDeletedRecords", aDeletedBidIndexs)
    Timer.Add(self, 3, function()
        for i, nBidIndex in ipairs(aDeletedBidIndexs) do
            teamBidMgr.DeleteBiddingInfo(nBidIndex)
            self:UpdateRecordInfo()
        end

        self.tDeleteBidInfoMap = {}
    end)

    AuctionData.dwDeleteRecordsStartTime = GetTickCount()
end

function UIWidgetAuctionStatsPage:DispatchUnpaidRecord()
	local nChannel = AuctionData.GetChannel()
	if nChannel and AuctionData.IsDistributeMan() then
		local player = GetClientPlayer()
		local aTextList = {}
		aTextList = self:GetStatisticMsg_Record()

		for k, tText in ipairs(aTextList) do
			Player_Talk(player, nChannel, "", tText)
		end
	end
    AuctionData.dwDistribUnpaidRecordsTime = GetTickCount()
end

function UIWidgetAuctionStatsPage:GetStatisticMsg_Record()
	local aTextList = {}
	local szData = string.rep("*", 15) .. g_tStrings.GOLD_TEAM_UNPAID_RECORD_LIST_TITLE .. string.rep("*", 15)
	table.insert(aTextList, { { type="text", text=szData}})

	local tPlayerUnpaidGoldInfos =
	{
		-- [dwUnpaidPrice, dwPaidPrice], -- dwPaidPrice包括被代付的
	}
    local teamBidMgr = GetTeamBiddingMgr()
	local aBidInfoList = teamBidMgr.GetAllBiddingInfo() or {}
	for i, tBidInfo in ipairs(aBidInfoList) do
		local nState = tBidInfo.nState
		if nState ~= BIDDING_INFO_STATE.INVALID and nState ~= BIDDING_INFO_STATE.BIDDING and nState ~= BIDDING_INFO_STATE.COUNT_DOWN then
			local szPlayerName = UIHelper.GBKToUTF8(tBidInfo.szDestPlayerName)
			local dwUnpaidPrice, dwPaidPrice = GoldTeamBase_GetRequiredGold(tBidInfo)
			if dwUnpaidPrice + dwPaidPrice > 0 then -- 包括已付完款的
				tPlayerUnpaidGoldInfos[szPlayerName] = (tPlayerUnpaidGoldInfos[szPlayerName] or {0, 0})
				tPlayerUnpaidGoldInfos[szPlayerName][1] = tPlayerUnpaidGoldInfos[szPlayerName][1] + dwUnpaidPrice
				tPlayerUnpaidGoldInfos[szPlayerName][2] = tPlayerUnpaidGoldInfos[szPlayerName][2] + dwPaidPrice
			end
		end
	end

	if IsTableEmpty(tPlayerUnpaidGoldInfos) then
		table.insert(aTextList, {{ type="text", text=g_tStrings.GOLD_TEAM_NO_UNPAID_RECORDS}})
	else
		for szPlayerName, t in pairs(tPlayerUnpaidGoldInfos) do
			local dwUnpaidPrice, dwPaidPrice = t[1], t[2]
			local szTip = FormatString(g_tStrings.GOLD_TEAM_UNPAID_GOLD, GoldTeam_GetGoldText(dwUnpaidPrice, false, true),
					GoldTeam_GetGoldText(dwPaidPrice + dwUnpaidPrice, false, true), GoldTeam_GetGoldText(dwPaidPrice, false, true))
			table.insert(aTextList, { {type = "name", text = "[".. szPlayerName .."]", name = szPlayerName},
									  {type="eventlink", name=szTip, linkinfo="OpenGoldTeam"} })
		end
	end

	table.insert(aTextList, { {type="text", text=string.rep("*", 41)} })
    for _, textInfo in ipairs(aTextList) do
        for _, textBar in ipairs(textInfo) do
            if textBar.text then
                textBar.text = UIHelper.UTF8ToGBK(textBar.text)
            end
            if textBar.name then
                textBar.name = UIHelper.UTF8ToGBK(textBar.name)
            end
            if textBar.szTip then
                textBar.szTip = UIHelper.UTF8ToGBK(textBar.szTip)
            end
        end
    end
	return aTextList
end

function UIWidgetAuctionStatsPage:RefreshDeleteRecordButton()
    if not AuctionData.dwDeleteRecordsStartTime or AuctionData.dwDeleteRecordsStartTime == 0 then
		return
	end

	local dwLeftTime = (GetTickCount() - AuctionData.dwDeleteRecordsStartTime)/1000
	local szTitle = "删除"
	if dwLeftTime < DELETE_CD_TIME then
		local dwDisplayTime = math.floor((DELETE_CD_TIME - dwLeftTime))
        UIHelper.SetString(self.LabelDoDelete, szTitle .. "(" .. dwDisplayTime .. ")")
		UIHelper.SetButtonState(self.BtnDoDelete, BTN_STATE.Disable, "删除操作尚在冷却中")
	else
        UIHelper.SetString(self.LabelDoDelete, szTitle)
		UIHelper.SetButtonState(self.BtnDoDelete, BTN_STATE.Normal)
		AuctionData.dwDeleteRecordsStartTime = 0
	end
end

function UIWidgetAuctionStatsPage:RefreshUnpaidRecordButton()
    if not AuctionData.dwDistribUnpaidRecordsTime or AuctionData.dwDistribUnpaidRecordsTime == 0 then
		return
	end

	local dwLeftTime = (GetTickCount() - AuctionData.dwDistribUnpaidRecordsTime)/1000
	local szTitle = "发布未付项"
	if dwLeftTime < UNPAID_CD_TIME then
		local dwDisplayTime = math.floor((UNPAID_CD_TIME - dwLeftTime))
        UIHelper.SetString(self.LabelUnpaidRecord, szTitle .. "(" .. dwDisplayTime .. ")")
		UIHelper.SetButtonState(self.BtnUnpaidRecord, BTN_STATE.Disable, "发布未付记录操作尚在冷却中")
	else
        UIHelper.SetString(self.LabelUnpaidRecord, szTitle)
		UIHelper.SetButtonState(self.BtnUnpaidRecord, BTN_STATE.Normal)
		AuctionData.dwDistribUnpaidRecordsTime = 0
	end
end

return UIWidgetAuctionStatsPage