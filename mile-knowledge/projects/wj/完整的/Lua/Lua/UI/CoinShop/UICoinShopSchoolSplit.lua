-- ---------------------------------------------------------------------------------
-- Name: UICoinShopSchoolSplit
-- WidgetLieBianActivity
-- Desc: 外观 - 校服裂变活动 - 规则
-- ---------------------------------------------------------------------------------
local UICoinShopSchoolSplit = class("UICoinShopSchoolSplit")

-- ----------------------------- 常量 ------------------------------------
local REWARD_LEVEL = 120
local FISSION_BUFF_ID = 28501
local MAX_INVITE_COUNT = 3
local REWARD_INDEX = 68314
local REFRESH_CD = 60
-- UpdateItemInfoBoxObject(hBox, 0, ITEM_TABLE_TYPE.OTHER, REWARD_INDEX)

----------------------------- DataModel ------------------------------
local DataModel = {}

function DataModel.Init()
end

function DataModel.SetExtPointValue(nValue)
	DataModel.nCoinShopFission = nValue
end

function DataModel.GetPlayerLevel()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return 0
	end
	return hPlayer.nLevel
end

function DataModel.GetRewardState(nPos)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local nValue = hPlayer.GetExtPointByBits(EXT_POINT.COINSHOP_FISSION_STATE, nPos, 1)
	return nValue
end

function DataModel.GetTotalRewardCount()
	local nTotalCount = DataModel.GetRewardCount()
	local nLevelRewardState = DataModel.GetLevelRewardState()
	if nLevelRewardState == OPERACT_REWARD_STATE.CAN_GET then
		nTotalCount = nTotalCount + 1
	end
	return nTotalCount
end

function DataModel.GetRewardCount()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local nValue = DataModel.nCoinShopFission or hPlayer.GetExtPoint(EXT_POINT.COINSHOP_FISSION)
	return nValue or 0
end

function DataModel.GetRewardHasGotCount()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return 0
	end

	local nCount = 0
	for i = 1, MAX_INVITE_COUNT do
		local nValue = hPlayer.GetExtPointByBits(EXT_POINT.COINSHOP_FISSION_STATE, i, 1)
		if nValue and nValue ~= 0 then
			nCount = nCount + 1
		end
	end
	return nCount
end

function DataModel.GetLevelRewardState()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local nBuffStack = Buffer_GetStackNum(FISSION_BUFF_ID)
	if nBuffStack >= 2 then
		return OPERACT_REWARD_STATE.ALREADY_GOT
	end
	if hPlayer.nLevel >= REWARD_LEVEL then
		return OPERACT_REWARD_STATE.CAN_GET
	end
	return OPERACT_REWARD_STATE.NON_GET
end

function DataModel.GetAutoShareUrl()
	local Url = "https://jx3.xoyo.com/p/zt/2024/05/27/public-testing/index.html#/guest?share_token="
    local testUrl = "https://test-zt.xoyo.com/jx3.xoyo.com/p/zt/2024/05/27/public-testing/index.html#/guest?share_token="
    local account = Login_GetAccount()
    local token
    local data
    local key = "kingt9Joy:8Xit"
    token = MD5(account .. key)
    data = account .. "&" .. token

    data = Base64_Encode( data )
    data = UrlEncode(data)

    local url = Url .. data
    return url
end

function DataModel.GetAutoLoginUrl(url)
	local account = Login_GetAccount()
    local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbSelectServer = LoginServerList.GetSelectServer()
    local code = tbSelectServer.szSerial
    local time    = GetCurrentTime()

    local key = "kingt9Joy:8Xit"
    local token = table.concat({account, code, time, key}, "")
    token = MD5(token)
    local data = table.concat({account, code, time, token}, "&")
    data = Base64_Encode( data )
    data = UrlEncode(data)

    url = url .. data
    return url
end

function DataModel.UnInit()
	DataModel.nCoinShopFission = nil
end

----------------------------- View ------------------------------
function UICoinShopSchoolSplit:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

	RemoteCallToServer("On_Activity_FissionGetInfo")
	DataModel.Init()

	self:InitCell()

	Timer.AddCycle(self, 0.1, function()
		self:UpdateRefreshBtn()
	end)
end

function UICoinShopSchoolSplit:OnExit()
    self.bInit = false
    self:UnRegEvent()

	DataModel.UnInit()
end

function UICoinShopSchoolSplit:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
		local bVisible = UIHelper.GetVisible(self.WidgetTips)
		UIHelper.SetVisible(self.WidgetTips, not bVisible)
    end)

	UIHelper.BindUIEvent(self.BtnMine, EventType.OnClick, function() -- 我的邀请
		WebUrl.OpenByID(35)
    end)

	UIHelper.BindUIEvent(self.BtnInvite, EventType.OnClick, function() -- 邀请好友
		self:OpenSharePop()
    end)

	UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function()
        RemoteCallToServer("On_Activity_FissionGetReward", 0) -- 领取奖励
		Timer.Add(self, 1, function()
			self:Update()
			Event.Dispatch("SchoolActivityRedUpdate")
		end)
    end)

	UIHelper.BindUIEvent(self.BtnRenovat, EventType.OnClick, function()
		self:RefreshData()
	end)
end

function UICoinShopSchoolSplit:RegEvent()
    Event.Reg(self, "CHANGE_NEW_EXT_POINT_NOTIFY", function(arg0)
        if arg0 == EXT_POINT.COINSHOP_FISSION or arg0 == EXT_POINT.COINSHOP_FISSION_STATE then
			self:Update()
		end
    end)

	Event.Reg(self, EventType.HideAllHoverTips, function()
        local bVisible = UIHelper.GetVisible(self.WidgetTips)
		if bVisible then
			UIHelper.SetVisible(self.WidgetTips, false)
		end

		UIHelper.SetVisible(self.tip._rootNode, false)
    end)

	Event.Reg(self, EventType.CoinShopSchoolExteriorUpdateFissionInfo, function(nTotalNum)
		self:UpdateFissionInfo(nTotalNum)
	end)
end

function UICoinShopSchoolSplit:UnRegEvent()

end

----------------------------- function ------------------------------

function UICoinShopSchoolSplit:InitCell()
	-- self.scriptLevel = UIHelper.AddPrefab(PREFAB_ID.WidgetLieBianActivityCell, self.WidgetActivityCell)

	self.tip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTips)
	UIHelper.SetVisible(self.tip._rootNode, false)

	local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem80) assert(tItemScript)
    tItemScript:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, REWARD_INDEX)
	tItemScript:SetClickCallback(function()
		-- self.tip:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, REWARD_INDEX)
		self.tip:OnInitSchoolSplitTip(ITEM_TABLE_TYPE.OTHER, REWARD_INDEX)
		UIHelper.SetSelected(tItemScript.ToggleSelect, false, false)
		UIHelper.SetVisible(self.tip.BtnItemShare, false)
	end)

	self.scriptList = {}
	self:InitInviteCell()
	UIHelper.LayoutDoLayout(self.LayoutActivityCell)
	Timer.AddFrame(self, 5, function()
		UIHelper.LayoutDoLayout(self.LayoutActivityCell)
	end)

	UIHelper.SetTouchDownHideTips(self.ScrollViewTipsLabel, false)
end

function UICoinShopSchoolSplit:InitInviteCell()
    for nIndex = 1, MAX_INVITE_COUNT do
        self:GetInviteScript(nIndex)
    end
end

function UICoinShopSchoolSplit:GetInviteScript(nIndex)
	if not self.scriptList then
		self.scriptList = {}
	end
    if #self.scriptList < nIndex then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetLieBianActivityCell, self.LayoutActivityCell)
		assert(script)
		local ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, script.WidgetItem80) assert(ItemScript)
		ItemScript:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, REWARD_INDEX)
		ItemScript:SetClickCallback(function()
			self.tip:OnInitSchoolSplitTip(ITEM_TABLE_TYPE.OTHER, REWARD_INDEX)
			UIHelper.SetSelected(ItemScript.ToggleSelect, false, false)
			UIHelper.SetVisible(self.tip.BtnItemShare, false)
		end)
		self.scriptList[nIndex] = script
    end
end

function UICoinShopSchoolSplit:Update()
	self:UpdateTitle()
	self:UpdateLevelReward()
	self:UpdateInviteReward()
	self:UpdateRefreshBtn()
end

function UICoinShopSchoolSplit:UpdateTitle()
	local nRewardCount   = DataModel.GetRewardCount()
	local szRewardCount  = FormatString("邀请好友一起玩（<D0>/<D1>）", nRewardCount, MAX_INVITE_COUNT)
	UIHelper.SetString(self.LabelTitle2, szRewardCount)

	local nHasGotCount   = DataModel.GetRewardHasGotCount()
	local szHasGotCount  = FormatString("<color=#d4bf8a>受邀用户购买15元点月卡，则邀请者可获得【校服券*1】（当前角色已领取</c><color=#ffffff> <D0> </c><color=#d4bf8a>次奖励，每个角色最多可领3次）</color>", nHasGotCount)
	UIHelper.SetRichText(self.LabelTip, szHasGotCount)
end

function UICoinShopSchoolSplit:UpdateLevelReward()
	local tInfo = {}
	tInfo.nIndex = 0
	tInfo.nState = DataModel.GetLevelRewardState()
	tInfo.nLevel = g_pClientPlayer.nLevel
	-- self.scriptLevel:UpdateLevel(tInfo)

	local szTaskDes = FormatString("当前等级（<D0>/120）", tInfo.nLevel)
    UIHelper.SetString(self.LabelTaskDes, szTaskDes)

    if tInfo.nState == OPERACT_REWARD_STATE.NON_GET then
		UIHelper.SetVisible(self.ImgUndoneIcon, true)
        UIHelper.SetVisible(self.ImgCanGet, false)
		UIHelper.SetVisible(self.ImgItemCanGet, false)
        UIHelper.SetVisible(self.ImgFinishIcon, false)
    elseif tInfo.nState == OPERACT_REWARD_STATE.CAN_GET then
		UIHelper.SetVisible(self.ImgUndoneIcon, false)
        UIHelper.SetVisible(self.ImgCanGet, true)
		UIHelper.SetVisible(self.ImgItemCanGet, true)
        UIHelper.SetVisible(self.ImgFinishIcon, false)
    elseif tInfo.nState == OPERACT_REWARD_STATE.ALREADY_GOT then
		UIHelper.SetVisible(self.ImgUndoneIcon, false)
        UIHelper.SetVisible(self.ImgCanGet, false)
		UIHelper.SetVisible(self.ImgItemCanGet, false)
        UIHelper.SetVisible(self.ImgFinishIcon, true)
		UIHelper.SetOpacity(self.LabelTaskDes, 76)
    end
end

function UICoinShopSchoolSplit:UpdateInviteReward()
	local tDataInfo = {}
	local nRewardCount = DataModel.GetRewardCount()
	for i = 1, MAX_INVITE_COUNT do
		local tInfo = {}
		tInfo.nIndex = i
		local nValue = DataModel.GetRewardState(i)
		if nValue == 1 then
			tInfo.nState = OPERACT_REWARD_STATE.ALREADY_GOT
		else
			if nRewardCount >= i then
				tInfo.nState = OPERACT_REWARD_STATE.CAN_GET
			else
				tInfo.nState = OPERACT_REWARD_STATE.NON_GET
			end
		end
		table.insert(tDataInfo, tInfo)
	end

	for i = 1, MAX_INVITE_COUNT do
		local script = self.scriptList and self.scriptList[i]
		if not script then
			self:InitInviteCell()
			script = self.scriptList and self.scriptList[i]
		end
		script:UpdateInvite(tDataInfo[i])
	end
end

function UICoinShopSchoolSplit:OpenSharePop()
    if Platform.IsWindows() then
        local szShareUrl = DataModel.GetAutoShareUrl()
        SetClipboard(szShareUrl)
        TipsHelper.ShowNormalTip("邀请链接复制成功，快发送给好友吧！")
        XGSDK_TrackEvent("game.share.liebianActivity", "share", {})
    else
        if not UIMgr.GetView(VIEW_ID.PanelSharePop) then
            UIMgr.Open(VIEW_ID.PanelSharePop)
        end
    end
end

function UICoinShopSchoolSplit:UpdateRefreshBtn()
	if not DataModel.nLastRefreshTime then
		UIHelper.SetVisible(self.WidgetRenovatCD, false)
		UIHelper.SetOpacity(self.ImgRenovat, 255)
		UIHelper.SetTouchEnabled(self.BtnRenovat, true)
		UIHelper.SetVisible(self.LableRenovat, true)
		return
	end
	local nTime = GetGSCurrentTime()
	local nTimeDiff = nTime - DataModel.nLastRefreshTime
	if nTimeDiff >= REFRESH_CD then
		UIHelper.SetVisible(self.WidgetRenovatCD, false)
		UIHelper.SetOpacity(self.ImgRenovat, 255)
		UIHelper.SetTouchEnabled(self.BtnRenovat, true)
		UIHelper.SetVisible(self.LableRenovat, true)
		DataModel.nLastRefreshTime = nil
	else
		local nLeftCD = math.max(REFRESH_CD - nTimeDiff - 1, 0)
		local szText = nLeftCD .. "(秒)"
		UIHelper.SetVisible(self.WidgetRenovatCD, true)
		UIHelper.SetString(self.LableRenovatCD, szText)
		UIHelper.SetOpacity(self.ImgRenovat, 128)
		UIHelper.SetTouchEnabled(self.BtnRenovat, false)
		UIHelper.SetVisible(self.LableRenovat, false)
	end
end

function UICoinShopSchoolSplit:RefreshData()
	local bTestMode = IsDebugClient()
	local Url
	if bTestMode then
		Url = "https://test-ws.xoyo.com/jx3/publicbeta240428/trigger_sync?account="
	else
		Url = "https://ws.xoyo.com/jx3/publicbeta240428/trigger_sync?account="
	end
	local nTime = GetGSCurrentTime()
	if DataModel.nLastRefreshTime and nTime - DataModel.nLastRefreshTime < REFRESH_CD then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SYNC_MEMBER_INFO)
		return
	end
	DataModel.nLastRefreshTime = nTime
	local szAccount = Login_GetAccount()
	local szUrl = Url .. szAccount
	CURL_HttpPost("SchoolExteriorRefresh", szUrl, {}, true)
	LOG.INFO("SchoolSplit refresh url=%s", szUrl)
	TipsHelper.ShowNormalTip("刷新申请已提交，重新打开界面后可获取最新进度")
end

function UICoinShopSchoolSplit:UpdateFissionInfo(nValue)
	DataModel.SetExtPointValue(nValue)
	self:Update()
end

return UICoinShopSchoolSplit