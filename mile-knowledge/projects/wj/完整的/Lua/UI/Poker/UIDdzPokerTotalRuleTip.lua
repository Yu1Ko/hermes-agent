-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerTotalRuleTip
-- Date: 2023-08-11 14:34:25
-- Desc: 斗地主卡牌综合规则提示
-- 包含：规则，倍数提示，调整面板等
-- ---------------------------------------------------------------------------------

local UIDdzPokerTotalRuleTip = class("UIDdzPokerTotalRuleTip")
local DI_CARD_NUM = 3
local tTimesNum = {
	["SpecialCard"] = function() return DdzPokerData.DataModel.nDiPaiDouble end,
	["MingPaiReady"] = function() return DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_MINGPAI_STATE_INIT] end,
	["MingPai"] = function() return DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_MINGPAI_STATE_SHUFFLE] end,
	["JiaoDiZhu"] = function() return DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_CHAIRMAN_CALL] end,
	["QiangDiZhu"] = function() return DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_CHAIRMAN_ROB]end,
	["JiaBei"] = function() return DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_NORMAL] end,
	["SuperJiaBei"] = function() return DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_SUPER] end,
}
local LAIZI_START_NUM = 3
local LAIZI_END_NUM = 15

function UIDdzPokerTotalRuleTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDdzPokerTotalRuleTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerTotalRuleTip:BindUIEvent()

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetJiabeiBoard,false)
    end)

    UIHelper.SetTouchDownHideTips(self.TogPublicTimes , false)
    UIHelper.BindUIEvent(self.TogPublicTimes , EventType.OnClick , function ()
        UIHelper.SetVisible(self.WidgetJiabeiBoard,true)
    end)
end

function UIDdzPokerTotalRuleTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerTotalRuleTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerTotalRuleTip:UpdateRuleText()
    local szText = g_tStrings.STR_DDZ_DIFEN[DdzPokerData.DataModel.tRule.nDiFen] .. g_tStrings.STR_CONNECT ..
		g_tStrings.STR_DDZ_WANFA[DdzPokerData.DataModel.tRule.nWanFa] .. g_tStrings.STR_CONNECT ..
		g_tStrings.STR_DDZ_XIPAI[DdzPokerData.DataModel.tRule.nXiPai]
    UIHelper.SetString(self.TextRuleDetail , szText)
end

function UIDdzPokerTotalRuleTip:UpdateCardCount()
    self:CheckCardCounCells()
    local nidx = DdzPokerData.CARD_START
    for i, v in ipairs(self.tbCardCountCells) do
        v:ShowCardCount(DdzPokerData.DataModel.tCardCount[nidx])
        nidx = nidx + 1
    end
end

function UIDdzPokerTotalRuleTip:CheckCardCounCells()
    if not self.tbCardCountCells then
        self.tbCardCountCells = {}
        for i = DdzPokerData.CARD_START, DdzPokerData.CARD_END do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCardCount , self.LayoutCardCount)
            script:UpdateCardType(i)
            table.insert( self.tbCardCountCells, script)
        end
    end
end

function UIDdzPokerTotalRuleTip:UpdateDiCard()
    self:CheckDiCard()
    for i = 1, DI_CARD_NUM do
        self.tbDiCardCells[i]:SetVisible(table_is_empty(DdzPokerData.DataModel.tThreeCards.tUIData))
    end
end

function UIDdzPokerTotalRuleTip:InitDiCard()
    self:CheckDiCard()
    local tThreeCards = DdzPokerData.DataModel.tThreeCards.tUIData
    for i = 1, DI_CARD_NUM do
        self.tbDiCardCells[i]:SetVisible(true)
		self.tbDiCardCells[i]:ShowDiCard(tThreeCards[i])
	end
end

function UIDdzPokerTotalRuleTip:InitTableThreeCard()
    for i = 1, 3 do
        local szIconPath = DdzPokerData.GetCardIconPath(DdzPokerData.DataModel.tThreeCards.tUIData[i])
        UIHelper.SetSpriteFrame(self.tbShowDiCard[i], szIconPath)
	end
end

function UIDdzPokerTotalRuleTip:UpdateTableThreeCard(bVisible)
    UIHelper.SetVisible(self.WidgetShowDiCard , bVisible)
end

function UIDdzPokerTotalRuleTip:CheckDiCard()
    if not self.tbDiCardCells then
        self.tbDiCardCells = {}
        for i = 1, DI_CARD_NUM do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetDiCard , self.LayoutDiCard)
            table.insert(self.tbDiCardCells, script)
        end
    end
end

function UIDdzPokerTotalRuleTip:UpdateCmpButton()
    UIHelper.SetString(self.LabelSequence ,DdzPokerData.IsAsc() and "降序" or "升序")
end

function UIDdzPokerTotalRuleTip:InitLaiziIcon()
    local tCard = DdzPokerData.DataModel.tDiLaiZi.tUIData
	local nDiCardNum
	if tCard and (not table_is_empty(tCard)) then
		nDiCardNum = tCard[3]
	else
		nDiCardNum = 0
	end
	tCard = DdzPokerData.DataModel.tTianLaiZi.tUIData
	local nTianCardNum
	if tCard and (not table_is_empty(tCard)) then
		nTianCardNum = tCard[3]
	else
		nTianCardNum = 0
	end
    self:CheckCardCounCells()
	for i, v in pairs(self.tbCardCountCells) do
        v:InitLaiziIcon(nDiCardNum , nTianCardNum)
    end
end


function UIDdzPokerTotalRuleTip:UpdateLaiziState(bVisible)
    self:CheckCardCounCells()
    for i, v in pairs(self.tbCardCountCells) do
        v:UpdateLaiziState(bVisible)
    end
end

function UIDdzPokerTotalRuleTip:UpdateDiCardTip(bVisible)
    UIHelper.SetVisible(self.WidgetDiCardTips , bVisible)
end

function UIDdzPokerTotalRuleTip:SetCardCountVisible(bVisible)
    UIHelper.SetVisible(self.WidgetCardCountGroup , bVisible)
end

function UIDdzPokerTotalRuleTip:InitDoubleTimes()
    self:SetDoubleText(self.LableChushiNum , DdzPokerData.DataModel.nInitDouble)
    self:SetDoubleText(self.LableDipaiNum , DdzPokerData.DataModel.nDiPaiDouble)
    self:SetDoubleText(self.LableMingpaiNum , DdzPokerData.DataModel.nMingPaiDouble)
    self:SetDoubleText(self.LableZhadanNum , DdzPokerData.DataModel.nBoomDouble)
    self:SetDoubleText(self.LableQiangdizhuNum , DdzPokerData.DataModel.nDiZhuDouble)
    self:SetDoubleText(self.LableChuntianNum , DdzPokerData.DataModel.nSpringDouble)
    self:SetDoubleText(self.LabelDizhujiabeiNum , DdzPokerData.DataModel.nDiZhuDoubleTimes)
    self:SetDoubleText(self.LabelNongminjiabeiNum , DdzPokerData.DataModel.nNongMingDoubleTimes)
    DdzPokerData.DataModel.nTotalDoubleTimes = DdzPokerData.DataModel.nNongMingDoubleTimes * DdzPokerData.DataModel.nDiZhuDoubleTimes * DdzPokerData.DataModel.nPublicTimes
    self:SetDoubleText(self.LabelWanjiabeishuNum , DdzPokerData.DataModel.nTotalDoubleTimes)
    UIHelper.SetString(self.TextBeiNum , DdzPokerData.DataModel.nTotalDoubleTimes)
    UIHelper.SetString(self.LabelGonggongbeishuNum , DdzPokerData.DataModel.nPublicTimes)
end

function UIDdzPokerTotalRuleTip:SetDoubleText(labelText , nNum)
    UIHelper.SetString(labelText , g_tStrings.STR_MUL .. (nNum or 1))
end

function UIDdzPokerTotalRuleTip:InitDiCardTip()
    if g_tStrings.STR_DDZ_BOTTOMTYPE_TIP[DdzPokerData.DataModel.nBottomType] then
        local content = string.gsub( g_tStrings.STR_DDZ_BOTTOMTYPE_TIP[DdzPokerData.DataModel.nBottomType] , "<D0>" , DdzPokerData.DataModel.nDiPaiDouble)
        UIHelper.SetString(self.TextDiCard , content)
	end
end

function UIDdzPokerTotalRuleTip:PlayTimesTipAni(szType)
    UIHelper.SetVisible(self.WidgetTimesTip , true)
    local nNum = tTimesNum[szType]()
    UIHelper.SetSpriteFrame(self.ImgTimesTipNum , "UIAtlas2_Mahjong_MahjongNum_yellow"..nNum)
    Timer.Add(self , 1 , function ()
        UIHelper.SetVisible(self.WidgetTimesTip , false)
    end)
end

function UIDdzPokerTotalRuleTip:InitShowRule()
    UIHelper.SetString(self.LabelDiFen , g_tStrings.STR_DDZ_DIFEN[DdzPokerData.DataModel.tRule.nDiFen])
    UIHelper.SetString(self.LabelLaiZi , g_tStrings.STR_DDZ_WANFA[DdzPokerData.DataModel.tRule.nWanFa])
    UIHelper.SetString(self.LabelXiPai , g_tStrings.STR_DDZ_XIPAI[DdzPokerData.DataModel.tRule.nXiPai])
end

function UIDdzPokerTotalRuleTip:UpdateShowRule(bShow)
    UIHelper.SetVisible(self.WidgetShowRule, bShow)
    if bShow then
        Timer.DelTimer(self, self.nShowRuleTimeID)
        self.nShowRuleTimeID = Timer.Add(self , 2 , function ()
            UIHelper.SetVisible(self.WidgetShowRule, false)
        end)
    end
end


return UIDdzPokerTotalRuleTip