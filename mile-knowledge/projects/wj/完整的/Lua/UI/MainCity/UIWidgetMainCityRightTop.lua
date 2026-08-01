
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetMainCityRightTop
-- Date: 2022-11-15
-- Desc: 场景右上角入口相关
-- Prefab: WidgetMainCityRightTop
-- ---------------------------------------------------------------------------------
local UIWidgetMainCityRightTop = class("UIWidgetMainCityRightTop")

local SwitchMode = {
	Homeland = 1,
	BossDbm = 2,
	Dungeon = 3,
	MonsterBook = 4
}

local SwitchMode2PrefabID = {
	[SwitchMode.Homeland] = PREFAB_ID.WidgetHomeConstructFunctions,
	[SwitchMode.BossDbm] = PREFAB_ID.WidgetMainCityDbmCell,
	[SwitchMode.MonsterBook] = PREFAB_ID.WidgetBaiZhanFunctions
}

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetMainCityRightTop:_LuaBindList()
    self.ImgBubbleQuestionnaire = self.ImgBubbleQuestionnaire --- 问卷 的气泡图片
    self.ImgBubblePlayerLetter  = self.ImgBubblePlayerLetter --- 制作人的一封信 的气泡图片
    self.ImgBubbleGuessing      = self.ImgBubbleGuessing --- 帮会联赛竞猜 的气泡图片
end

function UIWidgetMainCityRightTop:OnEnter(bCustom)
	if bCustom then
		self:UdpateCustomInfo()
	else
		self.m = {}
		if not self.bInit then
			self:RegEvent()
			self:BindUIEvent()
			self.bInit = true
		end
		self:Init()

		self:OnUpdate()
	end

	-- self.m.nTimerID = Timer.AddCycle(self, 1, function ()
	-- 	self:OnUpdate()
	-- end)
end

function UIWidgetMainCityRightTop:OnExit()
	self.bInit = false
	self:UnRegEvent()

	ItemData.SetBagExpiringBubbleShowing(false)
	-- if self.m.nTimerID then
	-- 	Timer.DelTimer(self, self.m.nTimerID)
	-- 	self.m.nTimerID = nil
	-- end

	self.m = nil
end

function UIWidgetMainCityRightTop:BindUIEvent()
	-- Character
	UIHelper.BindUIEvent(self.BtnCharacter, EventType.OnClick, function()
		if not UIMgr.GetView(VIEW_ID.PanelCharacter) then
        	UIMgr.Open(VIEW_ID.PanelCharacter)
		end
	end)
	-- MiddleMap
	UIHelper.BindUIEvent(self.BtnMap, EventType.OnClick, function()
		if not UIMgr.GetView(VIEW_ID.PanelMiddleMap) then
        	UIMgr.Open(VIEW_ID.PanelMiddleMap)
		end
	end)
	-- bag
	UIHelper.BindUIEvent(self.BtnBag, EventType.OnClick, function()
		ItemData.OpenBag()
	end)
	-- system menu
	UIHelper.BindUIEvent(self.BtnMenu, EventType.OnClick, function()
		if not UIMgr.GetView(VIEW_ID.PanelSystemMenu) then
        	UIMgr.Open(VIEW_ID.PanelSystemMenu)
		end
	end)
	-- Quick menu
	UIHelper.BindUIEvent(self.BtnQuickOperation, EventType.OnClick, function()
		if not UIMgr.GetView(VIEW_ID.PanelQuickOperation) then
        	UIMgr.Open(VIEW_ID.PanelQuickOperation)
		end
	end)
	UIHelper.BindUIEvent(self.BtnActivity, EventType.OnClick, function()
		if not UIMgr.GetView(VIEW_ID.PanelOperationCenter) then
        	UIMgr.Open(VIEW_ID.PanelOperationCenter)
		end

		-- 部分气泡在点击过一次后，就将其藏起来，方便显示后续优先级的气泡
        local tActivityImgBubbleList = {
            self.ImgBubble15Anni,
            self.ImgBubbleTicket,
            self.ImgBubbleGuessing,
            self.ImgBubbleQuestionnaire,
			self.ImgBubbleQunyingBaoming,
			self.ImgBubbleQunyingJingcai,
        }

        for _, imgBubble in ipairs(tActivityImgBubbleList) do
            if UIHelper.GetVisible(imgBubble) then
                UIHelper.SetVisible(imgBubble, false)
                self.bVisibleBubble = false
            end
        end

        self:UpdateConflictBubble()
	end)
	UIHelper.BindUIEvent(self.BtnShop, EventType.OnClick, function ()
		if not UIMgr.GetView(VIEW_ID.PanelExteriorMain) then
			CoinShopData.Open()
		end

		if UIHelper.GetVisible(self.ImgBubbleShop) then
			UIHelper.SetVisible(self.ImgBubbleShop, false)
			self.bVisibleBubble = false
		end

		local tList = CoinShop_GetHomeList()
		local nMax = 0
		for _, tLine in pairs(tList) do
			nMax = math.max(nMax, tLine.dwGoodsID)
		end
		Storage.CoinShop.dwMaxHomeGoodsID = nMax
		Storage.CoinShop.Dirty()

		self:UpdateConflictBubble()
	end)

	UIHelper.BindUIEvent(self.BtnJianghuXingji, EventType.OnClick, function ()
		if not UIMgr.GetView(VIEW_ID.PanelBenefits) then
			UIMgr.Open(VIEW_ID.PanelBenefits)
		end
	end)

    UIHelper.BindUIEvent(self.TogSystemBtnSwitch, EventType.OnSelectChanged, function(_,bSelected)
		if not g_pClientPlayer then return end

		local nMapID = g_pClientPlayer.GetMapID()
        if HomelandData.IsPrivateHome(nMapID) or HomelandData.IsHomelandCommunityMap(nMapID) or self.nCurSwitchMode and self.nCurSwitchMode == SwitchMode.MonsterBook then
			UIHelper.SetVisible(self.LayoutSystemBtn, bSelected)
			UIHelper.SetVisible(self.WidgetBtnSwitch, not bSelected)

			if not bSelected then
				Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelMainCity, UIHelper.GetName(self.TogSystemBtnSwitch))
			end
		else
			UIHelper.SetVisible(self.LayoutSystemBtn, bSelected)
			UIHelper.SetVisible(self.LayoutDbm, not bSelected)
			UIHelper.SetVisible(self.BtnEscMiJing, not bSelected and self:CanShowEscMijingBtn())
			UIHelper.SetVisible(self.WidgetBtnSwitchMiJing, not bSelected)
		end
    end)

    UIHelper.SetCombinedBatchEnabled(self.LayoutSystemBtn, true)

	UIHelper.BindUIEvent(self.BtnEscMiJing, EventType.OnClick, function()
		self:LeaveDungeonScene()
    end)

	UIHelper.BindUIEvent(self.BtnDaXiaZhiLu, EventType.OnClick, function()
		-- UIMgr.Open(VIEW_ID.PanelCollection, CollectionData.nLastOpenType or COLLECTION_PAGE_TYPE.DAY, CollectionData.nLastPageType or CLASS_TYPE.NORMAL)
		UIMgr.Open(VIEW_ID.PanelRoadCollection, CollectionData.nLastOpenType or COLLECTION_PAGE_TYPE.DAY)
	end)

	UIHelper.BindUIEvent(self.BtnEscLangKe, EventType.OnClick, function()
		if MapHelper.IsRemotePvpMap() then
			PVPFieldData.LeavePVPField()
		end
		if SelfieData.IsInStudioMap() then
			SelfieData.OnLeaveStudioScene(false)
		end
	end)
end

function UIWidgetMainCityRightTop:RegEvent()
	Event.Reg(self, EventType.OnUpdateHomelandEntranceState, function(bShow)
        self:SwitchMode(SwitchMode.Homeland, bShow)

		if bShow then
			if self.scriptCurSwitch then
				self.scriptCurSwitch:UpdateBtnState()
			end
			Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelMainCity, UIHelper.GetName(self.TogSystemBtnSwitch))
		end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function(nRetCode)
        if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO then
            local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
            local dwCurrMapID, nCurrCopyIndex, nCurrLandIndex = HomelandBuildData.GetMapInfo()
            if dwCurrMapID == dwMapID and nCurrCopyIndex == nCopyIndex and nCurrLandIndex == nLandIndex then
                self:UpdateHomelandInfo()
            end
        end
    end)

    Event.Reg(self, "SCENE_END_LOAD", function(nSceneID)
        self:SwitchMode(SwitchMode.Homeland, false)
    end)

	Event.Reg(self, "ON_UPDATEBOSSDBM_STATE", function(bShow)
		local player = GetClientPlayer()
		if player then
			local dwMapID = player.GetMapID()
			local _, nMapType = GetMapParams(dwMapID)

			if nMapType == 1 then --秘境
				if dwMapID ~= MonsterBookData.PLAY_MAP_ID and not MonsterBookData.bIsPlaying then
					self:SwitchMode(SwitchMode.Dungeon, true)
				else
					self:SwitchMode(SwitchMode.MonsterBook, true)
				end
			end
		end
    end)

	Event.Reg(self, "LOADING_END", function ()
		local player = GetClientPlayer()
		if player then
			local dwMapID = player.GetMapID()
			local _, nMapType = GetMapParams(dwMapID)

			if nMapType == 1 then --秘境
				if dwMapID ~= MonsterBookData.PLAY_MAP_ID and not MonsterBookData.bIsPlaying then
					self:SwitchMode(SwitchMode.Dungeon, true)
				else
					self:SwitchMode(SwitchMode.MonsterBook, true)
				end
			end
		end

		UIHelper.SetVisible(self.BtnEscLangKe, MapHelper.IsRemotePvpMap() or SelfieData.IsInStudioMap()) --退出按钮
		UIHelper.LayoutDoLayout(self.LayoutSystemBtn)

		Timer.AddFrame(self, 1, function()
			self:UpdateConflictBubble()
		end)
    end)

	Event.Reg(self, "PLAYER_LEVEL_UPDATE", function (dwPlayerID)
		if SystemOpen.IsSystemOpen(SystemOpenDef.MainCityCustom) then
			Event.Dispatch("OnUpdateCustomRedPoint")
		end
		if g_pClientPlayer and g_pClientPlayer.dwID == dwPlayerID and g_pClientPlayer.nLevel == 108 then
			self:UpdateConflictBubble()
		end
    end)

	Event.Reg(self, EventType.On_Get_Daily_Allinfo, function(tbQuestList, nGetRewardLv, nReachLv)
        self:UpdateDaXiaZhiluNum()
    end)
	Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function (tbFontShow, nNodeType)
		if nNodeType == CUSTOM_TYPE.MENU then
			for k, label in pairs(self.tbLabelList) do
				UIHelper.SetVisible(label, tbFontShow[nNodeType])
			end
		end
    end)
	--Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function (bVisible)
	--	for k, label in pairs(self.tbLabelList) do
	--		UIHelper.SetVisible(label, bVisible)
	--	end
    --end)

    Event.Reg(self, EventType.OnQuestionnaireInfoChanged, function()
		self:UpdateConflictBubble()
    end)

	Event.Reg(self, EventType.OnBagViewOpen, function()
		if UIHelper.GetVisible(self.imgBubbleTimeLimit) then
			if UIHelper.GetVisible(self.imgBubbleTimeLimit) then
				UIHelper.SetVisible(self.imgBubbleTimeLimit, false)
				self.bVisibleBubble = false
			end
			ItemData.SetBagExpiringBubbleShowing(false)
			self:UpdateConflictBubble()
		end
	end)

	Event.Reg(self, "ON_PLAY_UNLOCK_ANIMATION", function(szTitle)
		if AppReviewMgr.IsReview() then
			return
		end

		local tbLockData = {
			["江湖行记"] = {
				AniParent = self.WidgetXingjiAni,
				node = self.BtnJianghuXingji
			},
			["大侠之路"] = {
				AniParent = self.WidgetDaxiaAni,
				node = self.BtnDaXiaZhiLu
			}
		}
		local tbData = tbLockData[szTitle]
		UIHelper.PlayAni(self, tbData.AniParent, "AniDaXiaZhiLu", function ()
			UIHelper.SetVisible(tbData.node, true)
			UIHelper.LayoutDoLayout(self.LayoutSystemBtn)
		end)
    end)

	-- Event.Reg(self, "SchoolActivityRedUpdate", function()
	-- 	local liebianNode = UIHelper.GetChildByName(self.BtnShop, "imgBubbleLieBian")
	-- 	UIHelper.SetVisible(liebianNode, false)
	-- 	self:TryShowQuestionnaireBubble()
    -- end)

	Event.Reg(self, "FIRST_LOADING_END", function()
		Timer.AddFrame(self, 1, function()
			self:UpdateConflictBubble(true)
		end)
	end)

    Event.Reg(self, EventType.OnDoSomething, function(szKey)
        if szKey == HuaELouData.szDidKeyTongWarGuessing then
            --- 在帮会联赛匹配界面点竞猜按钮时，也要刷新竞猜的气泡
            self:UpdateConflictBubble()
        end
    end)
end

function UIWidgetMainCityRightTop:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end

function UIWidgetMainCityRightTop:OnUpdate()

	-- self:UpdateWifi()
	-- self:UpdateSignal()
	-- self:UpdateBattery()
	-- self:UpdateTime()
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local Def = {

}


function UIWidgetMainCityRightTop:Init()
	self:UpdateHomelandInfo()

	self:InitBubbleBox()

	self:UpdateNodeVisible()
	self:UpdateDaXiaZhiluNum()

	self:UpdateNodeScale()

    -- 查询帮会申请信息
    TongData.TryGetApplyJoinInList()

	self:UpdateConflictBubble(true)
end

function UIWidgetMainCityRightTop:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIWidgetMainCityRightTop:SwitchMode(nSwitchMode, bEnabled)
	if not bEnabled then
		self.nCurSwitchMode = nil
		self.scriptCurSwitch = nil
		UIHelper.SetSelected(self.TogSystemBtnSwitch, true)
		UIHelper.SetVisible(self.TogSystemBtnSwitch, false)
		UIHelper.SetVisible(self.LayoutSystemBtn, true)
		UIHelper.SetVisible(self.WidgetBtnSwitch, false)
		UIHelper.SetVisible(self.WidgetBtnSwitchMiJing, false)
		UIHelper.SetVisible(self.BtnEscMiJing, false)
		UIHelper.RemoveAllChildren(self.LayoutDbm)
		UIHelper.RemoveAllChildren(self.WidgetBtnSwitch)
		return
	end

	if self.nCurSwitchMode ~= nSwitchMode then
		self.nCurSwitchMode = nSwitchMode
		if nSwitchMode == SwitchMode.Dungeon then
			UIHelper.RemoveAllChildren(self.WidgetBtnSwitch)
			UIHelper.SetVisible(self.WidgetBtnSwitchMiJing, true)
			UIHelper.SetVisible(self.BtnEscMiJing, self:CanShowEscMijingBtn())
		else
			UIHelper.SetVisible(self.BtnEscMiJing, false)
			UIHelper.SetVisible(self.WidgetBtnSwitchMiJing, false)
			UIHelper.RemoveAllChildren(self.WidgetBtnSwitch)
			self.scriptCurSwitch = UIHelper.AddPrefab(SwitchMode2PrefabID[nSwitchMode], self.WidgetBtnSwitch)
		end
	end

	if not UIHelper.GetVisible(self.TogSystemBtnSwitch) then
		Event.Dispatch(EventType.OnTeachButtonShow, VIEW_ID.PanelMainCity, UIHelper.GetName(self.TogSystemBtnSwitch))
	end

	UIHelper.SetVisible(self.TogSystemBtnSwitch, true)
	UIHelper.SetSelected(self.TogSystemBtnSwitch, false)
end


function UIWidgetMainCityRightTop:UpdateHomelandInfo()
	self:SwitchMode(SwitchMode.Homeland, HomelandData.IsShowHomelandEntrance())
end

function UIWidgetMainCityRightTop:InitBubbleBox()
    local scriptBubbleBox = UIHelper.GetBindScript(self.WidgetBubble)
	scriptBubbleBox:OnEnter(self)

	if AppReviewMgr.IsReview() then
		UIHelper.SetVisible(self.WidgetBubble, false)
	end
end

function UIWidgetMainCityRightTop:LeaveDungeonScene()
	if RoomData.IsInGlobalRoomDungeon() then
		RoomData.ConfirmLeaveRoomScene()
	else
		local confirmDialog = UIHelper.ShowConfirm(g_tStrings.STR_ROOM_LEAVE_DUNGEON_MAP_CONFIRM, function()
			RemoteCallToServer("On_Dungeon_Leave")
		end, nil)
		confirmDialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
	end
end

function UIWidgetMainCityRightTop:UpdateNodeVisible()
	UIHelper.SetVisible(self.BtnJianghuXingji, SystemOpen.IsSystemOpen(SystemOpenDef.JiangHuXingJi))
	UIHelper.SetVisible(self.BtnDaXiaZhiLu, not AppReviewMgr.IsReview() and SystemOpen.IsSystemOpen(SystemOpenDef.RiKe))
	UIHelper.SetVisible(self.BtnActivity, not AppReviewMgr.IsReview())
	UIHelper.LayoutDoLayout(self.LayoutSystemBtn)
end

function UIWidgetMainCityRightTop:UpdateDaXiaZhiluNum()
	local nCount, nTotal = CollectionDailyData.GetDailyQuestFinishCount()
	UIHelper.SetString(self.LabelDaXiaZhiLu, string.format("(%s/%s)", nCount, nTotal))
end

function UIWidgetMainCityRightTop:UpdateNodeScale()
	for k, label in pairs(self.tbLabelList) do
		UIHelper.SetVisible(label, Storage.ControlMode.tbFontShow[CUSTOM_TYPE.MENU])
	end
end

function UIWidgetMainCityRightTop:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
	self.nMode = nMode
end

function UIWidgetMainCityRightTop:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end

function UIWidgetMainCityRightTop:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIWidgetMainCityRightTop:UpdateConflictBubble(bFirstInit)
	-- 判断需要读表格，等loading完再初始化
	if SceneMgr.IsLoading() then
		return
	end

    --- 按照下面的顺序尝试显示气泡，如果一个气泡显示了，后面的就不再显示
    --- 花萼楼的气泡要特殊处理有等级判断
    local tFnTryShowBubbleOrderList = {
        self.TryShowCoinShopNew, --- 外观新品热卖
        self.TryShowBubble15Anni, --- 15周年庆
        self.TryShowBubbleTicket, --- 15周年庆售票
        self.TryShowCompetitiveMatch2025,
        self.TryShowCompetitiveMatchGuess2025,
        self.TryShowTongWarGuessing, --- 帮会联赛竞猜
        --self.TryShowSchoolActivity, --- 免费领外观（校服）
        self.TryShowBagHint, --- 物品即将过期
        --self.TryShowProducerLetter, --- 制作人的一封信
        self.TryShowQuestionnaireBubble, --- 问卷
    }

    for _, fnTryShowBubble in ipairs(tFnTryShowBubbleOrderList) do
        if self.bVisibleBubble then
            --- 有任何一个气泡显示了，则不再尝试后续的
            break
        end

        fnTryShowBubble(self)
    end

    UIHelper.SetVisible(self.ImgHuaELouBubble, not HuaELouData.CheckHuaELouBubble())
end

function UIWidgetMainCityRightTop:TryShowCoinShopNew()
    if UIHelper.GetVisible(self.ImgBubbleShop) then
        return
    end

    local bShow = false

    local tList = CoinShop_GetHomeList()
    local nMax  = 0
    for _, tLine in pairs(tList) do
        nMax = math.max(nMax, tLine.dwGoodsID)
    end
    bShow = nMax > Storage.CoinShop.dwMaxHomeGoodsID
    UIHelper.SetVisible(self.ImgBubbleShop, bShow)
    if bShow then
        UIHelper.SetString(self.LabelBubbleShop, "新品热卖中")
    end

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowBubble15Anni()
    if UIHelper.GetVisible(self.ImgBubble15Anni) then
        return
    end

	if HuaELouData.CheckHuaELouBubble() then
		return
	end

    local bShow = false

    if WebUrl.CanShow(WEBURL_ID.FIFTEEN_Anni_LIVE_STREAMING) then
        local szFirstRunKey = "15Anni_Live_Bubble_Limit" -- 每天仅尝试最多显示一次气泡
        if not APIHelper.IsDidToday(szFirstRunKey) then
            bShow = true
        end
        APIHelper.DoToday(szFirstRunKey)
    end

    UIHelper.SetVisible(self.ImgBubble15Anni, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowBubbleTicket()
    if UIHelper.GetVisible(self.ImgBubbleTicket) then
        return
    end

	if HuaELouData.CheckHuaELouBubble() then
		return
	end


    local bShow = false

    if WebUrl.CanShow(WEBURL_ID.TICKETS_PURCHASE_ELIGIBILITY) then
        local szFirstRunKey = "Ticket_Bubble_Limit" -- 每天仅尝试最多显示一次气泡
        if not APIHelper.IsDidToday(szFirstRunKey) then
            bShow = true
        end
        APIHelper.DoToday(szFirstRunKey)
    end

    UIHelper.SetVisible(self.ImgBubbleTicket, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowCompetitiveMatch2025()
    if UIHelper.GetVisible(self.ImgBubbleQunyingBaoming) then
        return
    end

	if HuaELouData.CheckHuaELouBubble() then
		return
	end

    local bShow = false

    if WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH) then
        local szFirstRunKey = "Competitive_Match_2025" -- 每天仅尝试最多显示一次气泡
        if not APIHelper.IsDidToday(szFirstRunKey) then
            bShow = true
        end
        APIHelper.DoToday(szFirstRunKey)
    end

    UIHelper.SetVisible(self.ImgBubbleQunyingBaoming, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowCompetitiveMatchGuess2025()
    if UIHelper.GetVisible(self.ImgBubbleQunyingJingcai) then
        return
    end

	if HuaELouData.CheckHuaELouBubble() then
		return
	end

    local bShow = false

    if WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH_GUESS) then
        local szFirstRunKey = "Competitive_Match_Guess_2025" -- 每天仅尝试最多显示一次气泡
        if not APIHelper.IsDidToday(szFirstRunKey) then
            bShow = true
        end
        APIHelper.DoToday(szFirstRunKey)
    end

    UIHelper.SetVisible(self.ImgBubbleQunyingJingcai, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowTongWarGuessing()
    if UIHelper.GetVisible(self.ImgBubbleGuessing) then
        return
    end

	if HuaELouData.CheckHuaELouBubble() then
		return
	end

    local bShow = false

    if WebUrl.CanShow(WEBURL_ID.TONG_WAR_GUESSING) then
        local szFirstRunKey = "Tong_War_Guessing_Bubble_Limit" -- 每天仅尝试最多显示一次气泡
        if not APIHelper.IsDidToday(szFirstRunKey) then
            bShow = true
        end
        APIHelper.DoToday(szFirstRunKey)
    end

    UIHelper.SetVisible(self.ImgBubbleGuessing, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowSchoolActivity()
    if UIHelper.GetVisible(self.ImgBubbleShop) then
        return
    end

    local bShow = false

    local bActivityOpen = self:IsSchoolActivityOpen()
    if bActivityOpen then
        local activityNode  = UIHelper.GetChildByName(self.BtnShop, "imgShop_Actvity")

        UIHelper.SetVisible(activityNode, true)
        UIHelper.SetVisible(self.ImgBubbleShop, true)

        bShow = true
    end

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:IsSchoolActivityOpen()
    local SCHOOL_EXTERIOR = 927
    local bOpen           = ActivityData.IsActivityOn(SCHOOL_EXTERIOR) or UI_IsActivityOn(SCHOOL_EXTERIOR)
    return bOpen
end

function UIWidgetMainCityRightTop:TryShowBagHint()
    if UIHelper.GetVisible(self.imgBubbleTimeLimit) then
        return
    end

    local bShow = false

    if ItemData.IsBagContainExpiringItem() or ItemData.IsRoleWareHouseContainExpiringItem() then
        local szFirstRunKey = "bag_time_limit"    -- 每天仅尝试最多显示一次气泡
        if not APIHelper.IsDidToday(szFirstRunKey) then
            bShow = true
            ItemData.SetBagExpiringBubbleShowing(true)
        end
        APIHelper.DoToday(szFirstRunKey)
    end
    UIHelper.SetVisible(self.imgBubbleTimeLimit, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowProducerLetter()
    --- note: 制作人的一封信是通过判断花萼楼页面里的那个按钮是否被点击过来判断，所以这里不像其他的气泡一样在自己已显示的情况下就不检查了

	if HuaELouData.CheckHuaELouBubble() then
		return
	end

    local bShow = false

    if WebUrl.CanShow(WEBURL_ID.PRODUCER_LETTER) then
        bShow = HuaELouData.GetProducerLetterRedPoint()
    end

    UIHelper.SetVisible(self.ImgBubblePlayerLetter, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:TryShowQuestionnaireBubble()
    if UIHelper.GetVisible(self.ImgBubbleQuestionnaire) then
        return
    end

	if HuaELouData.CheckHuaELouBubble() then
		return
	end

    local bShow = false

    if QuestionnaireData.bHasNew then
        -- 对于每个问卷，每天仅尝试最多显示一次气泡
        local szFirstRunKey = string.format("questionnaire_%s", QuestionnaireData.tQuestionnaire.szSurveyID)
        if not APIHelper.IsDidToday(szFirstRunKey) then
            bShow = true
        end
        APIHelper.DoToday(szFirstRunKey)
    end
    UIHelper.SetVisible(self.ImgBubbleQuestionnaire, bShow)

    --互斥规则 一个气泡存在时 后面的不显示
    self.bVisibleBubble = bShow
end

function UIWidgetMainCityRightTop:UdpateCustomInfo()
	Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function (tbFontShow, nNodeType)
		if nNodeType == CUSTOM_TYPE.MENU then
			for k, label in ipairs(self.tbLabelList or {}) do
				if tbFontShow then
					UIHelper.SetVisible(label, tbFontShow[nNodeType])
				end
			end
		end
    end)

	UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.RIGHT, CUSTOM_TYPE.MENU, self.nMode or Storage.ControlMode.nMode)
    end)

	self:UpdateNodeScale()
end

function UIWidgetMainCityRightTop:UpdateSubsidiaryCustomState(bSubsidiaryCustom)
	UIHelper.SetVisible(self.LayoutSystemBtn, not bSubsidiaryCustom)
	UIHelper.SetVisible(self.WidgetBtnSwitchMiJing, bSubsidiaryCustom)
	UIHelper.SetVisible(self.TogSystemBtnSwitch, bSubsidiaryCustom)
end

function UIWidgetMainCityRightTop:CanShowEscMijingBtn()
	local bResult = true
	if g_pClientPlayer and g_pClientPlayer.GetMapID() == 451 then
		bResult = false
	end
	return bResult
end

return UIWidgetMainCityRightTop
