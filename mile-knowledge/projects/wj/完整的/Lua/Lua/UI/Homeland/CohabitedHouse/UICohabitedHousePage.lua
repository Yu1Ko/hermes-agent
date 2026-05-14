-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICohabitedHousePage
-- Date: 2023-07-19 11:16:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICohabitedHousePage = class("UICohabitedHousePage")

local BG_PATH = "mui/Resource/JYPlay/Cohabitation.png"
local bTestMode = false -- 重要： 测试用
local bDebugMode = true
local nRuleID = 26

local DataModel =
{
	---- 逻辑数据
	aMyLandInfos = -- 用于识别收到的事件是不是自己要关心的
	{
		--[1] = {szLandID=szLandID, bHasNews=true/false}, -- bHasNews: 有没有客人主动提出了退出共居
	},
	aCohabitedLandInfos = -- 用于识别收到的事件是不是自己要关心的
	{
		--[1] = {szLandID=szLandID, bHasNews=true/false}, -- bHasNews: 主人有没有对自己解除共居
	},

	nDwellerCallUpCount = 0,

	---- 逻辑常量
	tUnlockLevelsForCohabitRooms =
	{
		--[[
		[1] = 5, -- 5级解锁第一个席位；下面类似
		[2] = 10,
		[3] = 15,
		--]]
	},

	nLandDelayKickOutTime = 0, -- 单位：秒

	---- UI数据
	tJumpedToHouseLocationInfo = nil,
	--[=[
	{
		[1] = dwMapID,
		[2] = nCopyIndex,
		[3] = nLandIndex,
	}
	--]=]
	hCBoxSelectedHouse = nil,

	---- UI常量
	MAX_COHABIT_PLAYERS = 3, -- 来自逻辑（同时也是客人控件的固定数目）
	MAX_MY_HOUSES = 1, -- 来自逻辑（同时也是自己家园控件的固定数目）
	MAX_COHABIT_HOUSES = 3, -- 来自逻辑（同时也是共居家园控件的固定数目）
}

------------------------------ 数据相关函数
function DataModel.Init()
	DataModel.aMyLandInfos = {}
	DataModel.aCohabitedLandInfos = {}
	DataModel.tJumpedToHouseLocationInfo = nil

	local tConfig = GetHomelandMgr().GetConfig()
	local aCriticalLevels = tConfig.AlliedSegmentInfo
	for i, nLevel in ipairs(aCriticalLevels) do
		DataModel.tUnlockLevelsForCohabitRooms[i] = nLevel + 1
	end
	DataModel.nLandDelayKickOutTime = tConfig.nLandDelayKickOutTime

	DataModel.RequestAllCohabitInfo()
	RemoteCallToServer("On_HomeLand_CallUpCount")
end

function DataModel.RequestAllCohabitInfo()
	if bDebugMode then
		Log("=== 调用了 Cohabitation.RequestAllCohabitInfo()，并即将调用 ApplyEstate()")
	end
	local hlMgr = GetHomelandMgr()
	hlMgr.ApplyEstate()
end

function DataModel.UnInit()
	DataModel.aMyLandInfos = {}
	DataModel.aCohabitedLandInfos = {}
	DataModel.tJumpedToHouseLocationInfo = nil
	--DataModel.nDwellerCallUpCount = 0
	DataModel.hCBoxSelectedHouse = nil
end

---------------- 逻辑相关

function DataModel.IsLandMine(szLandID)
	local t = FindTableValueByKey(DataModel.aMyLandInfos, "szLandID", szLandID)
	return t ~= nil, t
end

function DataModel.IsLandCohabited(szLandID)
	local t = FindTableValueByKey(DataModel.aCohabitedLandInfos, "szLandID", szLandID)
	return t ~= nil, t
end

function DataModel.HasNews()
	for _, t in pairs(DataModel.aMyLandInfos) do
		if t.bHasNews then
			return true
		end
	end

	for _, t in pairs(DataModel.aCohabitedLandInfos) do
		if t.bHasNews then
			return true
		end
	end

	return false
end

function UICohabitedHousePage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        DataModel.Init()
    end

    DataModel.tJumpedToHouseLocationInfo = nil
    -- UIHelper.SetTexture(self.ImgBg, BG_PATH)
	self:InitHelpDesc()
    self:UpdateInfo()
end

function UICohabitedHousePage:OnExit()
    self.bInit = false
    DataModel.UnInit()
end

function UICohabitedHousePage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnQuit, EventType.OnClick, function ()
        if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
            return
        end

        local dwMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.tbSelectedInfo.szLandID)

        local szTips = FormatString(g_tStrings.STR_HOMELAND_COHABIT_TERMINATE_CONFIRM_MESSAGE_11, self:GetStringTerminateCohabitLeftTime(0))
        UIHelper.ShowConfirm(szTips, function ()
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
                return
            end
            GetHomelandMgr().LandKickOutAllied( dwMapID, nCopyIndex, nLandIndex, PlayerData.GetPlayerID(), false)
        end, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnPleaseGo, EventType.OnClick, function ()
        if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
            return
        end

        local dwMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.tbSelectedInfo.szLandID)
        UIMgr.Open(VIEW_ID.PanelHouseholdEndPop, dwMapID, nCopyIndex, nLandIndex, function (nTime)
			return self:GetStringTerminateCohabitLeftTime(nTime)
		end)
    end)

    UIHelper.BindUIEvent(self.BtnExamine, EventType.OnClick, function ()
        if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
            return
        end

        local dwMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.tbSelectedInfo.szLandID)

        Event.Dispatch(EventType.OnSelectHomelandMainPage, 1)
        Event.Dispatch(EventType.OnSelectHomelandMyHomeMap, dwMapID, nCopyIndex, nLandIndex)
    end)

    UIHelper.BindUIEvent(self.BtnGoHome, EventType.OnClick, function ()
        if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
            return
        end

        local hHomeland = GetHomelandMgr()
        local dwMapID, nCopyIndex, nLandIndex = hHomeland.ConvertLandID(self.tbSelectedInfo.szLandID)
        local bPrivateHome = hHomeland.IsPrivateHomeMap(dwMapID)
        local tPrivateInfo = bPrivateHome and hHomeland.GetPrivateHomeInfo(dwMapID, nCopyIndex)
        local dwSkinID = tPrivateInfo and tPrivateInfo.dwSkinID

        local function _backToLand()
            HomelandData.BackToLand(dwMapID, nCopyIndex, nLandIndex)

            UIMgr.Close(VIEW_ID.PanelHome)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(dwMapID, dwSkinID, _backToLand) then
            _backToLand()
        end
    end)

    -- UIHelper.BindUIEvent(self.BtnSkip, EventType.OnClick, function ()
    --     self:JumpToMap()
    -- end)

	-- UIHelper.BindUIEvent(self.BtnSkip01, EventType.OnClick, function ()
    --     self:JumpToMap()
    -- end)

    UIHelper.BindUIEvent(self.BtnStopLeave, EventType.OnClick, function ()
        if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
            return
        end

        local dwMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.tbSelectedInfo.szLandID)

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
            return
        end
        GetHomelandMgr().LandKickOutAllied( dwMapID, nCopyIndex, nLandIndex, PlayerData.GetPlayerID(), true)
    end)

	UIHelper.BindUIEvent(self.BtnConfirmLeave, EventType.OnClick, function ()
        if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
            return
        end

        local dwMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.tbSelectedInfo.szLandID)

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
            return
        end
        GetHomelandMgr().LandKickOutAllied( dwMapID, nCopyIndex, nLandIndex, PlayerData.GetPlayerID(), false)
    end)
end

function UICohabitedHousePage:RegEvent()
	Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogHelp1, false)
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
        local nRetCode = arg0
		if nRetCode == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED or nRetCode == HOMELAND_RESULT_CODE.APPLY_ESTATE_TO_HS_SUCCEED then -- 重要：先统一处理，后面再做出区分
			self:OnApplyEstateSucceed()
		end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
        local nRetCode = arg0
		if nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			self:OnApplyLandInfoSuccess(dwMapID, nCopyIndex, nLandIndex)
		elseif nRetCode == HOMELAND_RESULT_CODE.APPLY_COMMUNITY_INFO then
			local dwMapID, nCopyIndex, nCenterID, nIndex = arg1, arg2, arg3, arg4 -- 重要： 可能走的不是这个机制？
			self:OnApplyCommunityInfoSucceed(dwMapID, nCopyIndex)
		elseif nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_ALLIED_INFO_SUCCEED then
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			self:OnApplyLandAlliedInfoSucceed(dwMapID, nCopyIndex, nLandIndex)
		elseif nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_ALLIED_INFO_FAILED then
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			self:OnApplyLandAlliedInfoFail(dwMapID, nCopyIndex, nLandIndex)
		elseif nRetCode == HOMELAND_RESULT_CODE.ALLIED_INFO_CHANGE then
			local dwMapID, nCopyIndex, nLandIndex, nNoticeType = arg1, arg2, arg3, arg4
			--local hWndOneHouse = View.FindWndOneHouseByLocation(View.GetWndMain(hFrame), nil, dwMapID, nCopyIndex, nLandIndex)
			if nNoticeType == HOMELAND_RESULT_CODE.ALLIED_CHANGE_BY_ADD then
				--LOG.INFO("==== 并且操作类型是【建立】！")
			elseif nNoticeType == HOMELAND_RESULT_CODE.ALLIED_CHANGE_BY_DELETE then
				--LOG.INFO("==== 并且操作类型是【解除】！")
				self.nSelectIndex = nSelectedIndex
				self.tbSelectedInfo = tbSelectedInfo
				DataModel.Init()
				self:UpdateInfo()
			elseif nNoticeType == HOMELAND_RESULT_CODE.ALLIED_CHANGE_BY_OTHER then
				--LOG.INFO("==== 并且操作类型是【更新】！")
				-- Do nothing for now.
		end
		end
    end)
end

function UICohabitedHousePage:InitHelpDesc()
	local tbConfig = TabHelper.GetUIRuleTab(nRuleID)
    if not tbConfig then
        return
    end

    local i = 1
	local szDesc = ""
    while tbConfig["nPrefabID"..i] and tbConfig["szDesc"..i] and tbConfig["nPrefabID"..i] > 0 and tbConfig["szDesc"..i] ~= "" do
		if szDesc ~= "" then
			szDesc = szDesc .. "\n"
		end
        szDesc = szDesc .. tbConfig["szDesc"..i]
        i = i + 1
    end

	UIHelper.SetString(self.LabelHelp, szDesc)
	UIHelper.LayoutDoLayout(self.ImgHelpBg)
end

function UICohabitedHousePage:UpdateInfo()
    self:UpdateBgInfo()
    self:UpdateLeftInfo()
    self:UpdateRightInfo()
end

function UICohabitedHousePage:UpdateBgInfo()
    if table.is_empty(DataModel.aMyLandInfos) and table.is_empty(DataModel.aCohabitedLandInfos) then
        UIHelper.SetVisible(self.WidgetAnchorLeft, false)
    else
        UIHelper.SetVisible(self.WidgetAnchorLeft, true)
    end
end

function UICohabitedHousePage:UpdateLeftInfo()
    local nIndex = 1
    local tbMyLandInfos = DataModel.aMyLandInfos
    if table.is_empty(tbMyLandInfos) then
        tbMyLandInfos = {{}}
    end
    for i, tbInfo in ipairs(tbMyLandInfos) do
        self.scriptMyLandCell = self.scriptMyLandCell or UIHelper.AddPrefab(PREFAB_ID.WidgetHouseholdTitleTog, self.WidgettHomeTitleTog)
        self.scriptMyLandCell:OnEnter(nIndex, tbInfo, true)
        self.scriptMyLandCell:SetClickCallback(function (nSelectedIndex, tbSelectedInfo)
			self.nSelectIndex = nSelectedIndex
			self.tbSelectedInfo = tbSelectedInfo
            self:OnClickToggleCell(nSelectedIndex, tbSelectedInfo)
        end)
        nIndex = nIndex + 1
        break
    end

    self.tbCohabitedLandCell = self.tbCohabitedLandCell or {}
    for i = 1, DataModel.MAX_COHABIT_HOUSES do
        local tbInfo = DataModel.aCohabitedLandInfos[i]
        if not self.tbCohabitedLandCell[i] then
            self.tbCohabitedLandCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHouseholdTitleTog, self.LayoutHouseholdTitleTogCell)
            self.tbCohabitedLandCell[i]:SetClickCallback(function (nSelectedIndex, tbSelectedInfo)
				self.nSelectIndex = nSelectedIndex
				self.tbSelectedInfo = tbSelectedInfo
                self:OnClickToggleCell(nSelectedIndex, tbSelectedInfo)
            end)
        end

        self.tbCohabitedLandCell[i]:OnEnter(nIndex, tbInfo)
        nIndex = nIndex + 1
    end

    UIHelper.LayoutDoLayout(self.LayoutHouseholdTitleTogCell)
end

function UICohabitedHousePage:UpdateRightInfo()
    if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
        UIHelper.SetVisible(self.WidgetHouseholdRight, false)
        UIHelper.SetVisible(self.ImgBg, true)
        UIHelper.SetVisible(self.WidgetMiddleLabel, table.is_empty(DataModel.aMyLandInfos) and table.is_empty(DataModel.aCohabitedLandInfos))
        UIHelper.SetVisible(self.WidgetHouseholdTips, self.nSelectIndex and self.nSelectIndex == 1)
        UIHelper.SetVisible(self.WidgetHouseholdTips01, self.nSelectIndex and self.nSelectIndex > 1)
        return
    else
        UIHelper.SetVisible(self.WidgetHouseholdRight, true)
        UIHelper.SetVisible(self.ImgBg, false)
        UIHelper.SetVisible(self.WidgetMiddleLabel, false)
        UIHelper.SetVisible(self.WidgetHouseholdTips, false)
        UIHelper.SetVisible(self.WidgetHouseholdTips01, false)
    end

    local hlMgr = GetHomelandMgr()
	local dwMapID, nCopyIndex, nLandIndex = hlMgr.ConvertLandID(self.tbSelectedInfo.szLandID)
    local aCohabitPlayerInfos = hlMgr.GetLandAlliedInfo(dwMapID, nCopyIndex, nLandIndex)
	aCohabitPlayerInfos = aCohabitPlayerInfos or {}
    self.tbCohabitedMemberCell = self.tbCohabitedMemberCell or {}
    local szMyName = UIHelper.GBKToUTF8(GetClientPlayer().szName)
	local bIsLandlordMyself = UIHelper.GBKToUTF8(aCohabitPlayerInfos.Name) == szMyName
    for i = 1, DataModel.MAX_COHABIT_PLAYERS + 1, 1 do
        local tbInfo = aCohabitPlayerInfos
        if i > 1 then
            tbInfo = aCohabitPlayerInfos[i - 1]
        end
        if not self.tbCohabitedMemberCell[i] then
            self.tbCohabitedMemberCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHouseholdFriendListCell, self.LayoutHouseholdFriendList)
        end

		local szKickOutLeftTime = ""
		if tbInfo and tbInfo.KickOutTime and tbInfo.KickOutTime > 0 then
			szKickOutLeftTime = self:GetStringTerminateCohabitLeftTime(GetCurrentTime() - tbInfo.KickOutTime)
		end
        self.tbCohabitedMemberCell[i]:OnEnter(tbInfo, self.tbSelectedInfo.szLandID, bIsLandlordMyself, szKickOutLeftTime)

		local tLandInfo = hlMgr.GetLandInfo(dwMapID, nCopyIndex, nLandIndex)
		local nCurLandLevel = tLandInfo.nLevel
		local nUnlockLevel = DataModel.tUnlockLevelsForCohabitRooms[i - 1] or 0
		if nCurLandLevel >= nUnlockLevel then
			self.tbCohabitedMemberCell[i]:SetUnloclDesc("屋主需与好友组队前往屋主“管家阿甘”处申请共居。")
		else
			self.tbCohabitedMemberCell[i]:SetUnloclDesc(FormatString(g_tStrings.STR_HOMELAND_COHABIT_ROOM_LOCKED_FOR_LEVEL, nUnlockLevel))
		end
    end

	RemoteCallToServer("On_HomeLand_CallUpCount")

    self:UpdateBtnInfo(aCohabitPlayerInfos)
    UIHelper.LayoutDoLayout(self.LayoutHouseholdFriendList)
end

function UICohabitedHousePage:UpdateBtnInfo(aCohabitPlayerInfos)
    local bKickOutDrawer = false
    local nKickOutTime = 0
    local szMyName = UIHelper.GBKToUTF8(GetClientPlayer().szName)
    for i = 1, DataModel.MAX_COHABIT_PLAYERS, 1 do
        local tbInfo = aCohabitPlayerInfos[i]
        if tbInfo and UIHelper.GBKToUTF8(tbInfo.Name) == szMyName and tbInfo.KickOutTime and tbInfo.KickOutTime > 0 then
            bKickOutDrawer = tbInfo.KickOutDrawer
            nKickOutTime = tbInfo.KickOutTime
            break
        end
    end

	local bIsLandlordMyself = UIHelper.GBKToUTF8(aCohabitPlayerInfos.Name) == szMyName
    if nKickOutTime > 0 then
        UIHelper.SetVisible(self.BtnExamine, false)
        UIHelper.SetVisible(self.BtnGoHome, false)
        UIHelper.SetVisible(self.BtnPleaseGo, false)
        UIHelper.SetVisible(self.BtnQuit, false)
        UIHelper.SetVisible(self.WidgetStopLeave, true)
		if bKickOutDrawer then
			UIHelper.SetVisible(self.BtnStopLeave, true)
			UIHelper.SetVisible(self.BtnConfirmLeave, false)
			UIHelper.SetRichText(self.LabelEndTime, string.format("<color=#00ff00>正在退出共居，</c><color=#0fffff>%s后或屋主同意将生效</c>", self:GetStringTerminateCohabitLeftTime(GetCurrentTime() - nKickOutTime)))
		else
			UIHelper.SetVisible(self.BtnStopLeave, false)
			UIHelper.SetVisible(self.BtnConfirmLeave, true)
			UIHelper.SetRichText(self.LabelEndTime, string.format("<color=#00ff00>屋主正与您解除共居关系，</c><color=#0fffff>%s后将终止共居状态</c>", self:GetStringTerminateCohabitLeftTime(GetCurrentTime() - nKickOutTime)))
		end
    else
        UIHelper.SetVisible(self.BtnExamine, true)
        UIHelper.SetVisible(self.BtnGoHome, true)
        UIHelper.SetVisible(self.BtnPleaseGo, bIsLandlordMyself and aCohabitPlayerInfos[1] ~= nil)
        UIHelper.SetVisible(self.BtnQuit, not bIsLandlordMyself)
        UIHelper.SetVisible(self.WidgetStopLeave, false)
    end
end

function UICohabitedHousePage:UpdateSelectState()
    local tbMyLandInfos = DataModel.aMyLandInfos
    if table.is_empty(tbMyLandInfos) then
        tbMyLandInfos = {{}}
    end

	if self.nSelectIndex and self.tbSelectedInfo then
		self:OnClickToggleCell(self.nSelectIndex, self.tbSelectedInfo)
		return
	end

	if not table.is_empty(tbMyLandInfos[1]) then
		self.nSelectIndex = 1
		self.tbSelectedInfo = tbMyLandInfos[1]
		self:OnClickToggleCell(self.nSelectIndex, self.tbSelectedInfo)
	else
		for i = 1, DataModel.MAX_COHABIT_HOUSES do
			local tbInfo = DataModel.aCohabitedLandInfos[i]
			if tbInfo and not table.is_empty(tbInfo) then
				self.nSelectIndex = i + 1
				self.tbSelectedInfo = tbInfo
				self:OnClickToggleCell(self.nSelectIndex, self.tbSelectedInfo)
			end
		end
	end

	if not self.nSelectIndex then
		self.nSelectIndex = 1
		self.tbSelectedInfo = tbMyLandInfos[1]
		self:OnClickToggleCell(self.nSelectIndex, self.tbSelectedInfo)
	end
end

function UICohabitedHousePage:ClearSelect()
	self.scriptMyLandCell:SetSelected(false)
    for i, cell in ipairs(self.tbCohabitedLandCell) do
        cell:SetSelected(false)
    end
end

function UICohabitedHousePage:OnClickToggleCell(nIndex, tbInfo)
	self:ClearSelect()

    if nIndex == 1 then
        self.scriptMyLandCell:SetSelected(true)
    else
        self.tbCohabitedLandCell[nIndex - 1]:SetSelected(true)
    end
    self:UpdateRightInfo()
end

function UICohabitedHousePage:JumpToMap()
	local tAllLinkInfo = Table_GetCareerGuideAllLink(2228)
	if #tAllLinkInfo > 0 then
		local tbTravel = tAllLinkInfo[1]
		MapMgr.SetTracePoint("阿甘", tbTravel.dwMapID, {tbTravel.fX, tbTravel.fY, tbTravel.fZ})
		UIMgr.Open(VIEW_ID.PanelMiddleMap, tbTravel.dwMapID, 0)
	end
end

function UICohabitedHousePage:OnApplyEstateSucceed()
	if bDebugMode then
		LOG.INFO("=== 调用了 Cohabitation.OnApplyEstateSucceed()")
	end
	local hlMgr = GetHomelandMgr()
	local aAllMyLandInfos = hlMgr.GetAllMyLand()

	if bDebugMode then
		LOG.INFO("=== 并且调用 GetAllMyLand()后，得到的 aAllMyLandInfos == ")
		LOG.TABLE(aAllMyLandInfos)
	end

	DataModel.aMyLandInfos = {}
	DataModel.aCohabitedLandInfos = {}
	for _, tOneLandInfo in ipairs(aAllMyLandInfos) do
		if not tOneLandInfo.bPrivateLand then
			local szLandID = tOneLandInfo.uLandID
			local dwMapID, nCopyIndex, nLandIndex = hlMgr.ConvertLandID(szLandID)
			--table.insert(tPlayerHomeData, {nMapID = nMapID, nCopyIndex = nCopyIndex, nLandIndex = nLandIndex})
			if tOneLandInfo.bAllied then
				table.insert(DataModel.aCohabitedLandInfos, {szLandID=szLandID, bHasNews=false})
			else
				table.insert(DataModel.aMyLandInfos, {szLandID=szLandID, bHasNews=false})
			end
			hlMgr.ApplyCommunityInfo(dwMapID, nCopyIndex)
			hlMgr.ApplyLandInfo(dwMapID, nCopyIndex, nLandIndex)
			if bDebugMode then
				LOG.INFO("=== 即将调用 ApplyLandAlliedInfo()")
				LOG.TABLE({" dwMapID == ", dwMapID, " nCopyIndex == ", nCopyIndex, " nLandIndex == ", nLandIndex})
			end
			hlMgr.ApplyLandAlliedInfo(dwMapID, nCopyIndex, nLandIndex)
		end
	end

	if bDebugMode then
		LOG.INFO("=== 最终得到的 DataModel.aCohabitedLandInfos == ")
		LOG.TABLE(DataModel.aCohabitedLandInfos)

		LOG.INFO("=== 最终得到的 DataModel.aMyLandInfos == ")
		LOG.TABLE(DataModel.aMyLandInfos)
	end
end

function UICohabitedHousePage:OnApplyLandInfoSuccess(dwMapID, nCopyIndex, nLandIndex)
	if bDebugMode then
		LOG.INFO("=== 调用了函数 OnApplyLandInfoSuccess()，参数：")
		LOG.TABLE({dwMapID, nCopyIndex, nLandIndex})
	end

	self:UpdateInfo()
end

function UICohabitedHousePage:OnApplyCommunityInfoSucceed(dwMapID, nCopyIndex)
	if bDebugMode then
		LOG.INFO("=== === 调用了函数 Cohabitation.OnApplyCommunityInfoSucceed()，参数：")
		LOG.TABLE({dwMapID, nCopyIndex})
	end
end

function UICohabitedHousePage:OnApplyLandAlliedInfoSucceed(dwMapID, nCopyIndex, nLandIndex)
	if bDebugMode then
		LOG.INFO("=== 调用了函数 Cohabitation.OnApplyLandAlliedInfoSucceed()，参数：")
		LOG.TABLE({dwMapID, nCopyIndex, nLandIndex})
	end

	local hlMgr = GetHomelandMgr()
	local szLandID = hlMgr.GetLandID(dwMapID, nCopyIndex, nLandIndex)

	local tInfo
	local bRes, t = DataModel.IsLandMine(szLandID)
	if bRes then
		tInfo = t
	else
		bRes, t = DataModel.IsLandCohabited(szLandID)
		if bRes then
			tInfo = t
		else
			return
		end
	end

	local aCohabitPlayerInfos = hlMgr.GetLandAlliedInfo(dwMapID, nCopyIndex, nLandIndex)
	local szMyName = GetClientPlayer().szName
	local bIsLandlordMyself = aCohabitPlayerInfos.Name == szMyName

	local nCohabitPlayers = #aCohabitPlayerInfos
	for i = 1, nCohabitPlayers do
		local tCohabitPlayerInfo = aCohabitPlayerInfos[i]
		local szThisDwellerName = tCohabitPlayerInfo.Name
		local bIsTheDwellerMyself = szMyName == szThisDwellerName
		local bInKickOut = tCohabitPlayerInfo.KickOutTime ~= 0
		local bKickedOutFromDweller = tCohabitPlayerInfo.KickOutDrawer

		local bHasNews = false
		if bInKickOut then
			if bIsLandlordMyself then
				if bKickedOutFromDweller then
					bHasNews = true
				end
			else
				if bIsTheDwellerMyself and not bKickedOutFromDweller then
					bHasNews = true
				end
			end
		else
			-- Do nothing
		end
		tInfo.bHasNews = bHasNews
	end

	local bHasNews = DataModel.HasNews()
	FireUIEvent("UI_HOMELAND_COHABIT_NEW_UPDATE", bHasNews)

	self:UpdateSelectState()
end

function UICohabitedHousePage:OnApplyLandAlliedInfoFail(dwMapID, nCopyIndex, nLandIndex)
	-- 重要： 可能需要把对应房屋控件删除？
	LOG.INFO(("=== ERROR! 未能成功获取家园(%s, %s, %s)的共居信息！"):format(tostring(dwMapID), tostring(nCopyIndex), tostring(nLandIndex)))
end

function UICohabitedHousePage:GetStringTerminateCohabitLeftTime(dwTimeElapsed)
	local dwTimeLeft = DataModel.nLandDelayKickOutTime - dwTimeElapsed
	local szTime = ""
	local fHours = dwTimeLeft / 3600
	if fHours > 1 then
		local nHours = GetRoundedNumber(fHours)
		szTime = nHours .. g_tStrings.STR_HOUR
	else
		local fMinutes = dwTimeLeft / 60
		if fMinutes > 1 then
			local nMinutes = GetRoundedNumber(fMinutes)
			szTime = nMinutes .. g_tStrings.STR_MINUTE
		else
			szTime = g_tStrings.STR_HOMELAND_DWELLER_TERMINATION_LEFT_LESS_THAN_ONE_MINUTE
		end
	end

	return szTime
end

return UICohabitedHousePage