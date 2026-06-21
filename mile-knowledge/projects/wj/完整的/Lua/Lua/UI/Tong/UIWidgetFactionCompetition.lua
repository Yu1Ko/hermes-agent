-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetFactionCompetition
-- Date: 2023-03-244
-- Desc: 帮会外交约战
-- Prefab: PREFAB_ID.WidgetFactionCompetition
-- Mark: 
-- ---------------------------------------------------------------------------------

local UIWidgetFactionCompetition = class("UIWidgetFactionCompetition")

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

BigIntSub = BigIntSub or function (a, b)
	return a - b
end

local lc_GetThisWeekStarTime = function ()
	local nTime = GetCurrentTime()
	local tTime = TimeToDate(nTime)
	
	if tTime.weekday == 0 then 
		nTime = BigIntSub(nTime, 6 * 3600 * 24)
	else
		nTime = BigIntSub(nTime, (tTime.weekday - 1) * 3600 * 24)
	end

	nTime = BigIntSub(nTime, tTime.hour * 3600)
	nTime = BigIntSub(nTime, tTime.minute * 60)
	nTime = BigIntSub(nTime, tTime.second)
	return nTime
end

local tWeekdayTimeSegment = {}
local tWeekdayTimeSegmentMenu = {}
local lc_GetFightTimeSegment = function ()
	local nCurrentTime = GetCurrentTime()
	local nDeltaTime = nCurrentTime - lc_GetThisWeekStarTime()
	local tFightTimeSegment = GetTongContractWarTimeSegment()
	local nIndex
	for i, nValue in pairs(tFightTimeSegment) do 
		if nValue > nDeltaTime + 1800 then 			-- 开战前半小时不可选
			nIndex = i
			break
		end
	end	
	if not nIndex then 
		return
	end
	
	tWeekdayTimeSegment = {}
	tWeekdayTimeSegmentMenu = {}
	
	for i = nIndex, #tFightTimeSegment do 
		local nTimeCanFight = lc_GetThisWeekStarTime() + tFightTimeSegment[i]
		local tTimeCanFight = TimeToDate(nTimeCanFight)
		local nWeekday = tTimeCanFight.weekday
		
		if not tWeekdayTimeSegment[nWeekday] then 
			tWeekdayTimeSegment[nWeekday] = {}
			local szFightTime = g_tStrings.tWeek[nWeekday]
			szFightTime = szFightTime.."  "..tTimeCanFight.year.."年"..tTimeCanFight.month.."月"..tTimeCanFight.day.."日"
			table.insert(tWeekdayTimeSegmentMenu, {szFightTime, nWeekday})
		end
		table.insert(tWeekdayTimeSegment[nWeekday], tFightTimeSegment[i])
	end
end


local _NodeNameArr = {
	"BtnCompetitionInvitation",

	"EditBox",

	"ToggleGroupContractType",
	"LayoutChooseLastingTime",	

	"LabelFightScale",
	
	"WidgetDateFilter",
	"ScrollViewDateFilter",	
	"BtnDateFilter",	
	"LabelDateFilter",
    "ImgDown",

    "LabelFightTime",
    "WidgetChooseFightTime",
    "ToggleGroupTime",
    "LayoutChooseTime",

	"ToggleGroupContractCost",
	"WidgetTogFightCostDuel",
	"LayoutTogFightCost",
	"LabelFightCostCompare",
    
    "WidgetFightAward",
	"TogFightRules",
	"WidgetTips01",	
    "LabelTips01",
	"ScrollViewRecordFactionRecord01",		

	"BtnComfirm",

	"ScrollViewCompetitionInformation",
    "WidgetDeco",
}

function UIWidgetFactionCompetition:Init()
	self.m = {}	
	self.m.nModeIndex = 1
	self.m.nWeekdayIndex = 1
	self.m.nTimeSegmentIndex = 1
	self.m.nMoneyIndex = 1	
	self.m.nNeedMoney = 0

	local tNodes = {}
	UIHelper.FindNodeByNameArr(self._rootNode, tNodes, _NodeNameArr)
	self.m.tNodes = tNodes

	self:RegEvent()
	self:BindUIEvent()


	self:UpdateUI(true)
end

function UIWidgetFactionCompetition:UnInit()
	self:UnRegEvent()

	UIHelper.RemoveFromParent(self._rootNode)
	self.m = nil
end

function UIWidgetFactionCompetition:BindUIEvent()
	local tNodes = self.m.tNodes
	UIHelper.BindUIEvent(tNodes.TogFightRules, EventType.OnClick, function()
		UIHelper.SetTouchLikeTips(tNodes.WidgetTips01, UIMgr.GetLayer(UILayer.Page), function ()
			UIHelper.SetSelected(tNodes.TogFightRules, false)
		end)		
	end)	
	UIHelper.BindUIEvent(tNodes.BtnComfirm, EventType.OnClick, function()
		self:OnSendCompetition()
	end)	
	UIHelper.BindUIEvent(tNodes.BtnCompetitionInvitation, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelCompetitionInvitationPop)		
	end)	
	UIHelper.RegisterEditBoxEnded(tNodes.EditBox, function()
		self.m.szTargetName = UIHelper.GetText(tNodes.EditBox)
		self:UpdateUI()
	end)
	
	UIHelper.BindUIEvent(tNodes.BtnDateFilter, EventType.OnClick, function()
		self:ShowChooseDateMenu()	
	end)

    tNodes.ToggleGroupContractType:addEventListener(function(toggle, nIndexBaseZero)
        self:SwitchMode(nIndexBaseZero + 1)
    end)
    tNodes.ToggleGroupContractCost:addEventListener(function(toggle, nIndexBaseZero)
        self:SwitchMoney(nIndexBaseZero + 1)
    end)
    tNodes.ToggleGroupTime:addEventListener(function(toggle, nIndexBaseZero)
        self:SwitchTime(nIndexBaseZero + 1)
    end)

end

function UIWidgetFactionCompetition:SwitchMode(nIndex)
	self.m.nModeIndex = nIndex

	if nIndex == 1 then
		self.m.nNeedMoney = tonumber(UIHelper.GetString(self.m.tNodes.LabelFightCostCompare)) 
		self:UpdateUI()
	else
		UIHelper.SetToggleGroupSelected(self.m.tNodes.ToggleGroupContractCost, 0)

        self:UpdateRewards()
	end
end

function UIWidgetFactionCompetition:SwitchMoney(nIndex)		
	local tMoneyArr = GetTongContractWarCastMoney()
	self.m.nNeedMoney = tMoneyArr[nIndex] or 0
	self.m.nMoneyIndex = nIndex
	self:UpdateUI()
end

function UIWidgetFactionCompetition:SwitchTime(nIndex)
    self.m.nTimeSegmentIndex = nIndex
end

function UIWidgetFactionCompetition:ShowChooseDateMenu()
	lc_GetFightTimeSegment()
	local tNodes = self.m.tNodes
	UIHelper.SetVisible(tNodes.WidgetDateFilter, true)
    UIHelper.SetRotation(tNodes.ImgDown, 0)
	UIHelper.SetTouchLikeTips(tNodes.WidgetDateFilter, UIMgr.GetLayer(UILayer.Page), function ()
		UIHelper.SetVisible(tNodes.WidgetDateFilter, false)
        UIHelper.SetRotation(tNodes.ImgDown, -90)
	end)

	if self.m.nWeekdayIndex > #tWeekdayTimeSegmentMenu then
		self.m.nWeekdayIndex = 1
	end

	local list = tNodes.ScrollViewDateFilter
	local children = UIHelper.GetChildren(list)
	for i, child in ipairs(children) do
		local tItem = tWeekdayTimeSegmentMenu[i]		
		UIHelper.SetVisible(child, tItem ~= nil)
		if tItem ~= nil then
			local sz = tItem[1]
			child.nIndex = i
			UIHelper.SetString(UIHelper.FindChildByName(child, "LabelStyleFilterMain"), sz)
			UIHelper.SetString(UIHelper.FindChildByName(child, "LabelStyleFilterMainUp"), sz)
			UIHelper.SetSelected(child, self.m.nWeekdayIndex == i)			
			
			UIHelper.BindUIEvent(child, EventType.OnClick, function(cell)
				self.m.nWeekdayIndex = cell.nIndex
				self.m.nTimeSegmentIndex = 1
				self:UpdateUI()
				UIHelper.SetVisible(tNodes.WidgetDateFilter, false)
                UIHelper.SetRotation(tNodes.ImgDown, -90)
                
                -- 点击后调整约战时间选项
                UIHelper.SetToggleGroupSelected(tNodes.ToggleGroupTime, self.m.nTimeSegmentIndex-1)
			end)			
		end		
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false)	

end

function UIWidgetFactionCompetition:UpdateTimeSegment()
    local tNodes = self.m.tNodes

    local nWeekday = tWeekdayTimeSegmentMenu[self.m.nWeekdayIndex][2]
    local tWeekdaySegment = tWeekdayTimeSegment[nWeekday]
    -- 现在手机这边有点山寨，端游是一个下拉框，按照逻辑设定的选择时间，vk这边是一个固定选项，或者一个两个toggle的选择，这里先按这个来弄
    local bSingle = #tWeekdaySegment == 1
    UIHelper.SetVisible(tNodes.LabelFightTime, bSingle)
    UIHelper.SetVisible(tNodes.WidgetChooseFightTime, not bSingle)
end

function UIWidgetFactionCompetition:OnSendCompetition()

	local szErr = self:CheckCondition()
	if szErr then
		OutputMessage("MSG_ANNOUNCE_NORMAL", szErr)
		return
	end	

	local tNodes = self.m.tNodes
	local szTargetName = UIHelper.GetText(tNodes.EditBox)
	local sz = FormatString(g_tStrings.STR_FIGHT_LAUNCH_WARMING, szTargetName)	
	local nSubType = 1
	if self.m.nModeIndex == 2 then
		nSubType = nSubType + self.m.nMoneyIndex
	end
	local tTimeSegment = GetTongContractWarTimeSegment()
	local nWeekday = tWeekdayTimeSegmentMenu[self.m.nWeekdayIndex][2]
	local nTimeSegment = tWeekdayTimeSegment[nWeekday][self.m.nTimeSegmentIndex]
	assert(nTimeSegment)
	local nIndex
	for i, nValue in ipairs(tTimeSegment) do 
		if nValue == nTimeSegment then 
			nIndex = i
			break
		end
	end
	UIHelper.ShowConfirm(sz, function ()
		RemoteCallToServer(
			"On_Tong_LaunchCWRequest", 
			u2g(szTargetName), 
			nSubType,
			nIndex)
	end)
end

function UIWidgetFactionCompetition:RegEvent()	
	-- Event.Reg(self, "UPDATE_OTHER_TONG_ROSTER_FINISH", function ()		
	-- 	self:UpdateUI()
	-- end)

    Event.Reg(self, "UPDATE_TONG_DIPLOMACY_INFO", function()
        self:UpdateUI()
    end)
end

function UIWidgetFactionCompetition:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFactionCompetition:UpdateUI(bInit)
	local tNodes = self.m.tNodes
	if bInit then
		lc_GetFightTimeSegment()

        do
            UIHelper.ToggleGroupRemoveAllToggle(tNodes.ToggleGroupContractType)
            local children = UIHelper.GetChildren(tNodes.LayoutChooseLastingTime)
            for i, child in ipairs(children) do
                UIHelper.ToggleGroupAddToggle(tNodes.ToggleGroupContractType, child)
            end
            UIHelper.SetToggleGroupSelected(tNodes.ToggleGroupContractType, 0)
        end

        do
            UIHelper.ToggleGroupRemoveAllToggle(tNodes.ToggleGroupContractCost)
            local children = UIHelper.GetChildren(tNodes.LayoutTogFightCost)
            for i, child in ipairs(children) do
                UIHelper.ToggleGroupAddToggle(tNodes.ToggleGroupContractCost, child)
            end
            UIHelper.SetToggleGroupSelected(tNodes.ToggleGroupContractCost, 0)
        end
        
        do
            UIHelper.ToggleGroupRemoveAllToggle(tNodes.ToggleGroupTime)
            local children = UIHelper.GetChildren(tNodes.LayoutChooseTime)
            for i, child in ipairs(children) do
                UIHelper.ToggleGroupAddToggle(tNodes.ToggleGroupTime, child)
            end
            UIHelper.SetToggleGroupSelected(tNodes.ToggleGroupTime, 0)
        end
	end
	
	-- 约定列表
	self:UpdateContractedList(bInit)

	-- 时间
	UIHelper.SetString(tNodes.LabelDateFilter, tWeekdayTimeSegmentMenu[self.m.nWeekdayIndex][1])

	-- 消耗
	UIHelper.SetVisible(tNodes.LabelFightCostCompare, self.m.nModeIndex == 1)
	UIHelper.SetVisible(tNodes.WidgetTogFightCostDuel, self.m.nModeIndex == 2)

	--
	self:UpdateBtn()
    
    self:UpdateRewards()
    
    -- 刷新约战时间选项
    self:UpdateTimeSegment()
end

function UIWidgetFactionCompetition:UpdateContractedList(bInit)
	local list = self.m.tNodes.ScrollViewCompetitionInformation
	assert(list)
	UIHelper.RemoveAllChildren(list)		

	local arr = TongData.GetContractWarDataArr()
    self.m.tDataArr = arr
	local bEmpty = #arr == 0

    UIHelper.SetVisible(self.m.tNodes.ScrollViewCompetitionInformation, not bEmpty)
    UIHelper.SetVisible(self.m.tNodes.WidgetDeco,  bEmpty)
    
    self.m.tCellArr = {}    
	if bEmpty then return end

	for i, tData in ipairs(arr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetCompetitionInformation, list)
		assert(cell)
        table.insert(self.m.tCellArr, cell)        
		self:UpdateContractedCell(i)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false) 	
end


local _tCellFieldNameArr = {
	"LabelDuel",
	"LabelFactionName",
	"LabelCompetitionDate",
    "LabelCompetitionTime",
    "LayoutCompetitionCost",
	"LabelCompetitionCost",	
}
function UIWidgetFactionCompetition:UpdateContractedCell(nIndex)
    local cell = self.m.tCellArr[nIndex]    
	assert(cell)
    local tData = self.m.tDataArr[nIndex]
	assert(tData)
    local tNodes = {}
    UIHelper.FindNodeByNameArr(cell, tNodes, _tCellFieldNameArr)

    local tMoneyArr = GetTongContractWarCastMoney()
    local nMoney = tMoneyArr[tData.wSubType]
    assert(nMoney, "nMoney is nil, index: " .. tData.wSubType)    
	
	local dwTargetTongID = tData.dwSrcTongID ~= GetTongClient().dwTongID and tData.dwSrcTongID or tData.dwDstTongID
    local tInfo = GetTongSimpleInfo(dwTargetTongID)
    assert(tInfo)
    UIHelper.SetString(tNodes.LabelFactionName, g2u(tInfo.szTongName))
    UIHelper.SetString(tNodes.LabelCompetitionDate, TongData.GetDateString(tData.nStartTime))
    UIHelper.SetString(tNodes.LabelCompetitionTime, TongData.GetTimeString(tData.nStartTime))
    UIHelper.SetString(tNodes.LabelDuel, tData.wSubType == 1 and "切磋" or "对决") -- wSubType的值由1到4
    UIHelper.SetString(tNodes.LabelCompetitionCost, nMoney)
    UIHelper.LayoutDoLayout(tNodes.LayoutCompetitionCost) 


end


function UIWidgetFactionCompetition:CheckCondition()
	local szErr
	repeat
		-- fund
		local nFund = TongData.GetFund()
		if self.m.nNeedMoney == 0 or nFund < self.m.nNeedMoney then
			szErr = g_tStrings.STR_TONG_TREE_UPDATE_REQUIRE_FUND
			break
		end
		
	until true
	
	return szErr
end

function UIWidgetFactionCompetition:UpdateBtn()
	local tNodes = self.m.tNodes
	local szTargetName = UIHelper.GetText(tNodes.EditBox)

	local bEnable = false
	if szTargetName and szTargetName ~= "" then
		bEnable = true		
	end

	UIHelper.SetEnable(tNodes.BtnComfirm, bEnable)
	UIHelper.SetNodeGray(tNodes.BtnComfirm, not bEnable, true)
end

-- note: 端游这个是通过 g_tStrings.tWinTongBattleReward 配置的字符串来展示的，我们这里额外显示对应情况胜利时的奖励，若那边有改动，需同步到这里
local _tSubTypeToWinRewardList = {
    [1] = {},
    [2] = {
        {
            szType = CurrencyType.GangFunds,
            nCount = 15000,
        },
        {
            szType = CurrencyType.Justice,
            nCount = 20,
        },
    },
    [3] = {
        {
            szType = CurrencyType.GangFunds,
            nCount = 150000,
        },
        {
            szType = CurrencyType.Justice,
            nCount = 50,
        },
    },
    [4] = {
        {
            szType = CurrencyType.GangFunds,
            nCount = 750000,
        },
        {
            szType = CurrencyType.Justice,
            nCount = 100,
        },
    },
}

function UIWidgetFactionCompetition:UpdateRewards()
    local nSubType = 1
    if self.m.nModeIndex == 2 then
        nSubType = nSubType + self.m.nMoneyIndex
    end

    -- tips
    local tRewardStr = g_tStrings.tWinTongBattleReward[nSubType]
    local szTips     = string.format(
            "帮会奖励\n%s\n%s\n\n个人奖励\n%s\n%s",
            tRewardStr["Tong"]["Win"],
            tRewardStr["Tong"]["Lost"],
            tRewardStr["Persion"]["Win"],
            tRewardStr["Persion"]["Lost"]
    )
    UIHelper.SetString(self.m.tNodes.LabelTips01, szTips)
    
    -- 奖励 端游的奖励是使用文字的，我们这里增加显示图标奖励，仅显示胜利时的奖励
    local tRewardList = _tSubTypeToWinRewardList[nSubType]
    local scrollView = self.m.tNodes.ScrollViewRecordFactionRecord01

    UIHelper.SetVisible(self.m.tNodes.WidgetFightAward, #tRewardList > 0)
    
    UIHelper.RemoveAllChildren(scrollView)

    for _, tReward in ipairs(tRewardList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetAward, scrollView, tReward.szType, tReward.nCount)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
    end
    
    UIHelper.ScrollViewDoLayout(scrollView)
    UIHelper.ScrollToLeft(scrollView, 0)
end


return UIWidgetFactionCompetition

