-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractSettleDataView
-- Date: 2025-03-31 16:32:14
-- Desc: ?
-- ---------------------------------------------------------------------------------
local DELAY_CACULATE = 1500
local DELAY_UPDATE   = 500
local DELAY_FINAL_UPDATE = 1000

local tbPage2ShowAni = {
    [1] = {First = "AniMoneyGetItemList", Common = "AniMoneyGetItemListReturn"},
    [2] = {First = "AniRewardList", Common = "AniRewardListReturn"},
    [3] = {First = "AniCardList", Common = "AniCardListReturn"},
}

local REMOTE_DATA = {
	TREASURE_HUNT = 1183,
}

local tStaticList = {
    {szTitle = "生存时间",  nPQIndex = PQ_STATISTICS_INDEX.SPECIAL_OP_8,       szSuffix = "_Survive",  bTime = true    },
    {szTitle = "代币兑换",  nPQIndex = PQ_STATISTICS_INDEX.FINAL_MARK,         szSuffix = "_Pickup",   bBigNum = true  },
    {szTitle = "伤害",      nPQIndex = PQ_STATISTICS_INDEX.HARM_OUTPUT,        szSuffix = "_Damage",   bBigNum = true  },
    {szTitle = "治疗",      nPQIndex = PQ_STATISTICS_INDEX.TREAT_OUTPUT,       szSuffix = "_Heal",     bBigNum = true  },
    {szTitle = "击杀",      nPQIndex = PQ_STATISTICS_INDEX.DECAPITATE_COUNT,   szSuffix = "_Kill",                     },
    {szTitle = "助攻",      nPQIndex = PQ_STATISTICS_INDEX.KILL_COUNT,         szSuffix = "_Assist",                   },
}

local nGameStatePQIndex = PQ_STATISTICS_INDEX.SPECIAL_OP_5

local function ConverToTenK(nVal)
	if not nVal or type(nVal) ~= "number" or nVal < 10000 then
		return nVal
	end
	local szNewValue = FormatString(g_tStrings.MPNEY_TENTHOUSAND, KeepDecimalPoint(nVal / 10000, 1))
	return szNewValue
end
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(tUIInfo)
    if not tUIInfo then
        return
    end
    DataModel.bInit        = false
    DataModel.tCalcItems   = nil
    DataModel.nCurPrice    = 0
    DataModel.nBPAddExp    = tUIInfo.nBPAddExp
    DataModel.nBanishTime  = tUIInfo.nBanishTime
    DataModel.nTotalPrice  = tUIInfo.nTotalPrice
    DataModel.nMatchResult = tUIInfo.nMatchResult
    DataModel.tSoldItems   = tUIInfo.tSoldItems
    DataModel.tStoredItems = tUIInfo.tStoredItems
    DataModel.dwTeamID     = nil
    DataModel.bPlayHonorSFX = false
end

function DataModel.GetSoldItems()
    return DataModel.tSoldItems or {}
end

function DataModel.GetStoredItems()
    return DataModel.tStoredItems or {}
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

-----------------------------DataModel------------------------------
local UIExtractSettleDataView = class("UIExtractSettleDataView")
function UIExtractSettleDataView:OnEnter(tUIInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nCurPage = 1
    self.tbPage2ShowAni = clone(tbPage2ShowAni)

    self:Init(tUIInfo)
    self:UpdatePage()
end

function UIExtractSettleDataView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractSettleDataView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        if self.nCurPage < #self.tbPageWidget then
            self.nCurPage = self.nCurPage + 1
            self:UpdatePage()
            return
        end
        BattleFieldData.LeaveBattleField()
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        self.nCurPage = self.nCurPage - 1
        self:UpdatePage()
    end)
end

function UIExtractSettleDataView:RegEvent()
    Event.Reg(self, "BATTLE_FIELD_SYNC_STATISTICS", function ()
        self:UpdateStaticData_Self()
        self:UpdateTeammateCard()
    end)

    Event.Reg(self, EventType.UpdateTBFWareHouse, function ()
        self:UpdateBattlePass()
    end)
end

function UIExtractSettleDataView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractSettleDataView:Init(tUIInfo)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if not hPlayer.HaveRemoteData(REMOTE_DATA.TREASURE_HUNT) then
        hPlayer.ApplyRemoteData(REMOTE_DATA.TREASURE_HUNT, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
    end

    ApplyBattleFieldStatistics()
    -- BattleFieldData.ApplyTreasureBFTeamMemberCard()
    DataModel.Init(tUIInfo)
    self:UpdateInfo()
    self.nBanishTimer = Timer.AddFrameCycle(self, 1, function ()
        if DataModel.nBanishTime then
            local nCurTime = GetTickCount()
            local nTime = math.max(0, math.floor((DataModel.nBanishTime - nCurTime) / 1000))
            local szText = FormatString(g_tStrings.STR_BATTLEFIELD_BANISH, nTime)
            UIHelper.SetString(self.LabelTime, szText)
            if nTime <= 0 then
                DataModel.nBanishTime = nil
                BattleFieldData.LeaveBattleField()
            end
        end
    end)
end

function UIExtractSettleDataView:UpdateInfo()
    self:UpdateTitle()
    self:UpdateBattlePass()
    self:UpdateSelfCard()
    self:UpdateStaticData_Self()
    self:UpdateSoldItem()
    self:UpdateStoredItem()
    self:UpdateTeammateCard()
end

function UIExtractSettleDataView:UpdateSelfCard()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    UIHelper.RemoveAllChildren(self.WidgetPersonalCard1)
    local szGlobalID  = pPlayer.GetGlobalID()
    local scriptPersonalCard = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard1, szGlobalID)
	scriptPersonalCard:SetPlayerId(pPlayer.dwID)
    scriptPersonalCard:SetEquipNumVisible(false)
end

function UIExtractSettleDataView:UpdateTeammateCard()
    local hTeam = GetClientTeam()
    if not hTeam then
        return
    end
    local nIndex = 1
    local tMembers     = {}
    local dwTeamID     = DataModel.dwTeamID
    local szMyGlobalID = UI_GetClientPlayerGlobalID()
    local tbStaticData = GetBattleFieldStatistics()
    for dwID, v in pairs(tbStaticData) do
        local nTeam = v[11]
        if nTeam == dwTeamID then
            v.dwID = dwID
            table.insert(tMembers, v)
        end
    end

    table.sort(tMembers, function(a, b)
        return a.GlobalID == szMyGlobalID or (b.GlobalID ~= szMyGlobalID and a.GlobalID < b.GlobalID)
    end)

    for _, tPlayer in ipairs(tMembers) do
        local tbInfo     = {}
        local tbData     = tbStaticData[tPlayer.dwID] or {}
        local hMember    = hTeam.GetMemberInfo(tPlayer.dwID) or {}
        local szGlobalID = tPlayer.GlobalID or hMember.szGlobalID
        local widgetCard = self.tbTeammateCard[nIndex]
        local scriptCard = UIHelper.GetBindScript(widgetCard)
        for _, v in ipairs(tStaticList) do
            local szTitle = v.szTitle
            local szValue = tbData[v.nPQIndex] or 0
            if v.bTime then
                szValue = TimeLib.ACCInfo_Base_GetFormatTime(tonumber(szValue))
            end
            if v.bBigNum then
                szValue = ConverToTenK(tonumber(szValue))
            end
            table.insert(tbInfo, {szTitle = szTitle, szValue = szValue})
        end
        tbInfo.nState = tbData[nGameStatePQIndex] or 0

        UIHelper.SetVisible(widgetCard, szGlobalID and not table_is_empty(tbInfo))
        scriptCard:OnEnter(tbInfo, tPlayer.dwID, szGlobalID)
        nIndex = nIndex + 1
    end
end

function UIExtractSettleDataView:UpdateTitle()
    local nPrice = DataModel.nTotalPrice
    local nMatchResult = DataModel.nMatchResult

    local szTitleImgPath = tbExtractResultTitleImg[nMatchResult]
    local szTitleBgPath = tbExtractResultTitleBg[nMatchResult]
    local szPrice = "奇境宝钞  ".. tostring(nPrice)

    UIHelper.SetSpriteFrame(self.ImgRank1, szTitleImgPath)
    UIHelper.SetSpriteFrame(self.ImgCompeteMiddleTitle, szTitleBgPath)
    UIHelper.SetVisible(self.tbResultEff[nMatchResult], true)
    UIHelper.SetString(self.LabelMoney, szPrice)
    UIHelper.LayoutDoLayout(self.LayoutMoney)
end

function UIExtractSettleDataView:UpdateBattlePass()
    local nAddExp = DataModel.nBPAddExp
    local tbInfo = GDAPI_TbfWareSeasonLvInfo()
    if not tbInfo then
        return
    end

    local szAddExp = "+" .. tostring(nAddExp)
    local szLevel = string.format("等级 %d级", tbInfo.nCurLv)
    local nOldPercent = (tbInfo.nCurExp - nAddExp) / tbInfo.nLvUpExp * 100
    nOldPercent = math.max(nOldPercent, 0)
    local nNewPercent = tbInfo.nCurExp / tbInfo.nLvUpExp * 100

    UIHelper.SetString(self.LabelLevel, szLevel)
    UIHelper.SetString(self.LabelExpGain, szAddExp)
    UIHelper.SetProgressBarPercent(self.SliderLevel, nOldPercent)
    UIHelper.SetProgressBarPercent(self.SliderLevelAdd, nNewPercent)
end

function UIExtractSettleDataView:UpdateStaticData_Self()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tbStaticData  = GetBattleFieldStatistics()
    local tbMyInfo      = tbStaticData and tbStaticData[hPlayer.dwID] or {}
    DataModel.dwTeamID  = tbMyInfo[PQ_STATISTICS_INDEX.SPECIAL_OP_2]

    UIHelper.RemoveAllChildren(self.LayoutInfo)
    for _, v in ipairs(tStaticList) do
        local szTitle = v.szTitle
        local szValue = tbMyInfo[v.nPQIndex] or 0
        if v.bTime then
            szValue = TimeLib.ACCInfo_Base_GetFormatTime(tonumber(szValue))
        end
        if v.bBigNum then
            szValue = ConverToTenK(tonumber(szValue))
        end
        local tbData = {szTitle = szTitle, szValue = szValue}
        UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoSettlementRewardInfo, self.LayoutInfo, tbData)
    end
end

function UIExtractSettleDataView:UpdateSoldItem()
    UIHelper.RemoveAllChildren(self.ScrollViewItemList_Sold)

    local tSoldItems = DataModel.GetSoldItems()
    local szCurrencyImg = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_QiJing"
    for _, item in ipairs(tSoldItems) do
        local iteminfo = GetItemInfo(item.dwTabType, item.dwIndex)
        local szName = UIHelper.GBKToUTF8(iteminfo.szName)
		local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.ScrollViewItemList_Sold)
        local szValue = UIHelper.GetCurrencyText(item.nPrice, szCurrencyImg, 25)
        itemIcon:OnEnter(szName, item.nCount, item.dwTabType, item.dwIndex)
        itemIcon:SetIconCount(item.nCount)
        itemIcon:SetSingleClickCallback(function(nTabType, nItemIndex)
            if nTabType and nItemIndex then
                TipsHelper.ShowItemTips(itemIcon._rootNode, nTabType, nItemIndex, false, TipsLayoutDir.AUTO)
            end
        end)
        UIHelper.SetVisible(itemIcon.LabelTxt, false)
        UIHelper.SetVisible(itemIcon.RichTextTxt, true)
        UIHelper.SetRichText(itemIcon.RichTextTxt, szValue)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItemList_Sold)
end

function UIExtractSettleDataView:UpdateStoredItem()
    UIHelper.RemoveAllChildren(self.ScrollViewItemList_Store)

    local tStoredItems = DataModel.GetStoredItems()
    for _, item in ipairs(tStoredItems) do
        local tbItemInfo = {dwItemType = item.dwTabType or item[1], dwItemIndex = item.dwIndex or item[2], nNum = item.nCount or item[3]}
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoItemCell, self.ScrollViewItemList_Store)
        scriptCell:SetForbidShowCoolDown(true)
        scriptCell:OnEnter(tbItemInfo)

        scriptCell:SetClearSeletedOnCloseAllHoverTips(true)
        scriptCell:SetSelectChangeCallback(function (_, bSelected)
            if bSelected then
                TipsHelper.ShowItemTips(scriptCell._rootNode, item.dwTabType, item.dwIndex, false, TipsLayoutDir.AUTO)
            end
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItemList_Store)
end

function UIExtractSettleDataView:UpdatePage()
    for index, widget in ipairs(self.tbPageWidget) do
        UIHelper.SetVisible(widget, index == self.nCurPage)
    end

    local tbAni = self.tbPage2ShowAni[self.nCurPage]
    if not tbAni.bFirst then
        tbAni.bFirst = true
        UIHelper.PlayAni(self, self.tbPageWidget[self.nCurPage], tbAni.First)
    else
        UIHelper.PlayAni(self, self.tbPageWidget[self.nCurPage], tbAni.Common)
    end

    local szNextText = self.nCurPage >= #self.tbPageWidget and g_tStrings.STR_BATTLEFIELD_BACK_TO_MAINCITY or "继续"
    UIHelper.SetString(self.LabelLeave, szNextText)
    UIHelper.SetVisible(self.BtnBack, self.nCurPage > 1)
    UIHelper.SetVisible(self.WidgetBg, self.nCurPage ~= #self.tbPageWidget)
end

return UIExtractSettleDataView