-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDailySignIn
-- Date: 2022-12-23 15:34:49
-- Desc: ?
-- ---------------------------------------------------------------------------------


local UIDailySignIn = class("UIDailySignIn")

local EX_POINT_YUNSHI		= 257	-- 七天里每天的签到运势：个十百千万十万百万七位用1~5记录签到运势,[1] = "末吉签",[2] = "中平签",[3] = "上吉签",[4] = "上上签",[5] = "鸿运签",
local EX_POINT_AWARD_INDEX 	= 260	-- 七天里每天的签到的奖励index：个十百千万十万百万七位用1~9记录当前签到池的奖励index
local EX_POINT_LUCKY		= 258	-- 七天里每天是否鸿运：个十百千万十万百万七位：0表示未签，1表示已中鸿运，2表示未触发任何特殊效果（鸿运、奇遇），3表示已中奇遇，4表示即将鸿运，5表示即将奇遇，6表示即将上上签
local EX_POINT_SIGN_DAY		= 259	-- 签到天数
local EX_PROGRESS_OF_SIGN	= 384   -- 记录进度条进度 气运值，满一百下次签到必鸿运

local SIGN_DAY_COUNT = 7
local TIMES_OF_HONGYUN_AWARD = 4 --鸿运基础奖励是4倍
local MAX_DAY_OF_NEW_PLAYER = 7

local AUTO_TURN_PAGE_TIME = 3
local PAGE_TURNING_TIME = 1

local awardName = {
    [1] = "江湖画扇",
    [2] = "里飞沙·马驹",
    [3] = "山海间",
    [4] = "夜幕星河",
}

local tSignInBg= {
    [1] = "UIAtlas2_OperationCenter_DailySignInNew_Img_fengling2_1.png",
    [2] = "UIAtlas2_OperationCenter_DailySignInNew_Img_fengling2_1.png",
    [3] = "UIAtlas2_OperationCenter_DailySignInNew_Img_fengling2_1.png",
    [4] = "UIAtlas2_OperationCenter_DailySignInNew_Img_fengling2_1.png",
    [5] = "UIAtlas2_OperationCenter_DailySignInNew_Img_fengling2_1.png",
}

function UIDailySignIn:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    self.dwOperatActID = dwOperatActID
    self.tInfo = tLine
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self:UpdateInfo(tActivity.szbgImgPath)
    UIHelper.SetPageIndex(self.PageViewRewardItem, 0)
    self.autoTurnPage = true
    UIHelper.SetSelected(self.tbToggleGroup[1],true)
    self:AutoTurnPage()
end

function UIDailySignIn:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.nPageTimerID then
        Timer.DelTimer(self, self.nPageTimerID)
        self.nPageTimerID = nil
    end
    Timer.DelAllTimer(self)
end

function UIDailySignIn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPress,EventType.OnClick,function ()
        RemoteCallToServer("On_NewDailySign_Sign")
    end)

    UIHelper.BindUIEvent(self.BtnLuckDetail,EventType.OnClick,function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnLuckDetail, TipsLayoutDir.TOP_CENTER ,g_tStrings.STR_SING_IN_LUCKY_NUM)
    end)

    UIHelper.BindUIEvent(self.PageViewRewardItem, EventType.OnTurningPageView, function ()
        if not self.bInit then
            return
        end
        local index = UIHelper.GetPageIndex(self.PageViewRewardItem)
        UIHelper.SetString(self.LabelItemName,awardName[index+1])
        if not self.bSetSelected then
            for k,v in ipairs(self.tbToggleGroup) do
                UIHelper.SetSelected(v, k == index + 1)
            end
        else
            self.bSetSelected = false
        end

        if self.autoTurnPage == true then
            self.autoTurnPage = false
        else
            self:AutoTurnPage()
        end
    end)

    for k,v in ipairs(self.tbToggleGroup) do
        UIHelper.BindUIEvent(v,EventType.OnSelectChanged,function (_,bSelected)
            if bSelected then
                UIHelper.ScrollToPage(self.PageViewRewardItem, k-1, PAGE_TURNING_TIME/4)
                self.bSetSelected = true
            else
                self.bSetSelected = false
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        local tInfo = self.tInfo
        local szTitle = tInfo.szName and UIHelper.GBKToUTF8(tInfo.szName) or ""
        UIMgr.Open(VIEW_ID.PanelHuaELouHelpPop, self.dwOperatActID, szTitle, tInfo.szActivityExplain)
    end)

    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function()
        local tInfo = self.tInfo
        local szName = tInfo.szName and UIHelper.GBKToUTF8(tInfo.szName) or ""
        local szLinkInfo = string.format("OperationCenter/%d", self.dwOperatActID)
        ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
    end)
end

function UIDailySignIn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self,"ON_DAILY_SIGN_REFRESH",function ()
        self:InitSignInInfo()
        self:UpdateSignInState()
        self:UpdateRewardList()
        self:UpdateProgress()
        self:GetDoSomething()
    end)

    Event.Reg(self,"ON_DAILY_SIGN_GET_AWARD",function ()
        self.onDailySignGetAward = true
        self:InitSignInInfo()
        self:UpdateSignInState()
        self:UpdateProgress()
        self:GetDoSomething()
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        if self.scriptItemTip then
            UIHelper.SetVisible(self.WidgetAnchorItemTipShell, false)
            UIHelper.RemoveAllChildren(self.WidgetAnchorItemTipShell)
            self.scriptItemTip = nil
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self:AutoTurnPage()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if not self.SelectToggle then
            return
        end
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
        self.SelectToggle = nil
    end)
end

function UIDailySignIn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDailySignIn:UpdateInfo(szbgImgPath)
    self:InitSignInInfo()
    local nTotalDays = self:GetTotalDayOfSignIn()
    local szText = FormatString(g_tStrings.SIGN_IN_TOTAL_DAY_NEW,nTotalDays)
    UIHelper.SetString(self.LabelRight,szText)
    self:UpdateProgress()--气运条
    self:GetDoSomething()--今日宜**
    local szMonName, szDayName = GetLunarDate()
    UIHelper.SetString(self.LabelCalendar, szMonName)--农历
    UIHelper.SetString(self.LabelCalendarDate, g_tLunarString.DATA_TITLE .. szDayName)--农历
    self:UpdateSignInState()
    self:UpdateRewardList()
    UIHelper.SetTexture(self.BgSignIn, szbgImgPath)
end

function UIDailySignIn:AutoTurnPage()
    local nMaxPageCount = #UIHelper.GetListViewItems(self.PageViewRewardItem)
    if nMaxPageCount <= 0 then return end

    if self.nPageTimerID then
        Timer.DelTimer(self, self.nPageTimerID)
        self.nPageTimerID = nil
    end

    self.nPageTimerID = Timer.AddCycle(self, AUTO_TURN_PAGE_TIME, function()
        local nPageIndex = UIHelper.GetPageIndex(self.PageViewRewardItem)
        nPageIndex = nPageIndex + 1
        if nPageIndex >= nMaxPageCount then
            nPageIndex = 0
        end

        UIHelper.ScrollToPage(self.PageViewRewardItem, nPageIndex, PAGE_TURNING_TIME)
        self.autoTurnPage = true
        UIHelper.SetString(self.LabelItemName, awardName[nPageIndex+1])
        for k,v in ipairs(self.tbToggleGroup) do
            UIHelper.SetSelected(v, k == nPageIndex + 1)
        end
    end)
end

function UIDailySignIn:InitSignInInfo()
    self.m_tYunShi = Convert(g_pClientPlayer.GetExtPoint(EX_POINT_YUNSHI))
	self.m_tLucky  = Convert(g_pClientPlayer.GetExtPoint(EX_POINT_LUCKY))
	self.m_tAwardIndex = Convert(g_pClientPlayer.GetExtPoint(EX_POINT_AWARD_INDEX))
end

function UIDailySignIn:GetDataFromSignInLucky()
	if not self.tDataFromSignInLucky then
		self.tDataFromSignInLucky = {}
		local nTotalLucky = g_tTable.SignInLucky:GetRowCount() - 1
		for i = 1, nTotalLucky do
			local tLine = g_tTable.SignInLucky:GetRow(i)
			self.tDataFromSignInLucky[tLine.dwID] = tLine
		end
	end
	return self.tDataFromSignInLucky
end

function UIDailySignIn:GetTodayIndex()
	local nDay = g_pClientPlayer.nAccContinuousLoginCount % SIGN_DAY_COUNT
	if nDay == 0 then
		nDay = SIGN_DAY_COUNT
	end
	return nDay
end

function UIDailySignIn:GetTotalDayOfSignIn()
	local nDay = g_pClientPlayer.GetExtPoint(EX_POINT_SIGN_DAY) or 0
	return nDay
end

function UIDailySignIn:GetTotalDayOfSignInAward()
	local nDay = g_pClientPlayer.GetExtPoint(EX_POINT_SIGN_DAY) or 0
    if not IsSigned() then
        nDay = nDay + 1
    end
	return nDay
end

--返回奖励倍数
function UIDailySignIn:GetTimesOfAward(nYunShi)
	local nTimes = nYunShi
	if nTimes  > TIMES_OF_HONGYUN_AWARD then
		nTimes  = TIMES_OF_HONGYUN_AWARD
	end
	return nTimes
end

function UIDailySignIn:UpdateProgress()
    local nTodayIndex	= self:GetTodayIndex()
	self.nRatio			= g_pClientPlayer.GetExtPoint(EX_PROGRESS_OF_SIGN) or 0
    local nTodayLuckValue	= self.m_tLucky[nTodayIndex]
	self.bIsHongYun		= nTodayLuckValue == 1 --是否中鸿运
    UIHelper.SetString(self.LabelLuckNum,self.nRatio)
    UIHelper.SetProgressBarPercent(self.SliderLuckLight,self.nRatio)
end

--更新上面七个
function UIDailySignIn:UpdateRewardList()
    local nTotalDay		= self:GetTotalDayOfSignInAward()
	--local nTodayIndex	= self:GetTodayIndex()
    for i = 1, SIGN_DAY_COUNT do
        local nAwardIndex 	= self.m_tAwardIndex[i]
        local award 		= self:GetAwardPool(i, nTotalDay)[i][nAwardIndex]
        if award then
            -- UIHelper.SetVisible(self.tbNotSignedDay[i],false)
            UIHelper.SetVisible(self.tbSignedDay[i],true)
            UIHelper.SetSpriteFrame(self.tbSignedDay[i], tSignInBg[self.m_tYunShi[i]])
            -- UIHelper.SetVisible(self.tbWidgetGoodLuckTag[i],true)
            if self.m_tYunShi[i] < 5 then
                UIHelper.SetRichText(self.tbLabelLotLevelDay[i],g_tStrings.SIGN_IN_NAME_OF_RESULT_WITH_COLOR[self.m_tYunShi[i]])
            else
                UIHelper.SetVisible(self.tbLabelLotLevelDay[i], false)
                UIHelper.SetVisible(self.tbLabelLuckyDay[i], true)
            end

            UIHelper.RemoveAllChildren(self.tbWidgetDays[i])
            local itemicon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80,self.tbWidgetDays[i])
            if itemicon then
                itemicon:OnInitWithTabID(award[1], award[2])
                itemicon:SetClickCallback(function()
                    self.SelectToggle =  itemicon.ToggleSelect
                    TipsHelper.ShowItemTips(itemicon._rootNode, award[1], award[2])
                end)
            end

            local nCount = award[3] * self:GetTimesOfAward(self.m_tYunShi[i])
            -- if award[4] and award[4] ~= 0 then
            --     nCount = award[3] * award[4]
            -- end

            UIHelper.SetString(self.tbLabelItemNum[i], nCount)
            UIHelper.SetVisible(self.tbLabelItemNum[i], self.m_tYunShi[i] ~= 0)
        else
            -- UIHelper.SetVisible(self.tbNotSignedDay[i],true)
            UIHelper.SetVisible(self.tbSignedDay[i],false)
            -- UIHelper.SetVisible(self.tbWidgetGoodLuckTag[i],false)
        end
        UIHelper.SetVisible(self.tImgDayText[i], not award)
        self:UpdateGoodLuckTag(i)
    end
    local nTotalDays = self:GetTotalDayOfSignIn()
    local szText = FormatString(g_tStrings.SIGN_IN_TOTAL_DAY_NEW,nTotalDays)
    UIHelper.SetString(self.LabelRight,szText)
end

function UIDailySignIn:UpdateGoodLuckTag(i)
    if self.m_tLucky[i] == 3 then
        UIHelper.SetVisible(self.tbImgBgTagLuckyMeeting[i],true)
    elseif self.m_tLucky[i] == 4 then
        UIHelper.SetVisible(self.tbImgBgTagGoodLuck2[i],true)
    elseif self.m_tLucky[i] == 5 then
        UIHelper.SetVisible(self.tbImgBgTagGoodLuck3[i],true)
    elseif self.m_tLucky[i] == 6 then
        UIHelper.SetVisible(self.tbImgBgTagGoodLuck1[i],true)
    end

    UIHelper.LayoutDoLayout(self.tbLayoutHint[i])
end

function UIDailySignIn:GetAwardPool(nCountinuousDay, nTotalDay)
	local tPool = tDailyRewardPool

	if  nCountinuousDay <= MAX_DAY_OF_NEW_PLAYER and nTotalDay <= MAX_DAY_OF_NEW_PLAYER then
		tPool = tFirstWeekRewardPool
	end
	return tPool
end

function UIDailySignIn:GetInfoOfDoSomethingByLuckValue(nLuckValue)
	local tInfo = {}
    local tDataFromSignInLucky = self:GetDataFromSignInLucky()
    for k, v in pairs(tDataFromSignInLucky) do
        if v.nLuckValue == nLuckValue then
            tInfo = v
            break
        end
    end
	return tInfo
end

function UIDailySignIn:GetDoSomething()
	local tDataFromSignInLucky 	= self:GetDataFromSignInLucky()
	local nTodayIndex			= self:GetTodayIndex()
	local nLuckValue			= self.m_tLucky[nTodayIndex]
	local tInfoOfDoSomething	= self:GetInfoOfDoSomethingByLuckValue(nLuckValue)
    if IsTableEmpty(tInfoOfDoSomething) then
        local player = g_pClientPlayer
        local nTime = GetCurrentTime()
        local t = TimeToDate(nTime)
        local nTotalLucky = g_tTable.SignInLucky:GetRowCount() - 1
        local nLuck1 = ((t.year + t.month * 12 + t.day * 30 + t.weekday * 7 + player.dwID) % nTotalLucky) + 1
        local nLuck2 = ((nLuck1 + t.day * 31 + t.weekday * 6 + player.dwID) % nTotalLucky) + 1
        if nLuck1 == nLuck2 then
            nLuck2 = (nLuck2 + 1) % nTotalLucky
        end

        if t.year == 2024 and t.month == 10 and  t.day == 30 and t.hour >= 7 then
            nLuck1 = 49
            nLuck2 = 50
        elseif t.year == 2024 and t.month == 10 and  t.day == 31 and t.hour >= 7 then
            nLuck1 = 49
            nLuck2 = 25
        end

        local tLuck1 = g_tTable.SignInLucky:Search(nLuck1)
        local tLuck2 = g_tTable.SignInLucky:Search(nLuck2)
        UIHelper.SetString(self.LabelRecommend1,UIHelper.GBKToUTF8(tLuck1.szDesc))
        UIHelper.SetString(self.LabelRecommend2,UIHelper.GBKToUTF8(tLuck2.szDesc))
        UIHelper.SetVisible(self.LabelRecommend2,true)
    else
        UIHelper.SetString(self.LabelRecommend1,UIHelper.GBKToUTF8(tInfoOfDoSomething.szDesc))
        UIHelper.SetVisible(self.LabelRecommend2,false)
    end
end

--更新的是下面签筒的状态
function UIDailySignIn:UpdateSignInState()
    if IsSigned() then
        UIHelper.StopAni(self,self.WidgetAniLotPot,"AniLotPotLoop")
        UIHelper.SetVisible(self.WidgetLotBig,true)
        UIHelper.SetVisible(self.WidgetLotPot,false)
        UIHelper.SetVisible(self.BtnPress,false)

        local nTodayIndex = self:GetTodayIndex()
		local nYunShi = self.m_tYunShi[nTodayIndex]
        UIHelper.SetVisible(self.tbWidgetLotBig[nYunShi],true)

        if self.onDailySignGetAward then
            UIHelper.SetVisible(self.WidgetLotPot,true)
            UIHelper.PlayAni(self,self.WidgetAniLotPot,"AniPressSignin",function ()
                UIHelper.SetVisible(self.WidgetLotPot,false)
                UIHelper.SetVisible(self.BtnPress,false)
                UIHelper.SetOpacity(self.WidgetLotBig,225)
                self:InitSignInInfo() -- 需要在动画结束后重新取一次扩展点信息
                --播完动画再更新弹窗提示一类
                self:ShowWndOfReward()
                self:UpdateRewardList()
            end)
        end
    else
        UIHelper.SetVisible(self.WidgetLotBig,false)
        UIHelper.SetVisible(self.WidgetLotPot,true)
        UIHelper.SetVisible(self.BtnPress,true)
        UIHelper.PlayAni(self,self.WidgetAniLotPot,"AniLotPotLoop")
    end
end

--抽了之后的
function UIDailySignIn:ShowWndOfReward()
    local nTodayIndex	= self:GetTodayIndex()
	local nAwardIndex 	= self.m_tAwardIndex[nTodayIndex]
	local nTotalDay		= self:GetTotalDayOfSignInAward()
	local tAward 		= self:GetAwardPool(nTodayIndex, nTotalDay)[nTodayIndex][nAwardIndex]
	local nYunShi 		= self.m_tYunShi[nTodayIndex]
	local nTimes		= self:GetTimesOfAward(nYunShi)
    local nLucky 		= self.m_tLucky[nTodayIndex]

    local szText = FormatString(g_tStrings.STR_TIMES_OF_REWARD, g_tStrings.SIGN_IN_NAME_OF_RESULT[nYunShi], self:GetTimesOfAward(nYunShi))
    TipsHelper.ShowNormalTip(szText)

    szText = g_tStrings.SIGN_IN_AWARD_TEXT[nLucky]
    if szText then
        TipsHelper.ShowNormalTip(szText)
    end

    local nCount = nTimes*tAward[3]
    if not nCount or nCount == 0 then nCount = 1 end
    -- 把那个通用弹窗屏蔽了，这里手动加一个 重复了
    TipsHelper.ShowRewardList({
        {nTabType = tAward[1], nTabID = tAward[2], nCount = nCount}
    },1) -- 避免弹窗还没展开就被点击关闭的情况，强制两秒后才能关闭
end

function IsSigned()
	return g_pClientPlayer.bContinuousLoginRewardFlag
end

function Convert(nVal)
	local szVal = tostring(nVal)
	local nCount = #szVal
	local tVal = {}
	for i = 1, SIGN_DAY_COUNT do
		local char = string.sub(szVal, -i, -i)
		tVal[i] = tonumber(char) or 0
	end
	return tVal
end

function GetLunarDate(nTime)
	nTime = nTime or GetCurrentTime()
	local t = TimeToDate(nTime)
	local tLunar = GetActivityMgrClient().SolarDateToLunar(t.year, t.month, t.day)
	return g_tLunarString.tMonName[tLunar.nMonth], g_tLunarString.tDayName[tLunar.nDay]
end

g_tLunarString = {
	--农历日期名
	DATA_TITLE = "农历",
    tDayName =
    {
        "初一","初二","初三","初四","初五",
        "初六","初七","初八","初九","初十",
        "十一","十二","十三","十四","十五",
        "十六","十七","十八","十九","二十",
        "廿一","廿二","廿三","廿四","廿五",
        "廿六","廿七","廿八","廿九","三十"
    },
    --农历月份名
    tMonName = {"正月","二月","三月","四月","五月","六月", "七月","八月","九月","十月","十一月","腊月"}
};

return UIDailySignIn