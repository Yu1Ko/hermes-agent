-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetTongOverview
-- Date: 2023-02-23
-- Desc: 帮会总览
-- Prefab: WidgetlFactionMain
-- ---------------------------------------------------------------------------------

local UIWidgetTongOverview = class("UIWidgetTongOverview")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetTongOverview:_LuaBindList()
    self.ScrollViewActivitySummary = self.ScrollViewActivitySummary --- 帮会活动概要信息的scroll view
end

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

local _DonateMax = 200000
local _MaxTongFund = 1000000
local _MaxTongLevel = TongData.GetMaxLevel()
local _MaxGoods = 100000

local _tRebornTreePreviewIDArr = {
    33, -- 百废俱兴
    35, -- 一念千里
    64, -- 镖头
    76, -- 唇齿留香
}

local _NodeNameArr = {
	"WidgetAnchorOnlineAnnounce",
	"WidgetAnchorNewAnnounce",
	"BtnModifyOnlineAnnounce",
	"BtnModifyNewAnnounce",
	"ScrollViewOnlineAnnounceContent",
	"LabelOnlineAnnounceContent",
	"ScrollViewNewAnnounceContent",
	"LabelNewAnnounceContent",
	"ImgNewAnnouncementBg",
	"ImgOnlineAnnouncementBg",
    "TogOnlineAnnounce",
    "TogNewAnnounce",

	"BtnDonateFactionMoney",
	"TogMemberCeiling",
	"WidgetTips01",

	"ProgressBarFactionMoney",
	"LabelFactionMoneyNum",
	"ImgWeeklyLimitate",

	"ProgressBarMoneyPersonal",
	"LabelMoneyPersonalNum",

	"ProgressBarFactionCarrier",
	"LabelFactionCarrierNum",

	"ProgressBarFactionCarrierCollected",
	"LabelFactionCarrierCollectedNum",

    "ImgLevelBg",
	"ImgFactionflag",
	"LabelFactionGrade",
	"LabelFactionNameTitle",
    "ImgPartyIcon",
	"LabelFactionMemberNum",
    "ImgFactionLevel",

	"LabelFactionBriefIntroduction",
	"BtnFactionDemesne",
	"BtnFactionUpgrade",
	"WidgetDownload",
    "BtnApplicationList",
    "ImgApplyListRedDot",

	"ScrollListActivityState",
	"ScrollListRebornTree",

	"WidgetScrollViewTips",
}



function UIWidgetTongOverview:Init()
	self.m = {}

	local tNodes = {}
	UIHelper.FindNodeByNameArr(self._rootNode, tNodes, _NodeNameArr)
	self.m.tNodes = tNodes

	self.m.tAnnouncePos = {}
	self.m.tAnnouncePos[1] = tNodes.WidgetAnchorOnlineAnnounce:getPositionX()
	self.m.tAnnouncePos[2] = tNodes.WidgetAnchorNewAnnounce:getPositionX()
	self.m.bOnlineAnnounce = false


	self:RegEvent()
	self:BindUIEvent()

	self:InitUI()
	TongData.RequestBaseData()

    -- 从服务器拉取是否拥有帮会领地
    if g_pClientPlayer.dwTongID ~= 0 then
        RemoteCallToServer("On_Tong_GetTongMap", g_pClientPlayer.dwTongID)
    end
end

function UIWidgetTongOverview:UnInit()
	self:UnRegEvent()

	if self.m.tRebornTreeList then
		self.m.tRebornTreeList:Destroy()
		self.m.tRebornTreeList = nil
	end

	UIHelper.RemoveFromParent(self._rootNode, true)
	self.m = nil
end

function UIWidgetTongOverview:BindUIEvent()
	local tNodes = self.m.tNodes
	UIHelper.BindUIEvent(tNodes.BtnModifyNewAnnounce, EventType.OnClick, function()
		self:OnModifyNewAnnounce()
	end)
	UIHelper.BindUIEvent(tNodes.BtnModifyOnlineAnnounce, EventType.OnClick, function()
		self:OnModifyOnlineAnnounce()
	end)
	UIHelper.BindUIEvent(tNodes.BtnDonateFactionMoney, EventType.OnClick, function()
		self:OnClickDonate()
	end)
	UIHelper.BindUIEvent(tNodes.TogMemberCeiling, EventType.OnClick, function()
		self:UpdateFundTips()
		UIHelper.SetTouchLikeTips(tNodes.WidgetTips01, UIMgr.GetLayer(UILayer.Page), function ()
			UIHelper.SetSelected(tNodes.TogMemberCeiling, false)
		end)
	end)
	UIHelper.BindUIEvent(tNodes.BtnFactionUpgrade, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelFactionUpgradePop)
	end)
	UIHelper.BindUIEvent(tNodes.BtnFactionDemesne, EventType.OnClick, function()
		if TongData.IsDemesnePurchased() then
			local enterTongMap = function()
				MapMgr.CheckTransferCDExecute(function()
					--TongData.ShowDemesneEntry()
					--MapMgr.TryTransfer(TongData.DEMESNE_MAP_ID)
					UIMgr.Close(VIEW_ID.PanelFactionManagement)
					RemoteCallToServer("On_Tong_ToTongMapDetection")
				end)
			end

			--地图资源下载检测拦截
			if not PakDownloadMgr.UserCheckDownloadMapRes(TongData.DEMESNE_MAP_ID, enterTongMap) then
				return
			end

			enterTongMap()
		else
			TongData.ShowDemesneNpcMenu(tNodes.WidgetScrollViewTips)
		end
	end)
    UIHelper.BindUIEvent(tNodes.BtnApplicationList, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelApplicationListPop)
    end)
end

function UIWidgetTongOverview:RegEvent()
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()
		self:InitUI()
		RemoteCallToServer("On_Tong_GetWeeklyPointRemain")
	end)
    Event.Reg(self, "UPDATE_TONG_ROSTER_FINISH", function ()
        self:InitUI()
    end)
	Event.Reg(self, "ON_TONG_SYNC_CUSTOMDATA", function ()
		self:UpdateCustomData()
	end)
	Event.Reg(self, "ON_GET_TONG_WEEKLY_POINT", function ()
		RemoteCallToServer("OnSyncTongCustomData")
	end)
	Event.Reg(self, "TONG_EVENT_NOTIFY", function ()
        if arg0 == TONG_EVENT_CODE.MODIFY_ANNOUNCEMENT_SUCCESS
                or arg0 == TONG_EVENT_CODE.MODIFY_ONLINE_MESSAGE_SUCCESS
        then
            GetTongClient().ApplyTongInfo()
        elseif arg0 == TONG_EVENT_CODE.INVITE_SUCCESS or arg0 == TONG_EVENT_CODE.KICK_OUT_SUCCESS or
                arg0 == TONG_EVENT_CODE.CHANGE_MEMBER_REMARK_SUCCESS or arg0 == TONG_EVENT_CODE.CHANGE_MEMBER_GROUP_SUCCESS then
            TongData.ApplyTongRoster()
        end
	end)

    Event.Reg(self, "On_Tong_GetActivityTimeRespond", function()
        self:UpdateGoingGuildActivity()
    end)
    Event.Reg(self, "OnTongApplyListRedPointUpdate", function ()
        -- 红点
        UIHelper.SetVisible(self.m.tNodes.ImgApplyListRedDot, TongData.HasApplyRedPoint())
    end)
end

function UIWidgetTongOverview:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTongOverview:InitUI()
	local tNodes = self.m.tNodes

    TongData.TryGetApplyJoinInList()

	-- 等级
    local nLevel = TongData.GetLevel()
    if nLevel == 0 then
        -- GM刚创建帮会时，或第一次打开帮会时，GetTongClient().nLevel可能还未同步下来（KTongClient::UpdateBaseInfo），此时值为0，会导致下面报错，这种情况设置为1确保下面流程正常
        nLevel = 1
    end
	UIHelper.SetString(tNodes.LabelFactionGrade, string.format("%d级", nLevel))

    local szImgLevel = string.format("UIAtlas2_Faction_Faction_img_level_%d", nLevel)
    UIHelper.SetSpriteFrame(tNodes.ImgFactionLevel, szImgLevel, false)

	-- 名称
	UIHelper.SetString(tNodes.LabelFactionNameTitle, g2u(TongData.GetName()))
	-- 阵营
    local szCampImage = CampData.GetCampImgPath(TongData.GetCamp(), false, true)
    UIHelper.SetVisible(tNodes.ImgPartyIcon, szCampImage ~= nil)
    if szCampImage then
        UIHelper.SetSpriteFrame(tNodes.ImgPartyIcon, szCampImage)
    end

	-- 成员数量
	local nTotal, nOnline = TongData.GetMemberCount()
	UIHelper.SetString(tNodes.LabelFactionMemberNum, string.format("%d/%d", nOnline, nTotal))

    UIHelper.CascadeDoLayoutDoWidget(tNodes.ImgLevelBg, true, true)

	-- 帮会升级
	UIHelper.SetVisible(tNodes.BtnFactionUpgrade, TongData.GetLevel() < _MaxTongLevel)

	-- 帮会领地
	UIHelper.SetVisible(tNodes.BtnFactionDemesne, not TongData.IsInDemesne())

	-- 公告/通知
	self:UpdateAnnouncement()

	-- 天工树
	self:UpdateRebornTreeList()

	-- 活动
	self:ShowActivity()

	--资源下载Widget
	local scriptDownload = UIHelper.GetBindScript(tNodes.WidgetDownload)
	local nPackID = PakDownloadMgr.GetMapResPackID(TongData.DEMESNE_MAP_ID)
	scriptDownload:OnInitWithPackID(nPackID)
end

function UIWidgetTongOverview:UpdateRebornTreeList()
	local list = self.m.tNodes.ScrollListRebornTree
	assert(list)

	TongData.SortNode(_tRebornTreePreviewIDArr)

	local tList = self.m.tRebornTreeList
	if not tList then
		tList = UIScrollList.Create({
			listNode = list,
			bHorizontal = true,
			nSpace = 10,
			fnGetCellType = function(nIndex) return PREFAB_ID.WidgetRebornTreeIcon end,
			fnUpdateCell = function(cell, nIndex)
				self:UpdateRebornTreeCell(cell, nIndex)
			end,
		})
		assert(tList)
		self.m.tRebornTreeList = tList
	end

	tList:Reset(#_tRebornTreePreviewIDArr)
end

function UIWidgetTongOverview:UpdateRebornTreeCell(cell, nIndex)
	assert(cell)
	assert(nIndex)
	local nNodeID = _tRebornTreePreviewIDArr[nIndex]
	assert(nIndex)

	TongData.UpdateTreeCell(cell, nNodeID, false, true)

	UIHelper.BindUIEvent(UIHelper.FindChildByName(cell, "Button"), EventType.OnClick, function()
		self:GotoRebornTree(nNodeID)
	end)

end

function UIWidgetTongOverview:GotoRebornTree(nNodeID)
	assert(nNodeID)
	Event.Dispatch("Tong_SwitchTab", 3, 2, nNodeID)
end

function UIWidgetTongOverview:RequestData()
	TongData.RequestBaseData()
end

function UIWidgetTongOverview:UpdateFundTips()
	local node
	local root = self.m.tNodes.WidgetTips01
	node = UIHelper.FindChildByName(root, "LabelTipsFactionMoney")
	assert(node)
	local szPattern = self.m.szFundPattern
	if not szPattern then
		szPattern = UIHelper.GetString(node)
	end
	UIHelper.SetString(node,
		string.format(szPattern,
			TongData.GetFund(),
			_MaxTongFund,
			TongData.GetWeeklyPoint()
		)
	)
end

function UIWidgetTongOverview:UpdateCustomData()
	local tNodes = self.m.tNodes
	local tong = GetTongClient()

	-- 帮会资金
	do
		local nFund = TongData.GetFund()
		local nPoint = TongData.GetWeeklyPoint()
		local nTotal = nFund + nPoint
		nTotal = math.min(nTotal, _MaxTongFund)
		UIHelper.SetProgressBarPercent(tNodes.ProgressBarFactionMoney, 100 * nFund / _MaxTongFund)
		UIHelper.SetString(tNodes.LabelFactionMoneyNum, nFund .. "/" .. _MaxTongFund)
		local w = UIHelper.GetContentSize(tNodes.ProgressBarFactionMoney)
		UIHelper.SetPositionX(UIHelper.FindChildByName(tNodes.ProgressBarFactionMoney, "ImgLight"), w * nFund / _MaxTongFund)
		UIHelper.SetPositionX(tNodes.ImgWeeklyLimitate, w * nTotal / _MaxTongFund)
	end
	-- 个人资金
	do
		local nVal = tong.GetFundTodayRemainCanUse() or 0
		local nMax = tong.GetFundDailyUseLimit()
		local nPercent = nMax == 0 and 0 or (nVal / nMax)
		UIHelper.SetProgressBarPercent(tNodes.ProgressBarMoneyPersonal, nPercent * 100)
		UIHelper.SetString(tNodes.LabelMoneyPersonalNum, nVal .. "/" .. nMax)
		local w = UIHelper.GetContentSize(tNodes.ProgressBarMoneyPersonal)
		UIHelper.SetPositionX(UIHelper.FindChildByName(tNodes.ProgressBarMoneyPersonal, "ImgLight"), w * nPercent)

	end
	-- 载具物资
	do
		local nVal = get(TongData.GetCustomData(), "DW_CANUSE_CARRIERRESOURCES")
		local nMax = _MaxGoods
		local nPercent = nVal / nMax
		UIHelper.SetProgressBarPercent(tNodes.ProgressBarFactionCarrier, nPercent * 100)
		UIHelper.SetString(tNodes.LabelFactionCarrierNum, nVal .. "/" .. nMax)
		local w = UIHelper.GetContentSize(tNodes.ProgressBarFactionCarrier)
		UIHelper.SetPositionX(UIHelper.FindChildByName(tNodes.ProgressBarFactionCarrier, "ImgLight"), w * nPercent)

	end
	-- 载具收集
	do
		local nVal = get(TongData.GetCustomData(), "DW_NEXTWEEK_CARRIERRESOURCES")
		local nMax = _MaxGoods
		local nPercent = nVal / nMax
		UIHelper.SetProgressBarPercent(tNodes.ProgressBarFactionCarrierCollected, nPercent * 100)
		UIHelper.SetString(tNodes.LabelFactionCarrierCollectedNum, nVal .. "/" .. nMax)
		local w = UIHelper.GetContentSize(tNodes.ProgressBarFactionCarrierCollected)
		UIHelper.SetPositionX(UIHelper.FindChildByName(tNodes.ProgressBarFactionCarrierCollected, "ImgLight"), w * nPercent)
	end

end

function UIWidgetTongOverview:UpdateAnnouncement()
	self:UpdateNewAnnouncement(not self.m.bOnlineAnnounce)
	self:UpdateOnlineAnnouncement(self.m.bOnlineAnnounce)
end

function UIWidgetTongOverview:UpdateNewAnnouncement(bShow)
	local tNodes = self.m.tNodes
    UIHelper.SetSelected(tNodes.TogNewAnnounce, bShow, false)

	UIHelper.BindUIEvent(tNodes.TogNewAnnounce, EventType.OnClick, function()
        self:UpdateOnlineAnnouncement(false)
		self:UpdateNewAnnouncement(true)
	end)

	if not bShow then return end

	UIHelper.SetString(tNodes.LabelNewAnnounceContent, g2u(TongData.GetNewAnnouncement()))
	UIHelper.ScrollViewDoLayout(tNodes.ScrollViewNewAnnounceContent)
	UIHelper.ScrollToTop(tNodes.ScrollViewNewAnnounceContent, 0, false)

end

function UIWidgetTongOverview:UpdateOnlineAnnouncement(bShow)
	self.m.bOnlineAnnounce = bShow

	local tNodes = self.m.tNodes
    UIHelper.SetSelected(tNodes.TogOnlineAnnounce, bShow, false)

	UIHelper.BindUIEvent(tNodes.TogOnlineAnnounce, EventType.OnClick, function()
		self:UpdateOnlineAnnouncement(true)
		self:UpdateNewAnnouncement(false)
	end)

	if not bShow then return end

	UIHelper.SetString(tNodes.LabelOnlineAnnounceContent, g2u(TongData.GetOnlineAnnouncement()))
	UIHelper.ScrollViewDoLayout(tNodes.ScrollViewOnlineAnnounceContent)
	UIHelper.ScrollToTop(tNodes.ScrollViewOnlineAnnounceContent, 0, false)

end


function UIWidgetTongOverview:OnModifyNewAnnounce()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
        return
    end

    -- 取当前公告
	local szText = g2u(TongData.GetNewAnnouncement()) or ""
	UIHelper.ShowEditPanel("修改帮会公告", szText, function (szText)
		if szText then
			TongData.SetNewAnnouncement(u2g(szText))
		end
	end, 128, "请输入公告内容")
end

function UIWidgetTongOverview:OnModifyOnlineAnnounce()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
        return
    end

	-- 取当前公告
	local szText = g2u(TongData.GetOnlineAnnouncement()) or ""
	UIHelper.ShowEditPanel("修改上线通知", szText, function (szText)
		if szText then
			TongData.SetOnlineAnnouncement(u2g(szText))
		end
	end, 128, "请输入通知内容")
end

function UIWidgetTongOverview:OnClickDonate()
	UIMgr.Open(VIEW_ID.PanelFactionDonatePop, nil, "1",
		function (szText)
			if szText then
				local nCount = tonumber(szText)
				if nCount > 0 then
                    self:DonateMoney(nCount)
				end
			end
		end,
		function (szText)
			local nCount = tonumber(szText)
			if not nCount or nCount < 1 then
				nCount = 1
			elseif nCount > _DonateMax then
				nCount = _DonateMax
			end
			return tostring(nCount)
		end
	)
end

function UIWidgetTongOverview:DonateMoney(nGold)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_DONATE, "msg") then
        return
    end

    local tMoney = PackMoney(nGold, 0, 0)
	if MoneyOptCmp(tMoney, GetClientPlayer().GetMoney()) > 0 then
		OutputMessage("MSG_TONG_FUND", g_tStrings.GUILD_GIVE_NOT_ENOUGH_MONEY)
	else
        --local szMessage = string.format(g_tStrings.GUILD_SET_GIVE_SURE, UIHelper.GetMoneyPureText(tMoney))
        local szMessage = string.format("你确定要向帮会捐赠%s吗？", UIHelper.GetMoneyPureText(tMoney))

		UIHelper.ShowConfirm(
                szMessage,
			function ()
				-- guild donation`s unit is copper
				GetTongClient().SaveMoney(nGold * 100 * 100)
				GetTongClient().ApplyTongInfo()
				RemoteCallToServer("On_Tong_GetWeeklyPointRemain")
			end, nil, false)
	end
end

function UIWidgetTongOverview:ShowActivity()
    if not TongData.GetActivityTimeData() then
        -- 没有数据，先请求
        self:GetActivityTimeRequest()
    else
        -- 已有数据，直接显示
        self:UpdateGoingGuildActivity()
    end
end

function UIWidgetTongOverview:GetActivityTimeRequest()
    RemoteCallToServer("On_Tong_GetActivityTimeRequest")
end

function UIWidgetTongOverview:UpdateGoingGuildActivity()
    local tData   = TongData.GetActivityTimeData()

    local tGoing  = {}
    local tPassed = {}
    local tComing = {}

    for _, v in pairs(tData) do
        if v.nFlag == 2 then
            table.insert(tPassed, v)
        elseif v.nFlag == 1 then
            table.insert(tGoing, v)
        elseif v.nFlag == 0 then
            table.insert(tComing, v)
        end
    end

    self:UpdateTongWeekActivity(tPassed, tGoing, tComing)
end

function UIWidgetTongOverview:UpdateTongWeekActivity(tPassed, tGoing, tComing)
    UIHelper.RemoveAllChildren(self.ScrollViewActivitySummary)

    local function fnUpdateList(tData, szText)
        if not tData[1] then
            return
        end

        --UIHelper.AddPrefab(PREFAB_ID.WidgetFactionActivityTitle, self.ScrollViewActivitySummary, szText)

        for _, v in pairs(tData) do
            UIHelper.AddPrefab(PREFAB_ID.WidgetFactionActivityEntrance, self.ScrollViewActivitySummary, v)
        end
    end

    --帮会联赛报名入口
    local tTongLeague = {
        nID1 = -1,
        nID2 = -1,
        tRecord = {
            szName =  UIHelper.UTF8ToGBK("武林争霸赛"),
            szState = "前往",
            bCanOpen = true,
            szIconPath = "UIAtlas2_Faction_Faction_icon_wlzbs.png",
            szImgBgPath = "UIAtlas2_Faction_Faction_bg_activity2.png",
            tFontColor = cc.c3b(255, 255, 255),
        },
        szLink = "PanelLink/GuildLeagueMatches.Open",
    }
    if IsActivityOn(ACTIVITY_ID.TONG_LEAGUE_RANK) then
        UIHelper.AddPrefab(PREFAB_ID.WidgetFactionActivityEntrance, self.ScrollViewActivitySummary, tTongLeague)
    end
    fnUpdateList(tGoing, g_tStrings.tActiveState[1])
    fnUpdateList(tComing, g_tStrings.tActiveState[2])
    -- 已结束活动在主页不显示 无操作
    --fnUpdateList(tPassed, g_tStrings.tActiveState[3])

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActivitySummary)
end

return UIWidgetTongOverview