-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFanpaiShuang11
-- Date: 2024-10-18 10:06:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFanpaiShuang11 = class("UIFanpaiShuang11")

local TOTAL_CARD_COUNT = 12
local LOTTERY_ONE = 1
local LOTTERY_TEN = 10
local tbMyShowCardPath = {
    "Resource/Shuang11Reward/Icon_LiFeiSha.png",
    "Resource/Shuang11Reward/Icon_Mache.png",
    "Resource/Shuang11Reward/Icon_YueKa.png",
    "Resource/Shuang11Reward/Icon_TongBao5.png",
    "Resource/Shuang11Reward/Icon_YishideZunjing.png",
}

function UIFanpaiShuang11:OnEnter(dwOperatActID, nID)
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
    if not tLine then
        return
    end

    Global.SetShowRewardListEnable(VIEW_ID.PanelHuaELou, false)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelHuaELou, true)

    self.nID = nID
    self.dwOperatActID = dwOperatActID

    self:UpdateBaseInfo()
    self:ApplyGlobalCounter()
    self:InitViewInfo()
end

function UIFanpaiShuang11:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    Global.SetShowRewardListEnable(VIEW_ID.PanelHuaELou, true)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelHuaELou, false)
end

function UIFanpaiShuang11:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOne, EventType.OnClick, function ()
        self.bIsLotteryAllowed = true
        self.bBtnOne = true
        self:BeginLottery(LOTTERY_ONE)
    end)

    UIHelper.BindUIEvent(self.BtnTen, EventType.OnClick, function ()
        self.bIsLotteryAllowed = true
        self:BeginLottery(LOTTERY_TEN)
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function ()
        self:ShowAwardsOwnedByPlayer(true)
    end)

    UIHelper.BindUIEvent(self.BtnCalendar, EventType.OnClick, function ()
        self:ShowSmallCalender(true)
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function ()
        self:ShowCardList(true)
    end)

    UIHelper.BindUIEvent(self.BtnBack2, EventType.OnClick, function ()
        self:ShowCardList(true)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function ()
        self:OnClickSure()
    end)

    UIHelper.BindUIEvent(self.BtnTen2, EventType.OnClick, function ()
        self.bIsLotteryAllowed = true
        self:BeginLottery(LOTTERY_TEN)
    end)

    UIHelper.BindUIEvent(self.BtnChongXiao, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnChongXiao,
        g_tStrings.STR_DOUBLE_ELEVEN_LOTTERY_TIPS1)
    end)

    UIHelper.BindUIEvent(self.BtnHelp2, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp2,
        g_tStrings.STR_DOUBLE_ELEVEN_LOTTERY_TIPS2)
    end)
end

function UIFanpaiShuang11:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "SYNC_GLOBAL_ACTIVITY_COUNTER", function (dwStartID, nCount)
        self:SyncGlobalCounterValue(dwStartID, nCount)
        self:UpdateLeftTongBao()
    end)

    Event.Reg(self, "GLOBAL_ACTIVITY_COUNTER_VALUE_UPDATE", function (dwCounterID, nValue)
        self.tAllGlobalCounterValue = self.tAllGlobalCounterValue or {}
        self.tAllGlobalCounterValue[dwCounterID] = nValue
        self:UpdateLeftTongBao()
    end)

    Event.Reg(self, "On_Recharge_CheckTongBaoGift_CallBack", function ()
        self:On_Recharge_CheckTongBaoGift_CallBack()
        self:ShowCardList(true)
    end)

    Event.Reg(self, "On_Recharge_GetTongBaoGiftRwd_CallBack", function (tCardsList, bSuccess, tRewardInfo)
        self:On_Recharge_GetTongBaoGiftRwd_CallBack(tCardsList, bSuccess, tRewardInfo)
    end)
end

function UIFanpaiShuang11:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFanpaiShuang11:UpdateBaseInfo()
    self.bReqSuccess = true
    local tLine = Table_GetOperActyInfo(self.dwOperatActID)
    if tLine then
        if tLine.szTitle then
            UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
            UIHelper.SetString(self.LabelLeft, UIHelper.GBKToUTF8(tLine.szTitle))
            local tStartTime, tEndTime = tLine.tStartTime, tLine.tEndTime
            local nStart = tStartTime[1]
            local nEnd = tEndTime and tEndTime[1]
            UIHelper.SetString(self.LabelTime, HuaELouData.GetTimeShowText(nStart, nEnd) or "")
        end

        self.dwCounterID = tLine.dwCounterID
        self.nCount = tLine.nCount

        self.tAwardOfLottery = Table_GetOperationActCard()
    end
end

function UIFanpaiShuang11:ApplyGlobalCounter()
    local nStartOfGlobalActivityCounterID = self.dwCounterID
    local nNumOfGlobalActivityCounterID = self.nCount
    if nStartOfGlobalActivityCounterID ~= -1 then
        ApplyGlobalActivityCounter(nStartOfGlobalActivityCounterID, nNumOfGlobalActivityCounterID)
    end

    RemoteCallToServer("On_Recharge_CheckTongBaoGift")
end

function UIFanpaiShuang11:SyncGlobalCounterValue(dwStartID, nCount)
    for dwCounterID = dwStartID, dwStartID + nCount - 1 do
        local nGlobalValue = GetGlobalActivityCounterValue(dwCounterID)

        self.tAllGlobalCounterValue = self.tAllGlobalCounterValue or {}
        self.tAllGlobalCounterValue[dwCounterID] = nGlobalValue
    end
end

function UIFanpaiShuang11:UpdateLeftTongBao()
    local nCounterID = self.dwCounterID
    local nLeftTongBao = 0
    if self.bReqSuccess then
        nLeftTongBao = self.tAllGlobalCounterValue and self.tAllGlobalCounterValue[nCounterID] or 0
    end
    local nTodayAvailableTimes = HuaELouData.nTodayTimesLeft4 or 0
    local bShowTongBaoCard = nLeftTongBao ~= 0
    local bTenEnable = (not bShowTongBaoCard) and (nTodayAvailableTimes >= 10)

    self:UpdateCounterValue(nLeftTongBao)
    self:ShowTongBaoCards(bShowTongBaoCard)
    self:EnableLotteryTenBtn(bTenEnable)
end

function UIFanpaiShuang11:UpdateCounterValue(nNewValue)
    local szNewValue = self:GetTabValue(nNewValue)
    UIHelper.SetString(self.LabelTongBao, szNewValue)
end

function UIFanpaiShuang11:GetTabValue(nNewValue)
    if not nNewValue then
		return
	end
	local tResidue = {}
	local nConsult = nNewValue
    local nResidue

	while string.len(tostring(nConsult)) > 3 do
		nResidue = nConsult%1000
		nConsult = math.floor(nConsult/1000)
		if string.len(nResidue) < 3 then
			nResidue = string.format("%03d", nResidue)
		end
		table.insert(tResidue, nResidue)
	end
	table.insert(tResidue, nConsult)

	local nLen = #tResidue
	local szVlaue = ""
	for i = nLen, 2, -1 do
		szVlaue = szVlaue .. tResidue[i] .. g_tStrings.STR_DELIMITER_COMMA
	end
	szVlaue = szVlaue .. tResidue[1]

	return szVlaue
end

--通宝相关的隐藏掉
function UIFanpaiShuang11:ShowTongBaoCards(bShow)
    for i = 1, TOTAL_CARD_COUNT do
        local scriptCard = self.tShowCardList[i]
        if scriptCard and scriptCard.szCardType == "TongBao" then
            UIHelper.SetVisible(scriptCard.WidgetReward, bShow)
            UIHelper.SetVisible(scriptCard.WidgetCardBg, not bShow)
        end
    end
end

function UIFanpaiShuang11:EnableLotteryTenBtn(bEnable)
    if bEnable ~= nil then
        UIHelper.SetButtonState(self.BtnTen, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnTen2, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetTouchEnabled(self.BtnTen, bEnable)
        UIHelper.SetTouchEnabled(self.BtnTen2, bEnable)
    end
end

function UIFanpaiShuang11:EnableLotteryOneBtn(bEnable)
    if bEnable ~= nil then
        UIHelper.SetButtonState(self.BtnOne, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetTouchEnabled(self.BtnOne, bEnable)
    end
end

function UIFanpaiShuang11:InitViewInfo()
    self:InitShowCardList()
    self:InitMyCardList()
    self:InitCalendar()
    self:InitSingleCard()
    self:InitCardList()
end

function UIFanpaiShuang11:InitShowCardList()
    local tAwardList = self:GetAwardInfoOfLotteryFromOperationActCardWithinRange(1, TOTAL_CARD_COUNT)
    local tAwardIter, tAwardIterVal = next(tAwardList)

    self.tShowCardList = {}
    for i = 1, TOTAL_CARD_COUNT, 1 do
        if tAwardIter then
            local scriptCard = UIHelper.GetBindScript(self.tShowCardListNode[i])
            if scriptCard then
                UIHelper.SetTexture(scriptCard.ImgReward, tAwardIterVal.szMoblieImage)
                UIHelper.SetString(scriptCard.LabelNum2, UIHelper.GBKToUTF8(tAwardIterVal.szName))
                scriptCard.szCardType = tAwardIterVal.szType
            end
            tAwardIter, tAwardIterVal = next(tAwardList, tAwardIter)

            table.insert(self.tShowCardList, scriptCard)
        end
    end
end

function UIFanpaiShuang11:InitMyCardList()
    for k, v in ipairs (self.tbShowCardImg) do
        UIHelper.SetTexture(v, tbMyShowCardPath[k])
    end
end

function UIFanpaiShuang11:InitCalendar()
    local m_tData = HuaELouData.GetCalenderData()
    local nDay = m_tData.nStart
    local nCount = m_tData.nDayCount
    local tStart = TimeToDate(m_tData.nStart)
    local tEnd = TimeToDate(m_tData.nEnd)

    local szEndTime = tEnd.month .. g_tStrings.STR_MONTH .. tEnd.day .. g_tStrings.STR_DAY
    szEndTime = szEndTime .. string.format(g_tStrings.STR_TIME_14, tEnd.hour, tEnd.minute, tEnd.second)
    UIHelper.SetString(self.LabelRight2, szEndTime)

    UIHelper.RemoveAllChildren(self.ScrollViewLayoutCardList2)
    self.tCalendar = {}

    for i = 1, nCount, 1 do
        local tDay = TimeToDate(nDay)

        local scriptCard = UIHelper.AddPrefab(PREFAB_ID.WidgetShuang11Card, self.ScrollViewLayoutCardList2)
        if scriptCard then
            UIHelper.SetVisible(scriptCard.WidgetCalendar, true)
            UIHelper.SetVisible(scriptCard.TogShuang11Card, false)
            UIHelper.SetString(scriptCard.LabelData, tDay.day)
            if i == nCount then
                UIHelper.SetVisible(scriptCard.LabelNum5, true)
                UIHelper.SetString(scriptCard.LabelNum5, tEnd.day)
            end
        end
        nDay = nDay + 24 * 3600

        table.insert(self.tCalendar, scriptCard)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLayoutCardList2)
end

function UIFanpaiShuang11:InitSingleCard()
    self.scriptSingleCard = UIHelper.GetBindScript(self.tbMySingleCardNode[1])
end

function UIFanpaiShuang11:InitCardList()
    self.scriptCardList = {}

    for i = 1, LOTTERY_TEN, 1 do
        local scriptCard = UIHelper.GetBindScript(self.tbMyTenCardNode[i])
        if scriptCard then
            table.insert(self.scriptCardList, scriptCard)
        end
    end
end

function UIFanpaiShuang11:GetAwardInfoOfLotteryFromOperationActCardWithinRange(from, to)
    local tResOfAwardList = {}
    for _, v in pairs(self.tAwardOfLottery) do
        if v.dwID >= from and v.dwID <= to then
            table.insert(tResOfAwardList, v)
        end
    end

    return tResOfAwardList
end

-- 	参数分别为
-- 充值消费总额，可抽奖总次数，已使用的抽奖次数，今天剩余的抽奖次数，
-- 过往（包括今天）每天使用的抽奖次数，未来（包括今天）每天的可抽次数，已获得的奖励数据，
-- 额外赠送次数使用信息, 额外资格总次数
function UIFanpaiShuang11:On_Recharge_CheckTongBaoGift_CallBack()
    self:UpdateRewardState()
end

function UIFanpaiShuang11:UpdateRewardState()
    self:UpdateChargeMoney()
    self:UpdateRemainTimes()
    self:UpdateTodayTimes()
    self:UpdateAwardsOwnedByPlayer()
    self:UpdateLeftTongBao()
    self:UpdateStateOfLotteryBtn()
    self:UpdateCountInfo()
    self:UpdateCalenderData()
end

function UIFanpaiShuang11:UpdateChargeMoney()
    UIHelper.SetString(self.LabelMoney, HuaELouData.nMoney4)
end

function UIFanpaiShuang11:UpdateRemainTimes()
    local nTotalTimes = HuaELouData.nTotalTimes4
    local nTotalAvailableTimes = HuaELouData.nUsedTimesTotal4 or 0
    local szRemainTimes = tostring(nTotalAvailableTimes) .."/" .. tostring(nTotalTimes)

    UIHelper.SetString(self.LabelNum2, szRemainTimes)
end

function UIFanpaiShuang11:UpdateTodayTimes()
    local nTodayAvailableTimes = HuaELouData.nTodayTimesLeft4
    local szText = FormatString(g_tStrings.STR_TIMES, nTodayAvailableTimes)

    UIHelper.SetString(self.LabelNum4, szText)
end

function UIFanpaiShuang11:UpdateAwardsOwnedByPlayer()
    local tRewardInfo = HuaELouData.tRewardInfo4 or {}
    local nNumOfAwardType = #tRewardInfo

    for i = 1, nNumOfAwardType, 1 do
        UIHelper.SetString(self.tbShowCardNum[i], tRewardInfo[i])
    end
end

function UIFanpaiShuang11:UpdateStateOfLotteryBtn()
    local nCounterID = self.dwCounterID
    local nLeftTongBao = self.tAllGlobalCounterValue and self.tAllGlobalCounterValue[nCounterID] or 0
    local nTodayAvailableTimes = HuaELouData.nTodayTimesLeft4 or 0
    local bOneEnable = nTodayAvailableTimes > 0
	local bTenEnable = nTodayAvailableTimes >= 10 and nLeftTongBao == 0

    self:EnableLotteryTenBtn(bTenEnable)
    self:EnableLotteryOneBtn(bOneEnable)
end

--所有卡牌列表，是否成功，已经获得的奖励信息，商城积分
--第十二张是真卡，也就是玩家这次抽出来的卡
--已经获得的奖励信息 ：{nRwdAmount_1, nRwdAmount_2, nRwdAmount_3, nRwdAmount_4, nRwdAmount_5} ,数据顺序必须与
--[[
tCardsList= {
	[1] = {21}, 21对应OperatActCard.txt里面的id
}
--]]
function UIFanpaiShuang11:On_Recharge_GetTongBaoGiftRwd_CallBack(tCardsList, bSuccess, tRewardInfo)
    self.bReqSuccess = bSuccess
    if not bSuccess or (#tCardsList ~= LOTTERY_ONE and #tCardsList ~= LOTTERY_TEN) then
        UIHelper.StopAllAni(self)
        Timer.AddFrame(self, 1, function ()
            self:OnClickSure()
            self:UpdateRewardState()
        end)
        return
    end

    self.bBtnOne = false

    self:UpdateCardContentByCardList(tCardsList)
    self:FlipAllCards(tCardsList)
end

function UIFanpaiShuang11:BeginLottery(nCardCount)
    for k, v in ipairs(self.tbShowCardListNode) do
        UIHelper.SetVisible(v, false)
    end

    for k, v in ipairs(self.tbSingleCard) do
        UIHelper.SetVisible(v, false)
    end

    for k, v in ipairs(self.tbCardList) do
        UIHelper.SetVisible(v, false)
    end

    local szClipName = ""
    if nCardCount == LOTTERY_ONE then
        szClipName = "AniPrizeDraw1"
    else
        szClipName = "AniPrizeDraw10"
    end

    UIHelper.PlayAni(self, self.WidgetCardList, szClipName, function ()
        if nCardCount == LOTTERY_ONE then
            RemoteCallToServer("On_Recharge_GetTongBaoGiftRwd", LOTTERY_ONE)
        else
            RemoteCallToServer("On_Recharge_GetTongBaoGiftRwd", LOTTERY_TEN)
        end
    end)
end

function UIFanpaiShuang11:ShowAwardsOwnedByPlayer(bShow)
    for k, v in ipairs(self.tbShowCardListNode) do
        UIHelper.SetVisible(v, not bShow)
    end

    for k, v in ipairs(self.tbMyCardListNode) do
        UIHelper.SetVisible(v, bShow)
    end
end

function UIFanpaiShuang11:ShowSmallCalender(bShow)
    for k, v in ipairs(self.tbShowCardListNode) do
        UIHelper.SetVisible(v, not bShow)
    end

    for k, v in ipairs(self.tbCalendarNode) do
        UIHelper.SetVisible(v, bShow)
    end
end

function UIFanpaiShuang11:ShowCardList(bShow)
    for k, v in ipairs(self.tbShowCardListNode) do
        UIHelper.SetVisible(v, bShow)
    end

    for k, v in ipairs(self.tbMyCardListNode) do
        UIHelper.SetVisible(v, not bShow)
    end

    for k, v in ipairs(self.tbCalendarNode) do
        UIHelper.SetVisible(v, not bShow)
    end
end

--[[
tCardsList= {
	[1] = {Type = "Zhekouquan", 21}, 21对应OperatActCard.txt里面的id
}
--]]
function UIFanpaiShuang11:UpdateCardContentByCardList(tCardsList)
    local tAwardInfoList = self.tAwardOfLottery

    local tAwardInfo = nil
    for i = 1, #tCardsList, 1 do
        for _, v in ipairs(tAwardInfoList) do
            if v.dwID == tCardsList[i][1] then
                tAwardInfo = v
                break
            end
        end

        if tAwardInfo then
            local scriptCard
            if #tCardsList == LOTTERY_ONE then
                scriptCard = self.scriptSingleCard
            else
                scriptCard = self.scriptCardList[i]
            end
            if scriptCard then
                UIHelper.SetTexture(scriptCard.ImgReward, tAwardInfo.szMoblieImage)
                UIHelper.SetString(scriptCard.LabelNum2, UIHelper.GBKToUTF8(tAwardInfo.szName))
            end
        end
    end
end

function UIFanpaiShuang11:FlipAllCards(tCardsList)
    if #tCardsList == LOTTERY_ONE then
        UIHelper.PlayAni(self, self.scriptSingleCard._rootNode, "AniFlip01", function ()
            for k, v in ipairs(self.tbSingleCard) do
                UIHelper.SetVisible(v, true)
            end
            self:AfterLotteryAnimationFinished()
        end)
    else
        local nIndex = 1

        self.tTimer = Timer.AddCycle(self, 0.34, function ()
            UIHelper.PlayAni(self, self.scriptCardList[nIndex]._rootNode, "AniFlip01")
            if nIndex == LOTTERY_TEN then
                Timer.DelTimer(self, self.tTimer)
                self.tTimer = nil
                for k, v in ipairs(self.tbCardList) do
                    UIHelper.SetVisible(v, true)
                end
                self:AfterLotteryAnimationFinished()
            else
                nIndex = nIndex + 1
            end
        end)
    end
end

function UIFanpaiShuang11:AfterLotteryAnimationFinished(tCardsList)
    self.bIsLotteryAllowed = false
    self:UpdateRewardState()
end

function UIFanpaiShuang11:UpdateCountInfo()
    if HuaELouData.nMaxExtraTimes4 == 0 then
        HuaELouData.tExtraTimesInfo4 = {}
    end

    local nExtraLeftTimes 	= math.max(0, (HuaELouData.nMaxExtraTimes4 - #(HuaELouData.tExtraTimesInfo4)))
    local nUsedTimesTotal 	= HuaELouData.nUsedTimesTotal4
    local nTotalTimes 		= HuaELouData.nTotalTimes4
    local nTodayTimesLeft 	= HuaELouData.nTodayTimesLeft4

    nTotalTimes 	= HuaELouData.nTotalTimes4 + HuaELouData.nMaxExtraTimes4
    nUsedTimesTotal = HuaELouData.nUsedTimesTotal4 + #(HuaELouData.tExtraTimesInfo4)
    nTodayTimesLeft = HuaELouData.nTodayTimesLeft4 + nExtraLeftTimes
    local nLeftCount = nTotalTimes - nUsedTimesTotal

    UIHelper.SetString(self.LabelNum2_c, nLeftCount .."/" .. nTotalTimes)
    UIHelper.SetString(self.LabelNum4_c, nTodayTimesLeft)
end

function UIFanpaiShuang11:UpdateCalenderData()
    if not HuaELouData.tUsedTimes4 and not HuaELouData.tLotteryTimes4 and not HuaELouData.tExtraTimesInfo4 then
        return
    end

    local m_tData = HuaELouData.GetCalenderData()
    local nTime = GetCurrentTime()
    local tTodayTime = TimeToDate(nTime)
    local nDay = tTodayTime.day

    local IsShow = nTime > m_tData.nStart and nTime < m_tData.nEnd
    if IsShow then
        local nDayIndex = HuaELouData.nDayIndex or 1

        local nLotteryCount = self:GetLotteryCount()
        local nUsedCount = #HuaELouData.tUsedTimes4
        local nNowCount = nLotteryCount + nUsedCount
        if nLotteryCount ~= 0 then
            nNowCount = nNowCount - 1
        end

        for k, v in ipairs(self.tCalendar) do
            if k > nNowCount then
                break
            end

            local nTodayAllCount
            local nLeftTodayNum
            local nExtraUsedCount = self:GetExtraUsedCount(k)
            if k == nDayIndex then
                nTodayAllCount = (HuaELouData.tLotteryTimes4[k] or 0) + math.max(0, (HuaELouData.nMaxExtraTimes4 - #(HuaELouData.tExtraTimesInfo4))) + nExtraUsedCount
                nLeftTodayNum = HuaELouData.nTodayTimesLeft4 + math.max(0, (HuaELouData.nMaxExtraTimes4 - #(HuaELouData.tExtraTimesInfo4)))
                local nTodayUsedCount = nTodayAllCount - nLeftTodayNum

                for i = 1, #v.tbLabelNum, 1 do
                    UIHelper.SetString(v.tbLabelNum[i], nTodayUsedCount .. "/" .. nTodayAllCount)
                end
            else
                nTodayAllCount = (HuaELouData.tUsedTimes4[k] or HuaELouData.tLotteryTimes4[k]) + nExtraUsedCount
                for i = 1, #v.tbLabelNum, 1 do
                    UIHelper.SetString(v.tbLabelNum[i], nTodayAllCount)
                end
            end
        end

        for k, v in ipairs(self.tCalendar) do
            UIHelper.SetVisible(v.ImgWidgetRewardBgpass, k < nDayIndex)
            UIHelper.SetVisible(v.LabelNum3pass, k < nDayIndex)
            UIHelper.SetVisible(v.ImgWidgetRewardBg, k == nDayIndex)
            UIHelper.SetVisible(v.LabelNum3, k == nDayIndex)
            UIHelper.SetVisible(v.WidgetTipRight, k == nDayIndex)
            if k < nDayIndex then
            elseif k == nDayIndex then
            elseif (HuaELouData.tUsedTimes4[k] or HuaELouData.tLotteryTimes4[k]) and (HuaELouData.tUsedTimes4[k] or HuaELouData.tLotteryTimes4[k]) >= 0 then
                UIHelper.SetVisible(v.ImgWidgetRewardBgFuture, true)
                UIHelper.SetVisible(v.LabelNum3Future, true)
            else
                UIHelper.SetVisible(v.ImgWidgetRewardBgFuture, false)
                UIHelper.SetVisible(v.LabelNum3Future, false)
                UIHelper.SetVisible(v.ImgWidgetRewardBgpass, true)
                UIHelper.SetVisible(v.LabelNum3pass, true)
            end
        end
    end
end

function UIFanpaiShuang11:GetLotteryCount()
    local nCount = 0
    for k,v in pairs(HuaELouData.tLotteryTimes4) do
        nCount = nCount + 1
    end
    return nCount
end

function UIFanpaiShuang11:GetExtraUsedCount(nIndex)
    local nCount = 0
    for k, v in pairs(HuaELouData.tExtraTimesInfo4) do
        if v == nIndex then
            nCount = nCount + 1
        end
    end
    return nCount
end

function UIFanpaiShuang11:OnClickSure()
    for k, v in ipairs(self.tbSingleCard) do
        UIHelper.SetVisible(v, false)
    end

    for k, v in ipairs(self.tbCardList) do
        UIHelper.SetVisible(v, false)
    end

    for k, v in ipairs(self.tbShowCardListNode) do
        UIHelper.SetVisible(v, true)
    end

    self.bIsLotteryAllowed = false

    UIHelper.PlayAni(self, self.WidgetCardList, "AniRestore",function ()
        self.bReqSuccess = true
        self:UpdateRewardState()
    end)
    for k, v in ipairs(self.tShowCardList) do
        UIHelper.SetVisible(v.WidgetReward, true)
        UIHelper.SetVisible(v.WidgetCardBg, false)
    end

    self:UpdateLeftTongBao()
end

return UIFanpaiShuang11